# *swi软中断*

## 1. 软中断的作用

APP通常运行于usr模式（功能受限，不能访问硬件）。如果APP想访问硬件，就必须切换模式。

如何切换？发生异常。使用swi指令（软中断），切换模式。

## 2. 要做哪些事情？

1. 复位之后，CPU处于svc模式，要切换到usr模式

    怎么切换到usr模式？设置cpsr寄存器的M4-M0

```as
/* 复位之后，CPU处于svc模式 */
/* 现在，切换到usr模式 */
mrs r0, cpsr		/* 读出cpsr */
bic r0, r0, #0xf	/* 修改M4-M0为0b10000，进入usr模式 */
msr cpsr, r0
```

2. 切换到usr模式后，要设置sp_usr堆栈指针

```as
do_swi:
	/* sp_svc未设置，先设置它 */
	ldr sp, =0x33e00000
```

添加swi异常的启动代码start.S

```as

.text
.global _start

_start:
	b reset				/* vector 0 : reset */
	/* 注意，这里不是ldr pc, =und_addr，表示去und_addr这个地址读内存
	 * ldr pc, =und_addr，即ldr pc, =0x3000 0008
	 * ldr pc, un_addr，即ldr pc, [0x3000 0008]
	 */
	ldr pc, und_addr	/* vector 4 : und */
	ldr pc, swi_addr	/* vector 8 : swi */

und_addr: .word do_und
swi_addr: .word do_swi

do_und:
	/* sp_und未设置，先设置它 */
	ldr sp, =0x34000000		/* 0x3000 0000 + 64M，指向64M SDRAM的最高地址 */

	/* 保存现场 */
	/* 在und异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生und异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	/* 处理und异常 */
	mrs r0, cpsr
	ldr r1, =und_string
	bl printException

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */

und_string:
	.string "undefined instruction exception"

.align 4

do_swi:
	/* sp_svc未设置，先设置它 */
	ldr sp, =0x33e00000

	/* 保存现场 */
	/* 在svc异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生swi异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	/* 处理swi异常 */
	mrs r0, cpsr
	ldr r1, =swi_string
	bl printException

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */

swi_string:
	.string "swi exception"

.align 4

reset:
	/* 关闭看门狗 */
	ldr r0, =0x53000000
	ldr r1, =0
	str r1, [r0]

	/* 设置MPLL, FCLK : HCLK : PCLK = 400m : 100m : 50m */
	/* LOCKTIME(0x4C000000) = 0xFFFFFFFF */
	ldr r0, =0x4C000000
	ldr r1, =0xFFFFFFFF
	str r1, [r0]

	/* CLKDIVN(0x4C000014) = 0X5, tFCLK:tHCLK:tPCLK = 1:4:8  */
	ldr r0, =0x4C000014
	ldr r1, =0x5
	str r1, [r0]

	/* 设置CPU工作于异步模式 */
	mrc p15,0,r0,c1,c0,0
	orr r0,r0,#0xc0000000   //R1_nF:OR:R1_iA
	mcr p15,0,r0,c1,c0,0

	/* 设置MPLLCON(0x4C000004) = (92<<12)|(1<<4)|(1<<0) 
	 *  m = MDIV+8 = 92+8=100
	 *  p = PDIV+2 = 1+2 = 3
	 *  s = SDIV = 1
	 *  FCLK = 2*m*Fin/(p*2^s) = 2*100*12/(3*2^1)=400M
	 */
	ldr r0, =0x4C000004
	ldr r1, =(92<<12)|(1<<4)|(1<<0)
	str r1, [r0]

	/* 一旦设置PLL, 就会锁定lock time直到PLL输出稳定
	 * 然后CPU工作于新的频率FCLK
	 */
	
	

	/* 设置内存: sp 栈 */
	/* 分辨是nor/nand启动
	 * 写0到0地址, 再读出来
	 * 如果得到0, 表示0地址上的内容被修改了, 它对应ram, 这就是nand启动
	 * 否则就是nor启动
	 */
	mov r1, #0
	ldr r0, [r1] /* 读出原来的值备份 */
	str r1, [r1] /* 0->[0] */ 
	ldr r2, [r1] /* r2=[0] */
	cmp r1, r2   /* r1==r2? 如果相等表示是NAND启动 */
	ldr sp, =0x40000000+4096 /* 先假设是nor启动 */
	moveq sp, #4096  /* nand启动 */
	streq r0, [r1]   /* 恢复原来的值 */

	bl sdram_init	

	/* 重定位text, rodata, data段整个程序 */
	bl copy2sdram

	/* 清除BSS段 */
	bl clean_bss

	/* 复位之后，CPU处于svc模式 */
	/* 现在，切换到usr模式 */
	mrs r0, cpsr		/* 读出cpsr */
	bic r0, r0, #0xf	/* 修改M4-M0为0b10000，进入usr模式 */
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

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
```

执行结果如下图。可以看到，swi指令正常执行了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_swi_1.png)

## 3. ATPCS规则 ARM-THUMB procedure call standard（ARM-Thumb过程调用标准）

1. 子函数通过r0-r3寄存器来传参和返回。在调用函数前后，r0-r3会发生改变
2. 子函数中r4-r11来保存局部变量，函数返回前会恢复这些寄存器值。在调用函数前后，r4-r11不会改变

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_atpcs_1.png)

3. 参数传递规则 使用r0-r3和栈

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_atpcs_2.png)

4. 参数返回规则 使用r0-r3和栈

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_atpcs_3.png)

