#ifndef __MAPENTRY_H
#define __MAPENTRY_H
#include "mapentry.h"
#include <cstdint>

class CMapEntry
{
private:
    uint8_t m_bkType;
    uint8_t m_player;
    uint16_t m_acEntry;
    uint16_t m_fwEntry[2];

public:
    CMapEntry();
    ~CMapEntry();

    inline uint8_t bk() const
    {
        return m_bkType;
    }

    inline void setBk(uint8_t bkv)
    {
        m_bkType = bkv;
    }

    inline bool player() const
    {
        return m_player;
    }

    inline void setPlayer(bool p)
    {
        m_player = static_cast<uint8_t>(p);
    }

    inline bool isEmpty() const
    {
        return m_bkType == m_acEntry == m_fwEntry[0] == m_fwEntry[1] == m_player == 0;
    }

    inline uint16_t acEntry() const
    {
        return m_acEntry;
    }

    inline void setAcEntry(const uint16_t ac)
    {
        m_acEntry = ac;
    }

    inline void setFwEntry(const uint16_t fw)
    {
        if ((m_fwEntry[0] == fw) || (m_fwEntry[1] == fw))
        {
            return;
        }
        for (uint32_t i = 0; i < sizeof(m_fwEntry) / sizeof(uint16_t); ++i)
        {
            if (m_fwEntry[i] == 0)
            {
                m_fwEntry[i] = fw;
                return;
            }
        }
    }

    inline void removeFwEntry(const uint16_t fw)
    {
        for (uint32_t i = 0; i < sizeof(m_fwEntry) / sizeof(uint16_t); ++i)
        {
            if (m_fwEntry[i] == fw)
            {
                m_fwEntry[i] = 0;
                return;
            }
        }
    }

    void debug() const;
};
#endif