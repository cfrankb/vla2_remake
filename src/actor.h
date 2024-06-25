#ifndef __CACTOR_H
#define __CACTOR_H

#include <cstdint>

class CActor
{
public:
    CActor();
    ~CActor();

    enum
    {
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
        BUTTON,
        TOTAL_AIMS = 4,
        AIM_NONE = 255
    };

    union
    {
        uint8_t attr;
        uint8_t task;
    };
    uint8_t type; // objType
    union
    {
        uint8_t u1;
        uint8_t aim;
        uint8_t triggerKey; // ???
    };
    union
    {
        uint8_t u2;
        uint8_t changeTo;
        uint8_t seqOffset;
    };

    uint16_t imageId;
    uint8_t x;
    uint8_t y;

    bool canMove(int aim);
    bool isPlayerThere(int aim);
    bool move(int aim);
    bool canFall();
    void debug() const;
    void clear();
    void attackPlayer() const;
    void killPlayer() const;
    void flipDir();
    int findNextDir();
    bool testAim(int aim);
    bool isFalling(int aim);

    friend class CGame;
};

#endif