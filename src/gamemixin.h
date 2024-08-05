#ifndef __GAME_MIXING_H
#define __GAME_MIXING_H

#include "game.h"

class CGame;

class CGameMixin
{
public:
    ~CGameMixin();

protected:
    CGameMixin();

    enum
    {
        ALPHA = 0xff000000,
        BLACK = 0xff000000,
        WHITE = 0xffffffff,
        PINK = 0xffd187e8,
        YELLOW = 0xff34ebeb,
        GREEN = 0xff009000,
        LIME = 0xff00ffbf,
        BLUE = 0xffff901e,
        CYAN = 0x00ffff00 | ALPHA,
        DARKBLUE = 0x00440000 | ALPHA,
        DARKGRAY = 0x00444444 | ALPHA,
        LIGHTGRAY = 0x00A9A9A9 | ALPHA,
    };

    enum KeyCode : uint8_t
    {
        Key_A,
        Key_N = Key_A + 13,
        Key_Y = Key_A + 24,
        Key_Z = Key_A + 25,
        Key_Space,
        Key_0,
        Key_9 = Key_0 + 9,
        Key_BackSpace,
        Key_Enter,
        Key_F1,
        Key_F2,
        Key_F3,
        Key_F4,
        Key_F5,
        Key_F6,
        Key_F7,
        Key_F8,
        Key_F9,
        Key_F10,
        Key_F11,
        Key_F12,
        Key_Count
    };

    enum
    {
        PROMPT_NONE,
        PROMPT_ERASE_SCORES,
        PROMPT_RESTART_GAME,
        PROMPT_LOAD,
        PROMPT_SAVE,
        PROMPT_RESTART_LEVEL,
        PROMPT_HARDCORE,
        PROMPT_TOGGLE_MUSIC
    };

    enum
    {
        PLAYER_FRAME_CYCLE = 8,
        FNT_BLOCK_SIZE = 8,
        BASE_ENTRY = 1,
        MAX_SCORES = 18,
        CARET = 0xff,
        KEY_REPETE_DELAY = 5,
        KEY_NO_REPETE = 1,
        MAX_NAME_LENGTH = 16,
        SAVENAME_PTR_OFFSET = 8,
        CARET_SPEED = 8,
        INTERLINES = 2,
        Y_STATUS = 2,
        WIDTH = 320,
        HEIGHT = 240,
        INVALID = -1,
        AIM_UP,
        AIM_DOWN,
        AIM_LEFT,
        AIM_RIGHT,
        BUTTON,
        JOY_STATES = 8,
        KEY_PRESSED = 1,
        KEY_RELEASED = 0,
        FONT_SIZE = 8,
        HealthBarHeight = 8,
        HealthBarOffset = 4,
    };

    using hiscore_t = struct
    {
        int score;
        int level;
        char name[MAX_NAME_LENGTH];
    };

    bool m_musicMuted = false;
    bool m_paused = false;
    int m_prompt = 0;
    bool m_hiscoreEnabled = false;
    int m_scoreRank = INVALID;
    bool m_recordScore = false;
    uint8_t m_keyStates[Key_Count];
    uint8_t m_keyRepeters[Key_Count];
    hiscore_t m_hiscores[MAX_SCORES];
    CGame *m_game = nullptr;
    uint8_t m_joyState[JOY_STATES];

    bool m_assetPreloaded = false;
    uint32_t m_ticks;
    uint32_t m_countdown;
    uint8_t *m_fontData;
    CFrameSet *m_annie;
    CFrameSet *m_points;
    std::string m_lastError;

    void enableHiScore();
    int rankScore();
    void drawScores(CFrame &bitmap);
    bool inputPlayerName();
    void clearScores();
    void clearKeyStates();
    void clearJoyStates();
    void manageGamePlay();
    void handleFunctionKeys();
    bool handlePrompts();
    virtual void drawHelpScreen(CFrame &bitmap);
    virtual bool loadScores();
    virtual bool saveScores();
    virtual bool read(FILE *sfile, std::string &name);
    virtual bool write(FILE *tfile, std::string &name);
    virtual void stopMusic();
    virtual void startMusic();
    void drawText(CFrame &frame, int x, int y, const char *text, const uint32_t color);
    void drawScreen(CFrame &screen);
    void drawRect(CFrame &frame, const rect_t &rect, const uint32_t color, bool fill);
    void preloadAssets();

    void drawPreScreen(CFrame &bitmap);
    virtual void save();
    virtual void load();
};

#endif