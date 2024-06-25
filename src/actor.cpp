#include "actor.h"
#include "game.h"
#include <cstring>

CActor::CActor()
{
    clear();
}

CActor::~CActor()
{
}

bool CActor::canMove(int aim)
{
    return CGame::getGame()->canMove(*this, aim);
}

bool CActor::move(int aim)
{
    switch (aim)
    {
    case AIM_UP:
        --y;
        break;
    case AIM_DOWN:
        ++y;
        break;
    case AIM_LEFT:
        --x;
        break;
    case AIM_RIGHT:
        ++x;
        break;
    default:
        return false;
    }

    return true;
}

void CActor::debug() const
{
    printf("type %x x=%d y=%d imageId=%.4x\n", type, x, y, imageId);
}

void CActor::clear()
{
    memset(this, 0, sizeof(CActor));
}

bool CActor::isPlayerThere(int aim)
{
    return CGame::getGame()->isPlayerThere(*this, aim);
}

void CActor::attackPlayer() const
{
    return CGame::getGame()->attackPlayer(*this);
}

void CActor::killPlayer() const
{
    return CGame::getGame()->killPlayer(*this);
}

void CActor::flipDir()
{
    aim ^= 1;
}

bool CActor::canFall()
{
    return CGame::getGame()->canFall(*this);
}

int CActor::findNextDir()
{
    static uint8_t AIMS[] = {
        AIM_DOWN, AIM_RIGHT, AIM_UP, AIM_LEFT,
        AIM_UP, AIM_LEFT, AIM_DOWN, AIM_RIGHT,
        AIM_RIGHT, AIM_UP, AIM_LEFT, AIM_DOWN,
        AIM_LEFT, AIM_DOWN, AIM_RIGHT, AIM_UP};

    int i = TOTAL_AIMS - 1;
    while (i >= 0)
    {
        int newAim = AIMS[aim * TOTAL_AIMS + i];
        if (testAim(newAim))
        {
            return newAim;
        }
        --i;
    }
    return AIM_NONE;
}

bool CActor::testAim(int aim)
{
    return CGame::getGame()->testAim(*this, aim);
}

bool CActor::isFalling(int aim)
{
    return CGame::getGame()->isFalling(*this, aim);
}