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
#include <cstdio>
#include <cstring>
#include <unordered_set>
#include <memory>
#include "game.h"
#include "shared/FrameSet.h"
#include "shared/Frame.h"
#include "shared/FileWrap.h"
#include "scriptarch.h"
#include "imswrap.h"
#include "framemap.h"
#include "actor.h"

constexpr const char DEFAULT_ARCHFILE[]{"data/levels.scrx"};
constexpr const char DefaultHp[]{"DefaultHp"};
constexpr const char DefaultOxygen[]{"DefaultOxygen"};
constexpr const char JumpCooldown[]{"JumpCooldown"};
constexpr const char DefaultLives[]{"DefaultLives"};
constexpr const char MaxHP[]{"MaxHP"};
constexpr const char FlowerHpBonus[]{"FlowerHpBonus"};
constexpr const char LevelCompletionBonus[]{"LevelCompletionBonus"};
constexpr const char ShowPoints[]{"ShowPoints"};

CGame *g_game = nullptr;

constexpr uint16_t g_points[]{
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

constexpr int pointCount = sizeof(g_points) / sizeof(uint16_t);

constexpr uint8_t AIMS[]{
    CActor::AIM_UP,
    CActor::AIM_DOWN,
    CActor::AIM_LEFT,
    CActor::AIM_RIGHT};

#define _J(_s_, _a_)          \
    {                         \
        .seq = _s_,           \
        .count = sizeof(_s_), \
        .aim = _a_            \
    }

#define _L(_s_) reinterpret_cast<const uint32_t *>(_s_)

using jumpSeq_t = struct
{
    const uint8_t *seq;
    const int count;
    const uint8_t aim;
};

enum
{
    UP,
    DOWN,
    LEFT,
    RIGHT,
    UP_LEFT,
    UP_RIGHT,
    DOWN_LEFT,
    DOWN_RIGHT,
    NO_AIM = 255,
    AIM_NONE = 255,
};

constexpr uint8_t jumpUP[]{UP, UP, UP, UP, DOWN, DOWN, DOWN, DOWN};
constexpr uint8_t jumpDOWN[]{};
constexpr uint8_t jumpLEFT[]{UP, LEFT, UP, LEFT, LEFT, DOWN, LEFT, DOWN};
constexpr uint8_t jumpRIGHT[]{UP, RIGHT, UP, RIGHT, RIGHT, DOWN, RIGHT, DOWN};
constexpr uint8_t jumpUP_LEFT[]{UP, UP, UP, UP, LEFT, LEFT, DOWN, DOWN, DOWN, DOWN};
constexpr uint8_t jumpUP_RIGHT[]{UP, UP, UP, UP, RIGHT, RIGHT, DOWN, DOWN, DOWN, DOWN};
constexpr uint8_t jumpDOWN_LEFT[]{UP, UP, LEFT, LEFT, LEFT, LEFT, DOWN, DOWN};
constexpr uint8_t jumpDOWN_RIGHT[]{UP, UP, RIGHT, RIGHT, RIGHT, RIGHT, DOWN, DOWN};

constexpr jumpSeq_t g_jumpSeqs[]{
    _J(jumpUP, UP),
    _J(jumpDOWN, DOWN),
    _J(jumpLEFT, LEFT),
    _J(jumpRIGHT, RIGHT),
    _J(jumpUP_LEFT, LEFT),
    _J(jumpUP_RIGHT, RIGHT),
    _J(jumpDOWN_LEFT, LEFT),
    _J(jumpDOWN_RIGHT, RIGHT),
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

bool CGame::init(const char *archname, const char *configfile)
{
    m_scriptArchName = archname ? archname : DEFAULT_ARCHFILE;
    if (!CScriptArch::indexFromFile(m_scriptArchName.c_str(), m_scriptIndex, m_scriptCount))
    {
        m_lastError = "can't read index: " + m_scriptArchName;
        printf("%s\n", m_lastError.c_str());
        return false;
    }
    printf("map count in index: %d\n", m_scriptCount);
    if (!readConfig(configfile))
    {
        printf("failed to read configfile.\n");
    }

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
        printf("%s\n", m_lastError.c_str());
        m_loadedTileSet = "";
        return false;
    }
    ims.toFrameSet(*m_frameSet, nullptr);
    m_loadedTileSet = tileset;
    m_frameMap->fromFrameSet(*m_frameSet, m_config[m_loadedTileSet].xmap);
    // m_frameMap->write("out/fmap.dat");
    return true;
}

bool CGame::loadLevel(int i)
{
    m_hp = define(DefaultHp);
    m_oxygen = define(DefaultOxygen);
    bool result = false;
    printf("reading level %.2d from: %s\n", i + 1, m_scriptArchName.c_str());
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
        // printf("flowers: %d\n", m_goals);
        int i = m_script->findPlayerIndex();
        m_player = nullptr;
        if (i != CScript::NOT_FOUND)
        {
            CActor &entry = (*m_script)[i];
            m_player = &entry;
            entry.aim = CActor::AIM_DOWN;
            //  printf("player found at: x=%d y=%d\n", entry.x, entry.y);
        }
        else
        {
            m_lastError = "no player found";
            printf("%s\n", m_lastError.c_str());
            return false;
        }
    }
    else
    {
        m_lastError = "can't open: " + m_scriptArchName;
        printf("%s\n", m_lastError.c_str());
        return false;
    }

    // load tileset
    const std::string tileset{m_script->tileset()};
    if (result &&
        (m_loadedTileSet != tileset) &&
        !loadTileset(tileset.c_str()))
    {
        result = false;
        m_lastError = "loadTileset failed";
    }
    // map script
    mapScript(m_script);
    m_levelHeight = findLevelHeight();
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
        const CActor &entry{(*script)[i]};
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
                else if (entry.type == TYPE_SAND ||
                         (a.bk() != TYPE_SAND && a.bk() < entry.type))
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
                // TODO: check this later
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

bool CGame::canLeap(const CActor &actor, int aim)
{
    CActor tmp{actor};
    if (aim != LEFT && aim != RIGHT)
    {
        return false;
    }
    return tmp.canMove(UP) &&
           tmp.move(UP) &&
           tmp.canMove(aim);
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
                if (mapEntry.bk() == TYPE_SAND &&
                    actor.type == TYPE_FISH)
                {
                    return false;
                }
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
            if (mapEntry.bk() == TYPE_LAVA &&
                actor.type == TYPE_FLYPLAT)
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
        len = frame->len() / FNT_BLOCK_SIZE;
        hei = frame->hei() / FNT_BLOCK_SIZE;
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
    const std::unordered_set<uint16_t> &hide = m_config[m_loadedTileSet].hide;
    const int scrLen = screen.len();
    const int scrHei = screen.hei();
    const int rows = screen.hei() / FNT_BLOCK_SIZE;
    const int cols = screen.len() / FNT_BLOCK_SIZE;
    const int hx = cols / 2;
    const int hy = rows / 2;
    const int mx = m_player->x < hx ? 0 : m_player->x - hx;
    const int my = m_player->y < hy ? 0 : m_player->y - hy;
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CFrame *frame;
        const auto &entry{(*m_script)[i]};
        if (entry.type == TYPE_PLAYER)
        {
            frame = (*m_annie)[entry.aim * PLAYER_FRAME_CYCLE +
                               m_playerFrameOffset];
        }
        else if (entry.type == TYPE_POINTS)
        {
            frame = (*m_points)[entry.imageId];
        }
        else if (entry.imageId >= m_frameSet->getSize() ||
                 CScript::isSystemType(entry.type) ||
                 hide.count(entry.imageId))
        {
            continue;
        }
        else
        {
            frame = (*m_frameSet)[entry.imageId];
        }
        const int fcols = frame->len() / FNT_BLOCK_SIZE;
        const int frows = frame->hei() / FNT_BLOCK_SIZE;
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
            for (int y = 0; y < fhei * FNT_BLOCK_SIZE; ++y)
            {
                if (sy * FNT_BLOCK_SIZE + y >= scrHei)
                    break;
                uint32_t *rgba = &screen.at(sx * FNT_BLOCK_SIZE, sy * FNT_BLOCK_SIZE + y);
                const uint32_t *pixel = &frame->at(offsetX * FNT_BLOCK_SIZE, offsetY * FNT_BLOCK_SIZE + y);
                for (int x = 0; x < flen * FNT_BLOCK_SIZE; ++x)
                {
                    if (sx * FNT_BLOCK_SIZE + x >= scrLen)
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
    uint16_t x = 0;
    sprintf(tmp, "%.8d ", m_score);
    drawText(screen, x, 0, tmp, WHITE);
    x += strlen(tmp) * FONT_SIZE;

    sprintf(tmp, "FLOWERS %.2d ", m_goals);
    drawText(screen, x, 0, tmp, YELLOW);
    x += strlen(tmp) * FONT_SIZE;

    sprintf(tmp, "LIVES %.2d ", m_lives);
    drawText(screen, x, 0, tmp, PINK);
    x += strlen(tmp) * FONT_SIZE;

    sprintf(tmp, "COINS %.2d", m_coins);
    drawText(screen, x, 0, tmp, BLUE);
    x += strlen(tmp) * FONT_SIZE;

    // draw health bar
    rect_t rect;
    const int sectionHeight = HealthBarHeight + HealthBarOffset;
    x = HealthBarOffset;
    uint16_t y = screen.hei() - sectionHeight * 2;
    rect = {x, y, std::min(m_hp / 2, screen.len() - HealthBarOffset), HealthBarHeight};
    drawRect(screen, rect, LIME, true);
    drawRect(screen, rect, WHITE, false);
    // draw oxygen bar
    y += sectionHeight;
    rect = {x, y, std::min(m_oxygen / 2, screen.len() - HealthBarOffset), HealthBarHeight};
    drawRect(screen, rect, LIGHTGRAY, true);
    drawRect(screen, rect, WHITE, false);
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
    return m_types[TYPE_PLAYER].speed; // DEFAULT_PLAYER_SPEED;
}

bool CGame::isPlayerDead()
{
    return m_hp == 0;
}

bool CGame::manageJump(const uint8_t *joyState)
{
    if (m_jumpCooldown)
    {
        --m_jumpCooldown;
        return false;
    }

    unmapEntry(NONE, *m_player);
    if (m_jumpFlag)
    {
        const uint8_t &aim = g_jumpSeqs[m_jumpSeq].seq[m_jumpIndex];
        if (m_player->canMove(aim))
        {
            m_player->move(aim);
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
        if (!m_jumpFlag)
        {
            m_jumpCooldown = define(JumpCooldown);
        }
    }
    else
    {
        if (joyState[BUTTON])
        {
            m_jumpIndex = 0;
            uint8_t newAim = NO_AIM;

            if (joyState[UP] && joyState[LEFT])
            {
                newAim = UP_LEFT;
            }
            else if (joyState[UP] && joyState[RIGHT])
            {
                newAim = UP_RIGHT;
            }
            else if (joyState[DOWN] && joyState[LEFT])
            {
                newAim = DOWN_LEFT;
            }
            else if (joyState[DOWN] && joyState[RIGHT])
            {
                newAim = DOWN_RIGHT;
            }
            else
            {
                const uint8_t aims[] = {UP, LEFT, RIGHT};
                for (int i = 0; i < sizeof(aims); ++i)
                {
                    const int aim = aims[i];
                    if (joyState[aim])
                    {
                        newAim = aim;
                        break;
                    }
                }
            }

            if (newAim != NO_AIM)
            {
                m_player->aim = g_jumpSeqs[newAim].aim;
                m_jumpFlag = true;
                m_jumpSeq = newAim;
            }
        }
    }
    mapEntry(NONE, *m_player);
    return m_jumpFlag;
}

void CGame::managePlayer(const uint8_t *joyState)
{

    managePlayerOxygenControl();

    // animate player
    if (m_playerHitCountdown)
    {
        --m_playerHitCountdown;
        m_playerFrameOffset = PLAYER_HIT_FRAME;
    }
    else if (*reinterpret_cast<const uint32_t *>(joyState))
    {
        m_playerFrameOffset = (m_playerFrameOffset + 1) % PLAYER_MOVE_FRAMES;
    }
    else
    {
        m_playerFrameOffset = 0;
    }

    consumeAll();

    unmapEntry(NONE, *m_player);
    for (uint8_t i = 0; i < sizeof(AIMS); ++i)
    {
        const uint8_t aim = AIMS[i];

        if (joyState[aim])
        {
            bool ok = false;
            switch (aim)
            {
            case UP:
                ok = m_player->testAim(aim);
                break;
            case DOWN:
                ok = m_player->canMove(aim);
                break;
            case LEFT:
            case RIGHT:
                ok = m_player->canMove(aim);
                if (!ok && (ok = m_player->canLeap(aim)))
                {
                    m_player->move(UP);
                }
            }
            if (ok)
            {
                m_player->move(aim);
                m_player->aim = aim;
                break;
            }
        }
    }
    mapEntry(NONE, *m_player);
}

void CGame::preloadAssets()
{
    CFileWrap file;

    using asset_t = struct
    {
        const char *filename;
        CFrameSet **frameset;
    };

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

void CGame::killPlayer()
{
    m_hp = 0;
}

void CGame::attackPlayer(const CActor &actor)
{
    int damage{0};
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
        damage = CanmibalDamage;
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

    m_playerHitCountdown = PlayerHitDuration;
    if (damage == KILL_PLAYER)
    {
        actor.killPlayer();
    }
    else
    {
        m_hp = std::max(0, m_hp - damage);
    }
}

void CGame::manageDroneVariant(int i, CActor &actor, const char *signcall, int frameCount)
{
    unmapEntry(i, actor);
    if (actor.aim < CActor::AIM_LEFT)
    {
        actor.aim = CActor::AIM_LEFT;
    }
    if (actor.canMove(actor.aim))
    {
        actor.move(actor.aim);
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
    actor.imageId = xdefine(signcall) +
                    frameCount * (actor.aim & 1) +
                    actor.seqOffset;
    mapEntry(i, actor);
}

void CGame::manageVamplant(int i, CActor &actor)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            actor.attackPlayer();
            break;
        }
    }
}

void CGame::manageVCreatureVariant(int i, CActor &actor, const char *signcall, int frameCount)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            actor.attackPlayer();
            break;
        }
    }

    unmapEntry(i, actor);
    int aim = actor.findNextDir();
    if (aim != AIM_NONE)
    {
        actor.move(aim);
        actor.aim = aim;
    }

    if (signcall != nullptr)
    {
        actor.imageId = xdefine(signcall) +
                        frameCount * actor.aim +
                        actor.seqOffset;
    }

    mapEntry(i, actor);
}

