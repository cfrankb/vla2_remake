/*
    vlamits2-runtime-sdl
    Copyright (C) 2024  Francois Blanchette

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
#define SDL_MAIN_HANDLED
#include <SDL2/SDL.h>
#include "gamemixin.h"

#pragma once

class CGame;
class CFrame;
class CFrameSet;

class CRuntime : public CGameMixin
{
public:
    CRuntime();
    virtual ~CRuntime();

    void paint();
    void run();
    bool SDLInit();
    bool doInput();
    bool init(const char *filearch, const char *configfile, int startLevel = 0);

private:
    void keyReflector(SDL_Keycode key, uint8_t keyState);
    virtual bool read(FILE *sfile, std::string &name) override;
    virtual bool write(FILE *sfile, std::string &name) override;
    virtual void save() override;
    virtual void load() override;
    using App = struct
    {
        SDL_Renderer *renderer;
        SDL_Window *window;
        SDL_Texture *texture;
    };

    App m_app;
    virtual bool loadScores() override;
    virtual bool saveScores() override;
    static void cleanup();
};