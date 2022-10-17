#! /usr/bin/python3
import xml.etree.ElementTree

import atheris
import sys
import io
import tempfile

with atheris.instrument_imports():
    import imagesize

def TestOneInput(data):
        temp_file = tempfile.NamedTemporaryFile()
        temp_file.name = "test" + ".png"
        temp_file.write(data)
        temp_file.flush()
        try:
            imagesize.get(temp_file.name)
            imagesize.getDPI(temp_file.name)
        except ValueError:
            pass

        temp_file.close()



def main():
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
