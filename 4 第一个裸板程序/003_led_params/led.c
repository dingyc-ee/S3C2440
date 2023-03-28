
void delay(int i)
{
    while (i--);
}

int led_on(int which)
{
    unsigned int *pGPFCON = (unsigned int *)0x56000050;
    unsigned int *pGPFDAT = (unsigned int *)0x56000054;

    if (which == 4) {
        *pGPFCON = 1 << 8;      // 配置GPF4为输出引脚

    }
    else if (which == 5) {
        *pGPFCON = 1 << 10;     // 配置GPF5为输出引脚
    }
    else if (which == 6) {
        *pGPFCON = 1 << 12;     // 配置GPF5为输出引脚
    }

    *pGPFDAT = 0;           // GPFDAT输出低电平

    return 0;
}
