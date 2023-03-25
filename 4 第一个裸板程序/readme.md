# _第一个裸板程序_

## _汇编点亮LED_

1. 原理图

*从原理图可以看到，3个LED均为上拉，n_LED中的n表示低电平有效，所以低电平点亮，高电平熄灭。分别接到了CPU芯片GPF4、GPF5、GPF6这3个管脚。*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.1_led1.png)
![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.2_led2.png)

2. S3C2440的GPIO官方文档

2440A芯片有130个GPIO，分为8组。LED所在的组为GPF。可以通过软件来配置GPIO的复用功能，如果没定义复用，则默认为普通的GPIO。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.3_gpio1.png)

GPF组共有8个管脚，分别为GPF0~GPF7。每个管脚还可以复用为外部中断的功能。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.4_gpio2.png)


寄存器总体描述：

+ GPnCON寄存器用来配置GPIO的复用功能。如果用作休眠唤醒，必须设为中断模式。
+ GPnDAT用于数据的读写。
+ GPnUP寄存器配置GPIO的上拉。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.5_gpio3.png)


GPF Port全部寄存器描述：

+ GPFCON： 0x56000050  bit设为01时，IO为输出模式。
+ GPFDAT： 0x56000054  如果IO为输出模式，则管脚电平和对应bit位一致。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.6_gpio4.png)

3. S3C2440的启动流程

存储说明：总共支持8个BANK，每个BANK有128M的空间。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.6_memory1.png)

2440的存储映射由2个管脚：OM0和O01来决定。

+ 当OM[1:0]为01或10时，从ROM（即NorFlash）启动，这要求我们的硬件设计上，NorFlash至少要接到BANK0上面，此时NorFlash起始地址为0x0000 0000，SRAM的起始地址为0x4000 0000。
+ 当OM[1:0]为00时，从NandFlash启动。此时硬件会把Nand的前4K内容复制到SRAM，SRAM的起始地址为0x0000 0000。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.7_memory2.png)

可以看到，JZ2440开发板的OM1接地，OM0设置按键来选择存储介质。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.8_memory3.png)
![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.9_memory4.png)

JZ2440的BANK0作为NorFlash的Boot区域。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.10_memory5.png)

4. Nand启动原理

2440为NAND设计了名为`Steppingstone`的机制，在启动时会把NAND的前4K数据复制到SRAM执行。在通常情况下，Boot启动代码应该要把NAND复制到SDRAM，然后跳转到SDRAM去执行。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/4.11_memory6.png)

