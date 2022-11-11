#! /usr/bin/python3

import atheris
import sys
import tempfile

with atheris.instrument_imports():
    import imagesize

def TestOneInput(data):
        fdp = atheris.FuzzedDataProvider(data)
        file_data = fdp.ConsumeBytes(atheris.ALL_REMAINING)
        temp_file = tempfile.NamedTemporaryFile()
        temp_file.write(file_data)
        temp_file.flush()
        fd = temp_file.name

        try:
            imagesize.get(fd)
            imagesize.getDPI(fd)
        except ValueError:
            pass

        temp_file.close()



def main():
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
