#!/usr/bin/env python3
"""Atheris fuzz harness for imagesize (port of the original img-fuzz harness).

Feeds arbitrary bytes to imagesize's header parsers via a temp file:
  * imagesize.get()      — width/height detection across every supported format
  * imagesize.getDPI()   — DPI extraction (JPEG/PNG/TIFF paths)
  * imagesize.get_info() — the 2.0 ImageInfo API (orientation-aware)
Atheris instruments the imagesize module at import, so libFuzzer gets
coverage feedback from the parsing code itself.

Run modes (driven by the compiled launcher `img-fuzz` / `img-fuzz-standalone`):
  * fuzzing      — `python3 fuzz_img.py [libFuzzer args]`
  * single input — `python3 fuzz_img.py <file>` (libFuzzer runs it once)
"""
import os
import sys
import tempfile

import atheris

with atheris.instrument_imports():
    import imagesize


def TestOneInput(data: bytes) -> None:
    fd, path = tempfile.mkstemp(dir="/tmp")
    try:
        os.write(fd, data)
        os.close(fd)
        try:
            imagesize.get(path)
            imagesize.getDPI(path)
            imagesize.get_info(path)
        except ValueError:
            # imagesize raises ValueError on unsupported/corrupt headers.
            pass
    finally:
        os.unlink(path)


def main() -> None:
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
