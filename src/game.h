#ifndef __GAME_H
#define __GAME_H
#include <string>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include "mapentry.h"

class CFrameSet;
class CScript;
class CFrameMap;
class CFrame;
class CActor;

typedef std::vector<std::string> StringVector;
typedef std::unordered_map<uint16_t, uint16_t> PairMap;

class CGame
{
public:
    ~CGame();

    bool loadLevel(int i);
    const char *lastError();
    bool init(const char *archname, const char *configfile);
    int mode();
    void setMode(int mode);
    void drawScreen(CFrame &screen);
    static CGame *getGame();
    int playerSpeed();
    bool isPlayerDead();
    void managePlayer(const uint8_t *joyState);
    bool manageJump(const uint8_t *joyState);
    void preloadAssets();
    void manageMonsters(uint32_t ticks);
    void debugFrameMap(const char *outFile);
    void debugLevel(const char *filename);
    void setLevel(int i);
    int level();
    int lives();
    int goals();
    void drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color);
    void startGame();
    void restartGame();
    void restartLevel();
    void nextLevel();
    void manageGravity();
    void animator(uint32_t ticks);
    uint32_t define(const char *name);

    enum
    {
        MODE_INTRO = 0,
        MODE_LEVEL = 1,
        MODE_RESTART = 2,
        MODE_GAMEOVER = 3,
        BLACK = 0xff000000,
        WHITE = 0xffffffff,
        PINK = 0xffd187e8,
        YELLOW = 0xff34ebeb,
        GREEN = 0xff009000,
        LIME = 0xff00ffbf,
        LIGHTGRAY = 0xffd3d3d3,
        BLUE = 0xffff901e,
    };

private:
    CGame();
    enum
    {
        HERE = 255,
        PLAYER_RECT = 2,
        fntBlockSize = 8,
        BASE_ENTRY = 1,
        MAX_POS = 255,
        NONE = 0,
        PLAYER_FRAME_CYCLE = 8,
        PLAYER_MOVE_FRAMES = 7,
        PLAYER_HIT_FRAME = 7,
        fontSize = 8,
        INVALID = -1,
        KILL_PLAYER = -1,
        BUTTON = 4,
        NOT_FOUND = 255
    };

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
    };

    enum // game constants
    {
        NeedleDrain = 32,
        HpBonus = 4,
        LifeDrowning = 2,
        MaxOxygen = 256,
        OxygenAdd = 2,
        OxygenDrain = 1,
        OxygenBonus = 4,
        FishDrain = 20,
        PlantDrain = 4,
        VCreaDrain = 4,
        InMangaBite = -1,
        FleaDrain = 4,
        speedCount = 9,
        FishFrameCycle = 1,
        InMangaFrameCycle = 2,
        CanmibalDamage = 16,
        PlayerHitDuration = 2,
        HealthBarHeight = 8,
        HealthBarOffset = 4,
        Coins4Life = 100,
        OxygenLostDelay = 10,
    };
    typedef struct
    {
        uint16_t x;
        uint16_t y;
        int len;
        int hei;
    } rect_t;

    typedef struct
    {
        std::unordered_map<uint32_t, uint16_t> xdef;
        std::unordered_set<uint16_t> hide;
        std::unordered_set<uint16_t> xmap;
        PairMap swap;
    } config_t;

    typedef struct
    {
        uint8_t speed;
    } type_t;

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
    CActor *m_player;
    uint8_t *m_fontData;
    CFrameSet *m_annie;
    CFrameSet *m_points;
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

    bool loadTileset(const char *tileset);
    void mapScript(CScript *script);
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
    void handleRemove(int j, CActor &entry);
    void handleChange(int j, CActor &entry);
    void handleTeleport(int j, CActor &entry);
    void addToScore(int score);
    inline CMapEntry &mapAt(int x, int y);
    inline void sizeFrame(const CActor &entry, int &len, int &hei) const;
    inline bool calcActorRect(const CActor &actor, int aim, CGame::rect_t &rect);
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
    void splitString(const std::string str, StringVector &list);
    void drawRect(CFrame &frame, const rect_t &rect, const uint32_t color, bool fill);
    uint16_t xdefine(const char *sig);

    friend class CActor;
};

#endif