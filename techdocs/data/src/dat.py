def readDat(dat_filename):
    with open(dat_filename) as s:
        data = s.read().split("\n")

    lines = []
    x = 0
    while True:
        line = data[x]
        if line[0] == '*':
            break
        elif line[0] == '@':
            line = line[6:].replace('"', '')
        else:
            line = line[3:].replace('"', '')

        ims = data[x+1].replace("levels\\", "")
        scr = data[x+2].replace("levels\\", "")

        els = [ims, scr, line]
        lines.append('{' + ','.join(f'"{x}"' for x in els) + '}')
        # print(group)
        # print(line)
        x += 3
 #  print(data)
    #
    return lines


# lines  = []
lines = readDat('data/facile.dat')
lines += readDat('data/avance.dat')
print(',\n'.join(lines))
