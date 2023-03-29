
#include "s3c2440_soc.h"

void delay(volatile int i)
{
    while (i--);
}

int main(int which)
{
    unsigned int val1, val2;

    // 配置LED为输出引脚
    // LED顺序：GPF4 GPF5 GPF6
    GPFCON &= ~((3 << 8) | (3 << 10) | (3 << 12));
    GPFCON |=  ((1 << 8) | (1 << 10) | (1 << 12));

    // 配置KEY为输入引脚
    // KEY顺序：GPG3 GPF2 GPF0
    GPGCON &= ~(3 << 6);
    GPFCON &= ~((3 << 0) | (3 << 4));

    while (1) {
        val1 = GPFDAT;
        val2 = GPGDAT;

        // KEY:GPG3 -> LED:GPF4
        if (val2 & (1 << 3)) {
            // 松开
            GPFDAT |= (1 << 4);
        }
        else {
            // 按下
            GPFDAT &= ~(1 << 4);
        }

        // KEY:GPF2 -> LED:GPF5
        if (val1 & (1 << 2)) {
            // 松开
            GPFDAT |= (1 << 5);
        }
        else {
            // 按下
            GPFDAT &= ~(1 << 5);
        }

        // KEY:GPF0 -> LED:GPF6
        if (val1 & (1 << 0)) {
            // 松开
            GPFDAT |= (1 << 6);
        }
        else {
            // 按下
            GPFDAT &= ~(1 << 6);
        }

    }

    return 0;
}
