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
#include "gamemixin.h"
#include <cstring>
#include <string.h>
#include "script.h"
#include "shared/Frame.h"
#include "shared/FrameSet.h"
#include "defs.h"
#include "shared/FileWrap.h"

constexpr const char IntroCountdown[] = "IntroCountdown";
constexpr const char JumpSpeed[] = "JumpSpeed";
constexpr const char Gravity[] = "Gravity";
constexpr const char Animator[] = "Animator";

CGameMixin::CGameMixin()
{
    printf("CGameMixin()\n");
    m_game = CGame::getGame();
    m_assetPreloaded = false;
    m_ticks = 0;
    clearJoyStates();
    clearScores();
    clearKeyStates();
    enableHiScore();
    m_annie = nullptr;
    m_points = nullptr;
}

CGameMixin::~CGameMixin()
{
    if (m_annie)
    {
        delete m_annie;
    }

    if (m_points)
    {
        delete m_points;
    }

    if (m_fontData)
    {
        delete[] m_fontData;
    }
}

int CGameMixin::rankScore()
{
    int score = m_game->score();
    if (score <= m_hiscores[MAX_SCORES - 1].score)
    {
        return INVALID;
    }

    uint32_t i;
    for (i = 0; i < MAX_SCORES; ++i)
    {
        if (score > m_hiscores[i].score)
        {
            break;
        }
    }

    for (uint32_t j = MAX_SCORES - 2; j >= i; --j)
    {
        m_hiscores[j + 1] = m_hiscores[j];
    }

    m_hiscores[i].score = m_game->score();
    m_hiscores[i].level = m_game->level() + 1;
    memset(m_hiscores[i].name, 0, sizeof(m_hiscores[i].name));
    return i;
}

void CGameMixin::drawScores(CFrame &bitmap)
{
    bitmap.fill(BLACK);
    char t[50];
    int y = 1;
    strcpy(t, "HALL OF HEROES");
    int x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
    drawText(bitmap, x, y * FONT_SIZE, t, WHITE);
    ++y;
    strcpy(t, std::string(strlen(t), '=').c_str());
    x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
    drawText(bitmap, x, y * FONT_SIZE, t, WHITE);
    y += 2;

    for (uint32_t i = 0; i < MAX_SCORES; ++i)
    {
        uint32_t color = i & INTERLINES ? CYAN : BLUE;
        if (m_recordScore && m_scoreRank == i)
        {
            color = YELLOW;
        }
        bool showCaret = (color == YELLOW) && (m_ticks & CARET_SPEED);
        sprintf(t, " %.8d %.2d %s%c",
                m_hiscores[i].score,
                m_hiscores[i].level,
                m_hiscores[i].name,
                showCaret ? CARET : '\0');
        drawText(bitmap, 1, y * FONT_SIZE, t, color);
        ++y;
    }

    ++y;
    if (m_scoreRank == INVALID)
    {
        strcpy(t, " SORRY, YOU DIDN'T QUALIFY.");
        drawText(bitmap, 0, y * FONT_SIZE, t, YELLOW);
    }
    else if (m_recordScore)
    {
        strcpy(t, "PLEASE TYPE YOUR NAME AND PRESS ENTER.");
        x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
        drawText(bitmap, x, y++ * FONT_SIZE, t, YELLOW);
    }
}

void CGameMixin::drawHelpScreen(CFrame &bitmap)
{
    bitmap.fill(BLACK);
    const char *helptext[]{
        "",
        "!HELP",
        "!====",
        "",
        "Use cursor keys to move.",
        "Hold SPACE/SHIFT to jump.",
        "",
        "Collect all the flowers to move to the",
        "next level. Avoid monsters and other",
        "hazards.",
        "",
        "Pick up objects to open up secret",
        "passages.",
        "",
        "F1 Help",
        "F2 Restart Game",
        "F3 Erase Scores",
        "F4 Pause Game",
        "F9 Load savegame",
        "F10 Save savegame ",
        "F11 Toggle Music",
        "F12 Harcore Mode",
        "",
        "~PRESS [F1] AGAIN TO RETURN TO THE GAME.",
    };

    char t[50];
    int y = 0;

    for (size_t i = 0; i < sizeof(helptext) / sizeof(helptext[0]); ++i)
    {
        strcpy(t, helptext[i]);
        char *p = t;
        int x = 0;
        auto color = WHITE;
        if (p[0] == '~')
        {
            ++p;
            color = YELLOW;
        }
        else if (p[0] == '!')
        {
            ++p;
            x = (WIDTH - strlen(p) * FONT_SIZE) / 2;
        }
        drawText(bitmap, x, y * FONT_SIZE, p, color);
        ++y;
    }
}

