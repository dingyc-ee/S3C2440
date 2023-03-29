
#include "s3c2440_soc.h"

void delay(volatile int i)
{
    while (i--);
}

int main(int which)
{
    GPFCON &= ~((3 << 8) | (3 << 10) | (3 << 12));
    GPFCON |=  ((1 << 8) | (1 << 10) | (1 << 12));

    while (1) {
        GPFDAT = ~(1 << 4);
        delay(100000);
        GPFDAT = ~(1 << 5);
        delay(100000);
        GPFDAT = ~(1 << 6);
        delay(100000);
    }

    return 0;
}
