# *Printf*

## 1. 需要新增3个文件

`my_printf.c`

```c
#include  "my_printf.h"
//==================================================================================================
typedef char *  va_list;
#define _INTSIZEOF(n)   ( (sizeof(n) + sizeof(int) - 1) & ~(sizeof(int) - 1) )
//当sizeof(var)小于sizeof(int),则_INTSIZEOF(var)=4
#define va_start(ap,v)  ( ap = (va_list)&v + _INTSIZEOF(v) )

#define va_arg(ap,t)    ( *(t *)( ap=ap + _INTSIZEOF(t), ap- _INTSIZEOF(t)) )
#define va_end(ap)      ( ap = (va_list)0 )

//==================================================================================================
unsigned char hex_tab[]={'0','1','2','3','4','5','6','7',\
		                 '8','9','a','b','c','d','e','f'};
//输出单个字符
static int outc(int c) 
{
	__out_putchar(c);
	return 0;
}
//输出字符串
static int outs (const char *s)
{
	while (*s != '\0')	
		__out_putchar(*s++);
	return 0;
}
/*
 * 输出数字
 * n:数字, base:进制, lead:前导码, maxwidth:最大数字宽度
 */
static int out_num(long n,int base,char lead,int maxwidth)
{
	unsigned long res = 0;
	char buf[MAX_NUMBER_BYTES]; //数据缓冲区
	char *s = buf + sizeof(buf);
	int count = 0,i = 0;

	*--s = '\0';
	res = n < 0 ? -n : n; //若为负,转换正数暂存

	do{
		*--s = hex_tab[res%base]; //存储
		count++;
	}while((res/=base) != 0);

	if(maxwidth && count < maxwidth){
		for(i = maxwidth - count;i;i--){
			*--s = lead; //填充前导码,默认空格  eg:%6d,则为:   123(前面三个空格)
		}
	}
	if(n < 0){
		*--s = '-';
	}

	return outs(s);
}

   
//简易printf函数实现逻辑
/*reference :   int vprintf(const char *format, va_list ap); */
static int my_vprintf(const char *fmt, va_list ap) 
{
	char lead=' ';//前导码默认为空格
	int  maxwidth=0;
	
	 for(; *fmt != '\0'; fmt++)
	 {
		if (*fmt != '%') {//当未遇到%,直接输出字符
			outc(*fmt);
			continue;
		}	
		//format : %08d, %8d,%d,%u,%x,%f,%c,%s 
		fmt++;
		if(*fmt == '0'){//存放前导码
			lead = '0';
			fmt++;	
		}

		lead=' ';
		maxwidth=0;
		
		while(*fmt >= '0' && *fmt <= '9'){//计算最大数字宽度 eg: %6d
			maxwidth *=10;
			maxwidth += (*fmt - '0');
			fmt++;
		}
		
		switch (*fmt) {//选择数据格式
		case 'd': out_num(va_arg(ap, int),          10,lead,maxwidth); break;
		case 'o': out_num(va_arg(ap, unsigned int),  8,lead,maxwidth); break;				
		case 'u': out_num(va_arg(ap, unsigned int), 10,lead,maxwidth); break;
		case 'x': out_num(va_arg(ap, unsigned int), 16,lead,maxwidth); break;
		case 'c': outc(va_arg(ap, int   )); break;		
		case 's': outs(va_arg(ap, char *)); break;		  		
		default:  
			outc(*fmt);break;
		}
	}
	return 0;
}

//reference :  int printf(const char *format, ...); 
int my_printf(const char *fmt, ...) 
{
	va_list ap;

	va_start(ap, fmt);//移动至可变参数地址
	my_vprintf(fmt, ap);	
	va_end(ap);
	return 0;
}

int my_printf_test(void)
{
	my_printf("This is www.100ask.org   my_printf test\n\r") ;	
	my_printf("test char           =%c,%c\n\r", 'A','a') ;	
	my_printf("test decimal number =%d\n\r",    123456) ;
	my_printf("test decimal number =%d\n\r",    -123456) ;	
	my_printf("test hex     number =0x%x\n\r",  0x55aa55aa) ;	
	my_printf("test string         =%s\n\r",    "www.100ask.org") ;	
	my_printf("num=%08d\n\r",   12345);
	my_printf("num=%8d\n\r",    12345);
	my_printf("num=0x%08x\n\r", 0x12345);
	my_printf("num=0x%8x\n\r",  0x12345);
	my_printf("num=0x%02x\n\r", 0x1);
	my_printf("num=0x%2x\n\r",  0x1);

	my_printf("num=%05d\n\r", 0x1);
	my_printf("num=%5d\n\r",  0x1);

	return 0;
}
```

