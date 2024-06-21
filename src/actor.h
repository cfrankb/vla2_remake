#ifndef __CACTOR_H
#define __CACTOR_H

#include <cstdint>

class CActor
{
public:
    CActor();
    ~CActor();

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
    bool move(int aim);
    void debug();
    void clear();

private:
    enum
    {
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
    };

    friend class CGame;
};

#endif