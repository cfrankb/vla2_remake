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
#include "debug.h"
#include "game.h"
#include <unistd.h>
#include <stdio.h>
#include "runtime.h"
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

constexpr int FPS = 30;
constexpr const char MAPARCH_FILE[] = "data/levels.scrx";
constexpr const char CONFIG_FILE[] = "data/vlamits2.cfg";

bool g_exitRequested = false;

void loop_handler(void *arg)
{
    CRuntime *runtime = reinterpret_cast<CRuntime *>(arg);
    usleep(1000 / FPS * 1000);
    g_exitRequested = !runtime->doInput();
    runtime->paint();
    runtime->run();
}

int main(int argc, char *args[])
{
    int startLevel = argc > 1 ? atoi(args[1]) : 0;
    CRuntime runtime;
    runtime.init(MAPARCH_FILE, CONFIG_FILE, startLevel);
    runtime.SDLInit();
    runtime.paint();
#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop_arg(loop_handler, &runtime, -1, 1);
#else
    while (true)
    {
        loop_handler(&runtime);
        if (g_exitRequested)
        {
            break;
        }
    }
#endif
    return 0;
}