#include <cstdio>
#include <cstring>
#include <unordered_set>
#include "game.h"
#include "shared/FrameSet.h"
#include "shared/Frame.h"
#include "shared/FileWrap.h"
#include "scriptarch.h"
#include "imswrap.h"
#include "framemap.h"
#include "actor.h"

#define DEFAULT_ARCHFILE "data/levels.scrx"
CGame *g_game = nullptr;

static uint16_t g_points[] = {
    10,
    15,
    25,
    50,
    100,
    200,
    300,
    400,
    500,
    1000,
    2000,
    5000,
    10000,
};

const int pointCount = sizeof(g_points) / sizeof(u_int16_t);

static uint8_t AIMS[] = {
    CActor::AIM_UP,
    CActor::AIM_DOWN,
    CActor::AIM_LEFT,
    CActor::AIM_RIGHT};

#define _J(s)                        \
    {                                \
        .seq = s, .count = sizeof(s) \
    }

typedef struct
{
    const uint8_t *seq;
    const int count;
} jumpSeq_t;

uint8_t jumpUP[] = {UP, UP, UP, UP, DOWN, DOWN, DOWN, DOWN};
uint8_t jumpDOWN[] = {};
uint8_t jumpLEFT[] = {UP, LEFT, UP, LEFT, LEFT, DOWN, LEFT, DOWN};
uint8_t jumpRIGHT[] = {UP, RIGHT, UP, RIGHT, RIGHT, DOWN, RIGHT, DOWN};

jumpSeq_t g_jumpSeqs[] = {
    _J(jumpUP),
    _J(jumpDOWN),
    _J(jumpLEFT),
    _J(jumpRIGHT),
};

CGame::CGame()
{
    m_frameSet = new CFrameSet;
    m_scriptCount = 0;
    m_script = new CScript;
    m_frameMap = new CFrameMap;
    m_loadedTileSet = "";
}

