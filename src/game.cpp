#include "game.h"
#include "shared/FrameSet.h"
#include "scriptarch.h"
#include <cstdio>
#include "imswrap.h"
#include "framemap.h"
#include "defs.h"

CGame::CGame()
{
    m_frameSet = new CFrameSet;
    m_scriptArchName = "out/levels.scrx";
    m_scriptCount = 0;
    m_script = new CScript;
    m_valid = false;
    m_frameMap = new CFrameMap;

    if (!CScriptArch::indexFromFile(m_scriptArchName.c_str(), m_scriptIndex, m_scriptCount))
    {
        m_lastError = "can't read: " + m_scriptArchName;
        printf("can't read %s\n", m_scriptArchName.c_str());
        return;
    }

    m_valid = true;
}

CGame::~CGame()
{
    if (m_frameSet)
    {
        delete m_frameSet;
    }

    if (m_script)
    {
        delete m_script;
    }
}

bool CGame::loadTileset(const char *tileset)
{
    std::string tilesetName = "data/" + std::string(tileset) + ".ims";
    CImsWrap ims;
    if (!ims.readIMS(tilesetName.c_str()))
    {
        m_lastError = "can't read tileset: " + tilesetName;
        printf("can't read tileset: %s\n", tilesetName.c_str());
        return false;
    }
    ims.toFrameSet(*m_frameSet, nullptr);
    m_frameMap->fromFrameSet(*m_frameSet);
    m_frameMap->write("out/fmap.dat");
    return true;
}

bool CGame::loadLevel(int i)
{
    bool result = false;
    FILE *sfile = fopen(m_scriptArchName.c_str(), "rb");
    if (sfile)
    {
        // seek to level offset
        fseek(sfile, m_scriptIndex[i], SEEK_SET);
        // read level
        result = m_script->read(sfile);
        mapScript(m_script);

        printf("flower count: %d\n", m_script->countType(TYPE_FLOWER));
        int i = m_script->findPlayerIndex();
        if (i != CScript::NOT_FOUND)
        {
            scriptEntry_t &entry = (*m_script)[i];
            printf("player found at: x=%d y=%d\n", entry.x, entry.y);
        }
        else
        {
            printf("no player found\n");
        }
        fclose(sfile);
    }
    else
    {
        m_lastError = "can't open: " + m_scriptArchName;
        printf("can't open: %s\n", m_scriptArchName.c_str());
        return false;
    }

    // load tileset
    const std::string tileset = m_script->tileset();
    if (result && !loadTileset(tileset.c_str()))
    {
        result = false;
        m_lastError = "loadTileset failed";
    }
    return result;
}

const char *CGame::lastError()
{
    return m_lastError.c_str();
}

void CGame::mapScript(CScript *script)
{
    m_map.clear();
    for (int i = 0; i < script->getSize(); ++i)
    {
        const scriptEntry_t &entry = (*script)[i];
        if (entry.type != TYPE_BLANK && CScript::isBackgroundType(entry.type))
        {
            auto &a = m_map[CScript::toKey(entry.x, entry.y)];
            if (a != TYPE_SAND && a < entry.type)
            {
                a = entry.type;
            }
        }
    }
}

void CGame::splitScript()
{
    // TODO: implement this
    for (int i = 0; i < m_script->getSize(); ++i)
    {
    }
}