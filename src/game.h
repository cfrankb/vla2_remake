#ifndef __GAME_H
#define __GAME_H
#include <string>
#include <cstdint>
#include <unordered_map>

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

private:
    CFrameSet *m_frameSet;
    std::string m_scriptArchName;
    uint32_t *m_scriptIndex;
    uint32_t m_scriptCount;
    CScript *m_script;
    CFrameMap *m_frameMap;
    bool m_valid;
    std::string m_lastError;
    std::unordered_map<uint32_t, uint32_t> m_map;

    bool loadTileset(const char *tileset);
    void mapScript(CScript *script);
};

#endif