void CGame::manageFlyingPlatform(int i, CActor &actor)
{
    uint8_t aim{actor.aim};
    uint8_t pAim{NOT_FOUND};
    if (aim == UP || aim == LEFT || aim == RIGHT)
    {
        if (actor.isPlayerThere(aim))
        {
            pAim = aim;
        }
        else if (actor.isPlayerThere(UP))
        {
            pAim = UP;
        }

        if (pAim != NOT_FOUND)
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
            }
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

/// @brief
void CGame::manageMonsters(uint32_t ticks)
{
    bool speeds[speedCount];
    for (uint32_t i = 0; i < sizeof(speeds); ++i)
    {
        speeds[i] = i ? (ticks % i) == 0 : true;
    }

    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &actor{(*m_script)[i]};
        if (!CScript::isMonsterType(actor.type))
        {
            int x = m_types[actor.type].speed;
            if (speeds[x] && actor.type == TYPE_POINTS)
            {
                if ((actor.y) && (actor.y > m_player->y - 10))
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

        int x = m_types[actor.type].speed;
        if (!speeds[x])
        {
            continue;
        }

        switch (actor.type)
        {
        case TYPE_FISH:
            manageDroneVariant(i, actor, "FISH", FishFrameCycle);
            break;
        case TYPE_VAMPIREPLANT:
            manageVamplant(i, actor);
            break;
        case TYPE_VCREA:
            manageVCreatureVariant(i, actor, nullptr, 0);
            break;
        case TYPE_FLYPLAT:
            manageFlyingPlatform(i, actor);
            break;
        case TYPE_CANNIBAL:
            manageVCreatureVariant(i, actor, "CANN", 3);
            break;
        case TYPE_INMANGA:
            manageDroneVariant(i, actor, "INMA", InMangaFrameCycle);
            break;
        case TYPE_GREENFLEA:
            manageVCreatureVariant(i, actor, "SLUG", 2);
        };
    }
}

void CGame::drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color)
{
    uint32_t *rgba = frame.getRGB();
    const int rowPixels = frame.len();
    const int fontOffset = FONT_SIZE;
    const int textSize = strlen(text);
    for (int i = 0; i < textSize; ++i)
    {
        const uint8_t c{static_cast<uint8_t>(text[i] - ' ')};
        uint8_t *font = m_fontData + c * fontOffset;
        for (int yy = 0; yy < FONT_SIZE; ++yy)
        {
            uint8_t bitFilter{1};
            for (int xx = 0; xx < FONT_SIZE; ++xx)
            {
                rgba[(yy + y) * rowPixels + xx + x] = font[yy] & bitFilter ? color : BLACK;
                bitFilter = bitFilter << 1;
            }
        }
        x += FONT_SIZE;
    }
}

void CGame::addToScore(int score)
{
    m_score += score;
}

void CGame::handleRemove(int j, CActor &entry)
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &cur{(*m_script)[i]};
        if (i == j)
            continue;
        if (cur.triggerKey == entry.triggerKey)
        {
            unmapEntry(i, cur);
            cur.clear();
            cur.type = TYPE_EMPTY;
            mapEntry(i, cur);
        }
    }
}

