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
#include "framemap.h"
#include "actor.h"
#include "script.h"

constexpr const char DEFAULT_ARCHFILE[]{"data/levels.scrx"};
constexpr const char DefaultHp[]{"DefaultHp"};
constexpr const char DefaultOxygen[]{"DefaultOxygen"};
constexpr const char JumpCooldown[]{"JumpCooldown"};
constexpr const char DefaultLives[]{"DefaultLives"};
constexpr const char MaxHP[]{"MaxHP"};
constexpr const char FlowerHpBonus[]{"FlowerHpBonus"};
constexpr const char LevelCompletionBonus[]{"LevelCompletionBonus"};
constexpr const char ShowPoints[]{"ShowPoints"};
constexpr const char CANN_ID[] = "CANN";
constexpr const char INMA_ID[] = "INMA";
constexpr const char FISH_ID[] = "FISH";
constexpr const char SLUG_ID[] = "SLUG";
constexpr const char GOLD_ID[] = "GOLD";
constexpr const char GAME_SIGNATURE[] = {'V', 'L', 'A', '2'};

static CGame *g_game = nullptr;
#define typeref(__ref, __var) static_cast<decltype(__ref)>(__var)

inline auto _L = [](auto _s_)
{
    return reinterpret_cast<const uint32_t *>(_s_);
};

CGame::CGame()
{
    printf("creating game singleton\n");
    m_frameSet = new CFrameSet;
    m_scriptCount = 0;
    m_script = new CScript;
    m_frameMap = new CFrameMap;
    m_scriptIndex = nullptr;
    m_loadedTileSet = "";
    m_score = 0;
}

CGame::~CGame()
{
    printf("deleting game singleton\n");

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
        fseek(sfile, m_scriptIndex[i % m_scriptCount], SEEK_SET);
        // read level
        result = m_script->read(sfile);
        fclose(sfile);
    }
    else
    {
        m_lastError = "can't open: " + m_scriptArchName;
        printf("%s\n", m_lastError.c_str());
        return false;
    }

    return readyLevel();
}

bool CGame::readyLevel()
{
    m_script->sort();
    m_script->insertAt(0, CActor{});
    m_goals = m_script->countType(TYPE_FLOWER);
    // printf("flowers: %d\n", m_goals);
    int i = m_script->findPlayerIndex();
    if (i != CScript::NOT_FOUND)
    {
        CActor &entry = (*m_script)[i];
        m_player = &entry;
        entry.aim = CActor::AIM_DOWN;
        //  printf("player found at: x=%d y=%d\n", entry.x, entry.y);
    }
    else
    {
        m_player = nullptr;
        m_lastError = "no player found";
        printf("%s\n", m_lastError.c_str());
        return false;
    }

    // load tileset
    const std::string tileset{m_script->tileset()};
    if ((m_loadedTileSet != tileset) &&
        !loadTileset(tileset.c_str()))
    {
        m_lastError = "loadTileset failed";
        return false;
    }
    // map script
    mapScript(m_script);
    m_levelHeight = findLevelHeight();
    return true;
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

bool CGame::calcActorRect(const CActor &actor, int aim, rect_t &rect)
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

CGame *CGame::getGame()
{
    if (!g_game)
    {
        g_game = new CGame{};
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
    static const jumpSeq_t g_jumpSeqs[]{
        {UP, UP, UP, UP, UP, DOWN, DOWN, DOWN, DOWN},                  // up
        {DOWN},                                                        // down
        {LEFT, UP, LEFT, UP, LEFT, LEFT, DOWN, LEFT, DOWN},            // left
        {RIGHT, UP, RIGHT, UP, RIGHT, RIGHT, DOWN, RIGHT, DOWN},       // right
        {LEFT, UP, UP, UP, UP, LEFT, LEFT, DOWN, DOWN, DOWN, DOWN},    // up left
        {RIGHT, UP, UP, UP, UP, RIGHT, RIGHT, DOWN, DOWN, DOWN, DOWN}, // up right
        {LEFT, UP, UP, LEFT, LEFT, LEFT, LEFT, DOWN, DOWN},            // down left
        {RIGHT, UP, UP, RIGHT, RIGHT, RIGHT, RIGHT, DOWN, DOWN},       // down right
    };

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
    }
    if (*reinterpret_cast<const uint32_t *>(joyState))
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

void CGame::killPlayer(const CActor &actor)
{
    killPlayer();
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
        printf("type=0x%.2x no damage defined\n", actor.type);
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

void CGame::manageVamplant(const int i, CActor &actor)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        const uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            actor.attackPlayer();
            break;
        }
    }
}

