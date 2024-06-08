#ifndef __SCRIPTARCH
#define __SCRIPTARCH

#include <cstdint>
#include "script.h"

class CScript;

class CScriptArch
{
public:
    CScriptArch();
    ~CScriptArch();

    bool read(const char *filename);
    bool write(const char *filename);
    void add(scriptEntry_t *scriptArray, uint32_t size);
    void add(CScript *script);
    void forget();
    int getSize();
    CScript *operator[](int i);

private:
    enum
    {
        GROW_BY = 16,
        VERSION = 0,
        INDEXPTR_OFFSET = 8
    };

    uint32_t m_size;
    uint32_t m_max;
    CScript **m_scripts;
};

#endif