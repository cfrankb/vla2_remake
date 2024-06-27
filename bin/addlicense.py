from os.path import join
import os
import glob
from datetime import date
year = date.today().year
license_cpp = f'''/*
    vlamits2-runtime-sdl
    Copyright (C) {year} Francois Blanchette

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/\n'''

license_lua = license_cpp.replace('/*', '--[[').replace('*/', ']]--')

# from lgckutil.license import *

specs = [
    'src',
]


def scan_folder(folder):
    folders = [x[0] for x in os.walk(folder) if '/build/' not in x[0]]
    for x in folders[1:]:
        scan_folder(x)

    for ext in ['*.h', '*.cpp']:
        for x in glob.glob(f'{folder}/{ext}'):
            if 'version.h' in x or 'ss_' in x:
                continue
            with open(x, 'r') as s:
                data = s.read()
            if data[0:2] != '/*':
                print('*', x)
                with open(x, 'w') as t:
                    t.write(license_cpp + data)


for x in specs:
    for y in glob.glob(x):
        scan_folder(y)
