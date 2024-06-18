#include "game.h"
#include "shared/FrameSet.h"
#include "shared/Frame.h"
#include "scriptarch.h"
#include <cstdio>
#include "imswrap.h"
#include "framemap.h"
#include "defs.h"

CGame *g_game = nullptr;

CGame::CGame()
{
    m_frameSet = new CFrameSet;
    m_scriptCount = 0;
    m_script = new CScript;
    m_valid = false;
    m_frameMap = new CFrameMap;
    m_valid = false;
    m_loadedTileSet = "";
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

    if (m_frameMap)
    {
        delete m_frameMap;
    }
}

bool CGame::init(const char *archname)
{
    m_scriptArchName = archname ? archname : "data/levels.scrx";
    if (!CScriptArch::indexFromFile(m_scriptArchName.c_str(), m_scriptIndex, m_scriptCount))
    {
        m_lastError = "can't read index: " + m_scriptArchName;
        printf("can't read index: %s\n", m_scriptArchName.c_str());
        return false;
    }
    printf("map count: %d\n", m_scriptCount);
    return true;
}

bool CGame::loadTileset(const char *tileset)
{
    printf("loading tileset: %s\n", tileset);
    std::string tilesetName = "data/" + std::string(tileset) + ".ims";
    CImsWrap ims;
    if (!ims.readIMS(tilesetName.c_str()))
    {
        m_lastError = "can't read tileset: " + tilesetName;
        printf("can't read tileset: %s\n", tilesetName.c_str());
        m_loadedTileSet = "";
        return false;
    }
    ims.toFrameSet(*m_frameSet, nullptr);
    m_frameMap->fromFrameSet(*m_frameSet);
    m_frameMap->write("out/fmap.dat");
    m_loadedTileSet = tileset;
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

        printf("flowers: %d\n", m_script->countType(TYPE_FLOWER));
        int i = m_script->findPlayerIndex();
        m_player = nullptr;
        if (i != CScript::NOT_FOUND)
        {
            scriptEntry_t &entry = (*m_script)[i];
            m_player = &entry;
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
    if (result &&
        (m_loadedTileSet != tileset) &&
        !loadTileset(tileset.c_str()))
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

bool CGame::canMove(const scriptEntry_t &actor, int aim)
{
    int len, hei;
    sizeFrame(actor, len, hei);

    int x = actor.x;
    int y = actor.y;

    switch (aim)
    {
    case AIM_UP:
        if (y == 0)
            return false;
        --y;
        hei = 1;
        break;
    case AIM_DOWN:
        y += hei;
        hei = 1;
        break;
    case AIM_LEFT:
        x += len;
        len = 1;
        break;
    case AIM_RIGHT:
        if (x == 0)
            return false;
        --x;
        len = 1;
        break;
    default:
        return false;
    };

    // check collision map
    for (int iy; iy < hei; ++iy)
    {
        for (int ix; ix < len; ++ix)
        {
            uint32_t bkType = mapAt(x + ix, y + iy);
            if (CScript::isMonsterType(actor.type))
            {
                if (actor.type != TYPE_FISH &&
                    (bkType == TYPE_BOTTOMWATER || bkType == TYPE_TOPWATER))
                {
                    return false;
                }
                if (bkType == TYPE_STOPCLASS)
                {
                    return false;
                }
            }
            if (bkType == TYPE_OBSTACLECLASS)
            {
                return false;
            }
        }
    }

    // check script entries for inbound collisions
    int eLen;
    int eHei;
    for (int i = 0; i < m_script->getSize(); ++i)
    {
        scriptEntry_t &entry = (*m_script)[i];
        if (CScript::isMonsterType(entry.type) ||
            CScript::isPlayerType(entry.type))
        {
            sizeFrame(entry, eLen, eHei);
            if ((entry.x + eLen <= actor.x) ||
                (entry.x + eLen >= actor.x + len) ||
                (entry.y + eHei <= actor.y) ||
                (entry.y + eHei >= actor.y + hei))
            {
                continue;
            }
            return false;
        }
    }

    return true;
}

void CGame::sizeFrame(const scriptEntry_t &entry, int &len, int &hei) const
{
    if (entry.type == TYPE_PLAYER)
    {
        len = PLAYER_RECT;
        hei = PLAYER_RECT;
    }
    else
    {
        const CFrame *frame = (*m_frameSet)[entry.imageId];
        len = frame->len();
        hei = frame->hei();
    }
}

/// @brief
/// @param x
/// @param y
/// @return
uint32_t CGame::mapAt(int x, int y)
{
    int key = CScript::toKey(x, y);
    if (m_map.count(key) > 0)
    {
        return m_map[key];
    }
    else
    {
        return 0;
    }
}

int CGame::mode()
{
    return m_mode;
}

void CGame::setMode(int mode)
{
    m_mode = mode;
}

void CGame::drawScreen(CFrame &screen, CFrame *annie)
{
    const int rows = screen.hei() / fntBlockSize;
    const int cols = screen.len() / fntBlockSize;
    const int mx = 0;
    const int my = 0;
    for (int i = 0; i < m_script->getSize(); ++i)
    {
        CFrame *frame;
        const auto &entry = (*m_script)[i];
        if (entry.type == TYPE_PLAYER)
        {
            frame = annie;
        }
        else if (entry.imageId >= m_frameSet->getSize())
        {
            continue;
        }
        else
        {
            frame = (*m_frameSet)[entry.imageId];
        }

        const int frows = frame->hei() / fntBlockSize;
        const int fcols = frame->len() / fntBlockSize;
        const int rx = entry.x - mx;
        const int ry = entry.y - my;
        if ((rx < cols) &&
            (rx + fcols > 0) &&
            (ry < rows) &&
            (ry + frows > 0))
        {
            const int offsetX = rx < 0 ? -rx : 0;
            const int offsetY = ry < 0 ? -ry : 0;
            const int flen = fcols - offsetX;
            const int fhei = frows - offsetY;
            const int sx = rx > 0 ? rx : 0;
            const int sy = ry > 0 ? ry : 0;
            for (int y = 0; y < fhei * fntBlockSize; ++y)
            {
                uint32_t *rgba = &screen.at(sx * fntBlockSize, sy * fntBlockSize + y);
                for (int x = 0; x < flen * fntBlockSize; ++x)
                {
                    const uint32_t &pixel = frame->at(x + offsetX * fntBlockSize, y + offsetY * fntBlockSize);
                    if (pixel)
                    {
                        rgba[x] = pixel;
                    }
                }
            }
        }
    }
}

CGame *CGame::getGame()
{
    if (!g_game)
    {
        g_game = new CGame();
    }
    return g_game;
}