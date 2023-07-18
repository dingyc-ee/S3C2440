# *Nor Access Cycle*

## 1. NorFlash位宽

S3C2440的启动方式由OM[1:0]决定。00表示Nand启动，01表示Nor启动（Nor数据宽度为16bit），10表示Nor启动（Nor数据宽度为32bit）。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/9.1_bus_width.png)

## 2. 2440开发板接线

可以看到，2440开发板的OM1接地，OM0通过拨码开关选择高低电平。如果是低电平为Nand启动，如果是高电平，则为16bit的Nor启动。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/9.2_om.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/9.3_om.png)

## 3. NorFlash

NorFlash接线如下图所示。16位数据宽度，所以地址线偏移了一位（主控板的ADDR1接到Flash的A0）。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/9.4_norflash.png)

## 4. 测试代码

`init.c`

```c
#include "s3c2440_soc.h"
#include "init.h"

//设置bank0 Tacc
/* 参数如下,传递参数转换为十进制,即0~7
000 = 1  clock    001 = 2 clocks
010 = 3  clocks   011 = 4 clocks
100 = 6  clocks   101 = 8 clocks
110 = 10 clocks   111 = 14 clocks
*/
void bank0_tacc_set(int val)
{
	BANKCON0 = (val << 8);
}
```

`main.c`

```c
#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"
#include "my_printf.h"

int main(int which)
{
    led_init();
    uart0_init();
    unsigned char c;

    my_printf("Enter the Nor Tacc value:\r\n");

    while (1)
    {
        c = getchar();
        putchar(c);

        if (c >= '0' && c <= '7')
        {
            bank0_tacc_set(c - '0');
            while (1)
            {
                led_loop();
            }
        }
        else
        {
            my_printf("Error:Input must range from 0 to 7\r\n");
            my_printf("Enter the Nor Tacc value again:\r\n");
        }
    }
    return 0;
}
```

`Makefile`

*-Ttext 0 -Tdata 0xf40*

```mk

# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = NorAccessCycle
OBJ = start.o lib1funcs.o main.o led.o uart.o my_printf.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 -Tdata 0xf40 $^ -o $@.elf
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