`my_printf.h`

```h
#ifndef __MY_PRINTF_H
#define __MY_PRINTF_H

#include "uart.h"
#define __out_putchar putchar  //底层输出

#define  MAX_NUMBER_BYTES  64

int my_printf_test(void);
int my_printf(const char *fmt, ...);

#endif
```

`lib1funcs.S`

```asm
/*
 * linux/arch/arm/lib/lib1funcs.S: Optimized ARM division routines
 *
 * Author: Nicolas Pitre <nico@cam.org>
 *   - contributed to gcc-3.4 on Sep 30, 2003
 *   - adapted for the Linux kernel on Oct 2, 2003
 */

/* Copyright 1995, 1996, 1998, 1999, 2000, 2003 Free Software Foundation, Inc.

This file is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2, or (at your option) any
later version.

In addition to the permissions in the GNU General Public License, the
Free Software Foundation gives you unlimited permission to link the
compiled version of this file into combinations with other programs,
and to distribute those combinations without any restriction coming
from the use of this file.  (The General Public License restrictions
do apply in other respects; for example, they cover modification of
the file, and distribution when not linked into a combine
executable.)

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */

/*
#include <linux/linkage.h>
#include <asm/assembler.h>
*/

#define ALIGN		.align 4,0x90
#define __LINUX_ARM_ARCH__  1

#define ENTRY(name) \
  .globl name; \
  ALIGN; \
  name:

.macro ARM_DIV_BODY dividend, divisor, result, curbit

#if __LINUX_ARM_ARCH__ >= 5

	clz	\curbit, \divisor
	clz	\result, \dividend
	sub	\result, \curbit, \result
	mov	\curbit, #1
	mov	\divisor, \divisor, lsl \result
	mov	\curbit, \curbit, lsl \result
	mov	\result, #0
	
#else

	@ Initially shift the divisor left 3 bits if possible,
	@ set curbit accordingly.  This allows for curbit to be located
	@ at the left end of each 4 bit nibbles in the division loop
	@ to save one loop in most cases.
	tst	\divisor, #0xe0000000
	moveq	\divisor, \divisor, lsl #3
	moveq	\curbit, #8
	movne	\curbit, #1

	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
1:	cmp	\divisor, #0x10000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #4
	movlo	\curbit, \curbit, lsl #4
	blo	1b

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
1:	cmp	\divisor, #0x80000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #1
	movlo	\curbit, \curbit, lsl #1
	blo	1b

	mov	\result, #0

#endif

	@ Division loop
1:	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
	orrhs	\result,   \result,   \curbit
	cmp	\dividend, \divisor,  lsr #1
	subhs	\dividend, \dividend, \divisor, lsr #1
	orrhs	\result,   \result,   \curbit,  lsr #1
	cmp	\dividend, \divisor,  lsr #2
	subhs	\dividend, \dividend, \divisor, lsr #2
	orrhs	\result,   \result,   \curbit,  lsr #2
	cmp	\dividend, \divisor,  lsr #3
	subhs	\dividend, \dividend, \divisor, lsr #3
	orrhs	\result,   \result,   \curbit,  lsr #3
	cmp	\dividend, #0			@ Early termination?
	movnes	\curbit,   \curbit,  lsr #4	@ No, any more bits to do?
	movne	\divisor,  \divisor, lsr #4
	bne	1b

.endm


.macro ARM_DIV2_ORDER divisor, order

#if __LINUX_ARM_ARCH__ >= 5

	clz	\order, \divisor
	rsb	\order, \order, #31

#else

	cmp	\divisor, #(1 << 16)
	movhs	\divisor, \divisor, lsr #16
	movhs	\order, #16
	movlo	\order, #0

	cmp	\divisor, #(1 << 8)
	movhs	\divisor, \divisor, lsr #8
	addhs	\order, \order, #8

	cmp	\divisor, #(1 << 4)
	movhs	\divisor, \divisor, lsr #4
	addhs	\order, \order, #4

	cmp	\divisor, #(1 << 2)
	addhi	\order, \order, #3
	addls	\order, \order, \divisor, lsr #1

#endif

.endm


.macro ARM_MOD_BODY dividend, divisor, order, spare

#if __LINUX_ARM_ARCH__ >= 5

	clz	\order, \divisor
	clz	\spare, \dividend
	sub	\order, \order, \spare
	mov	\divisor, \divisor, lsl \order

#else

	mov	\order, #0

	@ Unless the divisor is very big, shift it up in multiples of
	@ four bits, since this is the amount of unwinding in the main
	@ division loop.  Continue shifting until the divisor is 
	@ larger than the dividend.
1:	cmp	\divisor, #0x10000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #4
	addlo	\order, \order, #4
	blo	1b

	@ For very big divisors, we must shift it a bit at a time, or
	@ we will be in danger of overflowing.
1:	cmp	\divisor, #0x80000000
	cmplo	\divisor, \dividend
	movlo	\divisor, \divisor, lsl #1
	addlo	\order, \order, #1
	blo	1b

#endif

	@ Perform all needed substractions to keep only the reminder.
	@ Do comparisons in batch of 4 first.
	subs	\order, \order, #3		@ yes, 3 is intended here
	blt	2f

1:	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
	cmp	\dividend, \divisor,  lsr #1
	subhs	\dividend, \dividend, \divisor, lsr #1
	cmp	\dividend, \divisor,  lsr #2
	subhs	\dividend, \dividend, \divisor, lsr #2
	cmp	\dividend, \divisor,  lsr #3
	subhs	\dividend, \dividend, \divisor, lsr #3
	cmp	\dividend, #1
	mov	\divisor, \divisor, lsr #4
	subges	\order, \order, #4
	bge	1b

	tst	\order, #3
	teqne	\dividend, #0
	beq	5f

	@ Either 1, 2 or 3 comparison/substractions are left.
2:	cmn	\order, #2
	blt	4f
	beq	3f
	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
	mov	\divisor,  \divisor,  lsr #1
3:	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
	mov	\divisor,  \divisor,  lsr #1
4:	cmp	\dividend, \divisor
	subhs	\dividend, \dividend, \divisor
5:
.endm


ENTRY(__udivsi3)

	subs	r2, r1, #1
	moveq	pc, lr
	bcc	Ldiv0
	cmp	r0, r1
	bls	11f
	tst	r1, r2
	beq	12f

	ARM_DIV_BODY r0, r1, r2, r3

	mov	r0, r2
	mov	pc, lr

11:	moveq	r0, #1
	movne	r0, #0
	mov	pc, lr

12:	ARM_DIV2_ORDER r1, r2

	mov	r0, r0, lsr r2
	mov	pc, lr


ENTRY(__umodsi3)

	subs	r2, r1, #1			@ compare divisor with 1
	bcc	Ldiv0
	cmpne	r0, r1				@ compare dividend with divisor
	moveq   r0, #0
	tsthi	r1, r2				@ see if divisor is power of 2
	andeq	r0, r0, r2
	movls	pc, lr

	ARM_MOD_BODY r0, r1, r2, r3

	mov	pc, lr


ENTRY(__divsi3)

	cmp	r1, #0
	eor	ip, r0, r1			@ save the sign of the result.
	beq	Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	subs	r2, r1, #1			@ division by 1 or -1 ?
	beq	10f
	movs	r3, r0
	rsbmi	r3, r0, #0			@ positive dividend value
	cmp	r3, r1
	bls	11f
	tst	r1, r2				@ divisor is power of 2 ?
	beq	12f

	ARM_DIV_BODY r3, r1, r0, r2

	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr

10:	teq	ip, r0				@ same sign ?
	rsbmi	r0, r0, #0
	mov	pc, lr

11:	movlo	r0, #0
	moveq	r0, ip, asr #31
	orreq	r0, r0, #1
	mov	pc, lr

12:	ARM_DIV2_ORDER r1, r2

	cmp	ip, #0
	mov	r0, r3, lsr r2
	rsbmi	r0, r0, #0
	mov	pc, lr


ENTRY(__modsi3)

	cmp	r1, #0
	beq	Ldiv0
	rsbmi	r1, r1, #0			@ loops below use unsigned.
	movs	ip, r0				@ preserve sign of dividend
	rsbmi	r0, r0, #0			@ if negative make positive
	subs	r2, r1, #1			@ compare divisor with 1
	cmpne	r0, r1				@ compare dividend with divisor
	moveq	r0, #0
	tsthi	r1, r2				@ see if divisor is power of 2
	andeq	r0, r0, r2
	bls	10f

	ARM_MOD_BODY r0, r1, r2, r3

10:	cmp	ip, #0
	rsbmi	r0, r0, #0
	mov	pc, lr


Ldiv0:

	str	lr, [sp, #-4]!
/*	bl	__div0	*/
	mov	r0, #0			@ About as wrong as it could be.
	ldr	pc, [sp], #4
```

