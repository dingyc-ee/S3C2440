# *NandFlash*

## *控制信号*

NandFlash原理图。可以看到，NAND和S3C2440之间只有数据线，怎么传输地址？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_1.png)

Nand Flash将地址数据，读写数据，命令数据全部放在了8条数据线上（上图中的LDATA0-7），然后使用控制信号CLE、ALE、WE、RE来区分数据线上的数据。

1. 当ALE为高电平时，传输的是地址
2. 当CLE为高电平时，传输的是命令
3. 当ALE和CLE都为低电平时，传输的是数据
4. CE（chip enable）片选信号
5. R/B：Flash当前状态引脚（高 -> 空闲或者就绪，低 -> 忙）
6. RE/WE：读写使能
7. WP：写保护引脚

## *控制原理*

怎么操作NAND FLASH？根据芯片手册，一般过程是：

1. 发出命令
2. 发出地址
3. 写数据/读数据

以读ID为例。先发命令90h，再发地址00h，然后读取数据。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_2.png)

S3C2440内置了NAND控制器。我们只需要设置寄存器，2440芯片就能自动的发出对应的控制信号。

|  操作 | NAND FLASH | S3C2440 |
|  ---- | ---- | ---- |
| 发命令  | 选中芯片<br>CLE设为高电平<br>再DATA0~DATA7输出命令值<br>发出一个写脉冲 | NFCMMD=命令值 |
| 发地址  | 选中芯片<br>ALE设为高电平<br>再DATA0~DATA7输出地址值<br>发出一个写脉冲 | NFADDR=地址值 |
| 发数据  | 选中芯片<br>ALE,CLE设为低电平<br>再DATA0~DATA7输出数据值<br>发出一个写脉冲 | NFDATA=数据值 |
| 读数据  | 选中芯片<br>发出读脉冲<br>读DATA0~DATA7的数据 | val=NFDATA |

## *uboot操作nand*

NAND的操作，总体来看和NOR类似，也是发命令+（发地址）+读写数据。

### 读ID

|  操作 | S3C2440 | u-boot |
|  ---- | ---- | ---- |
| 选中 | NFCONT的bit1设为0 | md.l 0x4e000004 1<br>mw.l 0x4e000004 1 |
| 发出命令0x90 | NFCMMD=0x90 | mw.b 0x4e000008 0x90 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 读数据得到0xec | val=NFDATA | md.b 0x4e000010 1 |
| 读数据得到device code | val=NFDATA | md.b 0x4e000010 1 |
| 退出读ID状态（复位） | NFCMMD=0xff | mw.b 0x4e000008 0xff |

实测效果：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_3.png)

### 读内容：读0地址的数据

使用uboot命令：nand dump 0

|  操作 | S3C2440 | u-boot |
|  ---- | ---- | ---- |
| 选中 | NFCONT的bit1设为0 | md.l 0x4e000004 1<br>mw.l 0x4e000004 1 |
| 发出命令0x00 | NFCMMD=0x00 | mw.b 0x4e000008 0x00 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 发出地址0x00 | NFADDR=0x00 | mw.b 0x4e00000c 0x00 |
| 发出命令0x30 | NFCMMD=0x00 | mw.b 0x4e000008 0x30 |
| 读数据得到0x17 | val=NFDATA | md.b 0x4e000010 1 |
| 读数据得到0x00 | val=NFDATA | md.b 0x4e000010 1 |
| 读数据得到0x00 | val=NFDATA | md.b 0x4e000010 1 |
| 读数据得到0xea | val=NFDATA | md.b 0x4e000010 1 |
| 退出读状态（复位） | NFCMMD=0xff | mw.b 0x4e000008 0xff |

实测效果：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_4.png)

## 初始化时序

### S3C2440控制NAND FLASH

S3C2440仅支持软件模式访问，通过操作寄存器，可以对NAND Flash发出时序信号。

1. 写命令寄存器：生成NAND Flash发命令时序信号
2. 写地址寄存器：生成NAND Flash发地址时序信号
3. 写数据寄存器：生成NAND Flash写数据时序信号
4. 读数据寄存器：生成NAND Flash读数据时序信号

*在软件模式中，必须使用查询或中断来检测RnB状态输入引脚。*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_8.png)

### 存储芯片的编程

