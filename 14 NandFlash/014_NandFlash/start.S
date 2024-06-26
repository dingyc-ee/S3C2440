
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

do_und:
	/* sp_und未设置，先设置它 */
	ldr sp, =0x34000000		/* 0x3000 0000 + 64M，指向64M SDRAM的最高地址 */

	/* 保存现场 */
	/* 在und异常处理函数中，有可能会修改r0-r12，所以先保存 */
	/* 发生und异常时，返回地址保存在lr寄存器中，而异常处理C函数也会使用到lr，所以lr也要保存 */
	stmdb sp!, {r0-r12, lr}

	/* 保存现场 */
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
	ldmia sp!, {r0-r12, pc}^  /* ^会把spsr_irq的值恢复到cpsr里 */


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

	//bl main  /* 使用BL命令相对跳转, 程序仍然在NOR/sram执行 */
	ldr lr, =halt
	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
	
