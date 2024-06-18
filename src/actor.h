#ifndef __CACTOR_H
#define __CACTOR_H

class CActor
{
public:
    CActor();
    ~CActor();

    bool canMove(int aim);
    bool move(int aim);

    friend class CGame;
};

#endif