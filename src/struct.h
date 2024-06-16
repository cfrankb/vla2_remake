#ifndef __STRUCT_H
#define __STRUCT_H
#include <cstdint>

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

#endif