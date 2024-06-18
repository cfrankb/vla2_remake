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