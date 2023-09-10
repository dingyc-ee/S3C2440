
#include "s3c2440_soc.h"

void sdram_init(void)
{
	BWSCON = 0x22000000;

	BANKCON6 = 0x18001;
	BANKCON7 = 0x18001;

	REFRESH  = 0x8404f5;

	BANKSIZE = 0xb1;

	MRSRB6   = 0x20;
	MRSRB7   = 0x20;
}

int sdram_test(void)
{
	volatile unsigned char *p = (volatile unsigned char *)0x30000000;
	int i;

	// write sdram
	for (i = 0; i < 1000; i++)
		p[i] = 0x55;

	// read sdram
	for (i = 0; i < 1000; i++)
		if (p[i] != 0x55)
			return -1;

	return 0;
}

void copy2sdram(void)
{
	/* 要从lds文件中，获得 __code_start, __bss_start
	 * 然后从0地址把数据复制到 __code_start
	 */

	/* 这里引用了2个外部符号 */
	extern int __code_start, __bss_start;

	volatile unsigned int *src  = (volatile unsigned int *)0;
	volatile unsigned int *dest = (volatile unsigned int *)&__code_start;	/* 取符号的地址 */
	volatile unsigned int *end  = (volatile unsigned int *)&__bss_start;	/* 取符号的地址 */

	while (dest < end) {
		*dest++ = *src++;
	}
}

void clean_bss(void)
{
	/* 要从lds文件中，获得 __bss_start, _end
	 * 然后清除 __bss_start ~ _end的数据
	 */

	/* 这里引用了2个外部符号 */
	extern int __bss_start, _end;

	volatile unsigned int *start = (volatile unsigned int *)&__bss_start;	/* 取符号的地址 */
	volatile unsigned int *end   = (volatile unsigned int *)&_end;			/* 取符号的地址 */

	while (start < end) {
		*start++ = 0;
	}
}
