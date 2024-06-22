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
        BUTTON
    };

    uint8_t attr;
    uint8_t type; // objType
    union
    {
        uint8_t u1;
        uint8_t aim;
    };
    uint8_t u2;
    uint16_t imageId;
    uint8_t x;
    uint8_t y;

    bool canMove(int aim);
    bool isPlayerThere(int aim);
    bool move(int aim);
    void debug();
    void clear();
    void attackPlayer() const;
    void killPlayer() const;
    void flipDir();

    friend class CGame;
};

#endif