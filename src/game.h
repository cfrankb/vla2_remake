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
#pragma once

#include <string>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include "mapentry.h"
#include "actor.h"

class CFrameSet;
class CScript;
class CFrameMap;
class CFrame;
class CActor;

using StringVector = std::vector<std::string>;
using PairMap = std::unordered_map<uint16_t, uint16_t>;
using rect_t = struct
{
    uint16_t x;
    uint16_t y;
    int len;
    int hei;
};
class CGame
{
public:
    ~CGame();

    bool loadLevel(int i);
    const char *lastError();
    bool init(const char *archname, const char *configfile);
    int mode();
    void setMode(int mode);
    bool loadTileset(const char *tileset);
    static CGame *getGame();
    int playerSpeed();
    bool isPlayerDead();
    void managePlayer(const uint8_t *joyState);
    bool manageJump(const uint8_t *joyState);
    void manageMonsters(uint32_t ticks);
    void setLevel(const int i);
    int level();
    int lives();
    CActor *player();
    void setLives(const int val);
    int goals();
    int coins();
    int score();
    void startGame();
    void restartGame();
    void restartLevel();
    void nextLevel();
    void manageGravity();
    void animator(uint32_t ticks);
    uint32_t define(const char *name);
    inline int playerFrameOffset() { return m_playerFrameOffset; }
    CFrameSet *tiles();
    CScript *script();
    int hp();
    int oxygen();
    const std::unordered_set<uint16_t> &hideList();
    inline int playerHitCountdown() { return m_playerHitCountdown; }

    enum GameMode
    {
        MODE_INTRO = 0,
        MODE_LEVEL = 1,
        MODE_RESTART = 2,
        MODE_GAMEOVER = 3,
        MODE_CLICKSTART,
        MODE_HISCORES,
        MODE_IDLE,
        MODE_HELP,
    };

    enum
    {
        HERE = 255,
        PLAYER_MOVE_FRAMES = 7,
        PLAYER_RECT = 2,
        FNT_BLOCK_SIZE = 8,
        BASE_ENTRY = 1,
        MAX_POS = 255,
        NONE = 0,
        PLAYER_HIT_FRAME = 7,
        FONT_SIZE = 8,
        INVALID = -1,
        KILL_PLAYER = -1,
        BUTTON = 4,
        NOT_FOUND = 255,
        JUMP_SEQ_MAX = 14,
    };

private:
    CGame();

    enum // bonus points
    {
        _10pts,
        _15pts,
        _25pts,
        _50pts,
        _100pts,
        _200pts,
        _300pts,
        _400pts,
        _500pts,
        _1000pts,
        _2000pts,
        _5000pts,
        _10000pts,
        PointCount
    };

    static constexpr uint16_t m_pointValues[]{
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

    static constexpr const uint8_t AIMS[] = {
        CActor::AIM_UP,
        CActor::AIM_DOWN,
        CActor::AIM_LEFT,
        CActor::AIM_RIGHT};

    enum : int // game constants
    {
        NeedleDrain = 32,
        HpBonus = 4,
        LifeDrowning = 2,
        MaxOxygen = 256,
        OxygenAdd = 2,
        OxygenDrain = 1,
        OxygenBonus = 4,
        FishDrain = 10,
        PlantDrain = 4,
        VCreaDrain = 4,
        InMangaBite = -1,
        FleaDrain = 4,
        FleaFrameCycle = 2,
        speedCount = 9,
        FishFrameCycle = 1,
        InMangaFrameCycle = 2,
        VCreaFrameCycle = 0,
        CannibalFrameCycle = 3,
        CanmibalDamage = 16,
        PlayerHitDuration = 2,
        Coins4Life = 100,
        OxygenLostDelay = 10,
    };

    enum : uint8_t
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

    struct config_t
    {
        std::unordered_map<uint32_t, uint16_t> xdef;
        std::unordered_set<uint16_t> hide;
        std::unordered_set<uint16_t> xmap;
        PairMap swap;
    };

    struct type_t
    {
        uint8_t speed;
    };

    struct jumpSeq_t
    {
        const uint8_t seq[JUMP_SEQ_MAX];
        const uint8_t count;
        const uint8_t aim;
        template <typename... T>
        jumpSeq_t(const uint8_t _aim, T... _list) : seq{_list...}, aim{_aim}, count{sizeof...(T)}
        {
        }
    };

    CFrameSet *m_frameSet;
    std::string m_scriptArchName;
    uint32_t *m_scriptIndex;
    uint32_t m_scriptCount;
    CScript *m_script;
    CFrameMap *m_frameMap;
    std::string m_lastError;
    std::unordered_map<uint32_t, CMapEntry> m_map;
    std::unordered_map<uint32_t, type_t> m_types;
    std::unordered_map<std::string, uint32_t> m_defines;
    std::unordered_map<std::string, config_t> m_config;
    std::string m_loadedTileSet;
    int m_goals;
    int m_score;
    int m_hp;
    int m_lives;
    int m_oxygen;
    int m_coins;
    int m_level;
    int m_mode;
    bool m_jumpFlag;
    int m_jumpSeq;
    int m_jumpIndex;
    int m_jumpCooldown;
    int m_playerFrameOffset;
    int m_playerHitCountdown;
    int m_underwaterCounter;
    int m_levelHeight;
    CActor *m_player = nullptr;

    void mapScript(CScript *script);
    int findLevelHeight();
    bool mapEntry(int i, const CActor &actor, bool removed = false);
    bool unmapEntry(int i, const CActor &actor);
    bool canMove(const CActor &actor, int aim);
    bool canLeap(const CActor &actor, int aim);
    bool isPlayerThere(const CActor &actor, int aim);
    bool isFalling(const CActor &actor, int aim);
    bool canFall(const CActor &actor);
    bool testAim(const CActor &actor, int aim);
    bool isUnderwater(const CActor &actor);
    uint8_t *getActorMap(const CActor &actor);
    void consumeAll();
    bool consumeObject(uint16_t j);
    void handleTrigger(int j, CActor &entry);
    void handleRemove(int j, const CActor &entry);
    void handleChange(int j, const CActor &entry);
    void handleTeleport(int j, const CActor &entry);
    void addToScore(int score);
    inline CMapEntry &mapAt(int x, int y);
    inline void sizeFrame(const CActor &entry, int &len, int &hei) const;
    inline bool calcActorRect(const CActor &actor, int aim, rect_t &rect);
    void attackPlayer(const CActor &actor);
    void killPlayer(const CActor &actor);
    void killPlayer();
    void manageVamplant(int i, CActor &actor);
    void manageVCreatureVariant(int i, CActor &actor, const char *signcall, int frameCount);
    void manageFlyingPlatform(int i, CActor &actor);
    void manageDroneVariant(int i, CActor &actor, const char *signcall, int frameCount);
    void managePlayerOxygenControl();
    bool readConfig(const char *confName);
    char *parseLine(int &line, std::string &tileset, char *p);
    void parseGeneralOptions(const StringVector &list, int line);
    void parseTilesetOptions(std::string tileset, const StringVector &list, int line);
    void splitString(const std::string &str, StringVector &list);
    uint16_t xdefine(const char *sig);

    friend class CActor;
};