## 2. 修改Makefile

```mk

# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = PRINTF
OBJ = start.o lib1funcs.o main.o uart.o my_printf.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

## 3. 编译结果

可以看到，编译出来的PRINTF.bin竟然有36K，太大了，4K内存装不下。

```sh
linux:~/s3c2440/008_printf$ ls -l
总计 112
-rw-rw-r-- 1 ding ding  1928  7月 15 00:06 lib1funcs.o
-rw------- 1 ding ding  7442  7月 15 00:06 lib1funcs.S
-rw------- 1 ding ding   388  7月 15 00:06 main.c
-rw-rw-r-- 1 ding ding  1056  7月 15 00:06 main.o
-rw------- 1 ding ding   508  7月 15 00:06 Makefile
-rw------- 1 ding ding  3514  7月 15 00:06 my_printf.c
-rw------- 1 ding ding   212  7月 15 00:06 my_printf.h
-rw-rw-r-- 1 ding ding  3576  7月 15 00:06 my_printf.o
-rwxrwxr-x 1 ding ding 36156  7月 15 00:06 PRINTF.bin
-rw-rw-r-- 1 ding ding 32218  7月 15 00:06 PRINTF.dis
-rwxrwxr-x 1 ding ding 37892  7月 15 00:06 PRINTF.elf
-rw------- 1 ding ding  3508  7月 15 00:06 s3c2440_soc.h
-rw-rw-r-- 1 ding ding   820  7月 15 00:06 start.o
-rw------- 1 ding ding  1152  7月 15 00:06 start.S
-rw------- 1 ding ding   889  7月 15 00:06 uart.c
-rw------- 1 ding ding   161  7月 15 00:06 uart.h
-rw-rw-r-- 1 ding ding  1116  7月 15 00:06 uart.o
```

为什么会这么大？看看反汇编文件

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/8.1_dis.png)

可以看到，反汇编文件的数据段地址，竟然直接从0xd28跳到了0x8d2c，导致文件变大。

## 4. 修改Makefile 设置数据段的地址，增加 -Tdata 0xd40

```mk
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = PRINTF
OBJ = start.o lib1funcs.o main.o uart.o my_printf.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 -Tdata 0xd40 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

