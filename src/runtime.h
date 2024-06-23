/*
    cs3-runtime-sdl
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
#include <SDL2/SDL.h>

class CGame;
class CFrame;
class CFrameSet;

class CRuntime
{
public:
    CRuntime();
    virtual ~CRuntime();

    void paint();
    void run();
    bool SDLInit();
    void doInput();
    bool init(const char *filearch, int startLevel = 0);

private:
    enum
    {
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
        BUTTON,
        JOY_STATES = 8,
        WIDTH = 320,
        HEIGHT = 240,
        KEY_PRESSED = 1,
        KEY_RELEASED = 0,
        FONT_SIZE = 8,
    };

    typedef struct
    {
        SDL_Renderer *renderer;
        SDL_Window *window;
        SDL_Texture *texture;
    } App;

    App m_app;
    CGame *m_game;
    uint8_t m_joyState[JOY_STATES];

    bool m_assetPreloaded;
    uint32_t m_ticks;
    uint32_t m_countdown;

    static void cleanup();
    void drawLevelIntro(CFrame &screen);
    void drawScreen(CFrame &screen);
    void mainLoop();
};