| 存储芯片的编程 | NAND FLASH                 |
| -------------- | -------------------------- |
| 初始化         | 主控芯片的NAND flash控制器 |
| 识别           | 读取ID                     |
| 读             | 一次读取一个页（page）     |
| 写             | 一次写一个页（page）       |
| 擦除           | 一次擦除一个块（block）    |

如果能读取到ID，说明NAND FLASH是正常工作的。

### 初始化

下图是NAND FLASH的控制时序。HCLK = 100Mhz`/* 设置MPLL, FCLK : HCLK : PCLK = 400m : 100m : 50m */`，一个脉冲周期为12ns。

TCALS ：发出CLE/ALE信号后，过多久再发出WE信号。在右图NAND的芯片手册中，CLE和WE的时间间隔为Tcls-Twp = 12 - 12 = 0，ALE和WE的时间间隔为Tals-Twp = 12 - 12 = 0。所以这款NAND芯片的TCALS可以为0，即地址/命令/写使能可以同时发出。

TWRPH0 ：写使能信号WE的持续时间。在右图NAND的芯片手册中，Twp最小是12ns，`Duration(最小12ns) = HCLK(10ns) × (TWRPH0 + 1)`，那么TWRPH0可以设置为1。

TWRPH0 ：WE写使能释放后，过多久可以释放CLE/ALE信号。在右图NAND的芯片手册中，即Tclh和Talh，均为5ns。`Duration(最小5ns) = HCLK(10ns) × (TWRPH1 + 1)`，那么TWRPH0可以设置为0。

命令Command/地址Addr持续时间：在右图NAND的芯片手册中，发出Command或Addr后，最少要维持Tds+Tdh=12+5=17ns的时间，所以我们实际在发出命令/地址时，要给一个短延时。

<img src="https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_5.png" style="zoom:100%;" />

```c
void nand_init(void)
{
    #define  TACLS   0
    #define  TWRPH0  1
    #define  TWRPH1  0
	/*设置NAND FLASH的时序*/
	NFCONF = (TACLS<<12) | (TWRPH0<<8) | (TWRPH1<<4);
	/*使能NAND FLASH控制器,初始化ECC，禁止片选*/
	NFCONT = (1<<4) | (1<<1) | (1<<0);
}
```

### 读ID

读ID时序图如下所示，我们应该如何操作他？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_6.png)

#### 1. 片选

一般是先拉低片选信号CE，只有片选使能后才能进行后面的操作。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_7.png)

```c
void nand_select(void)
{
	/*使能片选*/
	NFCONT &=~(1<<1);
}

void nand_deselect(void)
{
	/*禁止片选*/
	NFCONT |= (1<<1);
}
```

之后应该怎么做？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_9.png)

从时序图上看，片选信号CE先使能。拉高CLE（表示当前是命令），拉低WE（表示方向是写），然后IO线上发出命令0x90，拉高WE，此时NAND会保存IO线上的命令，再拉低CLE，表示命令结束。这么一个复杂的过程，能不能简化？

前面提到，我们写命令寄存器，2440就会自动产生发命令的时序信号。那就简单了，我们向NFCCMD寄存器写0x90，就能完成发命令操作。同时，出Command或Addr后，最少要维持Tds+Tdh=12+5=17ns的时间，我们需要给一个短延时。

#### 发命令

向NFCCMD寄存器写命令，并短延时来维持至少17ns。

```c
void nand_cmd(unsigned char cmd)
{
	volatile int i;
	NFCCMD = cmd;
	for(i=0; i<10; i++);
}
```

#### 发地址

向NFADDE寄存器写地址，并短延时来维持至少17ns。

```c
void nand_addr_byte(unsigned char addr)
{
	volatile int i;
	NFADDR = addr;
	for(i=0; i<10; i++);
}
```

#### 读数据

直接读NFDATA寄存器，S3C2440自动产生读数据的时序信号。

```c
unsigned char nand_data(void)
{
	return	NFDATA;
}
```

### 读ID的代码

