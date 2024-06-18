#ifndef __GAME_H
#define __GAME_H
#include <string>
#include <cstdint>
#include <unordered_map>

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
    void drawScreen(CFrame &screen, CFrame *annie);
    static CGame *getGame();

    int playerSpeed();
    bool isPlayerDead();
    void managePlayer(uint8_t *joyState);

    enum
    {
        MODE_INTRO = 0,
        MODE_LEVEL = 1,
        MODE_RESTART = 2,
        MODE_GAMEOVER = 3,
        DEFAULT_PLAYER_SPEED = 4
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
        MAX_POS = 255
    };

    CFrameSet *m_frameSet;
    std::string m_scriptArchName;
    uint32_t *m_scriptIndex;
    uint32_t m_scriptCount;
    CScript *m_script;
    CFrameMap *m_frameMap;
    bool m_valid;
    std::string m_lastError;
    std::unordered_map<uint32_t, uint32_t> m_map;
    int m_mode;
    std::string m_loadedTileSet;
    CActor *m_player;

    bool loadTileset(const char *tileset);
    void mapScript(CScript *script);
    void splitScript();
    bool canMove(const CActor &actor, int aim);
    inline uint32_t mapAt(int x, int y);
    inline void sizeFrame(const CActor &entry, int &len, int &hei) const;

    friend class CActor;
};

#endif