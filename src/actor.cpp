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

void CActor::debug()
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