bool CGameMixin::handlePrompts()
{
    auto result = m_prompt != PROMPT_NONE;
    if (m_prompt != PROMPT_NONE && m_keyStates[Key_N])
    {
        m_prompt = PROMPT_NONE;
    }
    else if (m_keyStates[Key_Y])
    {
        if (m_prompt == PROMPT_ERASE_SCORES)
        {
            clearScores();
            saveScores();
        }
        else if (m_prompt == PROMPT_RESTART_GAME)
        {
            m_game->restartGame();
        }
        else if (m_prompt == PROMPT_LOAD)
        {
            load();
        }
        else if (m_prompt == PROMPT_SAVE)
        {
            save();
        }
        else if (m_prompt == PROMPT_HARDCORE)
        {
            m_game->setLives(1);
        }
        else if (m_prompt == PROMPT_TOGGLE_MUSIC)
        {
            m_musicMuted ? startMusic() : stopMusic();
            m_musicMuted = !m_musicMuted;
        }
        m_prompt = PROMPT_NONE;
    }
    return result;
}

void CGameMixin::handleFunctionKeys()
{
    for (int k = Key_F1; k <= Key_F12; ++k)
    {
        if (!m_keyStates[k])
        {
            // keyup
            m_keyRepeters[k] = 0;
            continue;
        }
        else if (m_keyRepeters[k])
        {
            // avoid keys repeating
            continue;
        }
        if (m_paused && k != Key_F4)
        {
            // don't handle any other
            // hotkeys while paused
            continue;
        }

        switch (k)
        {
        case Key_F1:
            m_game->setMode(CGame::MODE_HELP);
            m_keyRepeters[k] = KEY_NO_REPETE;
            break;
        case Key_F2: // restart game
            m_prompt = PROMPT_RESTART_GAME;
            break;
        case Key_F3: // erase scores
            m_prompt = PROMPT_ERASE_SCORES;
            break;
        case Key_F4:
            m_paused = !m_paused;
            m_keyRepeters[k] = KEY_NO_REPETE;
            break;
        case Key_F9:
            m_prompt = PROMPT_LOAD;
            break;
        case Key_F10:
            m_prompt = PROMPT_SAVE;
            break;
        case Key_F11:
            m_prompt = PROMPT_TOGGLE_MUSIC;
            break;
        case Key_F12:
            m_prompt = PROMPT_HARDCORE;
        }
    }
}

bool CGameMixin::inputPlayerName()
{
    auto range = [](uint16_t keyCode, uint16_t start, uint16_t end)
    {
        return keyCode >= start && keyCode <= end;
    };

    int j = m_scoreRank;
    for (int k = 0; k < Key_Count; ++k)
    {
        m_keyRepeters[k] ? --m_keyRepeters[k] : 0;
    }

    for (int k = 0; k < Key_Count; ++k)
    {
        if (!m_keyStates[k])
        {
            m_keyRepeters[k] = 0;
            continue;
        }
        else if (m_keyRepeters[k])
        {
            continue;
        }
        char c = 0;
        if (range(k, Key_0, Key_9))
        {
            c = k + '0' - Key_0;
        }
        else if (range(k, Key_A, Key_Z))
        {
            c = k + 'A' - Key_A;
        }
        else if (k == Key_Space)
        {
            c = k + ' ' - Key_Space;
        }
        else if (k == Key_BackSpace)
        {
            m_keyRepeters[k] = KEY_REPETE_DELAY;
            int i = strlen(m_hiscores[j].name);
            if (i > 0)
            {
                m_hiscores[j].name[i - 1] = '\0';
            }
            continue;
        }
        else if (k == Key_Enter)
        {
            return true;
        }
        else
        {
            // don't handle any other keys
            m_keyRepeters[k] = 0;
            continue;
        }
        if (strlen(m_hiscores[j].name) == sizeof(m_hiscores[j].name) - 1)
        {
            // already at maxlenght
            continue;
        }
        m_keyRepeters[k] = KEY_REPETE_DELAY;
        char s[2] = {c, 0};
        strcat(m_hiscores[j].name, s);
    }
    return false;
}

bool CGameMixin::loadScores()
{
    return true;
}

