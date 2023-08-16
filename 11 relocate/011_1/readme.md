# *重定位*

## 1. 内存访问

S3C2440的内存控制器如下所示。CPU可以直接访问SDRAM、NorFlash、SRAM、NandFlash控制器，但不能直接访问Nand。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1_1_memory.png)

实际上，我们的代码是烧录在Nor或Nand上的。既然CPU不能直接访问Nand，那就没办法从Nand取指令，为什么2440还可以Nand启动？

根本原因是，当OM配置为Nand启动时，2440硬件默认会把nand的前4K内容读到SRAM，然后从SRAM（0地址）开始执行。

## 2. 存在的问题

### 2.1 NandFlash

如果程序>4K，拉后面的代码怎么执行？

*显然，前4K代码需要把整个程序读出来。然后放在那里？只能放在SDRAM。这就是重定位，重新确定程序的地址。*

### 2.2 NorFlash

使用Nor启动时，NorFlash的基地址为0，SRAM的地址为0x4000 0000。Nor的特点是，可以像内存一样读，但不能像内存一样写。举例说明：

```asm
mov r0, 0
ldr r1, [r0]
str r1, [r0]  ; 指令无效，不能直接写
```

存在的问题是，如果程序中含有需要写的变量（全局/静态），他们在bin文件中，写在Nor上直接修改无效。

*因此，需要把变量（全局/静态）重定位，放到SDRAM中。*

无论是Nor启动还是Nand启动，我们都需要重定位。

## 3. 代码分析

### 3.1 代码段+数据段

原始代码（1个全局变量）

```c
#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"
#include "my_printf.h"

char g_Char = 'A';

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
```

存在的问题：编译出来的bin文件非常大，如下所示：

```sh
ding@linux:~/s3c2440/011_1_relocate$ ls -l
总计 188
-rw------- 1 ding ding   929  8月 16 21:39 init.c
-rw------- 1 ding ding   117  8月 16 21:39 init.h
-rw-rw-r-- 1 ding ding  1032  8月 16 21:39 init.o
-rw------- 1 ding ding   685  8月 16 21:39 led.c
-rw------- 1 ding ding   132  8月 16 21:39 led.h
-rw-rw-r-- 1 ding ding  1100  8月 16 21:34 led.o
-rw-rw-r-- 1 ding ding  1928  8月 16 21:39 lib1funcs.o
-rw------- 1 ding ding  7442  8月 16 21:39 lib1funcs.S
-rw------- 1 ding ding   294  8月 16 21:39 main.c
-rw-rw-r-- 1 ding ding   928  8月 16 21:39 main.o
-rw------- 1 ding ding   409  8月 16 21:39 Makefile
-rw------- 1 ding ding  3500  8月 16 21:39 my_printf.c
-rw------- 1 ding ding   212  8月 16 21:39 my_printf.h
-rw-rw-r-- 1 ding ding  3576  8月 16 21:39 my_printf.o
-rwxrwxr-x 1 ding ding 33677  8月 16 21:39 RELOCATE.bin
-rw------- 1 ding ding  9516  8月 16 21:39 RELOCATE.dis
-rwxrwxr-x 1 ding ding 34972  8月 16 21:39 RELOCATE.elf
-rw------- 1 ding ding 33580  8月 16 21:39 s3c2440_soc.h
-rw------- 1 ding ding  4032  8月 16 21:39 SDRAM.bin
-rw------- 1 ding ding 38635  8月 16 21:39 SDRAM.dis
-rw-rw-r-- 1 ding ding   820  8月 16 21:39 start.o
-rw------- 1 ding ding  1152  8月 16 21:39 start.S
-rw------- 1 ding ding   889  8月 16 21:39 uart.c
-rw------- 1 ding ding   161  8月 16 21:39 uart.h
-rw-rw-r-- 1 ding ding  1116  8月 16 21:39 uart.o
```

为什么这么简单的代码，bin文件竟然有36KB，这也太不正常了，看看.dis反汇编文件。这里数据段的位置，并不是紧挨着代码段的结尾来保存，而是直接跳到了0x838c = 33676字节处。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1.3_dis.png)

所以要我们修改Makefile中，数据段的起始存放位置（新增 -Tdata 0x800）。

```mk
TARGET = RELOCATE
OBJ = start.o main.o uart.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 -Tdata 0x800 $^ -o $@.elf
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

重新编译，得到的文件大小，变为2049字节。

```sh
ding@linux:~/s3c2440/011_1_relocate$ ls -l
总计 128
-rw------- 1 ding ding   929  8月 16 21:43 init.c
-rw------- 1 ding ding   117  8月 16 21:43 init.h
-rw-rw-r-- 1 ding ding  1032  8月 16 21:43 init.o
-rw------- 1 ding ding   685  8月 16 21:43 led.c
-rw------- 1 ding ding   132  8月 16 21:43 led.h
-rw------- 1 ding ding  7442  8月 16 21:43 lib1funcs.S
-rw------- 1 ding ding   294  8月 16 21:43 main.c
-rw-rw-r-- 1 ding ding   928  8月 16 21:43 main.o
-rw------- 1 ding ding   422  8月 16 21:43 Makefile
-rw------- 1 ding ding  3500  8月 16 21:43 my_printf.c
-rw------- 1 ding ding   212  8月 16 21:43 my_printf.h
-rwxrwxr-x 1 ding ding  2049  8月 16 21:43 RELOCATE.bin
-rw-rw-r-- 1 ding ding  9507  8月 16 21:43 RELOCATE.dis
-rwxrwxr-x 1 ding ding 36112  8月 16 21:43 RELOCATE.elf
-rw------- 1 ding ding 33580  8月 16 21:43 s3c2440_soc.h
-rw-rw-r-- 1 ding ding   820  8月 16 21:43 start.o
-rw------- 1 ding ding  1152  8月 16 21:43 start.S
-rw------- 1 ding ding   889  8月 16 21:43 uart.c
-rw------- 1 ding ding   161  8月 16 21:43 uart.h
-rw-rw-r-- 1 ding ding  1116  8月 16 21:43 uart.o
```

修改数据段的链接地址后，数据段的位置变成了0x800。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1.4_dis.png)

可以看到，程序中至少包含：代码段和数据段。

### 3.2 

测试代码包含4各部分：非0全局变量，const常量，等于0的全局变量，未初始化的全局变量。

```c
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
```

反汇编文件说明如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1.5_dis.png)

.comment 段，其实是字符串信息的ACSII码。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1.7_comment.png)

### 3.3 内存布局

现在看到的内存布局如下图所示。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.1.6_memory_layout.png)
