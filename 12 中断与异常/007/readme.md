# *定时器*

## 结构框图

S3C2440定时器功能如下描述。

1. TCNTn寄存器用来计数，每来1个CLK，TCNTn减1
2. TCNTn减到TCMPn时，可以让对应PWM引脚翻转
3. TCNTn继续减1，当减到0时，可以产生中断，也可以让对应PWM引脚再次翻转
4. TCNTn = 0时，可以自动加载初值

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_1_timer_block.png)

根据这个框图，如何使用定时器？

1. 设置时钟
2. 设置初值
3. 加载初值，启动Timer
4. 设置自动加载
5. 中断服务

## 软件配置

### 1. 时钟

从时钟树可以看到，PWM定时器接到了PCLK总线上，而PCLK的总线时钟为50MHz。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_2_timer_clk.png)

从定时器的时钟框图看到，PCLK首先要经过8位预分频，然后再经过5选1的时钟分频，得到最终的定时器时钟。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_3_timer_div.png)

TCFG0寄存器设置预分频值99，TCFG1寄存器设置TIMER0的时钟分频为1/16。

```c
/* 设置TIMER0的时钟 */
/* Timer clk = PCLK / {prescaler value+1} / {divider value} 
                = 50000000/(99+1)/16
                = 31250
    */
TCFG0 = 99;  /* Prescaler 0 = 99, 用于timer0,1 */
TCFG1 &= ~0xf;
TCFG1 |= 3;  /* MUX0 : 1/16 */
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_4_tcon.png)

### 2. 设置初值

通过设置TCNTB0寄存器，来设置Timer0的初值。这里我们设置为0.5s中断一次。

```c
/* 设置TIMER0的初值 */
TCNTB0 = 15625;  /* 0.5s中断一次 */
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_4.png)

### 3. 加载初值+自动装载+自动定时器

加载初值，设置自动装载，然后启动定时器。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_5_TCON.png)

### 4. 设置中断控制器

Timer0没有外设专门的中断开关，所以直接操作中断控制器就可以。

```c
/* 初始化中断控制器 */
void interrupt_init(void)
{
    INTMSK &= ~((1 << 0) | (1 << 2) | (1 << 5));
    INTMSK &= ~(1 << 10); /* enable timer0 int */
}
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_6_intmsk.png)

### 5. 中断服务函数

```c
void handle_irq_c(void)
{
	/* 分辨中断源 */
	int bit = INTOFFSET;

	/* 调用对应的处理函数 */
	if (bit == 0 || bit == 2 || bit == 5)  /* eint0,2,eint8_23 */
	{
		key_eint_irq(bit); /* 处理中断, 清中断源EINTPEND */
	}
	else if (bit == 10)
	{
		timer_irq();
	}

	/* 清中断 : 从源头开始清 */
	SRCPND = (1<<bit);
	INTPND = (1<<bit);	
}

void timer_irq(void)
{
	/* 点灯计数 */
	static int cnt = 0;
	int tmp;

	cnt++;

	tmp = ~cnt;
	tmp &= 7;
	GPFDAT &= ~(7<<4);
	GPFDAT |= (tmp<<4);
}
```

## 改进中断服务函数

### 为什么要改进？

左图是外部中断EINT的interrupt.c，右图是定时器中断TIMER0的interrupt.c。可以看到，每次新增一个中断，我们都要对应的修改interrupt.c文件，加入中断服务函数。

这样做实在是太麻烦了！

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_7_7_compare.png)

### 如何解决？

很简单，把中断服务函数注册进去就好了

#### 1. 注册中断，同时使能中断控制器

```c
void register_irq(int irq, irq_func fp)
{
	irq_array[irq] = fp;

	INTMSK &= ~(1<<irq);
}
```

#### 2. 中断服务函数

```c
void handle_irq_c(void)
{
	/* 分辨中断源 */
	int bit = INTOFFSET;

	/* 调用对应的处理函数 */
	irq_array[bit](bit);
	
	/* 清中断 : 从源头开始清 */
	SRCPND = (1<<bit);
	INTPND = (1<<bit);	
}
```

#### 3. 使用实例-外部中断

```c
/* 初始化按键, 设为中断源 */
void key_eint_init(void)
{
	/* 配置GPIO为中断引脚 */
	GPFCON &= ~((3<<0) | (3<<4));
	GPFCON |= ((2<<0) | (2<<4));   /* S2,S3被配置为中断引脚 */

	GPGCON &= ~((3<<6) | (3<<22));
	GPGCON |= ((2<<6) | (2<<22));   /* S4,S5被配置为中断引脚 */
	

	/* 设置中断触发方式: 双边沿触发 */
	EXTINT0 |= (7<<0) | (7<<8);     /* S2,S3 */
	EXTINT1 |= (7<<12);             /* S4 */
	EXTINT2 |= (7<<12);             /* S5 */

	/* 设置EINTMASK使能eint11,19 */
	EINTMASK &= ~((1<<11) | (1<<19));

	register_irq(0, key_eint_irq);
	register_irq(2, key_eint_irq);
	register_irq(5, key_eint_irq);
}
```

#### 4. 使用实例-定时器中断

```c
void timer_init(void)
{
	/* 设置TIMER0的时钟 */
	/* Timer clk = PCLK / {prescaler value+1} / {divider value} 
	             = 50000000/(99+1)/16
	             = 31250
	 */
	TCFG0 = 99;  /* Prescaler 0 = 99, 用于timer0,1 */
	TCFG1 &= ~0xf;
	TCFG1 |= 3;  /* MUX0 : 1/16 */

	/* 设置TIMER0的初值 */
	TCNTB0 = 15625;  /* 0.5s中断一次 */

	/* 加载初值, 启动timer0 */
	TCON |= (1<<1);   /* Update from TCNTB0 & TCMPB0 */

	/* 设置为自动加载并启动 */
	TCON &= ~(1<<1);
	TCON |= (1<<0) | (1<<3);  /* bit0: start, bit3: auto reload */

	/* 设置中断 */
	register_irq(10, timer_irq);
}
```