void CGame::handleChange(int j, CActor &entry)
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &cur{(*m_script)[i]};
        if (i == j)
            continue;
        if (cur.triggerKey == entry.triggerKey)
        {
            unmapEntry(i, cur);
            cur.clear();
            cur.type = TYPE_OBSTACLECLASS;
            cur.imageId = entry.changeTo;
            mapEntry(i, cur);
        }
    }
}

void CGame::handleTeleport(int j, CActor &entry)
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &cur{(*m_script)[i]};
        if (i == j)
            continue;
        if ((cur.triggerKey == entry.triggerKey) &&
            (cur.task == TASK_DEST))
        {
            CActor &player = *m_player;
            unmapEntry(NONE, player);
            player.x = cur.x;
            player.y = cur.y;
            mapEntry(NONE, player);
            return;
        }
    }
    printf("no matching dest with triggerkey: %.2x\n", entry.triggerKey);
}

void CGame::handleTrigger(int j, CActor &entry)
{
    switch (entry.task)
    {
    case TASK_CHANGE:
        handleChange(j, entry);
        break;
    case TASK_REMOVE:
        handleRemove(j, entry);
        break;
    case TASK_SOURCE:
        handleTeleport(j, entry);
    }
}

uint16_t CGame::xdefine(const char *sig)
{
    if (m_config[m_loadedTileSet].xdef.count(*_L(sig)))
    {
        return m_config[m_loadedTileSet].xdef[*_L(sig)];
    }
    else
    {
        return 0;
    }
}

