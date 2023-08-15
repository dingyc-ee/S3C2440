# *sdram介绍*

## 1. SDRAM存储结构

SDRAM内部结构：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.1_sdram_logic.png)

S3C2440原理图：接在BANK6上（LnGCS6），数据宽度32bit，总存储容量64M。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.2_sdram_sch.png)

SDRAM存储容量和bank介绍，以及行地址和列地址划分。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.5_bank.png)

SDRAM芯片管脚接线说明

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.6_sdram_pin.png)

SDRAM刷新周期：64ms / 8192 = 7.8us。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.10_sdram_refresh.png)

TRP: 20ns， TRC：70ns。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.11_sdram_trp.png)

列地址时延：2或3个时钟信号。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.14_sdram_latency.png)

## 2. 读数据流程

以下面的汇编代码为例，SDRAM的处理流程：

```asm
// 读取0x30000000地址的值
ldr r0, =0x30000000
ldr r1, [r0]
```

SDRAM的处理流程如下：

1. 发出nGCS6片选信号
2. 根据SDRAM拆分地址：a BANK地址；b 行地址；c 列地址；（怎么拆分？行地址几条线，列地址几条线）
3. 读数据

## 3. 内存控制器说明

32位数据宽度，地址接线从A2开始

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.3_sdram_32bit.png)

BWSCON寄存器：设置数据宽度

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.4_bwscon.png)

BANKCON6寄存器：设置位SDRAM，以及9位列地址。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.7_sdram_bankcon6.png)

行地址和列地址之间的延时：tRCD取20ns。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.8_sdram_trcd.png)

2440的内存控制器接到了HCLK上，时钟配置成100MHz。20ns就是2个时钟周期。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.9_sdram_hclk.png)

REFRESH寄存器：设置刷新周期。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.12_sdram_refresh.png)

BANKSIZE寄存器：设置BANK大小。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.13_sdram_banksize.png)

MRSRB6寄存器，设置列地址时延。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/10.15_sdram_letency.png)

