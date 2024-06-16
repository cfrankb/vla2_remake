#ifndef __IMSWRAP_H
#define __IMSWRAP_H

#include <cstdint>
#include <string>

class CFrameSet;
class CFrame;

class CImsWrap
{
public:
    CImsWrap();
    ~CImsWrap();

    bool readIMS(const char *imsFilename);
    bool readSCR(const char *scrFilename);
    bool readSTO(const char *stoFilename);
    void toFrameSet(CFrameSet &frameSet, FILE *mapFile);
    void drawScreen(CFrame &screen, CFrameSet &frameSet);
    void debug(const char *filename);
    const char *stoName();

protected:
    typedef struct
    {
        uint8_t pixels[64];
    } fntEntry_t;

    typedef struct
    {
        uint8_t task;
        uint8_t objtype;
        uint16_t imageID;
    } stoEntry_t;

    typedef struct
    {
        uint16_t offsetNext;
        uint16_t len;
        uint16_t hei;
        uint16_t fntData;
    } imsEntry_t;

    typedef struct
    {
        imsEntry_t *ptrEntry;
        std::string name;
    } imsLookup_t;

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

    typedef struct
    {
        uint8_t red;
        uint8_t green;
        uint8_t blue;
        uint8_t alpha;
    } rgba_t;

    enum
    {
        IMSNAME_MAX = 8192,
        fntBlockSize = 8
    };

    int getImageCount(uint8_t *imsTable);
    void createImsIndex(uint8_t *imsTable, imsEntry_t **imsIndex);
    void createImsIndex(uint8_t *imsTable, char *imsNames, imsLookup_t *imsIndex);
    void freeIms();
    void freeScr();
    void freeSto();
    inline const char *getTypeName(int typeId);
    inline const char *getImageName(int imageID);
    inline const rgba_t &getPaletteColor(int i);

    std::string m_stoName;
    std::string m_imsName;
    int m_tiles;
    int m_imgCount;
    int m_imsTableLenght;
    int m_entryCount;
    int m_stoEntries;
    fntEntry_t *m_tileData;
    imsLookup_t *m_imsLookup;
    scriptEntry_t *m_script;
    stoEntry_t *m_stoData;
    uint8_t *m_imsTable;
};

#endif