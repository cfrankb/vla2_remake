#include <cstring>
#include "script.h"
#include "defs.h"
#include "actor.h"

CScript::CScript()
{
    m_script = nullptr;
    m_size = 0;
    m_max = m_size;
}

CScript::CScript(CActor *script, uint32_t size)
{
    m_script = script;
    m_size = size;
    m_max = m_size;
}

CScript::~CScript()
{
    forget();
}

void CScript::forget()
{
    if (m_script)
    {
        delete[] m_script;
    }
    m_script = nullptr;
    m_size = 0;
    m_max = 0;
}

void CScript::copy(CActor *script, int count)
{
    if (m_script)
    {
        delete[] m_script;
    }
    m_size = count;
    m_max = m_size;
    m_script = new CActor[m_size];
    memcpy(m_script, script, sizeof(CActor) * count);
}

bool CScript::write(FILE *tfile)
{
    // write entry count
    fwrite(&m_size, sizeof(m_size), 1, tfile);

    // save tileset name
    char tileset[TILESET_NAME_MAX];
    memset(tileset, 0, sizeof(tileset));
    strncpy(tileset, m_tileset.c_str(), sizeof(tileset));
    fwrite(tileset, sizeof(tileset), 1, tfile);

    // write script
    fwrite(m_script, sizeof(CActor) * m_size, 1, tfile);

    // write scriptname + padding
    char name[SCRIPTNAME_MAX];
    memset(name, 0, sizeof(name));
    strncpy(name, m_name.c_str(), sizeof(name) - 1);
    auto size = strlen(name);
    //    printf("name: %s %d 0x%.2x\n", name, size + 1, size + 1);
    fwrite(&size, sizeof(uint8_t), 1, tfile);
    fwrite(name, size, 1, tfile);
    auto padding = (4 - (1 + size) & 3) & 3;
    auto tmp = 0;
    //  printf("padding 0x%.2x\n", padding);
    fwrite(&tmp, padding, 1, tfile);
    return true;
}

bool CScript::read(FILE *sfile)
{
    forget();

    // read entry count
    fread(&m_size, sizeof(m_size), 1, sfile);
    m_max = m_size;
    printf("entrycount: %d\n", m_size);

    // read tileset name
    char tileset[TILESET_NAME_MAX + 1];
    memset(tileset, 0, sizeof(tileset));
    fread(tileset, TILESET_NAME_MAX, 1, sfile);
    m_tileset = tileset;

    // read script
    m_script = new CActor[m_size];
    fread(m_script, sizeof(CActor) * m_size, 1, sfile);

    // read scriptname
    char name[SCRIPTNAME_MAX + 1];
    memset(name, 0, sizeof(name));
    uint8_t size = 0;
    fread(&size, sizeof(uint8_t), 1, sfile);
    fread(name, size, 1, sfile);
    m_name = name;

    return true;
}

std::string CScript::name()
{
    return m_name;
}

void CScript::setName(const std::string &name)
{
    m_name = name;
}

std::string CScript::tileset()
{
    return m_tileset;
}

void CScript::setTileSet(const std::string &tileset)
{
    m_tileset = tileset;
}

void CScript::growArray()
{
    if (m_size == m_max)
    {
        m_max += GROW_BY;
        CActor *tmp = new CActor[m_max];
        for (int i = 0; i < m_size; ++i)
        {
            tmp[i] = m_script[i];
        }
        delete[] m_script;
        m_script = tmp;
    }
}

int CScript::add(const CActor &entry)
{
    growArray();
    m_script[m_size] = entry;
    return m_size++;
}

int CScript::insertAt(int i, const CActor &entry)
{
    growArray();
    for (int j = m_size; j > i; --j)
    {
        m_script[j] = m_script[j - 1];
    }
    m_script[i] = entry;
    ++m_size;
    return i;
}

void CScript::removeAt(int i)
{
    for (int j = i; j < m_size - 1; ++j)
    {
        m_script[i] = m_script[i + 1];
    }
    --m_size;
}

int CScript::findPlayerIndex()
{
    for (int i = 0; i < m_size; ++i)
    {
        if (m_script[i].type == TYPE_PLAYER)
        {
            return i;
        }
    }
    return NOT_FOUND;
}

int CScript::countType(uint8_t type)
{
    int count = 0;
    for (int i = 0; i < m_size; ++i)
    {
        if (m_script[i].type == type)
        {
            ++count;
        }
    }
    return count;
}

void CScript::replace(CActor *script, uint32_t size)
{
    if (m_script)
    {
        delete[] m_script;
    }
    m_size = size;
    m_max = size;
    m_script = script;
}