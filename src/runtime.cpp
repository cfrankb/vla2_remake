/*
    vlamits-runtime-sdl
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
#include "runtime.h"
#include "game.h"
#include "shared/Frame.h"
#include "shared/FrameSet.h"
#include <cstring>
#include "shared/FileWrap.h"

#define WINDOW_TITLE "The Vlamits2 Runtime"
#define IntroCountdown "IntroCountdown"
#define JumpSpeed "JumpSpeed"
#define Gravity "Gravity"
#define Animator "Animator"

CRuntime::CRuntime()
{
    memset(&m_app, 0, sizeof(App));
    m_game = CGame::getGame();
    m_assetPreloaded = false;
    m_ticks = 0;
    memset(m_joyState, 0, sizeof(m_joyState));
}

CRuntime::~CRuntime()
{
    SDL_DestroyTexture(m_app.texture);
    SDL_DestroyRenderer(m_app.renderer);
    SDL_DestroyWindow(m_app.window);
    SDL_Quit();

    if (m_game)
    {
        delete m_game;
    }
}

void CRuntime::paint()
{
    CFrame bitmap(WIDTH, HEIGHT);

    switch (m_game->mode())
    {
    case CGame::MODE_INTRO:
    case CGame::MODE_RESTART:
    case CGame::MODE_GAMEOVER:
        drawLevelIntro(bitmap);
        break;
    case CGame::MODE_LEVEL:
        drawScreen(bitmap);
    }

    SDL_UpdateTexture(m_app.texture, NULL, bitmap.getRGB(), WIDTH * sizeof(uint32_t));
    // SDL_RenderClear(m_app.renderer);
    SDL_RenderCopy(m_app.renderer, m_app.texture, NULL, NULL);
    SDL_RenderPresent(m_app.renderer);
}

bool CRuntime::SDLInit()
{
    int rendererFlags = SDL_RENDERER_ACCELERATED;
    int windowFlags = SDL_WINDOW_SHOWN;
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
        return false;
    }
    else
    {
        m_app.window = SDL_CreateWindow(
            WINDOW_TITLE,
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 2 * WIDTH, 2 * HEIGHT, windowFlags);
        if (m_app.window == NULL)
        {
            printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
            return false;
        }
        else
        {
            atexit(cleanup);
            //            SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
            m_app.renderer = SDL_CreateRenderer(m_app.window, -1, rendererFlags);
            if (m_app.renderer == nullptr)
            {
                printf("Failed to create renderer: %s\n", SDL_GetError());
                return false;
            }

            m_app.texture = SDL_CreateTexture(
                m_app.renderer,
                SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STATIC, WIDTH, HEIGHT);
            if (m_app.texture == nullptr)
            {
                printf("Failed to create texture: %s\n", SDL_GetError());
                return false;
            }
        }
    }
    return true;
}

void CRuntime::cleanup()
{
}

void CRuntime::run()
{
    mainLoop();
}

void CRuntime::doInput()
{
    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        case SDL_KEYUP:
            switch (event.key.keysym.sym)
            {
            case SDLK_UP:
                m_joyState[AIM_UP] = KEY_RELEASED;
                break;
            case SDLK_DOWN:
                m_joyState[AIM_DOWN] = KEY_RELEASED;
                break;
            case SDLK_LEFT:
                m_joyState[AIM_LEFT] = KEY_RELEASED;
                break;
            case SDLK_RIGHT:
                m_joyState[AIM_RIGHT] = KEY_RELEASED;
                break;
            case SDLK_LSHIFT:
                m_joyState[BUTTON] = KEY_RELEASED;
                break;
            default:
                break;
            }
            break;

        case SDL_KEYDOWN:
            switch (event.key.keysym.sym)
            {
            case SDLK_UP:
                m_joyState[AIM_UP] = KEY_PRESSED;
                break;
            case SDLK_DOWN:
                m_joyState[AIM_DOWN] = KEY_PRESSED;
                break;
            case SDLK_LEFT:
                m_joyState[AIM_LEFT] = KEY_PRESSED;
                break;
            case SDLK_RIGHT:
                m_joyState[AIM_RIGHT] = KEY_PRESSED;
                break;
            case SDLK_HOME:
                m_game->nextLevel();
                break;
            case SDLK_LSHIFT:
                m_joyState[BUTTON] = KEY_PRESSED;
                break;
            default:
                break;
            }
            break;

        case SDL_WINDOWEVENT:
            if (event.window.event == SDL_WINDOWEVENT_RESIZED)
            {
                SDL_SetWindowSize(m_app.window, event.window.data1, event.window.data2);
            }
            break;

        case SDL_QUIT:
#ifdef WASM
            //           emscripten_cancel_main_loop();
#endif
            exit(0);
            break;

        default:
            break;
        }
    }
}

void CRuntime::drawLevelIntro(CFrame &screen)
{
    char t[32];
    switch (m_game->mode())
    {
    case CGame::MODE_INTRO:
        sprintf(t, "LEVEL %.2d", m_game->level() + 1);
        break;
    case CGame::MODE_RESTART:
        sprintf(t, "LIVES LEFT %.2d", m_game->lives());
        break;
    case CGame::MODE_GAMEOVER:
        strcpy(t, "GAME OVER");
    };

    int x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
    int y = (HEIGHT - FONT_SIZE) / 2;
    screen.fill(CGame::BLACK);
    CGame::getGame()->drawText(screen, x, y, t, CGame::WHITE);
}

void CRuntime::drawScreen(CFrame &screen)
{
    m_game->drawScreen(screen);
}

void CRuntime::mainLoop()
{
    CGame &game = *CGame::getGame();
    if (m_countdown > 0)
    {
        --m_countdown;
    }

    switch (game.mode())
    {
    case CGame::MODE_INTRO:
    case CGame::MODE_RESTART:
    case CGame::MODE_GAMEOVER:
        if (m_countdown)
        {
            return;
        }
        if (game.mode() == CGame::MODE_GAMEOVER)
        {
            m_countdown = game.define(IntroCountdown);
            game.restartGame();
        }
        else
        {
            game.setMode(CGame::MODE_LEVEL);
        }
        break;
    }

    game.manageMonsters(m_ticks);

    if (m_ticks % game.define(Gravity) == 0)
    {
        game.manageGravity();
    }

    if (m_ticks % game.define(Animator) == 0)
    {
        game.animator(m_ticks);
    }

    if (game.isPlayerDead())
    {
        m_countdown = game.define(IntroCountdown);
        game.restartLevel();
        if (game.lives() == 0)
        {
            game.setMode(CGame::MODE_GAMEOVER);
        }
    }
    else
    {
        if (m_ticks % game.playerSpeed() == 0)
        {
            game.managePlayer(m_joyState);
        }

        if (m_ticks % game.define(JumpSpeed) == 0)
        {
            game.manageJump(m_joyState);
        }

        if (game.goals() == 0)
        {
            m_countdown = game.define(IntroCountdown);
            game.nextLevel();
        }
    }

    ++m_ticks;
}

bool CRuntime::init(const char *filearch, const char *configfile, int startLevel)
{
    if (!m_assetPreloaded)
    {
        m_game->preloadAssets();
        m_assetPreloaded = true;
    }

    m_game->setMode(CGame::MODE_INTRO);
    m_game->setLevel(startLevel);
    bool result = m_game->init(filearch, configfile);
    if (result)
    {
        int level = m_game->level();
        m_game->loadLevel(level);
    }
    m_game->startGame();
    m_countdown = m_game->define(IntroCountdown);

    return result;
}
