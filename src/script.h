#ifndef __SCRIPT_H
#define __SCRIPT_H
#include <string>
#include <cstdint>
#include <cstdio>
#include "defs.h"

typedef struct
{
    uint8_t attr;
    uint8_t type; // objType
    uint8_t u1;
    uint8_t u2;
    uint16_t imageId;
    uint8_t x;
    uint8_t y;
} scriptEntry_t;

class CScript
{
public:
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
    int getSize();
    inline scriptEntry_t &operator[](int i)
    {
        return m_script[i];
    }
    static inline uint16_t toKey(const uint8_t x, const uint8_t y)
    {
        return x + (y << 8);
    }
    static inline bool isBackgroundType(uint8_t type)
    {
        return type == TYPE_BLANK || type >= TYPE_LADDER;
    }
    static inline bool isForegroundType(uint8_t type)
    {
        return type != TYPE_BLANK && type < TYPE_LADDER;
    }
    int add(const scriptEntry_t &entry);
    int insertAt(int i, const scriptEntry_t &entry);
    void removeAt(int i);
    inline scriptEntry_t &at(int i)
    {
        return (*this)[i];
    }

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