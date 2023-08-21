
#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"

char g_Char = 'A';          // 非0全局变量   
const char g_Char2 = 'B';   // const常量
int g_A = 0;                // 为0的全局变量
int g_B;                    // 未初始化的全局变量

static void delay(volatile int i)
{
    while (i--)
        ;
}

int main(void)
{
    uart0_init();

    while (1) {
        putchar(g_Char);
        g_Char++;
        delay(1000000);
    }
    
    return 0;
}
