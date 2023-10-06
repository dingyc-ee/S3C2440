# *NorFlash*

## *原理*

NorFlash和NandFlash的差异：

1. NorFlash：操作简单，容量小价格贵。适合保存u-boot、内核、文件系统等代码
2. NandFlash：操作复杂，容量大价格便宜。适合保存APP应用程序

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_1.png)

注意：如果想访问NorFlash，必须把2440设为Nor启动。如果设为Nand启动，NorFlash对CPU不可见不可访问。

## *使用u-boot体验NorFlash*

### 命令表

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_3.png)

NorFlash的读、写、擦除包含2个过程：解锁+发命令。

1. 解锁：向地址555H写入AAH
2. 解锁：向地址2AAH写入55H
3. 发命令：向地址< addr >写入< data >

### 读数据 md.b < addr >

这里读0地址的数据，跟Flash中的bin文件完全一样。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_2.png)

### 写数据 mw.w < addr > < data >

mw.b 单字节写入

mw.w 双字节写入

### 读ID

1. 往地址555H写AAH
2. 往地址2AAH写55H
3. 往地址555H写90H（发命令）
4. 读0地址得到厂家ID：C2H
5. 读1地址得到设备ID：22DAH或225BH

JZ2440开发板的NorFlash为16bit访问，硬件连接线上会错开一位，即2440的A1接到了NorFlash的A0线上。这导致我们2440发出的地址必须左移1位，才是能实际到达NorFlash的地址。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_4.png)

u-boot应该以下操作：

| 步骤 | 描述                            | 命令        |
| ---- | ------------------------------- | ----------- |
| 1    | 往地址AAAH写AAH                 | mw.w aaa aa |
| 2    | 往地址554H写55H                 | mw.w 554 55 |
| 3    | 往地址AAAH写90H（发命令）       | mw.w aaa 90 |
| 4    | 读0地址得到厂家ID：C2H          | md.w 0 1    |
| 5    | 读2地址得到设备ID：22DAH或225BH | md.w 2 1    |

u-boot执行结果如下，厂家ID和设备ID都成功读到了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_5.png)

再去读0地址，发现读到的值竟然不对。为什么？

因为此时还在读ID状态，需要先退出来。怎么退出？执行`Reset命令，往任意地址写入F0H。`

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_6.png)

新增推出读ID状态的过程：

1. 往地址555H写AAH
2. 往地址2AAH写55H
3. 往地址555H写90H（发命令）
4. 读0地址得到厂家ID：C2H
5. 读1地址得到设备ID：22DAH或225BH
6. 退出读ID状态：给任意地址写F0H

| 步骤 | 描述                            | 命令        |
| ---- | ------------------------------- | ----------- |
| 1    | 往地址AAAH写AAH                 | mw.w aaa aa |
| 2    | 往地址554H写55H                 | mw.w 554 55 |
| 3    | 往地址AAAH写90H（发命令）       | mw.w aaa 90 |
| 4    | 读0地址得到厂家ID：C2H          | md.w 0 1    |
| 5    | 读2地址得到设备ID：22DAH或225BH | md.w 2 1    |
| 6    | 退出读ID状态                    | mw.w 0 f0   |

执行完退出命令，再次读状态结果正确。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_7.png)

### JEDEC与CFI模式

NorFlash有两种规范：jedec和cfi(common flash interface)。老式的NorFlash支持jedec，对应的Linux内核`jedec_probe.c`中维护有数组，根据厂家ID和设备ID来匹配对应的型号。现在新的NorFlash都支持cfi规范，cfi包含容量、电压等参数信息。

### 读取CFI信息

如何进入CFI？往地址55H写入98H。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_8.png)

CFI支持哪些命令？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_9.png)

#### 查询Query

| 序号 | 读写操作         | 描述        | 指令       |
| ---- | ---------------- | ----------- | ---------- |
| 1    | 往地址55H写入98H | 进入CFI模式 | mw.w aa 98 |
| 2    | 读10H得到0051    | 'Q'         | md.w 20 1  |
| 3    | 读11H得到0052    | 'R'         | md.w 22 1  |
| 4    | 读12H得到0059    | 'Y'         | md.w 24 1  |
| 5    | 读27H得到容量    | 2^N bytes   | md.w 4e 1  |
| 6    | 退出CFI模式      | 复位命令    | mw.w 0 f0  |

测试结果如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_10.png)

### 写入NorFlash

注意：我们写NorFlash时不能破坏u-boot，由于u-boot大小没有超过1M，所以可以向1M地址处写入数据。从结果可以看到，内存可以直接写，但NorFlash不能直接写入。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_11.png)

NorFlash写指令如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_12.png)

| 步骤 | 读写操作        | 描述       | 指令             |
| ---- | --------------- | ---------- | ---------------- |
| 1    | 往地址555H写AAH | 解锁       | mw.w aaa aa      |
| 2    | 往地址2AAH写55H | 解锁       | mw.w 554 55      |
| 3    | 往地址555H写A0H | 发出写命令 | mw.w aaa a0      |
| 4    | 往地址PA写PD    | 写数据     | mw.w 100000 1234 |

