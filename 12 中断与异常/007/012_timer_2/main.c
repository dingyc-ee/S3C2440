#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"

char g_Char = 'A';
char g_Char3 = 'a';
const char g_Char2 = 'B';
int g_A = 0;
int g_B;

int main(void)
{
	led_init();
	key_eint_init();		/* 初始化按键，设为中断源 */
	timer_init();

	puts("\n\rg_A = ");
	printHex(g_A);
	puts("\n\r");

	while (1)
	{
		putchar(g_Char);
		g_Char++;

		putchar(g_Char3);
		g_Char3++;
		delay(1000000);
	}

	return 0;
}
