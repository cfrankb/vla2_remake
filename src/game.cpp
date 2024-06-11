#include "game.h"
#include "shared/FrameSet.h"
#include "scriptarch.h"
#include <cstdio>
#include "imswrap.h"
#include "framemap.h"

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
        printf("can't read tileset %s\n", tilesetName.c_str());
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
        fclose(sfile);
    }
    else
    {
        m_lastError = "can't open: " + m_scriptArchName;
        printf("can't read %s\n", m_scriptArchName.c_str());
        return false;
    }

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