#include <cstdio>
#include <cstdint>
#include <cctype>
#include <cstring>
#include <string>

#include "imswrap.h"

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

int main(int argc, char *args[])
{
    CImsWrap ims;
    //  ims.readIMS("data/caves.ims");
    // ims.readSCR("data/_lev21.scr");

    /*
        ims.readIMS("data/jungle.ims");
        ims.readSCR("data/_lev01.scr");
        ims.debug("jungle1.txt");
        */

    size_t count = sizeof(filedefs) / sizeof(filedef_t);
    for (size_t i = 0; i < count; ++i)
    {
        const filedef_t &def = filedefs[i];
        const std::string scrName = std::string("data/") + def.scrFile;
        ims.readSCR(scrName.c_str());
        printf("%s %s %s\n", def.scrFile, def.imsFile, ims.stoName());
    }
}