测试结果如下，数据正确写入。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_13.png)

### 擦除NorFlash

| 步骤 | 读写操作           | 描述         | 指令           |
| ---- | ------------------ | ------------ | -------------- |
| 1    | 往地址555H写AAH    | 解锁         | mw.w aaa aa    |
| 2    | 往地址2AAH写55H    | 解锁         | mw.w 554 55    |
| 3    | 往地址555H写80H    | 发出擦除命令 | mw.w aaa 80    |
| 4    | 往地址555H写AAH    | 再次解锁     | mw.w aaa aa    |
| 5    | 往地址2AAH写55H    | 再次解锁     | mw.w 554 55    |
| 6    | 往地址100000H写30H | 擦除扇区     | mw.w 100000 30 |

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_14.png)

擦除测试的结果如下所示。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_15.png)

## NorFlash编程识别

1. 编译程序时加上： -march=armv4
   
   否则
```c
volatile unsigned shord *p = xxx;
*p = val;   // 会被拆分成2个strb操作
```

2. 把timer中断去掉

否则：测试nor时进入CFI等模式时，如果发生了中断，cpu必定读nor，那么读不到正确的指令，导致程序崩溃

## 测试代码

```c
#include "my_printf.h"
#include "string_utils.h"

#define NOR_FLASH_BASE 0 /* jz2440, nor-->cs0, base addr = 0 */

/* 比如:   55H 98
 * 本意是: 往(0 + (0x55)<<1)写入0x98
 */
void nor_write_word(unsigned int base, unsigned int offset, unsigned int val)
{
	volatile unsigned short *p = (volatile unsigned short *)(base + (offset << 1));
	*p = val;
}

/* offset是基于NOR的角度看到 */
void nor_cmd(unsigned int offset, unsigned int cmd)
{
	nor_write_word(NOR_FLASH_BASE, offset, cmd);
}

unsigned int nor_read_word(unsigned int base, unsigned int offset)
{
	volatile unsigned short *p = (volatile unsigned short *)(base + (offset << 1));
	return *p;
}

unsigned int nor_dat(unsigned int offset)
{
	return nor_read_word(NOR_FLASH_BASE, offset);
}

void wait_ready(unsigned int addr)
{
	unsigned int val;
	unsigned int pre;

	pre = nor_dat(addr >> 1);
	val = nor_dat(addr >> 1);
	while ((val & (1 << 6)) != (pre & (1 << 6)))
	{
		pre = val;
		val = nor_dat(addr >> 1);
	}
}

/* 进入NOR FLASH的CFI模式
 * 读取各类信息
 */
void do_scan_nor_flash(void)
{
	char str[4];
	unsigned int size;
	int regions, i;
	int region_info_base;
	int block_addr, blocks, block_size, j;
	int cnt;

	int vendor, device;

	/* 打印厂家ID、设备ID */
	nor_cmd(0x555, 0xaa); /* 解锁 */
	nor_cmd(0x2aa, 0x55);
	nor_cmd(0x555, 0x90); /* read id */
	vendor = nor_dat(0);
	device = nor_dat(1);
	nor_cmd(0, 0xf0); /* reset */

	nor_cmd(0x55, 0x98); /* 进入cfi模式 */

	str[0] = nor_dat(0x10);
	str[1] = nor_dat(0x11);
	str[2] = nor_dat(0x12);
	str[3] = '\0';
	printf("str = %s\n\r", str);

	/* 打印容量 */
	size = 1 << (nor_dat(0x27));
	printf("vendor id = 0x%x, device id = 0x%x, nor size = 0x%x, %dM\n\r", vendor, device, size, size / (1024 * 1024));

	/* 打印各个扇区的起始地址 */
	/* 名词解释:
	 *    erase block region : 里面含有1个或多个block, 它们的大小一样
	 * 一个nor flash含有1个或多个region
	 * 一个region含有1个或多个block(扇区)

	 * Erase block region information:
	 *    前2字节+1    : 表示该region有多少个block
	 *    后2字节*256  : 表示block的大小
	 */

	regions = nor_dat(0x2c);
	region_info_base = 0x2d;
	block_addr = 0;
	printf("Block/Sector start Address:\n\r");
	cnt = 0;
	for (i = 0; i < regions; i++)
	{
		blocks = 1 + nor_dat(region_info_base) + (nor_dat(region_info_base + 1) << 8);
		block_size = 256 * (nor_dat(region_info_base + 2) + (nor_dat(region_info_base + 3) << 8));
		region_info_base += 4;

		//		printf("\n\rregion %d, blocks = %d, block_size = 0x%x, block_addr = 0x%x\n\r", i, blocks, block_size, block_addr);

		for (j = 0; j < blocks; j++)
		{
			/* 打印每个block的起始地址 */
			// printf("0x%08x ", block_addr);
			printHex(block_addr);
			putchar(' ');
			cnt++;
			block_addr += block_size;
			if (cnt % 5 == 0)
				printf("\n\r");
		}
	}
	printf("\n\r");
	/* 退出CFI模式 */
	nor_cmd(0, 0xf0);
}

void do_erase_nor_flash(void)
{
	unsigned int addr;

	/* 获得地址 */
	printf("Enter the address of sector to erase: ");
	addr = get_uint();

	printf("erasing ...\n\r");
	nor_cmd(0x555, 0xaa); /* 解锁 */
	nor_cmd(0x2aa, 0x55);
	nor_cmd(0x555, 0x80); /* erase sector */

	nor_cmd(0x555, 0xaa); /* 解锁 */
	nor_cmd(0x2aa, 0x55);
	nor_cmd(addr >> 1, 0x30); /* 发出扇区地址 */
	wait_ready(addr);
}

void do_write_nor_flash(void)
{
	unsigned int addr;
	unsigned char str[100];
	int i, j;
	unsigned int val;

	/* 获得地址 */
	printf("Enter the address of sector to write: ");
	addr = get_uint();

	printf("Enter the string to write: ");
	gets(str);

	printf("writing ...\n\r");

	/* str[0],str[1]==>16bit
	 * str[2],str[3]==>16bit
	 */
	i = 0;
	j = 1;
	while (str[i] && str[j])
	{
		val = str[i] + (str[j] << 8);

		/* 烧写 */
		nor_cmd(0x555, 0xaa); /* 解锁 */
		nor_cmd(0x2aa, 0x55);
		nor_cmd(0x555, 0xa0); /* program */
		nor_cmd(addr >> 1, val);
		/* 等待烧写完成 : 读数据, Q6无变化时表示结束 */
		wait_ready(addr);

		i += 2;
		j += 2;
		addr += 2;
	}

	val = str[i];
	/* 烧写 */
	nor_cmd(0x555, 0xaa); /* 解锁 */
	nor_cmd(0x2aa, 0x55);
	nor_cmd(0x555, 0xa0); /* program */
	nor_cmd(addr >> 1, val);
	/* 等待烧写完成 : 读数据, Q6无变化时表示结束 */
	wait_ready(addr);
}
void do_read_nor_flash(void)
{
	unsigned int addr;
	volatile unsigned char *p;
	int i, j;
	unsigned char c;
	unsigned char str[16];

	/* 获得地址 */
	printf("Enter the address to read: ");
	addr = get_uint();

	p = (volatile unsigned char *)addr;

	printf("Data : \n\r");
	/* 长度固定为64 */
	for (i = 0; i < 4; i++)
	{
		/* 每行打印16个数据 */
		for (j = 0; j < 16; j++)
		{
			/* 先打印数值 */
			c = *p++;
			str[j] = c;
			printf("%02x ", c);
		}

		printf("   ; ");

		for (j = 0; j < 16; j++)
		{
			/* 后打印字符 */
			if (str[j] < 0x20 || str[j] > 0x7e) /* 不可视字符 */
				putchar('.');
			else
				putchar(str[j]);
		}
		printf("\n\r");
	}
}

void nor_flash_test(void)
{
	char c;

	while (1)
	{
		/* 打印菜单, 供我们选择测试内容 */
		printf("[s] Scan nor flash\n\r");
		printf("[e] Erase nor flash\n\r");
		printf("[w] Write nor flash\n\r");
		printf("[r] Read nor flash\n\r");
		printf("[q] quit\n\r");
		printf("Enter selection: ");

		c = getchar();
		printf("%c\n\r", c);

		/* 测试内容:
		 * 1. 识别nor flash
		 * 2. 擦除nor flash某个扇区
		 * 3. 编写某个地址
		 * 4. 读某个地址
		 */
		switch (c)
		{
		case 'q':
		case 'Q':
			return;
			break;

		case 's':
		case 'S':
			do_scan_nor_flash();
			break;

		case 'e':
		case 'E':
			do_erase_nor_flash();
			break;

		case 'w':
		case 'W':
			do_write_nor_flash();
			break;

		case 'r':
		case 'R':
			do_read_nor_flash();
			break;
		default:
			break;
		}
	}
}
```

```mk
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = NorFlash
OBJ = start.o uart.o init.o main.o led.o exception.o interrupt.o timer.o my_printf.o nor_flash.o string_utils.o lib1funcs.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -T sdram.lds $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

# 如果不加-march=armv4选项，对Nor的16bit写入会被编译成2次strb写入，导致Nor写入出错。-march=armv4来自u-boot
%.o: %.c
	arm-linux-gcc -march=armv4 -c -o $@ $<

%.o: %.S
	arm-linux-gcc -march=armv4 -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

## 测试结果

### 识别

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_16.png)

### 读写

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_17.png)

### 擦除

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_18.png)