bool CGame::consumeObject(uint16_t j)
{
    CActor &entry{(*m_script)[j]};
    int points = INVALID;
    bool consumed = true;
    switch (entry.type)
    {
    case TYPE_OXYGEN:
        points = _10pts;
        m_oxygen += OxygenBonus;
        break;
    case TYPE_TRANSPORTER:
        consumed = false;
        break;
    case TYPE_DIAMOND:
        if ((entry.imageId != 0) &&
            (entry.imageId == xdefine("GOLD")))
        {
            points = _50pts;
            m_coins += 5;
        }
        else
        {
            points = _25pts;
            m_coins += 1;
        }
        if (m_coins >= Coins4Life)
        {
            m_coins -= Coins4Life;
            ++m_lives;
        }
        break;
    case TYPE_FLOWER:
        points = _100pts;
        m_hp = std::min(m_hp + define(FlowerHpBonus), define(MaxHP));
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
        entry.attackPlayer();
        break;
    default:
        printf("unhanled type: %.2x at %d\n", entry.type, j);
    }

    // doPickup (pickup triggers)
    handleTrigger(j, entry);

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
        entry.type = define(ShowPoints) ? TYPE_POINTS : TYPE_EMPTY;
        entry.imageId = points;
    }
    return consumed;
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
            if (a.bk() == TYPE_LAVA)
            {
                // instant death
                killPlayer();
                return;
            }

            for (int i = 0; i < CMapEntry::fwCount; ++i)
            {
                uint16_t j{a.fwEntry(i)};
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

void CGame::startGame()
{
    m_playerHitCountdown = 0;
    m_hp = define(DefaultHp);
    m_oxygen = define(DefaultOxygen);
    m_lives = define(DefaultLives);
    m_mode = MODE_INTRO;
    m_jumpFlag = false;
    m_coins = 0;
}

void CGame::restartGame()
{
    m_level = 0;
    m_underwaterCounter = 0;
    startGame();
    loadLevel(m_level);
}

void CGame::restartLevel()
{
    m_underwaterCounter = 0;
    m_playerHitCountdown = 0;
    m_jumpFlag = false;
    m_hp = define(DefaultHp);
    m_oxygen = define(DefaultOxygen);
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
    m_score += define(LevelCompletionBonus);
    setMode(CGame::MODE_INTRO);
    ++m_level;
    loadLevel(m_level);
}

uint8_t *CGame::getActorMap(const CActor &actor)
{
    return actor.type == TYPE_PLAYER ? nullptr : (*m_frameMap)[actor.imageId];
}

bool CGame::canFall(const CActor &actor)
{
    return isFalling(actor, HERE) &&
           isFalling(actor, DOWN) &&
           actor.canMove(CActor::AIM_DOWN);
}

bool CGame::isFalling(const CActor &actor, int aim)
{
    if (actor.type == TYPE_FLYPLAT)
    {
        return false;
    }

    rect_t rect;
    if (!calcActorRect(actor, aim, rect))
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
            if (bk >= TYPE_LADDER && bk != TYPE_STOPCLASS &&
                bk != TYPE_LAVA && bk != TYPE_TOPWATER)
            {
                return false;
            }
        }
    }
    return true;
}

