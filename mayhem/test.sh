#!/usr/bin/env bash
#
# mayhem/test.sh — RUN imagesize's own upstream test suite (test/ — pytest collects the
# unittest+plain-assert tests upstream runs via `python -m unittest discover`) and emit a
# CTRF (ctrf.io) summary. exit 0 iff failed==0. PATCH-grade oracle: the tests assert exact
# (width, height)/DPI values for every shipped sample image, so a neutered library FAILS here.
#
# It does NOT compile — build.sh installed pytest into the in-image site dir and compiled the
# imagesize_run_tests ELF wrapper. The suite is routed through that compiled NON-system wrapper
# so the gate's sabotage check (neuter non-system binaries to exit(0)) actually perturbs the run.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"

SRC="${SRC:-/mayhem}"
cd "$SRC"

PY_PREFIX=/opt/toolchains/python
# shellcheck disable=SC1091
[ -f "$PY_PREFIX/env.sh" ] && source "$PY_PREFIX/env.sh"
export PYTHONPATH="$PY_PREFIX/site:$SRC${PYTHONPATH:+:$PYTHONPATH}"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

RUNNER="$SRC/imagesize_run_tests"
if [ ! -x "$RUNNER" ]; then
  echo "test.sh: $RUNNER missing/not executable — mayhem/build.sh must build it first" >&2
  emit_ctrf "pytest" 0 1 0
  exit 1
fi

# Run the ENTIRE upstream suite (test/). -p no:cacheprovider keeps the read-only image happy.
LOG="$(mktemp)"
"$RUNNER" -p no:cacheprovider -o addopts= -q test/ 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}

# Parse pytest's summary line, e.g. "123 passed, 2 skipped in 0.4s".
line="$(grep -E '^(=+ )?[0-9].*(passed|failed|error|skipped)' "$LOG" | tail -1)"
get() { echo "$line" | grep -oE "[0-9]+ $1" | grep -oE '^[0-9]+' | head -1; }
passed="$(get passed)";  passed="${passed:-0}"
failed="$(get failed)";  failed="${failed:-0}"
errors="$(get error)";   errors="${errors:-0}"
skipped="$(get skipped)"; skipped="${skipped:-0}"
rm -f "$LOG"

# pytest errors (collection/setup) count as failures for the oracle.
failed=$(( failed + errors ))

# If pytest itself could not run (rc!=0 and no parseable counts), report a failure.
if [ "$(( passed + failed + skipped ))" -eq 0 ] && [ "$rc" -ne 0 ]; then
  emit_ctrf "pytest" 0 1 0
  exit 1
fi

emit_ctrf "pytest" "$passed" "$failed" "$skipped"