bool CGameMixin::saveScores()
{
    return true;
}

void CGameMixin::enableHiScore()
{
    m_hiscoreEnabled = true;
}

void CGameMixin::clearScores()
{
    memset(m_hiscores, 0, sizeof(m_hiscores));
}

void CGameMixin::clearKeyStates()
{
    memset(m_keyStates, 0, sizeof(m_keyStates));
    memset(m_keyRepeters, 0, sizeof(m_keyRepeters));
}

void CGameMixin::clearJoyStates()
{
    memset(m_joyState, 0, sizeof(m_joyState));
}

bool CGameMixin::read(FILE *sfile, std::string &name)
{
    printf("must be reimplemented in child class");
    return true;
}

bool CGameMixin::write(FILE *tfile, std::string &name)
{
    printf("must be reimplemented in child class");
    return true;
}

void CGameMixin::drawPreScreen(CFrame &bitmap)
{
    const char t[] = "CLICK TO START";
    int x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
    int y = (HEIGHT - FONT_SIZE) / 2;
    bitmap.fill(BLACK);
    drawText(bitmap, x, y, t, WHITE);
}

void CGameMixin::stopMusic()
{
    // TODO: implement in child class
}

void CGameMixin::startMusic()
{
    // TODO: implement in child class
}

void CGameMixin::save()
{
}

void CGameMixin::load()
{
}