CGame::~CGame()
{
    if (m_annie)
    {
        delete m_annie;
    }

    if (m_points)
    {
        delete m_points;
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
    printf("map count in index: %d\n", m_scriptCount);
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
    m_hp = DefaultHp;
    m_oxygen = DefaultOxygen;
    // m_lives = DefaultLives;

    bool result = false;
    FILE *sfile = fopen(m_scriptArchName.c_str(), "rb");
    if (sfile)
    {
        // seek to level offset
        fseek(sfile, m_scriptIndex[i], SEEK_SET);
        // read level
        result = m_script->read(sfile);
        fclose(sfile);
        m_script->sort();
        m_script->insertAt(0, CActor());
        m_goals = m_script->countType(TYPE_FLOWER);
        printf("flowers: %d\n", m_goals);
        int i = m_script->findPlayerIndex();
        m_player = nullptr;
        if (i != CScript::NOT_FOUND)
        {
            CActor &entry = (*m_script)[i];
            m_player = &entry;
            entry.aim = CActor::AIM_DOWN;
            printf("player found at: x=%d y=%d\n", entry.x, entry.y);
        }
        else
        {
            printf("no player found\n");
            m_lastError = "no player found";
            return false;
        }
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
    for (int i = BASE_ENTRY; i < script->getSize(); ++i)
    {
        const CActor &entry = (*script)[i];
        mapEntry(i, entry);
    }
}

bool CGame::unmapEntry(int i, const CActor &actor)
{
    return mapEntry(i, actor, true);
}

bool CGame::mapEntry(int i, const CActor &entry, bool removed)
{
    if (entry.type == TYPE_BLANK)
        return true;
    uint8_t *map = getActorMap(entry);
    int len, hei;
    sizeFrame(entry, len, hei);
    for (int y = 0; y < hei; ++y)
    {
        for (int x = 0; x < len; ++x)
        {
            if (map && !*map++)
                continue;
            const uint32_t key = CScript::toKey(entry.x + x, entry.y + y);
            auto &a = m_map[key];
            if (CScript::isBackgroundType(entry.type))
            {
                if (removed)
                {
                    a.setBk(TYPE_BLANK);
                }
                else if (a.bk() != TYPE_SAND && a.bk() < entry.type)
                {
                    a.setBk(entry.type);
                }
            }
            else if (CScript::isMonsterType(entry.type))
            {
                a.setAcEntry(removed ? NONE : i);
            }
            else if (CScript::isObjectType(entry.type))
            {
                removed ? a.removeFwEntry(i) : a.setFwEntry(i);
            }
            else if (entry.type == TYPE_PLAYER)
            {
                a.setPlayer(removed ? false : true);
            }
            if (removed && a.isEmpty())
            {
                // m_map.erase(key);
            }
        }
    }
    return true;
}

bool CGame::isPlayerThere(const CActor &actor, int aim)
{
    rect_t rect;
    if (!calcActorRect(actor, aim, rect))
    {
        return false;
    }
    for (int y = 0; y < rect.hei; ++y)
    {
        for (int x = 0; x < rect.len; ++x)
        {
            const auto &key = CScript::toKey(rect.x + x, rect.y + y);
            // ignore empty locations
            if (m_map.count(key) == 0)
            {
                continue;
            }
            const auto &mapEntry = m_map[key];
            if (mapEntry.player())
            {
                return true;
            }
        }
    }
    return false;
}

bool CGame::calcActorRect(const CActor &actor, int aim, CGame::rect_t &rect)
{
    sizeFrame(actor, rect.len, rect.hei);
    rect.x = actor.x;
    rect.y = actor.y;
    switch (aim)
    {
    case CActor::AIM_UP:
        if (rect.y == 0)
            return false;
        --rect.y;
        rect.hei = 1;
        break;
    case CActor::AIM_DOWN:
        if (rect.y + rect.hei >= MAX_POS)
        {
            return false;
        }
        rect.y += rect.hei;
        rect.hei = 1;
        break;
    case CActor::AIM_LEFT:
        if (rect.x == 0)
            return false;
        --rect.x;
        rect.len = 1;
        break;
    case CActor::AIM_RIGHT:
        if (rect.x + rect.len >= MAX_POS)
        {
            return false;
        }
        rect.x += rect.len;
        rect.len = 1;
        break;
    case HERE:
        return true;
    default:
        return false;
    };
    return true;
}

bool CGame::canMove(const CActor &actor, int aim)
{
    rect_t rect;
    if (!calcActorRect(actor, aim, rect))
    {
        return false;
    }

    // check collision map
    for (int y = 0; y < rect.hei; ++y)
    {
        for (int x = 0; x < rect.len; ++x)
        {
            const auto &key = CScript::toKey(rect.x + x, rect.y + y);
            // ignore empty locations
            if (m_map.count(key) == 0)
            {
                continue;
            }
            const auto &mapEntry = m_map[key];
            if (CScript::isMonsterType(actor.type))
            {
                if (actor.type != TYPE_FISH &&
                    (mapEntry.bk() == TYPE_BOTTOMWATER ||
                     mapEntry.bk() == TYPE_TOPWATER))
                {
                    return false;
                }
                if (mapEntry.bk() == TYPE_STOPCLASS)
                {
                    return false;
                }
            }
            if (mapEntry.bk() == TYPE_OBSTACLECLASS)
            {
                return false;
            }

            //  check map entries for inbound collisions
            if (mapEntry.player() || mapEntry.acEntry())
            {
                return false;
            }
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
        len = frame->len() / fntBlockSize;
        hei = frame->hei() / fntBlockSize;
    }
}

/// @brief
/// @param x
/// @param y
/// @return
CMapEntry &CGame::mapAt(int x, int y)
{
    static CMapEntry tmp;
    const uint32_t key = CScript::toKey(x, y);
    if (m_map.count(key) != 0)
    {
        return m_map[key];
    }
    else
    {
        return tmp;
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
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CFrame *frame;
        const auto &entry = (*m_script)[i];
        if (entry.type == TYPE_PLAYER)
        {
            frame = (*m_annie)[entry.aim * PLAYER_FRAME_CYCLE];
        }
        else if (entry.type == TYPE_POINTS)
        {
            frame = (*m_points)[entry.imageId];
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

    // draw game status
    char tmp[16];
    int x = 0;
    sprintf(tmp, "%.8d ", m_score);
    drawText(screen, x, 0, tmp, WHITE);
    x += strlen(tmp) * fontSize;

    sprintf(tmp, "FLOWERS %.2d ", m_goals);
    drawText(screen, x, 0, tmp, YELLOW);
    x += strlen(tmp) * fontSize;

    sprintf(tmp, "LIVES %.2d ", m_lives);
    drawText(screen, x, 0, tmp, PINK);
    x += strlen(tmp) * fontSize;

    sprintf(tmp, "HP %.2d", m_hp);
    drawText(screen, x, 0, tmp, GREEN);
    x += strlen(tmp) * fontSize;
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
    return m_hp == 0;
}

bool CGame::manageJump(const uint8_t *joyState)
{
    if (m_jumpFlag)
    {
        const uint8_t &aim = g_jumpSeqs[m_jumpSeq].seq[m_jumpIndex];
        if (m_player->canMove(aim))
        {
            unmapEntry(NONE, *m_player);
            m_player->move(aim);
            mapEntry(NONE, *m_player);
        }
        else
        {
            m_jumpFlag = false;
        }
        ++m_jumpIndex;
        if (m_jumpIndex >= g_jumpSeqs[m_jumpSeq].count)
        {
            m_jumpFlag = false;
        }
    }
    else
    {
        if (joyState[BUTTON])
        {
            m_jumpIndex = 0;
            const uint8_t aims[] = {UP, LEFT, RIGHT};
            for (int i = 0; i < sizeof(aims); ++i)
            {
                const int aim = aims[i];
                if (joyState[aim])
                {
                    m_jumpFlag = true;
                    m_jumpSeq = aim;
                    break;
                }
            }
        }
    }
    return m_jumpFlag;
}

void CGame::managePlayer(const uint8_t *joyState)
{
    consumeAll();
    if (manageJump(joyState))
    {
        return;
    }

    for (uint8_t i = 0; i < sizeof(AIMS); ++i)
    {
        const uint8_t aim = AIMS[i];
        if (joyState[aim] &&
            m_player->canMove(aim))
        {
            unmapEntry(NONE, *m_player);
            m_player->move(aim);
            m_player->aim = aim;
            mapEntry(NONE, *m_player);
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
        {"data/points.obl", &m_points},
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

void CGame::killPlayer(const CActor &actor)
{
    m_hp = 0;
}

void CGame::attackPlayer(const CActor &actor)
{
    int damage = 0;

    switch (actor.type)
    {
    case TYPE_FISH:
        damage = FishDrain;
        break;
    case TYPE_VAMPIREPLANT:
        damage = PlantDrain;
        break;
    case TYPE_VCREA:
        damage = VCreaDrain;
        break;
    case TYPE_FLYPLAT:
        damage = KILL_PLAYER;
        break;
    case TYPE_CANNIBAL:
        damage = KILL_PLAYER;
        break;
    case TYPE_INMANGA:
        damage = KILL_PLAYER;
        break;
    case TYPE_GREENFLEA:
        damage = FleaDrain;
        break;
    case TYPE_DEADLYITEM:
        damage = NeedleDrain;
        break;
    default:
        printf("type=%d no damage defined\n", actor.type);
    };

    if (damage == KILL_PLAYER)
    {
        actor.killPlayer();
    }
    else
    {
        m_hp = std::max(0, m_hp - damage);
    }
}

void CGame::manageFish(int i, CActor &actor)
{
    if (actor.aim < CActor::AIM_LEFT)
    {
        actor.aim = CActor::AIM_LEFT;
    }
    if (actor.canMove(actor.aim))
    {
        unmapEntry(i, actor);
        actor.move(actor.aim);
        mapEntry(i, actor);
    }
    else
    {
        if (isPlayerThere(actor, actor.aim))
        {
            actor.attackPlayer();
        }
        else
        {
            actor.flipDir();
        }
    }
}

void CGame::manageVamplant(int i, CActor &actor)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            // PlantDrain
            actor.attackPlayer();
            break;
        }
    }
}

void CGame::manageVCreature(int i, CActor &actor)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            // PlantDrain
            actor.attackPlayer();
            break;
        }
    }
}

void CGame::manageFlyingPlatform(int i, CActor &actor)
{
    int aim = actor.aim;
    if (actor.isPlayerThere(aim))
    {
        if (m_player->canMove(aim))
        {
            unmapEntry(NONE, *m_player);
            m_player->move(aim);
            mapEntry(NONE, *m_player);
        }
        else
        {
            actor.attackPlayer();
            return;
        }
    }

    if (actor.canMove(aim))
    {
        unmapEntry(i, actor);
        actor.move(aim);
        mapEntry(i, actor);
    }
    else
    {
        actor.flipDir();
    }
}

void CGame::manageCannibal(int i, CActor &actor)
{
}

void CGame::manageInManga(int i, CActor &actor)
{
}

void CGame::manageGreenFlea(int i, CActor &actor)
{
}

/// @brief
void CGame::manageMonsters()
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &actor = (*m_script)[i];
        if (!CScript::isMonsterType(actor.type))
        {
            if (actor.type == TYPE_POINTS)
            {
                if (actor.y)
                {
                    --actor.y;
                }
                else
                {
                    actor.type = TYPE_EMPTY;
                }
            }
            continue;
        }

        switch (actor.type)
        {
        case TYPE_FISH:
            manageFish(i, actor);
            break;
        case TYPE_VAMPIREPLANT:
            manageVamplant(i, actor);
            break;
        case TYPE_VCREA:
            manageVCreature(i, actor);
            break;
        case TYPE_FLYPLAT:
            manageFlyingPlatform(i, actor);
            break;
        case TYPE_CANNIBAL:
            manageCannibal(i, actor);
            break;
        case TYPE_INMANGA:
            manageInManga(i, actor);
            break;
        case TYPE_GREENFLEA:
            manageGreenFlea(i, actor);
        };
    }
}

