/*
    vlamits2-runtime-sdl
    Copyright (C) 2024 Francois Blanchette

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
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

bool CActor::canMove(int aim) const
{
    return CGame::getGame()->canMove(*this, aim);
}

bool CActor::canLeap(int aim) const
{
    return CGame::getGame()->canLeap(*this, aim);
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
    printf("type %.2x x=%d y=%d u1=%.2x u2=%.2x imageId=%.4x\n", type, x, y, u1, u2, imageId);
}

void CActor::clear()
{
    memset(this, 0, sizeof(CActor));
}

bool CActor::isPlayerThere(int aim) const
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

bool CActor::canFall() const
{
    return CGame::getGame()->canFall(*this);
}

int CActor::findNextDir() const
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

bool CActor::testAim(int aim) const
{
    return CGame::getGame()->testAim(*this, aim);
}

bool CActor::isFalling(int aim) const
{
    return CGame::getGame()->isFalling(*this, aim);
}