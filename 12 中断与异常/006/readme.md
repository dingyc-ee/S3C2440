# *按键中断程序*

## 中断处理理论

### 1. 中断初始化

在前面关于中断举例中，远处声音的来源有多种（猫叫、门铃、哭声），传入耳朵，再由耳朵传入大脑。整个过程涉及：声音来源、耳朵、大脑。

为了确保实例中母亲看书的过程能被打断，我们必须确保：

1. 声音来源，能够正常发出声音
2. 耳朵没有聋
3. 脑袋没有傻

类比到嵌入式系统，我们需要：

1. 设置中断源，让他可以发出中断信号
2. 设置中断控制器，让他可以把中断发给CPU
3. 设置CPU，让他能处理中断（CPSR里有I位，中断总开关）

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_1_init.png)

### 2. 处理时，要分辨中断源

### 3. 处理完清中断

## 外部中断

### 1. 启动文件

由于CPU一上电就是SVC管理模式，所以我们在重定位后给他切换到了USR模式。中断初始化的这3步，都是在切到USR模式之后进行的。

3. 清除CPSR的IRQ禁止位，使能CPU中断总开关

```as
	bl sdram_init	

	/* 重定位text, rodata, data段整个程序 */
	bl copy2sdram

	/* 清除BSS段 */
	bl clean_bss

	/* 复位之后，CPU处于svc模式 */
	/* 现在，切换到usr模式 */
	mrs r0, cpsr		/* 读出cpsr */
	bic r0, r0, #0xf	/* 修改M4-M0为0b10000，进入usr模式 */
	bic r0, r0, #(1<<7)	/* 清除I位，使能中断 */
	msr cpsr, r0
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_2_fiq_bit.png)

2+1 先初始化中断控制器，再初始化按键中断

```as
* 复位之后，CPU处于svc模式 */
	/* 现在，切换到usr模式 */
	mrs r0, cpsr		/* 读出cpsr */
	bic r0, r0, #0xf	/* 修改M4-M0为0b10000，进入usr模式 */
	bic r0, r0, #(1<<7)	/* 清除I位，使能中断 */
	msr cpsr, r0

	/* 设置sp_usr */
	ldr sp, =0x33f00000

	/* 初始化串口，还没进入main函数就发生了und异常，所以要先初始化uart */
	ldr pc, =sdram
sdram:
	bl uart0_init

	/* 故意加入一条未定义指令 */
und_code:
	.word 0xdeadc0de

	swi 0x123				/* 执行此命令，触发swi异常，进入0x8地址执行 */

	bl interrupt_init		/* 初始化中断控制器 */
	bl key_eint_init		/* 初始化按键，设为中断源 */

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
```

### 2. 外部中断初始化

从原理图上可以看到，4个外部按键都是上拉。

EINT0 -> GPF0

EINT2 -> GPF2

EINT11 -> GPG3

EINT19 -> GPG11

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_4_sch.png)

1. 配置GPIO为中断管脚

```c
/* 配置GPIO为中断管脚 */
GPFCON &= ~((3 << 0) | (3 << 4));
GPFCON |= (2 << 0) | (2 << 4); // S2,S3被配置为中断引脚

GPGCON &= ~((3 << 6) | (3 << 11));
GPGCON |= ((2 << 6) | (2 << 11)); // S4,S5被配置为中断引脚
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_5.png)

2. 配置中断触发方式：双边沿触发

```c
/* 设置中断触发方式: 双边沿触发 */
EXTINT0 |= (7 << 0) | (7 << 8); /* S2,S3 */
EXTINT1 |= (7 << 12);           /* S4 */
EXTINT2 |= (7 << 12);           /* S5 */
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_6.png)

3. 设置外部中断屏蔽寄存器

注意看，EINT[0-3]没有屏蔽寄存器，说明这4个中断信号是直接发给中断控制器的。

```c
/* 设置EINTMASK使能eint11,19 */
EINTMASK &= ~((1 << 11) | (1 << 19));
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_7_eint_mask.png)

