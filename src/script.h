#ifndef __SCRIPT_H
#define __SCRIPT_H
#include <string>
#include <cstdint>
#include <cstdio>
#include "defs.h"
#include "struct.h"

class CScript
{
public:
    enum
    {
        NOT_FOUND = -1
    };

    CScript();
    CScript(scriptEntry_t *script, uint32_t size);
    ~CScript();

    void forget();
    void copy(scriptEntry_t *script, int count);
    bool write(FILE *tfile);
    bool read(FILE *sfile);
    std::string name();
    void setName(const std::string &name);
    std::string tileset();
    void setTileSet(const std::string &tileset);
    inline int getSize() const
    {
        return m_size;
    }
    inline scriptEntry_t &operator[](int i)
    {
        return m_script[i];
    }
    static inline uint32_t toKey(const uint8_t x, const uint8_t y)
    {
        return x + (y << 16);
    }
    static inline bool isBackgroundType(const uint8_t type)
    {
        return type == TYPE_BLANK || type >= TYPE_LADDER;
    }
    static inline bool isForegroundType(const uint8_t type)
    {
        return type != TYPE_BLANK && type < TYPE_LADDER;
    }
    static inline bool isMonsterType(const uint8_t type)
    {
        return (type & TYPE_FILTER_GROUP) == TYPE_MONSTER_FILTER;
    }
    static inline bool isPlayerType(const uint8_t type)
    {
        return type == TYPE_PLAYER;
    }

    int add(const scriptEntry_t &entry);
    int insertAt(int i, const scriptEntry_t &entry);
    void removeAt(int i);
    inline scriptEntry_t &at(int i)
    {
        return (*this)[i];
    }
    int findPlayerIndex();
    int countType(uint8_t type);

private:
    std::string m_name;
    std::string m_tileset;
    scriptEntry_t *m_script;
    uint32_t m_size;
    uint32_t m_max;
    enum
    {
        TILESET_NAME_MAX = 8,
        SCRIPTNAME_MAX = 255,
        GROW_BY = 16
    };
    inline void growArray();
};

#endif