bool CGame::testAim(const CActor &actor, int aim)
{
    CActor tmp{actor};
    if (!tmp.canMove(aim))
    {
        return false;
    }
    tmp.move(aim);
    if (tmp.canFall())
    {
        return false;
    }
    return true;
}

void CGame::manageGravity()
{
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &actor{(*m_script)[i]};
        if ((CScript::isMonsterType(actor.type) || (actor.type == TYPE_PLAYER)) &&
            (actor.type != TYPE_FLYPLAT) &&
            (actor.type != TYPE_FISH) &&
            canFall(actor))
        {
            if ((actor.type == TYPE_PLAYER) && m_jumpFlag)
            {
                continue;
            }
            unmapEntry(i, actor);
            actor.move(CActor::AIM_DOWN);
            mapEntry(i, actor);
            if (actor.type == TYPE_PLAYER && actor.y > m_levelHeight)
            {
                killPlayer();
            }
        }
    }
}

void CGame::parseGeneralOptions(const StringVector &list, int line)
{
    if (list[0] == "type")
    {
        if (list.size() == 3)
        {
            uint16_t val1{static_cast<decltype(val1)>(std::strtoul(list[1].c_str(), nullptr, 16))};
            uint16_t val2{static_cast<decltype(val2)>(std::strtoul(list[2].c_str(), nullptr, 16))};
            m_types[val1].speed = val2;
        }
        else
        {
            printf("type must have 3 args. %zu found on line %d\n", list.size(), line);
            for (size_t i = 0; i < list.size(); ++i)
            {
                printf(" -->%d %s\n", i, list[i].c_str());
            }
        }
    }
    else if (list[0] == "define")
    {
        if (list.size() == 3)
        {
            const std::string &key{list[1]};
            uint16_t val{static_cast<decltype(val)>(std::strtoul(list[2].c_str(), nullptr, 10))};
            m_defines[key] = val;
        }
        else
        {
            printf("define must have 3 args. %zu found on line %d\n", list.size(), line);
            for (size_t i = 0; i < list.size(); ++i)
            {
                printf(" -->%d %s\n", i, list[i].c_str());
            }
        }
    }
    else
    {
        printf("unknown list `%s` on line %d\n", list[0].c_str(), line);
    }
}