4. 中断源读取

当发生了外部中断后，我们要进一步读取中断源来分辨是哪个GPIO产生的中断，读取完成后还要清除。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_8_pend.png)

为什么EINT[0-3]没有？如果EINT[0-3]发生了中断，我们该如何知道？

S3C2440的中断源如下所示。可以看到，EINT[0-3]直通中断控制器，CPU可以直接读取到中断源。而如果发生了其他外部中断（如EINT11），CPU会产生EINT[8-23]中断，说明8~23这其中有管脚发生了中断。具体是哪一个，需要进一步读EINTPEND寄存器。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_9_int_get.png)

外部中断初始化如下：

```c
void key_eint_init(void)
{
    /* 配置GPIO为中断管脚 */
    GPFCON &= ~((3 << 0) | (3 << 4));
    GPFCON |= (2 << 0) | (2 << 4); // S2,S3被配置为中断引脚

    GPGCON &= ~((3 << 6) | (3 << 11));
    GPGCON |= ((2 << 6) | (2 << 11)); // S4,S5被配置为中断引脚

    /* 设置中断触发方式: 双边沿触发 */
    EXTINT0 |= (7 << 0) | (7 << 8); /* S2,S3 */
    EXTINT1 |= (7 << 12);           /* S4 */
    EXTINT2 |= (7 << 12);           /* S5 */

    /* 设置EINTMASK使能eint11,19 */
    EINTMASK &= ~((1 << 11) | (1 << 19));
}
```

### 3. 中断控制器

#### 中断控制器框架

1. 外部中断EINT没有子控制器，中断请求会直达SRCPND寄存器。有多个中断发生时，这个寄存器多个bit位都会置1
2. INTMSK寄存器，用于屏蔽中断。为0时中断正常服务，为1时该中断禁止。SRCPND的中断源经过INTMASK寄存器后，仍有可能多个bit位为1。此时表示CPU应该处理的有这些中断请求
3. 优先级寄存器，用于仲裁。有多个请求中断同时经过INTMSK寄存器后，我们先处理哪一个？由优先级决定
4. INTPND寄存器，表示当前正在服务的中断请求，同一时刻只能处理一个中断

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_10_block.png)

#### 中断控制寄存器

1. SRCPND寄存器

只要中断源产生了中断，就会置位SRCPND寄存器的对应位。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_11_srcpend.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_12_srcpend.png)

2. INTMOD寄存器

设置中断为IRQ模式或FIQ模式。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_13_mode.png)

3. INTMSK寄存器

用来使能或屏蔽中断。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_14_mask.png)

4. INTPND寄存器

表示当前要处理的唯一中断。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_15_intpnd.png)

5. INTOFFSET寄存器

跟INTPND寄存器功能差不多。只不过INTPND是通过bit位表示中断，而offset可以直接读到中断。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_6_16_intoffset.png)

总结：我们只需要设置INTMSK寄存器，而SRCPND和INTPND是处理中断时采取清除的。

```c
/* 初始化中断控制器 */
void interrupt_init(void)
{
    INTMSK &= ~((1 << 0) | (1 << 2) | (1 << 5));
}
```

## 实际代码

### 1. IRQ异常处理函数

start.S启动文件中，在IRQ异常的跳转地址处，放置IRQ异常服务函数。

