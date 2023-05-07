# *时钟*

## 系统框图

*系统时钟分为3部分。CPU时钟：FCLK；高速时钟：HCLK；低速时钟：PCLK。*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.3_block_diagram.png)

*3种时钟的最大频率：FCLK(400M) HLCK(136M) PCLK(68M)*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.4_frequency.png)

## CLOCK时钟概览

### S3C2440有2个锁相环PLLs：MainPLL(FCLK HCLK PCLK)和UsbPLL(48MHz)。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.5_2plls.png)

### 时钟框图

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.6_clock_block.png)

#### 1 时钟源选择

从左上角可以看到，时钟源有OSC晶振或EXTCLK外部时钟两种。通过OM[3:2]选择后，提供给MPLL和UPLL。具体怎么选择？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.7_om.png)

1. 通过两个引脚OM2和OM3来选择。在RESET复位管脚从低到高上升沿时，锁存使用OM[3:2]的值；
2. 复位后，系统时钟默认使用晶振或外部时钟。只有写入MPLLCON后，才会将MPLL输出作为系统时钟；
3. 开发板原理图上的OM[3:2]都接GND，00表示MPLL和UPLL都使用晶振；

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.8_om32.png)

#### 2 时钟分频

晶振的时钟，经过MPLL出来就是FCLK（CPU使用），经过HDIV分频为HCLK（AHB总线使用），经过PDIV分频为HCLK（APB总线使用）。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.9_div.png)

如何控制分频？

经过上面的分析：就是要控制MPLL、HDIV、PDIV。

#### 3 上电过程

根据芯片手册的描述，上电后要重新配置PLLCON寄存器。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.10_powerup.png)

*如何配置？*

就是设置P M S三个分频器的值。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.11_pms.png)

### 寄存器描述

#### PLLCON

*配置分频*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.12_pllcon.png)

#### CLKCON

*控制某些外设模块的时钟*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.13_clkcon.png)

#### CLKDIVN

*设置分频*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.14_clkdivn.png)

### 注意事项

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.14_asyn_mode.png)

## 代码实验

### 目标频率 FCLK:400MHz, HCLK:100MHz, PCLK:50MHz。

设置寄存器 MPLLCON:FLCK=400M, CLKDIVN:HCLK=FCLK/4, PCLK=HCLK/2。注意：要先设置分频寄存器CLKDIVN，再设置PLLCON寄存器。这样，当PLLCON写入生效时，就是我们想要的频率了。