```c
void nand_chip_id(void)
{ 
	unsigned char buf[5]={0};
	
	nand_select(); 
	nand_cmd(0x90);
	nand_addr_byte(0x00);

	buf[0] = nand_data();
	buf[1] = nand_data();	
	buf[2] = nand_data();
	buf[3] = nand_data();
	buf[4] = nand_data();	
	nand_deselect(); 	
    
    printf("maker   id  = 0x%x\n\r",buf[0]);
	printf("device  id  = 0x%x\n\r",buf[1]);	
	printf("3rd byte    = 0x%x\n\r",buf[2]);		
	printf("4th byte    = 0x%x\n\r",buf[3]);			
	printf("5th byte    = 0x%x\n\r",buf[4]);
}
```

实测效果：

可以看到，除第4个字节有差异外，其他字节EC DA 10 XX 44均相同，说明我们读ID操作成功了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_10.png)

#### 读页/块大小

第4个字节为什么有差异，代表了什么？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_11.png)

这就是NAND FLASH读ID后，第4个字节的描述。结束如下：

1. 芯片手册中的0x15，表示最小串行访问时间为50ns/30ns。实际读到的0x95，表示最小串行访问时间为25ns。不过这个参数一般用不到
2. Page Size：bit0~bit1表示页大小。01表示2KB
3. Block Size：bit4~bit5表示块大小。01表示128KB

我们可以写代码打印页大小和块大小：

```c
void nand_chip_id(void)
{ 
	unsigned char buf[5]={0};
	
	nand_select(); 
	nand_cmd(0x90);
	nand_addr_byte(0x00);

	buf[0] = nand_data();
	buf[1] = nand_data();	
	buf[2] = nand_data();
	buf[3] = nand_data();
	buf[4] = nand_data();	
	nand_deselect(); 	

	printf("maker   id  = 0x%x\n\r",buf[0]);
	printf("device  id  = 0x%x\n\r",buf[1]);	
	printf("3rd byte    = 0x%x\n\r",buf[2]);		
	printf("4th byte    = 0x%x\n\r",buf[3]);			
	printf("page  size  = %d kb\n\r",1  <<  (buf[3] & 0x03));	
	printf("block size  = %d kb\n\r",64 << ((buf[3] >> 4) & 0x03));	
	printf("5th byte    = 0x%x\n\r",buf[4]);
}
```

实测效果：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_12.png)

# *读数据*

NAND Flash内部结构图。可以看到，1个块（block）包括64个页（page），而每个页（page）包括2048字节的数据区域+64字节的OOB校验区。访问NAND时，要先发出Col列地址，再发出Row行地址。这些地址从哪来？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_13.png)

NAND Flash布局如下图所示。每一行表示一个Page，每一列表示Page中的第几个数据。所以我们要读取某个地址的数据时，要计算出Page（行地址）和Col（列地址），`列地址范围：0~2047`，然后依次发出这些地址。OOB区域CPU不可访问，是NAND Flash自己用来纠错的。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_14.png)

读数据时序分析：

1. 拉低片选信号CE
2. 发出0x00命令
3. 发出2次列地址
4. 发出3次Page行地址
5. 发出0x30命令
6. R/B管脚等待Busy，Busy期间为低电平
7. 开始读数据

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_15.png)

*注意：NAND一次最多读取1个Page的数据，超过了要重新发出这些命令。*

NAND读取代码如下：

```c
void nand_read(unsigned int addr, unsigned char *buf, unsigned int len)
{
	int i = 0;
	int page = addr / 2048;
	int col  = addr & (2048 - 1);
	
	nand_select(); 

	while (i < len)
	{
		/* 发出00h命令 */
		nand_cmd(00);

		/* 发出地址 */
		/* col addr */
		nand_addr_byte(col & 0xff);
		nand_addr_byte((col>>8) & 0xff);

		/* row/page addr */
		nand_addr_byte(page & 0xff);
		nand_addr_byte((page>>8) & 0xff);
		nand_addr_byte((page>>16) & 0xff);

		/* 发出30h命令 */
		nand_cmd(0x30);

		/* 等待就绪 */
		wait_ready();

		/* 读数据 */
		for (; (col < 2048) && (i < len); col++)
		{
			buf[i++] = nand_data();			
		}
		if (i == len)
			break;

		col = 0;
		page++;
	}
	
	nand_deselect(); 	
}
```

如何检测Busy？*实际上就是读R/B（Ready/Busy）管脚电平。高电平为就绪，低电平为忙碌。*

2440的NASTAT状态寄存器，可以读RnB管脚的电平。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_16.png)

检测NAND忙碌的代码，低电平表示忙碌，一直等待。

