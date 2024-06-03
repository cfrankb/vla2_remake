#include <cstdio>
#include <cstdint>
#include <cctype>
#include <cstring>
#include <string>

#include "imswrap.h"
#include "shared/FrameSet.h"
#include "shared/Frame.h"
#include "shared/FileWrap.h"

typedef struct
{
    const char *imsFile;
    const char *scrFile;
    const char *name;
} filedef_t;

const filedef_t filedefs[] = {
    //   {"intro.ims", "_lev00.scr", "il est temps de partir."},
    {"jungle.ims", "_lev01.scr", "et voila que commence ton aventure_"},
    {"jungle.ims", "_lev02.scr", "attention de ne pas tomber!"},
    {"jungle.ims", "_lev03.scr", "les fruits du diable_"},
    {"jungle.ims", "_lev04.scr", "la mort te guete."},
    {"jungle.ims", "_lev05.scr", "mechant! mechant!"},
    {"jungle.ims", "_lev06.scr", "jargons divers!"},
    {"jungle.ims", "_lev07.scr", "arachides fumees!"},
    {"jungle.ims", "_lev08.scr", "le nouveau_"},
    {"ocean.ims", "_lev09.scr", "la transition_"},
    {"ocean.ims", "_lev10.scr", "au milieu de la mer_"},
    {"ocean.ims", "_lev11.scr", "bla bla bla!"},
    {"ocean.ims", "_lev12.scr", "solution salee_"},
    {"ocean.ims", "_lev13.scr", "***solution salee_"},
    {"caves.ims", "_lev20.scr", "sentier mortel."},
    {"caves.ims", "_lev21.scr", "le grand gouffre_"},
    {"caves.ims", "_lev22.scr", "***le grand gouffre_"},
    {"oldvla.ims", "_leva0.scr", "tu vas reconnaitre!"},
    {"oldvla.ims", "_leva3.scr", "raison passion."},
    {"oldvla.ims", "_leva2.scr", "amionoux truc"},
    {"oldvla.ims", "_leva1.scr", "le grand complexe_"},
    {"oldvla.ims", "_leva4.scr", "zoomy zoom zoom!"},
    {"oldvla.ims", "_leva6.scr", "whoops!"},
    {"oldvla.ims", "_leva7.scr", "***whoops!"},
};

void exportIms()
{
    CImsWrap ims;
    CFileWrap file;
    CFrameSet frameSet;
    std::string tilesets[] = {
        "jungle",
        "ocean",
        "caves",
        "oldvla"};

    for (int i = 0; i < 4; ++i)
    {
        std::string oblFile = "out/" + tilesets[i] + ".obl";
        std::string imsFile = "data/" + tilesets[i] + ".ims";
        std::string mapFile = "out/" + tilesets[i] + ".map";
        if (file.open(oblFile.c_str(), "wb"))
        {
            ims.readIMS(imsFile.c_str());
            FILE *tfileMap = fopen(mapFile.c_str(), "wb");
            ims.toFrameSet(frameSet, tfileMap);
            frameSet.write(file);
            file.close();
            fclose(tfileMap);
            printf("%s -> %d images\n", oblFile.c_str(), frameSet.getSize());
        }
    }
}

void debugScr()
{
    CImsWrap ims;
    size_t count = sizeof(filedefs) / sizeof(filedef_t);
    for (size_t i = 0; i < count; ++i)
    {
        const filedef_t &def = filedefs[i];
        const std::string scrName = std::string("data/") + def.scrFile;
        ims.readSCR(scrName.c_str());
        printf("%s %s %s\n", def.scrFile, def.imsFile, ims.stoName());
    }
}

bool compositeLevel(std::string imsFile, std::string scrFile, std::string outFile)
{
    CImsWrap ims;
    if (!ims.readIMS(imsFile.c_str()))
    {
        printf("readims %s failed\n", imsFile.c_str());
        return true;
    }
    if (!ims.readSCR(scrFile.c_str()))
    {
        printf("readscr %s failed\n", scrFile.c_str());
        return true;
    }
    CFrameSet frameSet;
    // CFrame screen = CFrame(320, 240);
    CFrame screen = CFrame(1024, 1024);
    ims.toFrameSet(frameSet, nullptr);
    ims.drawScreen(screen, frameSet);
    CFileWrap file;
    if (file.open(outFile.c_str(), "wb"))
    {
        uint8_t *png = nullptr;
        int size;
        screen.toPng(png, size);
        file.write(png, size);
        file.close();
        delete[] png;
    }

    return true;
}

void compositeAll()
{
    size_t count = sizeof(filedefs) / sizeof(filedef_t);
    for (size_t i = 0; i < count; ++i)
    {
        const filedef_t &def = filedefs[i];
        const std::string scrFile = std::string("data/") + def.scrFile;
        const std::string imsFile = std::string("data/") + def.imsFile;
        char pngName[16];
        strcpy(pngName, def.scrFile);
        char *p = strstr(pngName, ".");
        if (p)
        {
            strcpy(p, ".png");
        }
        else
        {
            strcat(pngName, ".png");
        }
        const std::string outFile = std::string("out/") + pngName;
        compositeLevel(imsFile.c_str(), scrFile.c_str(), outFile.c_str());
    }
}

int main(int argc, char *args[])
{
    /*
        ims.readIMS("data/jungle.ims");
        ims.readSCR("data/_lev01.scr");
        ims.debug("jungle1.txt");
        */

    // exportIms();
    compositeAll();
}
