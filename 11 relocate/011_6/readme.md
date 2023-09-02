# *重定位 清除BSS段的C函数实现*

## 1. 汇编传参 C实现

`start.S`启动文件中，调用`copy2sdram`重定位，调用`clean_bss`清除BSS段。

```as
/* 重定位text, rodata, data段整个程序 */
ldr r0, =0
ldr r1, =_start			/* 第1条指令运行时的地址 */
ldr r2, =__bss_start	/* bss段的起始地址 */
sub r2, r2, r1

bl copy2sdram			/* src, dest, len */

/* 清除BSS段 */
ldr r0, =__bss_start
ldr r1, =_end

bl clean_bss			/* start, end */
```

C函数代码实现：

```c
void copy2sdram(volatile unsigned int *src,
				volatile unsigned int *dest,
				unsigned int len)
{
	unsigned int i = 0;

	while (i < len) {
		*dest++ = *src++;
		i += 4;
	}
}

void clean_bss(volatile unsigned int *start,
			   volatile unsigned int *end)
{
	while (start <= end) {
		*start++ = 0;
	}
}
```

## 2. 编译+链接+符号表

*1.编译和链接过程详解*

[C语言编译和链接过程详解：重定向表、导出符号表、未解决符号表](https://www.cnblogs.com/wfwenchao/articles/4140771.html)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.6.2_extern.png)

*2.彻底理解链接器系列*

[彻底理解链接器：一，概念](https://segmentfault.com/a/1190000016417397)

[彻底理解链接器：二，符号决议](https://segmentfault.com/a/1190000016433829)

[彻底理解链接器：三，库与可执行文件](https://segmentfault.com/a/1190000016433897)

[彻底理解链接器：四，重定位](https://segmentfault.com/a/1190000016433947)

*3.访问链接脚本中的符号*

[C代码中访问链接脚本中的符号](https://blog.csdn.net/tianizimark/article/details/129048974)


![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.6.1_symbol.png)

## 3. 以纯C语言的形式来实现重定位

启动文件`start.S`

```as
/* 重定位text, rodata, data段整个程序 */
bl copy2sdram

/* 清除BSS段 */
bl clean_bss
```

链接脚本

```ld
SECTIONS {
   . = 0x30000000;
   __code_start = .;

   . = ALIGN(4);
   .text :
   {
      *(.text)
   }

   . = ALIGN(4);
   .rodata  : { *(.rodata) }

   . = ALIGN(4);
   .data  : { *(.data) }

   . = ALIGN(4);
   __bss_start = .;
   .bss  : { *(.bss) *(.COMMON) }
   _end = .;
}
```

重定位代码`init.c`

C函数如何使用`lds链接脚本`中的变量？

1. 在C函数声明该变量为`extern`类型 *(引用符号链接)*
2. 使用时，药使用`&`取址 *(取符号的地址)*

```c

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
```

编译完成后，程序正常执行。

## 4. 分析符号表

在linux中，`nm`命令可以打印目标文件的符号表，如下所示为`init.c`的符号表。

```sh
ding@linux:$ nm init.o 
00000000 t $a
000001c4 t $a
000001bc t $d
0000021c t $d
         U __bss_start
000001c4 T clean_bss
         U __code_start
0000014c T copy2sdram
         U _end
00000000 T sdram_init
0000008c T sdram_test
```

参数意义说明：

1. T：符号为代码段
2. U：引用了未定义符号，需要外部提供

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.6.3_nm_table.png)