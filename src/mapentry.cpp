#include "mapentry.h"
#include <cstring>
#include <cstdio>

CMapEntry::CMapEntry()
{
    memset(this, 0, sizeof(CMapEntry));
}

CMapEntry::~CMapEntry()
{
}

void CMapEntry::debug() const
{
    printf("type=%.2x ac=%.4x fw0=%.4x fw1=%.4x p=%d\n", m_bkType, m_acEntry, m_fwEntry[0], m_fwEntry[1], m_player);
}