## 4. 读取swi指令的val

如何读取val？

1. SWI指令，包含24bit的传参val值。如果我们能读出SWI指令，取后24位就能读到val

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_swi_2.png)

2. 从哪里SWI指令？

从下面的反汇编中可以看到，执行SWI指令时，下一条指令的地址会被CPU作为返回地址，保存在lr_svc中，然后CPU跳到0x08地址，去执行swi异常处理函数。

那么在异常处理函数中，我们只要先读取lr_svc保存的地址，再-4（回退到上一条指令），就能获取到swi指令地址。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_swi_3.png)

看下现在的swi异常处理函数。由于调用C函数printException会修改lr寄存器，所以要先保存lr寄存器，防止被C函数破坏。如何保存？

```as
do_swi:
	/* sp_svc未设置，先设置它 */
	ldr sp, =0x33e00000

	/* 保存现场 */
	/* 在svc异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生swi异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	/* 处理swi异常 */
	mrs r0, cpsr
	ldr r1, =swi_string
	bl printException

	bl printSWIVal  /* 打印swi指令的val值 */

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */

swi_string:
	.string "swi exception"

.align 4
```

根据ATPCS规则，把lr_svc寄存器的值保存到r4-r11任意一个寄存器就可以了。

## 读取swi指令的值

我们在内核中，就是根据SWI指令的值，来判断是调用了哪个syscall系统调用。

```as
.text
.global _start

_start:
	b reset				/* vector 0 : reset */
	/* 注意，这里不是ldr pc, =und_addr，表示去und_addr这个地址读内存
	 * ldr pc, =und_addr，即ldr pc, =0x3000 0008
	 * ldr pc, un_addr，即ldr pc, [0x3000 0008]
	 */
	ldr pc, und_addr	/* vector 4 : und */
	ldr pc, swi_addr	/* vector 8 : swi */

und_addr: .word do_und
swi_addr: .word do_swi

do_und:
	/* sp_und未设置，先设置它 */
	ldr sp, =0x34000000		/* 0x3000 0000 + 64M，指向64M SDRAM的最高地址 */

	/* 保存现场 */
	/* 在und异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生und异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	/* 处理und异常 */
	mrs r0, cpsr
	ldr r1, =und_string
	bl printException

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */

und_string:
	.string "undefined instruction exception"

.align 4

do_swi:
	/* sp_svc未设置，先设置它 */
	ldr sp, =0x33e00000

	/* 保存现场 */
	/* 在svc异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生swi异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	mov r4, lr

	/* 处理swi异常 */
	mrs r0, cpsr
	ldr r1, =swi_string
	bl printException

	sub r0, r4, #4
	bl printSWIVal

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^	/* ^会把spsr的值恢复到cpsr里 */

swi_string:
	.string "swi exception"

.align 4

reset:
	/* 关闭看门狗 */
	ldr r0, =0x53000000
	ldr r1, =0
	str r1, [r0]

	/* 设置MPLL, FCLK : HCLK : PCLK = 400m : 100m : 50m */
	/* LOCKTIME(0x4C000000) = 0xFFFFFFFF */
	ldr r0, =0x4C000000
	ldr r1, =0xFFFFFFFF
	str r1, [r0]

	/* CLKDIVN(0x4C000014) = 0X5, tFCLK:tHCLK:tPCLK = 1:4:8  */
	ldr r0, =0x4C000014
	ldr r1, =0x5
	str r1, [r0]

	/* 设置CPU工作于异步模式 */
	mrc p15,0,r0,c1,c0,0
	orr r0,r0,#0xc0000000   //R1_nF:OR:R1_iA
	mcr p15,0,r0,c1,c0,0

	/* 设置MPLLCON(0x4C000004) = (92<<12)|(1<<4)|(1<<0) 
	 *  m = MDIV+8 = 92+8=100
	 *  p = PDIV+2 = 1+2 = 3
	 *  s = SDIV = 1
	 *  FCLK = 2*m*Fin/(p*2^s) = 2*100*12/(3*2^1)=400M
	 */
	ldr r0, =0x4C000004
	ldr r1, =(92<<12)|(1<<4)|(1<<0)
	str r1, [r0]

	/* 一旦设置PLL, 就会锁定lock time直到PLL输出稳定
	 * 然后CPU工作于新的频率FCLK
	 */
	
	

	/* 设置内存: sp 栈 */
	/* 分辨是nor/nand启动
	 * 写0到0地址, 再读出来
	 * 如果得到0, 表示0地址上的内容被修改了, 它对应ram, 这就是nand启动
	 * 否则就是nor启动
	 */
	mov r1, #0
	ldr r0, [r1] /* 读出原来的值备份 */
	str r1, [r1] /* 0->[0] */ 
	ldr r2, [r1] /* r2=[0] */
	cmp r1, r2   /* r1==r2? 如果相等表示是NAND启动 */
	ldr sp, =0x40000000+4096 /* 先假设是nor启动 */
	moveq sp, #4096  /* nand启动 */
	streq r0, [r1]   /* 恢复原来的值 */

	bl sdram_init	

	/* 重定位text, rodata, data段整个程序 */
	bl copy2sdram

	/* 清除BSS段 */
	bl clean_bss

	/* 复位之后，CPU处于svc模式 */
	/* 现在，切换到usr模式 */
	mrs r0, cpsr		/* 读出cpsr */
	bic r0, r0, #0xf	/* 修改M4-M0为0b10000，进入usr模式 */
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

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
```

执行结果如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/swi_4.png)