void CGame::drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color)
{
    uint32_t *rgba = frame.getRGB();
    const int rowPixels = frame.len();
    const int fontOffset = fontSize;
    const int textSize = strlen(text);
    for (int i = 0; i < textSize; ++i)
    {
        const uint8_t c = static_cast<uint8_t>(text[i]) - ' ';
        uint8_t *font = m_fontData + c * fontOffset;
        for (int yy = 0; yy < fontSize; ++yy)
        {
            uint8_t bitFilter = 1;
            for (int xx = 0; xx < fontSize; ++xx)
            {
                rgba[(yy + y) * rowPixels + xx + x] = font[yy] & bitFilter ? color : BLACK;
                bitFilter = bitFilter << 1;
            }
        }
        x += fontSize;
    }
}

void CGame::addToScore(int score)
{
    m_score += score;
}

bool CGame::consumeObject(uint16_t j)
{
    CActor &entry = (*m_script)[j];
    int points = INVALID;
    switch (entry.type)
    {
    case TYPE_OXYGEN:
        points = _10pts;
        m_oxygen += OxygenBonus;
        break;
    case TYPE_TRANSPORTER:
        return false;
    case TYPE_DIAMOND:
        points = _50pts;
        break;
    case TYPE_FLOWER:
        points = _100pts;
        m_hp += FlowerHpBonus;
        --m_goals;
        break;
    case TYPE_FRUIT:
        if (entry.imageId == 1)
        {
            points = _15pts;
        }
        else if (entry.imageId == 2)
        {
            points = _10pts;
        }
        else
        {
            points = _25pts;
        }
        break;
    case TYPE_MUSHROOM:
        points = entry.imageId % pointCount;
        break;
    case TYPE_MISC:
        // TODO: doPickup
        if (entry.imageId == 5)
        {
            points = _400pts;
        }
        else if (entry.imageId == 0x21)
        {
            points = _200pts;
        }
        else
        {
            points = _10pts;
        }
        break;
    case TYPE_DEADLYITEM:
        printf("TYPE_DEADLYITEM\n");
        entry.attackPlayer();
        break;
    }

    // unmap entry
    unmapEntry(j, entry);

    if (points == INVALID)
    {
        entry.type = TYPE_EMPTY;
        entry.imageId = 0;
    }
    else
    {
        addToScore(g_points[points]);
        entry.type = TYPE_POINTS;
        entry.imageId = points;
    }

    return true;
}