void CGame::parseTilesetOptions(std::string tileset, const StringVector &list, int line)
{
    if (list[0] == "hide")
    {
        if (list.size() < 2)
        {
            printf("hide list on line %d has %zu params, minimum is 2.", line, list.size());
        }
        else
        {
            for (size_t i = 1; i < list.size(); ++i)
            {
                uint16_t val{static_cast<decltype(val)>(std::strtoul(list[i].c_str(), nullptr, 16))};
                m_config[tileset].hide.insert(val);
            }
        }
    }
    else if (list[0] == "swap")
    {
        if (list.size() != 3)
        {
            printf("swap command  on line %d has %zu params not 3.", line, list.size());
        }
        else
        {
            uint16_t val1{static_cast<decltype(val1)>(std::strtoul(list[1].c_str(), nullptr, 16))};
            uint16_t val2{static_cast<decltype(val2)>(std::strtoul(list[2].c_str(), nullptr, 16))};
            m_config[tileset].swap[val1] = val2;
            m_config[tileset].swap[val2] = val1;
        }
    }
    else if (list[0] == "xmap")
    {
        if (list.size() < 2)
        {
            printf("xmap list on line %d has %zu params, minimum is 2.", line, list.size());
        }
        else
        {
            for (int i = 1; i < list.size(); ++i)
            {
                uint16_t val{static_cast<decltype(val)>(std::strtoul(list[i].c_str(), nullptr, 16))};
                m_config[tileset].xmap.insert(val);
            }
        }
    }
    else if (list[0] == "xdef")
    {
        if (list.size() < 2)
        {
            printf("xdef list on line %d has %zu params, must have 2.", line, list.size());
        }
        else
        {
            uint32_t key{*_L(list[1].c_str())};
            uint16_t val{static_cast<decltype(val)>(std::strtoul(list[2].c_str(), nullptr, 16))};
            m_config[tileset].xdef[key] = val;
        }
    }
    else
    {
        printf("unknown list `%s` on line %d\n", list[0].c_str(), line);
    }
}

