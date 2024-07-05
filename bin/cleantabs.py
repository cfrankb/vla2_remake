#!/usr/bin/python
import glob


def main():
    paths = ['src/*.cpp', "src/**/*.cpp", 'src/*.h', "src/**/*.h"]
    for pattern in paths:
        for f in glob.glob(pattern):
            with open(f, 'rb') as s:
                data = s.read().decode("utf-8")
            rdata = data
            if '\t' in data:
                data = data.replace('\t', '    ')
            if '\r\n' in data:
                data = data.replace('\r\n', '\n')
            if ' \n' in data:
                lines = []
                for line in data.split('\n'):
                    lines.append(line.rstrip())
                data = '\n'.join(lines)

            if rdata != data:
                print(f)
                # print(data)
                with open(f, 'wb') as t:
                    t.write(data.encode())


main()
