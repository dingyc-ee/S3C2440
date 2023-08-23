# *拷贝代码和链接脚本的改进*

## 为什么要改进 ?

之前拷贝代码是按字节拷贝的，具体过程是从Nor读取1字节数据，然后向SDRAM写入1字节。实际上Nor支持16位访问，SDRAM支持32位访问。所以，按字节拷贝效率太低了，需要优化。

```asm
// 按字节拷贝.data数据段
copy:
	ldrb r4, [r1]
	strb r4, [r2]
	add r1, r1, #1
	add r2, r2, #1
	cmp r2, r3
	bne copy

// 按字节清除.bss .common段
	ldr r1, =bss_start
	ldr r2, =bss_end
	ldr r3, =0
clean:
	strb r3, [r1]
	add r1, r1, #1
	cmp r1, r2
	bne clean
```

## 按4字节拷贝

将复制.data过程，清除.bss过程都改成是按4字节访问。

```asm
copy:
	ldr r4, [r1]
	str r4, [r2]
	add r1, r1, #4
	add r2, r2, #4
	cmp r2, r3
	ble copy

	/* 清除BSS段 */
	ldr r1, =bss_start
	ldr r2, =bss_end
	ldr r3, =0
clean:
	str r3, [r1]
	add r1, r1, #4
	cmp r1, r2
	ble clean
```

实际运行结果如下。我们的程序并没有循环打印.data全局变量，难道是.data段被破坏了吗？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.1_err.png)

修改测试代码如下，把.data全局变量的十六进制数打出来，再次编译运行。

`test.c`

```c
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
	uart0_init();

	puts("\n\rg_A = ");
	printHex(g_A);
	puts("\n\r");

	while (1)
	{
		puts("\n\rg_Char = ");
		printHex(g_Char);
		puts("\n\r");

		puts("\n\rg_Char3 = ");
		printHex(g_Char3);
		puts("\n\r");

		putchar(g_Char);
		g_Char++;

		putchar(g_Char3);
		g_Char3++;
		delay(1000000);
	}

	return 0;
}
```

运行结果如下。可以看到，我们的全局变量本来是'A'和'a'，现在打印出来却变成了0。这说明.data段确实是被破坏掉了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.2_print_data.png)

分析反汇编文件，.bss段的起始地址为0x3000 0002，不是4字节对齐，问题就出在这里。str命令会把地址进行4字节对齐，变为str 0, [0x3000 0000]   刚好把.data全局变量(g_Char  g_Char3)给覆盖掉。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.3_dis.png)

## 链接脚本内建函数

1. ALIGN函数：返回下一个与align字节对齐的地址
2. LOADADDR函数：返回段的加载地址

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.3_function.png)

## 4字节地址对齐

*出现问题的根本原因是，bss段起始地址不是4字节对齐的。那么我们在链接脚本中可以把bss段的地址设为4字节对齐取整，就可以解决。*

```ld
SECTIONS {
   .text   0  : { *(.text) }
   .rodata  : { *(.rodata) }
   .data 0x30000000 : AT(0x800)
   { 
      data_loadaddr = LOADADDR(.data);
      data_start = .;
      *(.data) 
      data_end = .;
   }
   . = ALIGN(4);
   bss_start = .;
   .bss  : { *(.bss) *(.COMMON) }
   bss_end = .;
}
```

修改完后，全局变量正常打印。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.3_global.png)

反汇编文件中，bss段的地址也变成为4字节对齐（0x3000 0002 -> 0x3000 0004）。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.4.3_new_dis.png)
