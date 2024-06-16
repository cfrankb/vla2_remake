import glob
import os


for s in glob.glob('*'):

    d = s.lower()
    print(s, d)
    if s != d:
        # continue
        os.rename(s, d)