void CGameMixin::drawScreen(CFrame &screen)
{
    const std::unordered_set<uint16_t> &hide = m_game->hideList();
    const int scrLen = screen.len();
    const int scrHei = screen.hei();
    const int rows = screen.hei() / FNT_BLOCK_SIZE;
    const int cols = screen.len() / FNT_BLOCK_SIZE;
    const int hx = cols / 2;
    const int hy = rows / 2;
    const CActor *player = m_game->player();
    const int mx = player->x < hx ? 0 : player->x - hx;
    const int my = player->y < hy ? 0 : player->y - hy;
    for (int i = BASE_ENTRY; i < m_game->script()->getSize(); ++i)
    {
        CFrame *frame{nullptr};
        const auto &entry{(*m_game->script())[i]};
        if (entry.type == TYPE_PLAYER)
        {
            uint16_t frameOffset = m_game->playerHitCountdown() &&
                                           !m_game->playerFrameOffset()
                                       ? CGame::PLAYER_HIT_FRAME
                                       : m_game->playerFrameOffset();
            frame = (*m_annie)[entry.aim * PLAYER_FRAME_CYCLE + frameOffset];
        }
        else if (entry.type == TYPE_POINTS)
        {
            frame = (*m_points)[entry.imageId];
        }
        else if (entry.imageId >= m_game->tiles()->getSize() ||
                 CScript::isSystemType(entry.type) ||
                 hide.count(entry.imageId))
        {
            continue;
        }
        else
        {
            frame = (*m_game->tiles())[entry.imageId];
        }
        const int fcols = frame->len() / FNT_BLOCK_SIZE;
        const int frows = frame->hei() / FNT_BLOCK_SIZE;
        const int rx = int(entry.x) - mx;
        const int ry = int(entry.y) - my;
        if ((rx < cols) &&
            (rx + fcols > 0) &&
            (ry < rows) &&
            (ry + frows > 0))
        {
            const int offsetX = rx < 0 ? -rx : 0;
            const int offsetY = ry < 0 ? -ry : 0;
            const int flen = fcols - offsetX;
            const int fhei = frows - offsetY;
            const int sx = rx > 0 ? rx : 0;
            const int sy = ry > 0 ? ry : 0;
            for (int y = 0; y < fhei * FNT_BLOCK_SIZE; ++y)
            {
                if (sy * FNT_BLOCK_SIZE + y >= scrHei)
                    break;
                uint32_t *rgba = &screen.at(sx * FNT_BLOCK_SIZE, sy * FNT_BLOCK_SIZE + y);
                const uint32_t *pixel = &frame->at(offsetX * FNT_BLOCK_SIZE, offsetY * FNT_BLOCK_SIZE + y);
                for (int x = 0; x < flen * FNT_BLOCK_SIZE; ++x)
                {
                    if (sx * FNT_BLOCK_SIZE + x >= scrLen)
                        break;
                    if (pixel[x])
                    {
                        rgba[x] = pixel[x];
                    }
                }
            }
        }
    }

    // draw game status
    char tmp[32];
    if (m_paused)
    {
        drawText(screen, 0, Y_STATUS, "PRESS [F4] TO RESUME PLAYING...", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_ERASE_SCORES)
    {
        drawText(screen, 0, Y_STATUS, "ERASE HIGH SCORES, CONFIRM (Y/N)?", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_RESTART_GAME)
    {
        drawText(screen, 0, Y_STATUS, "RESTART GAME, CONFIRM (Y/N)?", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_LOAD)
    {
        drawText(screen, 0, Y_STATUS, "LOAD PREVIOUS SAVEGAME, CONFIRM (Y/N)?", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_SAVE)
    {
        drawText(screen, 0, Y_STATUS, "SAVE GAME, CONFIRM (Y/N)?", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_HARDCORE)
    {
        drawText(screen, 0, Y_STATUS, "HARDCORE MODE, CONFIRM (Y/N)?", LIGHTGRAY);
    }
    else if (m_prompt == PROMPT_TOGGLE_MUSIC)
    {
        drawText(screen, 0, Y_STATUS,
                 m_musicMuted ? "PLAY MUSIC, CONFIRM (Y/N)?"
                              : "MUTE MUSIC, CONFIRM (Y/N)?",
                 LIGHTGRAY);
    }
    else
    {
        uint16_t x = 0;
        sprintf(tmp, "%.8d ", m_game->score());
        drawText(screen, x, 0, tmp, WHITE);
        x += strlen(tmp) * FONT_SIZE;

        sprintf(tmp, "FLOWERS %.2d ", m_game->goals());
        drawText(screen, x, 0, tmp, YELLOW);
        x += strlen(tmp) * FONT_SIZE;

        sprintf(tmp, "LIVES %.2d ", m_game->lives());
        drawText(screen, x, 0, tmp, PINK);
        x += strlen(tmp) * FONT_SIZE;

        sprintf(tmp, "COINS %.2d", m_game->coins());
        drawText(screen, x, 0, tmp, BLUE);
        x += strlen(tmp) * FONT_SIZE;
    }
    // draw health bar
    const int sectionHeight = HealthBarHeight + HealthBarOffset;
    uint16_t x = HealthBarOffset;
    uint16_t y = screen.hei() - sectionHeight * 2;
    rect_t rect{x, y, std::min(m_game->hp() / 2, screen.len() - HealthBarOffset), HealthBarHeight};
    drawRect(screen, rect, LIME, true);
    drawRect(screen, rect, WHITE, false);
    // draw oxygen bar
    y += sectionHeight;
    rect = {x, y, std::min(m_game->oxygen() / 2, screen.len() - HealthBarOffset), HealthBarHeight};
    drawRect(screen, rect, LIGHTGRAY, true);
    drawRect(screen, rect, WHITE, false);
}

void CGameMixin::drawLevelIntro(CFrame &screen)
{
    char t[32];
    switch (m_game->mode())
    {
    case CGame::MODE_INTRO:
        sprintf(t, "LEVEL %.2d", m_game->level() + 1);
        break;
    case CGame::MODE_RESTART:
        if (m_game->lives() > 1)
        {
            sprintf(t, "LIVES LEFT %.2d", m_game->lives());
        }
        else
        {
            strcpy(t, "LAST LIFE LEFT");
        }
        break;
    case CGame::MODE_GAMEOVER:
        strcpy(t, "GAME OVER");
    };

    int x = (WIDTH - strlen(t) * FONT_SIZE) / 2;
    int y = (HEIGHT - FONT_SIZE) / 2;
    screen.fill(BLACK);
    drawText(screen, x, y, t, WHITE);
}

void CGameMixin::mainLoop()
{
    CGame &game = *CGame::getGame();
    if (m_countdown > 0)
    {
        --m_countdown;
    }

    switch (game.mode())
    {
    case CGame::MODE_HISCORES:
        if (m_recordScore && inputPlayerName())
        {
            m_recordScore = false;
            saveScores();
        }
    case CGame::MODE_INTRO:
    case CGame::MODE_RESTART:
    case CGame::MODE_GAMEOVER:
        if (m_countdown)
        {
            return;
        }
        if (game.mode() == CGame::MODE_GAMEOVER)
        {
            if (!m_hiscoreEnabled)
            {
                m_countdown = game.define(IntroCountdown);
                game.restartGame();
                return;
            }

            game.setMode(CGame::MODE_HISCORES);
            if (!m_scoresLoaded)
            {
                m_scoresLoaded = loadScores();
            }
            m_scoreRank = rankScore();
            m_recordScore = m_scoreRank != INVALID;
            m_countdown = game.define(IntroCountdown);
            // m_countdown = HISCORE_DELAY;
            return;
        }
        else if (game.mode() == CGame::MODE_HISCORES)
        {
            if (!m_recordScore)
            {
                m_countdown = game.define(IntroCountdown);
                game.restartGame();
            }
            return;
        }
        else
        {
            game.setMode(CGame::MODE_LEVEL);
        }
        break;
    case CGame::MODE_IDLE:
    case CGame::MODE_CLICKSTART:
        return;
    case CGame::MODE_HELP:
        if (!m_keyStates[Key_F1])
        {
            // keyup
            m_keyRepeters[Key_F1] = 0;
        }
        else if (m_keyRepeters[Key_F1])
        {
            // avoid keys repeating
            return;
        }
        else
        {
            m_game->setMode(CGame::MODE_LEVEL);
            m_keyRepeters[Key_F1] = 1;
        }
        return;
    }

    manageGamePlay();
}

void CGameMixin::manageGamePlay()
{
    CGame &game = *CGame::getGame();

    if (!m_paused && handlePrompts())
    {
        return;
    }

    handleFunctionKeys();
    if (m_paused)
    {
        return;
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
        if (game.lives() == 0)
        {
            m_countdown = game.define(IntroCountdown);
            game.setMode(CGame::MODE_GAMEOVER);
        }
        else
        {
            game.restartLevel();
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

void CGameMixin::drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color)
{
    static uint8_t caret[8]{
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
        0xff,
    };
    uint32_t *rgba = frame.getRGB();
    const int rowPixels = frame.len();
    const int fontOffset = FONT_SIZE;
    const int textSize = strlen(text);
    for (int i = 0; i < textSize; ++i)
    {
        uint8_t *font = nullptr;
        if (static_cast<uint8_t>(text[i]) == CARET)
        {
            font = caret;
        }
        else
        {
            const uint8_t c = static_cast<uint8_t>(text[i]) - ' ';
            font = m_fontData + c * fontOffset;
        }

        for (int yy = 0; yy < FONT_SIZE; ++yy)
        {
            uint8_t bitFilter{1};
            for (int xx = 0; xx < FONT_SIZE; ++xx)
            {
                rgba[(yy + y) * rowPixels + xx + x] = font[yy] & bitFilter ? color : BLACK;
                bitFilter = bitFilter << 1;
            }
        }
        x += FONT_SIZE;
    }
}

void CGameMixin::drawRect(CFrame &frame, const rect_t &rect, const uint32_t color, bool fill)
{
    uint32_t *rgba = frame.getRGB();
    const int rowPixels = frame.len();
    if (fill)
    {
        for (int y = 0; y < rect.hei; y++)
        {
            for (int x = 0; x < rect.len; x++)
            {
                rgba[(rect.y + y) * rowPixels + rect.x + x] = color;
            }
        }
    }
    else
    {
        for (int y = 0; y < rect.hei; y++)
        {
            for (int x = 0; x < rect.len; x++)
            {
                if (y == 0 || y == rect.hei - 1 || x == 0 || x == rect.len - 1)
                {
                    rgba[(rect.y + y) * rowPixels + rect.x + x] = color;
                }
            }
        }
    }
}

void CGameMixin::preloadAssets()
{
    CFileWrap file;
    using asset_t = struct
    {
        const char *filename;
        CFrameSet **frameset;
    };

    asset_t assets[] = {
        {"data/annie.obl", &m_annie},
        {"data/points.obl", &m_points},
    };

    for (size_t i = 0; i < sizeof(assets) / sizeof(asset_t); ++i)
    {
        asset_t &asset = assets[i];
        *(asset.frameset) = new CFrameSet();
        if (file.open(asset.filename, "rb"))
        {
            printf("reading %s\n", asset.filename);
            if ((*(asset.frameset))->extract(file))
            {
                printf("extracted: %d\n", (*(asset.frameset))->getSize());
            }
            file.close();
        }
    }

    const char fontName[] = "data/bitfont.bin";
    int size = 0;
    if (file.open(fontName, "rb"))
    {
        size = file.getSize();
        m_fontData = new uint8_t[size];
        file.read(m_fontData, size);
        file.close();
        printf("loaded %s: %d bytes\n", fontName, size);
    }
    else
    {
        printf("failed to open %s\n", fontName);
    }
}
