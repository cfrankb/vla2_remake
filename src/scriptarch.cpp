#include "scriptarch.h"
#include "script.h"
#include <cstdio>
#include <cstring>

static const char *SIGNATURE = "SCRX";

CScriptArch::CScriptArch()
{
    m_size = 0;
    m_max = GROW_BY;
    m_scripts = new CScript *[m_max];
}

CScriptArch::~CScriptArch()
{
    forget();
}

bool CScriptArch::read(const char *filename)
{
    /*
    4 signature      "SCRX"
    2 version
    2 script count
    4 index offset
    */
    FILE *sfile = fopen(filename, "rb");
    if (sfile)
    {
        forget();
        char signature[4];
        uint16_t version;
        uint16_t count;
        uint32_t indexPtr;
        fread(signature, 4, 1, sfile);
        fread(&version, sizeof(version), 1, sfile);
        if (memcmp(signature, SIGNATURE, sizeof(signature)) != 0)
        {
            printf("invalid signature: %s\n", signature);
            fclose(sfile);
            return false;
        }
        if (version > VERSION)
        {
            printf("invalid version: %d\n", version);
            fclose(sfile);
            return false;
        }
        fread(&count, sizeof(count), 1, sfile);
        fread(&indexPtr, sizeof(indexPtr), 1, sfile);

        printf("count: %d\n", count);
        // read index
        m_size = count;
        m_max = m_size;
        uint32_t *index = new uint32_t[m_size];
        fseek(sfile, indexPtr, SEEK_SET);
        printf("indexPtr: %.8x\n", indexPtr);
        fread(index, sizeof(uint32_t) * m_size, 1, sfile);
        m_scripts = new CScript *[m_max];

        // read individual scripts
        for (int i = 0; i < count; ++i)
        {
            printf("--> script:%d [index: 0x%.8x]\n", i, index[i]);
            fseek(sfile, index[i], SEEK_SET);
            m_scripts[i] = new CScript();
            m_scripts[i]->read(sfile);
        }
        delete[] index;
        fclose(sfile);
    }
    return sfile != nullptr;
}

/// @brief
/// @param filename
/// @return
bool CScriptArch::write(const char *filename)
{
    FILE *tfile = fopen(filename, "wb");
    if (tfile)
    {
        uint16_t version = 0;
        fwrite(SIGNATURE, strlen(SIGNATURE), 1, tfile);
        fwrite(&version, sizeof(version), 1, tfile);
        fwrite(&m_size, sizeof(uint16_t), 1, tfile);
        uint32_t tmp = 0;
        fwrite(&tmp, sizeof(tmp), 1, tfile);

        uint32_t *index = new uint32_t[m_size];
        printf("count:%d\n", m_size);
        for (int i = 0; i < m_size; ++i)
        {
            CScript *script = m_scripts[i];
            index[i] = ftell(tfile);
            printf("index: %.8x [entries: %d 0x%.4x]\n", index[i], script->getSize(), script->getSize());
            script->write(tfile);
        }

        uint32_t indexPtr = ftell(tfile);
        printf("indexPtr: %.8x\n", indexPtr);
        fwrite(index, sizeof(uint32_t) * m_size, 1, tfile);
        fseek(tfile, INDEXPTR_OFFSET, SEEK_SET);
        fwrite(&indexPtr, sizeof(indexPtr), 1, tfile);
        delete[] index;
        fclose(tfile);
    }
    return tfile != nullptr;
}

void CScriptArch::add(CScript *script)
{
    if (m_size == m_max)
    {
        m_max += GROW_BY;
        CScript **tmp = new CScript *[m_max];
        memcpy(tmp, m_scripts, sizeof(CScript *) * m_size);
        delete[] m_scripts;
        m_scripts = tmp;
    }
    m_scripts[m_size] = script;
    ++m_size;
}

void CScriptArch::add(scriptEntry_t *scriptArray, uint32_t size)
{
    add(new CScript(scriptArray, size));
}

void CScriptArch::forget()
{
    if (m_scripts)
    {
        //  for (int i = 0; i < m_size; ++i)
        //  {
        //     delete[] m_scripts[i];
        // }
        delete[] m_scripts;
    }
    m_scripts = nullptr;
    m_size = 0;
    m_max = 0;
}

int CScriptArch::getSize()
{
    return m_size;
}

CScript *CScriptArch::operator[](int i)
{
    return m_scripts[i];
}