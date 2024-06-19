#include "game.h"
#include "shared/FrameSet.h"
#include "shared/Frame.h"
#include "shared/FileWrap.h"
#include "scriptarch.h"
#include <cstdio>
#include "imswrap.h"
#include "framemap.h"
#include "defs.h"
#include "actor.h"

#define DEFAULT_ARCHFILE "data/levels.scrx"
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
    if (m_annie)
    {
        delete m_annie;
    }

    if (m_fontData)
    {
        delete[] m_fontData;
    }

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
    m_scriptArchName = archname ? archname : DEFAULT_ARCHFILE;
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

        printf("flowers: %d\n", m_script->countType(TYPE_FLOWER));
        int i = m_script->findPlayerIndex();
        m_player = nullptr;
        if (i != CScript::NOT_FOUND)
        {
            CActor &entry = (*m_script)[i];
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
    // map script
    m_frameMap->fromFrameSet(*m_frameSet);
    mapScript(m_script);

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
        const CActor &entry = (*script)[i];
        mapEntry(entry);
    }
}

void CGame::mapEntry(const CActor &entry)
{
    static uint8_t playerMap[] = {0xff, 0xff, 0xff, 0xff};
    uint8_t *map = entry.type == TYPE_PLAYER ? playerMap : (*m_frameMap)[entry.imageId];

    if (entry.type != TYPE_BLANK && CScript::isBackgroundType(entry.type))
    {
        int len, hei;
        sizeFrame(entry, len, hei);
        for (int y = 0; y < hei / fntBlockSize; ++y)
        {
            for (int x = 0; x < len / fntBlockSize; ++x)
            {
                //   if (*map++)
                //     continue;
                const uint32_t key = CScript::toKey(entry.x + x, entry.y + y);
                auto &a = m_map[key];
                if (a != TYPE_SAND && a < entry.type)
                {
                    a = entry.type;
                }
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

bool CGame::canMove(const CActor &actor, int aim)
{
    int len, hei;
    sizeFrame(actor, len, hei);

    int actX = actor.x;
    int actY = actor.y;
    switch (aim)
    {
    case AIM_UP:
        if (actY == 0)
            return false;
        --actY;
        hei = 1;
        break;
    case AIM_DOWN:
        if (actY + hei >= MAX_POS)
        {
            return false;
        }
        actY += hei;
        hei = 1;
        break;
    case AIM_LEFT:
        if (actX == 0)
            return false;
        --actX;
        len = 1;
        break;
    case AIM_RIGHT:
        if (actX + len >= MAX_POS)
        {
            return false;
        }
        actX += len;
        len = 1;
        break;
    default:
        return false;
    };

    // check collision map
    for (int iy = 0; iy < hei; ++iy)
    {
        for (int ix = 0; ix < len; ++ix)
        {
            uint32_t bkType = mapAt(actX + ix, actY + iy);
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

    // return true;
    //  check script entries for inbound collisions
    int eLen;
    int eHei;
    for (int i = 0; i < m_script->getSize(); ++i)
    {
        CActor &entry = (*m_script)[i];
        if (CScript::isMonsterType(entry.type) ||
            CScript::isPlayerType(entry.type))
        {
            sizeFrame(entry, eLen, eHei);
            eLen /= fntBlockSize;
            eHei /= fntBlockSize;
            if ((entry.x + eLen <= actX) ||
                (entry.x + eLen >= actX + len) ||
                (entry.y + eHei <= actY) ||
                (entry.y + eHei >= actY + hei))
            {
                continue;
            }
            return false;
        }
    }

    return true;
}

void CGame::sizeFrame(const CActor &entry, int &len, int &hei) const
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

void CGame::drawScreen(CFrame &screen)
{
    const int scrLen = screen.len();
    const int scrHei = screen.hei();
    const int rows = screen.hei() / fntBlockSize;
    const int cols = screen.len() / fntBlockSize;
    const int hx = cols / 2;
    const int hy = rows / 2;
    const int mx = m_player->x < hx ? 0 : m_player->x - hx;
    const int my = m_player->y < hy ? 0 : m_player->y - hy;
    for (int i = 0; i < m_script->getSize(); ++i)
    {
        CFrame *frame;
        const auto &entry = (*m_script)[i];
        if (entry.type == TYPE_PLAYER)
        {
            CFrame *annie = (*m_annie)[8];
            frame = annie;
        }
        else if (entry.imageId >= m_frameSet->getSize() ||
                 CScript::isSystemType(entry.type))
        {
            continue;
        }
        else
        {
            frame = (*m_frameSet)[entry.imageId];
        }
        const int fcols = frame->len() / fntBlockSize;
        const int frows = frame->hei() / fntBlockSize;
        const int rx = int(entry.x) - mx;
        const int ry = int(entry.y) - my;
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
                if (sy * fntBlockSize + y >= scrHei)
                    break;
                uint32_t *rgba = &screen.at(sx * fntBlockSize, sy * fntBlockSize + y);
                const uint32_t *pixel = &frame->at(offsetX * fntBlockSize, offsetY * fntBlockSize + y);
                for (int x = 0; x < flen * fntBlockSize; ++x)
                {
                    if (sx * fntBlockSize + x >= scrLen)
                        break;
                    if (pixel[x])
                    {
                        rgba[x] = pixel[x];
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

int CGame::playerSpeed()
{
    return DEFAULT_PLAYER_SPEED;
}

bool CGame::isPlayerDead()
{
    return false;
}

void CGame::managePlayer(uint8_t *joyState)
{
    uint8_t aims[] = {AIM_UP, AIM_DOWN, AIM_LEFT, AIM_RIGHT};
    for (uint8_t i = 0; i < 4; ++i)
    {
        uint8_t aim = aims[i];
        if (joyState[aim] &&
            m_player->canMove(aim) &&
            m_player->move(aim))
        {
            break;
        }
    }
}

void CGame::preloadAssets()
{
    CFileWrap file;

    typedef struct
    {
        const char *filename;
        CFrameSet **frameset;
    } asset_t;

    asset_t assets[] = {
        {"data/annie.obl", &m_annie},
    };

    for (size_t i = 0; i < sizeof(assets) / sizeof(asset_t); ++i)
    {
        asset_t &asset = assets[i];
        *(asset.frameset) = new CFrameSet();
        if (file.open(asset.filename, "rb"))
        {
            printf("reading %s\n", asset.filename);
            if ((*(asset.frameset))->extract(file))
            {
                printf("extracted: %d\n", (*(asset.frameset))->getSize());
            }
            file.close();
        }
    }

    const char fontName[] = "data/bitfont.bin";
    int size = 0;
    if (file.open(fontName, "rb"))
    {
        size = file.getSize();
        m_fontData = new uint8_t[size];
        file.read(m_fontData, size);
        file.close();
        printf("loaded %s: %d bytes\n", fontName, size);
    }
    else
    {
        printf("failed to open %s\n", fontName);
    }
}

void CGame::debugFrameMap()
{
    CFrameSet fs;

    for (int i = 0; i < m_frameSet->getSize(); ++i)
    {
        CFrame *frame = new CFrame((*m_frameSet)[i]);
        uint8_t *map = m_frameMap->mapPtr(i);
        for (int j = 0; j < frame->hei() / fntBlockSize; ++j)
        {
            for (int k = 0; k < frame->len() / fntBlockSize; ++k)
            {
                uint8_t c = *map++;
                uint8_t *p = &m_fontData[c * fntBlockSize];

                for (int y = 0; y < fntBlockSize; ++y)
                {
                    uint8_t bits = p[y];
                    for (int x = 0; x < fntBlockSize; ++x)
                    {
                        if (bits & 1)
                        {
                            frame->at(k * fntBlockSize + x, j * fntBlockSize + y) = 0xff00ffff;
                        }
                        bits = bits >> 1;
                    }
                }
            }
        }
        fs.add(frame);
    }

    CFileWrap file;
    if (file.open("out/map.obl", "wb"))
    {
        fs.write(file);
        file.close();
    }
}