void CGame::manageVCreatureVariant(const int i, CActor &actor, const char *signcall, const int frameCount, const bool ableToLeap)
{
    for (uint8_t j = 0; j < sizeof(AIMS); ++j)
    {
        const uint8_t aim = AIMS[j];
        if (isPlayerThere(actor, aim))
        {
            actor.attackPlayer();
            break;
        }
    }

    unmapEntry(i, actor);
    int aim = actor.findNextDir(ableToLeap);
    if (aim != AIM_NONE)
    {
        if (aim & CActor::AIM_LEAP)
        {
            aim ^= CActor::AIM_LEAP;
            actor.move(UP);
        }
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

void CGame::manageFlyingPlatform(const int i, CActor &actor)
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
void CGame::manageMonsters(const uint32_t ticks)
{
    // compute all time slices
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
            manageDroneVariant(i, actor, FISH_ID, FishFrameCycle);
            break;
        case TYPE_VAMPIREPLANT:
            manageVamplant(i, actor);
            break;
        case TYPE_VCREA:
            manageVCreatureVariant(i, actor, nullptr, VCreaFrameCycle, false);
            break;
        case TYPE_FLYPLAT:
            manageFlyingPlatform(i, actor);
            break;
        case TYPE_CANNIBAL:
            manageVCreatureVariant(i, actor, CANN_ID, CannibalFrameCycle, true);
            break;
        case TYPE_INMANGA:
            manageDroneVariant(i, actor, INMA_ID, InMangaFrameCycle);
            break;
        case TYPE_GREENFLEA:
            manageVCreatureVariant(i, actor, SLUG_ID, FleaFrameCycle, true);
        };
    }
}

void CGame::addToScore(int score)
{
    m_score += score;
}

void CGame::handleRemove(int j, const CActor &entry)
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

void CGame::handleChange(int j, const CActor &entry)
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

void CGame::handleTeleport(int j, const CActor &entry)
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
    case TASK_NONE:
        break;
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
        m_oxygen = std::min(m_oxygen + OxygenBonus, typeref(m_oxygen, MaxOxygen));
        break;
    case TYPE_TRANSPORTER:
        consumed = false;
        break;
    case TYPE_DIAMOND:
        if ((entry.imageId != 0) &&
            (entry.imageId == xdefine(GOLD_ID)))
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
        points = entry.imageId % PointCount;
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
        addToScore(m_pointValues[points]);
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

void CGame::setLevel(const int i)
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
    m_score = 0;
    m_jumpCooldown = 0;
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
    m_jumpCooldown = 0;
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
                printf(" -->%zu %s\n", i, list[i].c_str());
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
                printf(" -->%zu %s\n", i, list[i].c_str());
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
        *e = '\0';
    }
    char *m = strstr(p, "\r");
    if (m)
    {
        *m = '\0';
    }
    if (m > e)
    {
        e = m;
    }

    char *c = strstr(p, "#");
    if (c)
    {
        *c = '\0';
    }
    int n = strlen(p);
    if (n)
    {
        char *t = p + n - 1;
        while (t > p && isspace(*t))
        {
            *t = '\0';
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
            *t = '\0';
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
        else if (tileset.size() == 0)
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
            list.emplace_back(str.substr(i, j - i));
            while (isspace(str[j]) && j < str.length())
            {
                ++j;
            }
            i = j;
            continue;
        }
        ++j;
    }
    list.emplace_back(str.substr(i, j - i));
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

void CGame::setLives(const int val)
{
    m_lives = val;
}

CActor *CGame::player()
{
    return m_player;
}

int CGame::coins()
{
    return m_coins;
}

int CGame::score()
{
    return m_score;
}

