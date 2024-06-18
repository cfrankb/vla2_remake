#include "actor.h"
#include "game.h"

CActor::CActor()
{
}

CActor::~CActor()
{
}

bool CActor::canMove(int aim)
{
    CGame *game = CGame::getGame();
    return game->canMove(*this, aim);
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