```c
void wait_ready(void)
{
	while (!(NFSTAT & 1));
}
```

既然我们已经能读取NAND的数据了，那应该就能够支持NAND上电启动。怎么做？

*在代码重定位函数中，区分是Nor启动还是Nand启动。如果是Nor启动直接读取，如果是Nand启动，先初始化Nand，再从Nand读数据到SDRAM。*

```c
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
	int len;

	len = ((int)&__bss_start) - ((int)&__code_start);

	if (isBootFromNorFlash())
	{
		while (dest < end)
		{
			*dest++ = *src++;
		}
	}
	else
	{
		nand_init();
		nand_read(src, dest, len);
	}
}
```

如何判断是Nor还是Nand启动呢？很简单，往0地址写值再读回来，如果相等证明是Nand启动，不相等则为Nor启动。

```c
int isBootFromNorFlash(void)
{
	volatile unsigned int *p = (volatile unsigned int *)0;
	unsigned int val = *p;

	*p = 0x12345678;
	if (*p == 0x12345678)
	{
		/* 写成功, 对应nand启动 */
		*p = val;
		return 0;
	}
	else
	{
		return 1;
	}
}
```

*<font color=red>注意：由于Nand启动时，CPU会从NAND只拷贝前4KB来执行。因此，我们的启动文件start.S、SDRAM初始化+代码重定位文件init.c、中断处理interrupt.c、nand操作nand_flash.c必须处于前4K的代码中。</font>*怎么做？很简单，把这几个文件放在Makefile的最前面。

```makefile
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = NandFlash
OBJ = start.o init.o interrupt.o nand_flash.o uart.o main.o led.o exception.o timer.o my_printf.o nor_flash.o string_utils.o lib1funcs.o

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

编译烧写到NAND Flash，选择NAND启动，测试结果如下。能够正常启动，，也能识别到NAND芯片ID。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_17.png)

# *擦除block*

NAND Flash只能以block块（128KB）为单位，来进行擦除。擦除时序如下：

1. 发出0x60命令
2. 发出3次行地址（Page号）
3. 发出0xD0命令
4. 等待Busy位擦除完成

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_18.png)

擦除NAND block代码：

```c
int nand_erase(unsigned int addr, unsigned int len)
{
	int page = addr / 2048;

	if (addr & (0x1FFFF))
	{
		printf("nand_erase err, addr is not block align\n\r");
		return -1;
	}
	
	if (len & (0x1FFFF))
	{
		printf("nand_erase err, len is not block align\n\r");
		return -1;
	}
	
	nand_select(); 

	while (1)
	{
		page = addr / 2048;
		
		nand_cmd(0x60);
		
		/* row/page addr */
		nand_addr_byte(page & 0xff);
		nand_addr_byte((page>>8) & 0xff);
		nand_addr_byte((page>>16) & 0xff);

		nand_cmd(0xD0);

		wait_ready();

		len -= (128*1024);
		if (len == 0)
			break;
		addr += (128*1024);
	}
	
	nand_deselect(); 	
	return 0;
}
```

# *写操作*

NAND Flash的写操作，以页（Page）为单位。操作流程如下：

1. 发出0x80命令
2. 发出5次地址
3. 发出数据
4. 发出0x10命令
5. 等待Busy

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_19.png)

写NAND Flash操作代码：

```c
void nand_write(unsigned int addr, unsigned char *buf, unsigned int len)
{
	int page = addr / 2048;
	int col  = addr & (2048 - 1);
	int i = 0;

	nand_select(); 

	while (1)
	{
		nand_cmd(0x80);

		/* 发出地址 */
		/* col addr */
		nand_addr_byte(col & 0xff);
		nand_addr_byte((col>>8) & 0xff);
		
		/* row/page addr */
		nand_addr_byte(page & 0xff);
		nand_addr_byte((page>>8) & 0xff);
		nand_addr_byte((page>>16) & 0xff);

		/* 发出数据 */
		for (; (col < 2048) && (i < len); )
		{
			nand_w_data(buf[i++]);
		}
		nand_cmd(0x10);
		wait_ready();

		if (i == len)
			break;
		else
		{
			/* 开始下一个循环page */
			col = 0;
			page++;
		}
		
	}
	
	nand_deselect(); 	
}
```

# *NAND Flash读写擦除测试*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/14_20.png)