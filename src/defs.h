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
#pragma once

// types

#define TYPE_BLANK 0x0
#define TYPE_PLAYER 0x1
#define TYPE_OXYGEN 0x3
#define TYPE_TRANSPORTER 0x4
#define TYPE_DIAMOND 0x10
#define TYPE_FLOWER 0x11
#define TYPE_FRUIT 0x12
#define TYPE_MUSHROOM 0x13
#define TYPE_MISC 0x14
#define TYPE_DEADLYITEM 0x15

#define TYPE_POINTS 0x8e
#define TYPE_EMPTY 0x8f

#define TYPE_FISH 0xc0
#define TYPE_VCREA 0xc1
#define TYPE_VAMPIREPLANT 0xc2
#define TYPE_FLYPLAT 0xc3
#define TYPE_SPIDER 0xc4
#define TYPE_CANNIBAL 0xc5
#define TYPE_INMANGA 0xc6
#define TYPE_GREENFLEA 0xcf

#define TYPE_LADDER 0xd0
#define TYPE_TREE 0xd1
#define TYPE_BRIDGE 0xd2
#define TYPE_LADDERDING 0xd3
#define TYPE_SAND 0xdd
#define TYPE_TOPWATER 0xde
#define TYPE_BOTTOMWATER 0xdf
#define TYPE_OBSTACLECLASS 0xe0
#define TYPE_STOPCLASS 0xf0
#define TYPE_LAVA 0xff

// filters

#define TYPE_OBJECT_SUBGROUP 0x1f
#define TYPE_FILTER_GROUP 0xf0
#define TYPE_MONSTER_FILTER 0xc0

// tasks

#define TASK_NONE 0
#define TASK_REMOVE 1
#define TASK_SOURCE 2
#define TASK_DEST 3
#define TASK_CHANGE 4
#define TASK_MESSAGER 5