/// @brief
void CGame::consumeAll()
{
    rect_t rect;
    if (!calcActorRect(*m_player, HERE, rect))
    {
        return;
    }

    std::unordered_set<uint16_t> fwEntries;
    for (int y = 0; y < rect.hei; ++y)
    {
        for (int x = 0; x < rect.len; ++x)
        {
            const auto &key = CScript::toKey(rect.x + x, rect.y + y);
            if (m_map.count(key) == 0)
            {
                // ignore empty locations
                continue;
            }
            auto &a = m_map[key];
            for (int i = 0; i < CMapEntry::fwCount; ++i)
            {
                uint16_t j = a.fwEntry(i);
                if (j == NONE)
                    continue;
                if (fwEntries.count(j) == 0)
                {
                    // consume object only once
                    fwEntries.insert(j);
                    if (!consumeObject(j))
                    {
                        // don't removed if not consumed
                        continue;
                    }
                }
                a.removeFwEntry(j);
            }
            if (a.isEmpty())
            {
                m_map.erase(key);
            }
        }
    }
}

void CGame::setLevel(int i)
{
    m_level = i;
}

int CGame::level()
{
    return m_level;
}

int CGame::lives()
{
    return m_lives;
}

void CGame::restartGame()
{
    m_hp = DefaultHp;
    m_oxygen = DefaultOxygen;
    m_lives = DefaultLives;
    m_level = 0;
    m_mode = MODE_INTRO;
    m_jumpFlag = false;
    loadLevel(m_level);
}