char *CGame::parseLine(int &line, std::string &tileset, char *p)
{
    ++line;
    char *e = strstr(p, "\n");
    if (e)
    {
        *e = 0;
    }
    char *m = strstr(p, "\r");
    if (m)
    {
        *m = 0;
    }
    if (m > e)
    {
        e = m;
    }

    char *c = strstr(p, "#");
    if (c)
    {
        *c = 0;
    }
    int n = strlen(p);
    if (n)
    {
        char *t = p + n - 1;
        while (t > p && isspace(*t))
        {
            *t = 0;
            --t;
        }
    }

    while (isspace(*p))
    {
        ++p;
    }
    if (*p == '[')
    {
        ++p;
        char *t = strstr(p, "]");
        if (t)
        {
            *t = 0;
        }
        else
        {
            printf("no section delimiter on line %d\n", line);
        }
        tileset = p;
    }
    else if (*p)
    {
        StringVector list;
        splitString(p, list);
        if (list.size() == 0)
        {
            printf("empty list on line %d\n", line);
        }
        else if (tileset == "")
        {
            parseGeneralOptions(list, line);
        }
        else
        {
            parseTilesetOptions(tileset, list, line);
        }
    }
    return e ? ++e : nullptr;
}

void CGame::splitString(const std::string &str, StringVector &list)
{
    int i = 0;
    unsigned int j = 0;
    while (j < str.length())
    {
        if (isspace(str[j]))
        {
            list.push_back(str.substr(i, j - i));
            while (isspace(str[j]) && j < str.length())
            {
                ++j;
            }
            i = j;
            continue;
        }
        ++j;
    }
    list.push_back(str.substr(i, j - i));
}

bool CGame::readConfig(const char *confName)
{
    printf("parsing: %s\n", confName);
    m_config.clear();
    FILE *sfile = fopen(confName, "rb");
    if (sfile)
    {
        fseek(sfile, 0, SEEK_END);
        size_t size = ftell(sfile);
        fseek(sfile, 0, SEEK_SET);
        char *data = new char[size + 1];
        data[size] = 0;
        fread(data, size, 1, sfile);
        fclose(sfile);

        char *p = data;
        std::string tileset;
        int line = 0;
        while (p && *p)
        {
            p = parseLine(line, tileset, p);
        }
        delete[] data;
    }
    return sfile != nullptr;
}

void CGame::animator(uint32_t ticks)
{
    PairMap &swap = m_config[m_loadedTileSet].swap;
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &actor = (*m_script)[i];
        if (swap.count(actor.imageId))
        {
            unmapEntry(i, actor);
            actor.imageId = swap[actor.imageId];
            mapEntry(i, actor);
        }
        else if (actor.type == TYPE_INMANGA ||
                 actor.type == TYPE_GREENFLEA ||
                 actor.type == TYPE_CANNIBAL)
        {
            unmapEntry(i, actor);
            actor.seqOffset ^= 1;
            mapEntry(i, actor);
        }
    }
}

uint32_t CGame::define(const char *name)
{
    if (m_defines.count(name))
    {
        return m_defines[name];
    }
    else
    {
        printf("define %s not found\n", name);
        return 0;
    }
}

void CGame::drawRect(CFrame &frame, const rect_t &rect, const uint32_t color, bool fill)
{
    uint32_t *rgba = frame.getRGB();
    const int rowPixels = frame.len();
    if (fill)
    {
        for (int y = 0; y < rect.hei; y++)
        {
            for (int x = 0; x < rect.len; x++)
            {
                rgba[(rect.y + y) * rowPixels + rect.x + x] = color;
            }
        }
    }
    else
    {
        for (int y = 0; y < rect.hei; y++)
        {
            for (int x = 0; x < rect.len; x++)
            {
                if (y == 0 || y == rect.hei - 1 || x == 0 || x == rect.len - 1)
                {
                    rgba[(rect.y + y) * rowPixels + rect.x + x] = color;
                }
            }
        }
    }
}

