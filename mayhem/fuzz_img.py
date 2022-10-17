#! /usr/bin/python3
import xml.etree.ElementTree

import atheris
import sys
import io
import tempfile

with atheris.instrument_imports():
    import imagesize

supported_ext = [".png"]

def TestOneInput(data):
        fdp = atheris.FuzzedDataProvider(data)
        ext = supported_ext[fdp.ConsumeIntInRange(0, len(supported_ext)-1)]
        file_data = fdp.ConsumeBytes(atheris.ALL_REMAINING)
        temp_file = tempfile.NamedTemporaryFile()
        temp_file.write(file_data)
        temp_file.flush()
        fd = temp_file.name
        # fd.name = "test" + ext

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
