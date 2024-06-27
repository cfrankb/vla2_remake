/*
    vlamits2-runtime-sdl
    Copyright (C) 2024 Francois Blanchette

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
*/
#ifndef __SCRIPTARCH
#define __SCRIPTARCH

#include <cstdint>
#include "script.h"

class CScript;
class CActor;

class CScriptArch
{
public:
    CScriptArch();
    ~CScriptArch();

    bool read(const char *filename);
    bool write(const char *filename);
    void add(CActor *scriptArray, uint32_t size);
    void add(CScript *script);
    void forget();
    int getSize();
    inline CScript *operator[](int i);
    inline CScript *at(int i);
    static bool indexFromFile(const char *filename, uint32_t *&index, uint32_t &size);
    CScript *removeAt(int i);

private:
    enum
    {
        GROW_BY = 16,
        VERSION = 0,
        INDEXPTR_OFFSET = 8,
        COUNT_OFFSET = 6
    };

    uint32_t m_size;
    uint32_t m_max;
    CScript **m_scripts;
};

#endif