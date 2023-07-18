#include "s3c2440_soc.h"
#include "uart.h"

void uart0_init(void)
{
    // 设置引脚用于串口
    // GPH2/3用于TXD0 RXD0
    GPHCON &= ~((3 << 4) | (3 << 6));
    GPHCON |= ((2 << 4) | (2 << 6));
    GPHUP &= ~((1 << 2) | (1 << 3));   // 设置内部上拉

    // 设置波特率
    // UBRDIVn = (int)( UART clock / (baudrate * 16) ) - 1
    // UART clock = 50M
    // UBRDIVn = (int)( 50000000 / (115200 * 16) ) - 1 = 26
    UCON0 = 0x05;   // PCLK 查询模式
    UBRDIV0 = 26;

    // 设置数据格式
    ULCON0 = 0x3;   // 8,n,1  8位数据 无校验位 1停止位

    //
}

int putchar(int c)
{
    while (!(UTRSTAT0 & (1 << 2)));
    UTXH0 = (unsigned char)c;
}

int getchar(void)
{
    while (!(UTRSTAT0 & (1 << 0)));
    return URXH0;
}

int puts(const char *s)
{
    while (*s) {
        putchar(*s);
        s++;
    }
}
