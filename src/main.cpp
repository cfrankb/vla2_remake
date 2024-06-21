#include "debug.h"
#include "game.h"
#include <unistd.h>
#include <stdio.h>
#include "runtime.h"
#ifdef WASM
#include <emscripten.h>
#endif

#define FPS 24
#define MAPARCH_FILE "data/levels.scrx"

void loop_handler(void *arg)
{
    CRuntime *runtime = reinterpret_cast<CRuntime *>(arg);
    usleep(1000 / FPS * 1000);
    runtime->doInput();
    runtime->paint();
    runtime->run();
}

int main(int argc, char *args[])
{
    for (int i = 0; i < argc; ++i)
    {
        printf("%d %s\n", i, args[i]);
    }
    int startLevel = argc > 1 ? atoi(args[1]) : 0;
    CRuntime runtime;
    runtime.init(MAPARCH_FILE, startLevel);
    runtime.SDLInit();
    runtime.paint();
#ifdef WASM
    emscripten_set_main_loop_arg(loop_handler, &runtime, -1, 1);
#else
    while (true)
    {
        loop_handler(&runtime);
    }
#endif
    return 0;
}