void CGame::restartLevel()
{
    m_jumpFlag = false;
    m_hp = DefaultHp;
    m_oxygen = DefaultOxygen;
    --m_lives;
    if (m_lives)
    {
        m_mode = MODE_RESTART;
        loadLevel(m_level);
    }
}

int CGame::goals()
{
    return m_goals;
}

void CGame::nextLevel()
{
    m_score += LevelCompletionBonus;
    setMode(CGame::MODE_INTRO);
    ++m_level;
    loadLevel(m_level);
}

uint8_t *CGame::getActorMap(const CActor &actor)
{
    return actor.type == TYPE_PLAYER ? nullptr : (*m_frameMap)[actor.imageId];
}

bool CGame::isFalling(CActor &actor)
{
    if (actor.type == TYPE_FLYPLAT)
    {
        return false;
    }

    if (!actor.canMove(CActor::AIM_DOWN))
    {
        return false;
    }

    rect_t rect;
    if (!calcActorRect(actor, HERE, rect))
    {
        return false;
    }

    // check collision map
    uint8_t *map = getActorMap(actor);
    for (int y = 0; y < rect.hei; ++y)
    {
        for (int x = 0; x < rect.len; ++x)
        {
            if (map && !*map++)
                continue;
            const auto &key = CScript::toKey(rect.x + x, rect.y + y);
            // ignore empty locations
            if (m_map.count(key) == 0)
            {
                continue;
            }
            const auto &mapEntry = m_map[key];
            uint8_t bk = mapEntry.bk();
            if (bk >= TYPE_LADDER && bk != TYPE_STOPCLASS)
            {
                return false;
            }
        }
    }
    return true;
}

void CGame::manageGravity()
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &actor = (*m_script)[i];
        if ((CScript::isMonsterType(actor.type) || (actor.type == TYPE_PLAYER)) &&
            (actor.type != TYPE_FLYPLAT) &&
            (actor.type != TYPE_FISH) &&
            isFalling(actor))
        {
            if ((actor.type == TYPE_PLAYER) && m_jumpFlag)
            {
                continue;
            }
            unmapEntry(i, actor);
            actor.move(CActor::AIM_DOWN);
            mapEntry(i, actor);
        }
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