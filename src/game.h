#ifndef __GAME_H
#define __GAME_H
#include <string>
#include <cstdint>
#include <unordered_map>
#include "mapentry.h"

class CFrameSet;
class CScript;
class CFrameMap;
class CFrame;
class CActor;

class CGame
{
public:
    ~CGame();

    bool loadLevel(int i);
    const char *lastError();
    bool init(const char *archname);
    int mode();
    void setMode(int mode);
    void drawScreen(CFrame &screen);
    static CGame *getGame();
    int playerSpeed();
    bool isPlayerDead();
    void managePlayer(uint8_t *joyState);
    void preloadAssets();
    void manageMonsters();
    void debugFrameMap();

    enum
    {
        MODE_INTRO = 0,
        MODE_LEVEL = 1,
        MODE_RESTART = 2,
        MODE_GAMEOVER = 3,
        DEFAULT_PLAYER_SPEED = 4,
    };

protected:
    CGame();

private:
    enum
    {
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
        HERE = 255,
        PLAYER_RECT = 2,
        fntBlockSize = 8,
        BASE_ENTRY = 1,
        MAX_POS = 255,
        NONE = 0,
        PLAYER_FRAME = 8,
        fontSize = 8,
        INVALID = -1
    };

    enum
    {
        BLACK = 0xff000000,
        WHITE = 0xffffffff,
        PINK = 0xffd187e8,
        YELLOW = 0xff34ebeb,
        GREEN = 0xff009000
    };

    enum
    {
        _10pts,
        _15pts,
        _25pts,
        _50pts,
        _100pts,
        _200pts,
        _400pts,
        _500pts,
        _1000pts,
        _5000pts,
        _10000pts,
        _50000pts
    };

    enum
    {
        DefaultLives = 5,
        NeedleDrain = 32,
        MaxOxygen = 256,
        DefaultHp = 128,
        HpBonus = 4,
        MaxHP = 8192,
        OxygenBonus = 4,
    };
    typedef struct
    {
        uint16_t x;
        uint16_t y;
        int len;
        int hei;
    } rect_t;

    CFrameSet *m_frameSet;
    std::string m_scriptArchName;
    uint32_t *m_scriptIndex;
    uint32_t m_scriptCount;
    CScript *m_script;
    CFrameMap *m_frameMap;
    bool m_valid;
    std::string m_lastError;
    std::unordered_map<uint32_t, CMapEntry> m_map;
    int m_mode;
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

    bool loadTileset(const char *tileset);
    void mapScript(CScript *script);
    bool mapEntry(int i, const CActor &actor, bool removed);
    bool canMove(const CActor &actor, int aim);
    bool isPlayerThere(const CActor &actor, int aim);
    void consumeAll();
    bool consumeObject(uint16_t j);
    void addToScore(int score);
    inline CMapEntry &mapAt(int x, int y);
    inline void sizeFrame(const CActor &entry, int &len, int &hei) const;
    inline bool calcActorRect(const CActor &actor, int aim, CGame::rect_t &rect);
    void drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color);
    void manageFish(int i, CActor &actor);

    friend class CActor;
};

#endif