bool CGame::isUnderwater(const CActor &actor)
{
    rect_t rect;
    if (!calcActorRect(actor, HERE, rect))
    {
        return false;
    }

    for (int x = 0; x < rect.len; ++x)
    {
        const auto &key = CScript::toKey(rect.x + x, rect.y);
        if (m_map.count(key) == 0)
        {
            // ignore empty locations
            return false;
        }
        if (m_map[key].bk() == TYPE_BOTTOMWATER)
        {
            continue;
        }
        return false;
    }

    return true;
}

void CGame::managePlayerOxygenControl()
{
    if (isUnderwater(*m_player))
    {
        ++m_underwaterCounter;
        if (m_underwaterCounter > OxygenLostDelay)
        {
            if (m_oxygen)
            {
                --m_oxygen;
            }
            else
            {
                m_playerHitCountdown = 1;
                if (m_hp)
                {
                    --m_hp;
                }
            }
        }
    }
    else
    {
        m_underwaterCounter = 0;
        m_oxygen = std::max(static_cast<uint32_t>(m_oxygen), define(DefaultOxygen));
    }
}

void CGame::debugFrameMap(const char *outFile)
{
    CFrameSet fs;
    for (int i = 0; i < m_frameSet->getSize(); ++i)
    {
        CFrame *frame = new CFrame((*m_frameSet)[i]);
        uint8_t *map = m_frameMap->mapPtr(i);
        for (int j = 0; j < frame->hei() / FNT_BLOCK_SIZE; ++j)
        {
            for (int k = 0; k < frame->len() / FNT_BLOCK_SIZE; ++k)
            {
                uint8_t c = *map++;
                uint8_t *p = &m_fontData[c * FNT_BLOCK_SIZE];

                for (int y = 0; y < FNT_BLOCK_SIZE; ++y)
                {
                    uint8_t bits = p[y];
                    for (int x = 0; x < FNT_BLOCK_SIZE; ++x)
                    {
                        if (bits & 1)
                        {
                            frame->at(k * FNT_BLOCK_SIZE + x, j * FNT_BLOCK_SIZE + y) = 0xff00ffff;
                        }
                        bits = bits >> 1;
                    }
                }
            }
        }
        fs.add(frame);
    }

    CFileWrap file;
    if (file.open(outFile, "wb"))
    {
        fs.write(file);
        file.close();
    }
}

int CGame::findLevelHeight()
{
    int len, hei;
    int maxY = 0;
    for (int i = BASE_ENTRY; i < m_script->getSize(); ++i)
    {
        CActor &cur{(*m_script)[i]};
        sizeFrame(cur, len, hei);
        maxY = std::max(maxY, cur.y + hei);
    }
    return maxY;
}

void CGame::debugLevel(const char *filename)
{
    std::unordered_map<uint16_t, std::string> imageNames;
    std::string mapFile = std::string("data/") + m_loadedTileSet + ".map";
    printf("reading: %s\n", mapFile.c_str());
    FILE *sfile = fopen(mapFile.c_str(), "rb");
    if (sfile)
    {
        fseek(sfile, 0, SEEK_END);
        size_t size = ftell(sfile);
        fseek(sfile, 0, SEEK_SET);
        char *data = new char[size + 1];
        data[size] = 0;
        fread(data, size, 1, sfile);
        fclose(sfile);
        char *p = data;
        uint16_t i = 0;
        while (p && *p)
        {
            char *e = strstr(p, "\n");
            if (e)
            {
                *e = 0;
            }
            if (*p)
            {
                imageNames[i] = p;
            }
            ++i;
            p = e ? ++e : nullptr;
        }
        delete[] data;
    }

    printf("total images:%zu\n", imageNames.size());

    FILE *tfile = fopen(filename, "wb");
    if (tfile)
    {
        fprintf(tfile, "imsfilename: %s\n", m_loadedTileSet.c_str());
        fprintf(tfile, "tiles: %d\n\n", m_frameSet->getSize());

        for (int i = 0; i < m_script->getSize(); ++i)
        {
            const CActor &entry = (*m_script)[i];
            fprintf(tfile, "#%d attr %x type %.2x (%s)\n", i, entry.attr, entry.type, CImsWrap::getTypeName(entry.type));
            fprintf(tfile, "    u1 %x u2 %x imageId %d (%s)\n", entry.u1, entry.u2, entry.imageId, imageNames[entry.imageId].c_str());
            fprintf(tfile, "    x:%d y:%d \n\n", entry.x, entry.y);
        }
    }
}