#ifndef __FRAMEMAP_H
#define __FRAMEMAP_H

#include <cstdint>

class CFrameSet;
class CFrame;

class CFrameMap
{
public:
    CFrameMap();
    ~CFrameMap();

    bool write(const char *filename);
    bool read(const char *filename);

    void fromFrameSet(CFrameSet &frameSet);
    uint8_t *mapPtr(int i);
    uint8_t *operator[](int i);

private:
    enum
    {
        fntTileSize = 8,
        threshold = 16
    };
    uint8_t **m_mapIndex;
    uint8_t *m_mapData;
    int m_dataSize;

    int scoreFromTile(CFrame &frame, int baseX, int baseY);
    void forget();
};

#endif