bool CGame::loadTileset(const char *tileset)
{
    printf("loading tileset: %s\n", tileset);
    std::string tilesetName = "data/" + std::string(tileset) + ".obl";
    CFileWrap file;
    if (file.open(tilesetName.c_str(), "rb"))
    {
        m_frameSet->read(file);
        file.close();
    }
    else
    {
        m_lastError = "can't read tileset: " + tilesetName;
        printf("%s\n", m_lastError.c_str());
        m_loadedTileSet = "";
        return false;
    }
    m_loadedTileSet = tileset;
    m_frameMap->fromFrameSet(*m_frameSet, m_config[m_loadedTileSet].xmap);
    return true;
}

CFrameSet *CGame::tiles()
{
    return m_frameSet;
}

CScript *CGame::script()
{
    return m_script;
}

int CGame::hp()
{
    return m_hp;
}

int CGame::oxygen()
{
    return m_oxygen;
}

const std::unordered_set<uint16_t> &CGame::hideList()
{
    return m_config[m_loadedTileSet].hide;
}

bool CGame::read(FILE *sfile)
{
    auto readfile = [sfile](auto ptr, auto size)
    {
        return fread(ptr, size, 1, sfile) == 1;
    };

    // check signature/version
    uint32_t signature = 0;
    readfile(&signature, sizeof(signature));
    uint32_t version = 0;
    readfile(&version, sizeof(version));
    if (memcmp(GAME_SIGNATURE, &signature, sizeof(GAME_SIGNATURE)) != 0)
    {
        char sig[5] = {0, 0, 0, 0, 0};
        memcpy(sig, &signature, sizeof(signature));
        printf("savegame signature mismatched: %s\n", sig);
        return false;
    }
    if (version != VERSION)
    {
        printf("savegame version mismatched: 0x%.8x\n", version);
        return false;
    }

    // ptr
    uint32_t indexPtr = 0;
    readfile(&indexPtr, sizeof(indexPtr));

    // general information
    m_script->read(sfile);

    readfile(&m_goals, sizeof(m_goals));
    readfile(&m_score, sizeof(m_score));
    readfile(&m_hp, sizeof(m_hp));
    readfile(&m_lives, sizeof(m_lives));
    readfile(&m_oxygen, sizeof(m_oxygen));
    readfile(&m_coins, sizeof(m_coins));
    readfile(&m_level, sizeof(m_level));
    readfile(&m_jumpFlag, sizeof(m_jumpFlag));
    readfile(&m_jumpSeq, sizeof(m_jumpSeq));
    readfile(&m_jumpIndex, sizeof(m_jumpIndex));
    readfile(&m_playerFrameOffset, sizeof(m_playerFrameOffset));
    readfile(&m_playerHitCountdown, sizeof(m_playerHitCountdown));
    readfile(&m_underwaterCounter, sizeof(m_underwaterCounter));
    readfile(&m_levelHeight, sizeof(m_levelHeight));

    return true;
}

bool CGame::write(FILE *tfile)
{
    auto writefile = [tfile](auto ptr, auto size)
    {
        return fwrite(ptr, size, 1, tfile) == 1;
    };

    // writing signature/version
    writefile(&GAME_SIGNATURE, sizeof(GAME_SIGNATURE));
    uint32_t version = VERSION;
    writefile(&version, sizeof(version));

    // ptr
    uint32_t indexPtr = 0;
    writefile(&indexPtr, sizeof(indexPtr));

    // general information
    m_script->write(tfile);

    writefile(&m_goals, sizeof(m_goals));
    writefile(&m_score, sizeof(m_score));
    writefile(&m_hp, sizeof(m_hp));
    writefile(&m_lives, sizeof(m_lives));
    writefile(&m_oxygen, sizeof(m_oxygen));
    writefile(&m_coins, sizeof(m_coins));
    writefile(&m_level, sizeof(m_level));
    writefile(&m_jumpFlag, sizeof(m_jumpFlag));
    writefile(&m_jumpSeq, sizeof(m_jumpSeq));
    writefile(&m_jumpIndex, sizeof(m_jumpIndex));
    writefile(&m_playerFrameOffset, sizeof(m_playerFrameOffset));
    writefile(&m_playerHitCountdown, sizeof(m_playerHitCountdown));
    writefile(&m_underwaterCounter, sizeof(m_underwaterCounter));
    writefile(&m_levelHeight, sizeof(m_levelHeight));

    return true;
}
