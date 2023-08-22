# *清除BSS段*

## 为什么要清除BSS ?

在前面的学习中，start.S文件把.data段从bin文件的加载地址（0x800），复制到了.data段的链接地址（0x3000 0000），因此正常打印非零的全局变量。

再看下面的代码，打印为0的全局变量。

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
		putchar(g_Char);
		g_Char++;

		putchar(g_Char3);
		g_Char3++;
		delay(1000000);
	}

	return 0;
}
```

g_A的初始值为0，但实际的测试结果如下。可以看到，由于没有清除bss段，导致g_A实际打印的随机值，重启还不一样。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.3.1_not_clear_bss.png)

## 清除BSS段

### 1. 链接脚本中添加bss变量

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
   bss_start = .;
   .bss  : { *(.bss) *(.COMMON) }
   bss_end = .;
}
```

### 2. start.S中清除bss段

```ld
	/* 清除BSS段 */
	ldr r1, =bss_start
	ldr r2, =bss_end
	ldr r3, =0
clean:
	strb r3, [r1]
	add r1, r1, #1
	cmp r1, r2
	bne clean
```

实际测试结果如下，多次重启之后g_A也是0。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.3.2_clean_bss.png)