重新编译，可以看到PRINTF.bin已经编程了只有3.4K，可以烧录到4K的内存中。

```sh
linux:~/s3c2440/008_printf$ ls -lh
总计 108K
-rw-rw-r-- 1 ding ding 1.9K  7月 15 00:20 lib1funcs.o
-rw------- 1 ding ding 7.3K  7月 15 00:06 lib1funcs.S
-rw------- 1 ding ding  388  7月 15 00:06 main.c
-rw-rw-r-- 1 ding ding 1.1K  7月 15 00:20 main.o
-rw------- 1 ding ding  437  7月 15 00:20 Makefile
-rw------- 1 ding ding 3.5K  7月 15 00:06 my_printf.c
-rw------- 1 ding ding  212  7月 15 00:06 my_printf.h
-rw-rw-r-- 1 ding ding 3.5K  7月 15 00:20 my_printf.o
-rwxrwxr-x 1 ding ding 3.4K  7月 15 00:20 PRINTF.bin
-rw-rw-r-- 1 ding ding  32K  7月 15 00:20 PRINTF.dis
-rwxrwxr-x 1 ding ding  38K  7月 15 00:20 PRINTF.elf
-rw------- 1 ding ding 3.5K  7月 15 00:06 s3c2440_soc.h
-rw-rw-r-- 1 ding ding  820  7月 15 00:20 start.o
-rw------- 1 ding ding 1.2K  7月 15 00:06 start.S
-rw------- 1 ding ding  889  7月 15 00:06 uart.c
-rw------- 1 ding ding  161  7月 15 00:06 uart.h
-rw-rw-r-- 1 ding ding 1.1K  7月 15 00:20 uart.o

```

更新后的反汇编文件，数据段也被指定到了0xd40的位置

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.2_data_section.png)

## 执行结果

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.3_result.png)