```as
.text
.global _start

_start:
	b reset				/* vector 0 : reset */
	/* 注意，这里不是ldr pc, =und_addr，表示去und_addr这个地址读内存
	 * ldr pc, =und_addr，即ldr pc, =0x3000 0008
	 * ldr pc, un_addr，即ldr pc, [0x3000 0008]
	 */
	ldr pc, und_addr	/* vector 0x04 : und */
	ldr pc, swi_addr	/* vector 0x08 : swi */
	b halt				/* vector 0x0c : prefetch abort */
	b halt				/* vector 0x10 : data abort */
	b halt				/* vector 0x14 : reserved */
	ldr pc, irq_addr	/* vector 0x18 : irq */
	b halt				/* vector 0x1c : fiq */

und_addr: .word do_und
swi_addr: .word do_swi
irq_addr: .word do_irq

do_irq:
	/* sp_irq未设置，先设置它 */
	ldr sp, =0x33d00000		/* 0x3000 0000 + 64M，指向64M SDRAM的最高地址 */

	/* 保存现场 */
	/* 在irq异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生irq异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	/* 发生IRQ异常时，该指令已经执行完了，所以lr-4是异常处理完之后的返回地址 */
	sub lr, lr, #4
	stmdb sp!, {r0-r12, lr} 

	/* 处理irq异常 */
	bl handle_irq_c

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */
```

### 2. 中断服务函数

下面这是通用的中断服务函数处理程序。分为3个过程：

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

	/* 清中断 : 从源头开始清 */
	SRCPND = (1<<bit);
	INTPND = (1<<bit);	
}
```

1. 分辨中断源

```c
int bit = INTOFFSET;
```

2. 调用对应的处理函数

注意：这里只处理外部EINT中断的功能。之前提到除EINT[0-3]外，如果发生了其他外部中断，要去进一步读取EINTPND寄存器来分辨，读取完后清除。

所以，这里不同硬件的中断服务函数，需要按实际情况来清除自己特有的寄存器。

```c
if (bit == 0 || bit == 2 || bit == 5)  /* eint0,2,eint8_23 */
{
    key_eint_irq(bit); /* 处理中断, 清中断源EINTPEND */
}
```

3. 清中断：从源头开始清

注意：这里只清除了中断控制器通用的PND寄存器。各个不同硬件中断源的PND寄存器，由处理函数来清除。

```c
SRCPND = (1<<bit);
INTPND = (1<<bit);	
```

4. 外部中断处理函数

```c
/* 读EINTPEND分辨率哪个EINT产生(eint4~23)
 * 清除中断时, 写EINTPEND的相应位
 */

void key_eint_irq(int irq)
{
    unsigned int val = EINTPEND;
    unsigned int val1 = GPFDAT;
    unsigned int val2 = GPGDAT;

    if (irq == 0) /* eint0 : s2 控制 D12 */
    {
        if (val1 & (1 << 0)) /* s2 --> gpf6 */
        {
            /* 松开 */
            GPFDAT |= (1 << 6);
        }
        else
        {
            /* 按下 */
            GPFDAT &= ~(1 << 6);
        }
    }
    else if (irq == 2) /* eint2 : s3 控制 D11 */
    {
        if (val1 & (1 << 2)) /* s3 --> gpf5 */
        {
            /* 松开 */
            GPFDAT |= (1 << 5);
        }
        else
        {
            /* 按下 */
            GPFDAT &= ~(1 << 5);
        }
    }
    else if (irq == 5) /* eint8_23, eint11--s4 控制 D10, eint19---s5 控制所有LED */
    {
        if (val & (1 << 11)) /* eint11 */
        {
            if (val2 & (1 << 3)) /* s4 --> gpf4 */
            {
                /* 松开 */
                GPFDAT |= (1 << 4);
            }
            else
            {
                /* 按下 */
                GPFDAT &= ~(1 << 4);
            }
        }
        else if (val & (1 << 19)) /* eint19 */
        {
            if (val2 & (1 << 11))
            {
                /* 松开 */
                /* 熄灭所有LED */
                GPFDAT |= ((1 << 4) | (1 << 5) | (1 << 6));
            }
            else
            {
                /* 按下: 点亮所有LED */
                GPFDAT &= ~((1 << 4) | (1 << 5) | (1 << 6));
            }
        }
    }

    EINTPEND = val;
}
```
