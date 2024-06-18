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
    uint8_t u1;
    uint8_t u2;
    uint16_t imageId;
    uint8_t x;
    uint8_t y;

    bool canMove(int aim);
    void move(int aim);

    friend class CGame;
};

#endif