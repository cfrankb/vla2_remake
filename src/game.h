#ifndef __GAME_H
#define __GAME_H
#include <string>
#include <cstdint>
#include <unordered_map>
#include "struct.h"

class CFrameSet;
class CScript;
class CFrameMap;

class CGame
{
public:
    CGame();
    ~CGame();

    bool loadLevel(int i);
    const char *lastError();
    inline int mode()
    {
        return m_mode;
    }
    void setMode(int mode)
    {
        m_mode = mode;
    }

    enum
    {
        MODE_INTRO = 0,
        MODE_LEVEL = 1,
        MODE_RESTART = 2,
        MODE_GAMEOVER = 3,
    };

private:
    enum
    {
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
        HERE = 255,
        PLAYER_RECT = 2,
        FntTileSize = 8,

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

    bool loadTileset(const char *tileset);
    void mapScript(CScript *script);
    void splitScript();
    bool canMove(const scriptEntry_t &actor, int aim);
    inline uint32_t mapAt(int x, int y);
    inline void sizeFrame(const scriptEntry_t &entry, int &len, int &hei) const;
};

#endif