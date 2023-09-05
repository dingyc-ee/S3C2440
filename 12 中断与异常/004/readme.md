# *Und异常*

## 1. ARM汇编基础

[ARM汇编基础](https://tearorca.github.io/ARM%E6%B1%87%E7%BC%96%E5%9F%BA%E7%A1%80/)

```as
.word expression            // 就是在当前位置放一个word型的值，这个值就是expression
.global                     // 告诉编译器后续跟的是一个全局可见的名字[可能是变量，也可以是函数名]
.align                      // 于对指令或者数据的存放地址进行对齐，有些CPU架构要求固定的指令长度并且存放地址相对于2的幂指数圆整，否则程序无法正常运行，比如ARM
ldima	sp!,{r0-r12，pc}^   // ^ 表示将spsr的值赋给cpsr
msr cpsr，r0                // 复制r0到cpsr中
mrs r0，cpsr                // 复制cpsr到r0中
```
## 2. 常见问题

*问题1. 为什么und异常要设置栈？*

回答：异常处理函数是个C函数，需要用到栈。虽然我们之前`start.S`已经设置了栈，但一上电CPU处于SVC管理模式，实际设置的是管理模式下的栈。发生und异常时，会使用`sp_und`，而这个栈没有人去设置他，所以und异常要设置栈。

*问题2：保存现场，具体要保存哪些寄存器？*

回答：und异常下r0-r12都可能被修改，所以要保存。同时，返回地址保存在lr中，而异常处理C函数也会使用lr，所以还需要保存lr，即`保存现场=r0-r12+lr`。

*问题3：恢复现场，需要恢复哪些寄存器？*

1. 前面保存了r0-12，这里要恢复r0-r12
2. lr中保存了返回地址，现在要赋值给PC，返回异常前的位置
3. 发生异常时，CPU硬件把CPSR保存到了SPSR中，异常返回时要把SPSR恢复到CPSR

*问题4：如何读取/写入PSR寄存器？*

回答：使用MRS/MSR指令。

## 3. 测试代码1

start.S启动文件中，调用und异常处理函数

```as

.text
.global _start

_start:
	b reset		/* vector 0 : reset */
	b do_und	/* vector 4 : und */

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

	/* 故意加入一条未定义指令 */
und_code:
	.word 0xff123456

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
```

exception.c 异常处理函数

```c
#include "uart.h"

void printException(unsigned int cpsr, char *str)
{
    puts("exception! cpsr = ");
    printHex(cpsr);
    puts(" ");
    puts(str);
    puts("\r\n");
}
```

实际运行效果如下。可以看到，程序竟然正常运行了，没有打印und异常，这是怎么回事？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_1_und.png)

通过对比2440指令集，可以看到，`.word 0xff123456`刚好是一条软中断指令。而我们并没有开中断，所以实际不会生效。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_2_soft_int.png)

所以，我们必须换一条未定义指令，选择`.word 0x03000000`。

## 4. 测试代码2

start.S启动文件中，先初始化串口再执行未定义指令。

```as
/* 清除BSS段 */
	bl clean_bss

	/* 初始化串口，还没进入main函数就发生了und异常，所以要先初始化uart */
	bl uart0_init

	/* 故意加入一条未定义指令 */
und_code:
	.word 0x03000000

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */
```

执行结果如下所示，可以看到，und异常可以打印了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_3_und.png)

打印的结果中，CPSR = 0x600000DB，bit0-4为11011，正好对应und模式。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_4_und_cpsr.png)

## 5. 仍然存在的细节问题

### 1. NAND启动时，异常处理函数越界

`b do_und`使用b命令，是相对跳转；而`bl printException`使用bl命令，也是相对跳转。在NAND启动时，SRAM映射为0~4096地址，SDRAM映射到0x3000 0000。当发生und异常时，PC指针从SDRAM跳回到0x04(SRAM)地址，执行b do_und。记住，此时回到了SRAM，而NAND启动时SRAM只有4K。如果printException函数在4K地址外，do_und调用printException一定会出错！

NAND启动时，发生und异常CPU一定会跳转到SRAM的0x04处运行。为防止超过4K边界，我们需要跳回到SDRAM中去执行do_und。所以，`b do_und`修改为`ldr pc, =do_und`。

```as
.text
.global _start

_start:
	b reset		/* vector 0 : reset */
	b do_und	/* vector 4 : und */

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
```

### 2. NAND启动时，ldr pc, =do_und越界

查看`ldr pc, =do_und`反汇编文件。NAND启动发生und异常时，CPU跳到0x04地址执行。此时是在SRAM执行，在跳到SDRAM之前代码空间只有4K，所以我们要用`ldr pc, =do_und`跳回SDRAM。问题来了，do_und这是个常量地址，所以是.rodata，会放在.text之后。`ldr pc, =do_und`的汇编代码是，从do_und这个rodata读到rodata读到do_und的链接地址，然后赋值给PC跳转。

当start.S比较大甚至超过4K时，rodata的地址一定超过4K。此时`ldr pc, =do_und`就会变成`ldr pc, [pc, #4K+]`，超过了SRAM的地址范围，一定会出错。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_5_do_und.png)

### 3. ldr pc, =do_und 只能跳转pc上下4K范围内的地址

下面在start.S启动文件中间，插入4096字节的数据，使.text代码段超过4K。

```as
.text
.global _start

_start:
	b reset			/* vector 0 : reset */
	ldr pc, =do_und	/* vector 4 : und */

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

fill_data:
	.space 4096, 0		/* 填充数据，使代码段变大超过4K */

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

	/* 初始化串口，还没进入main函数就发生了und异常，所以要先初始化uart */
	bl uart0_init

	/* 故意加入一条未定义指令 */
und_code:
	.word 0xdeadc0de

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */

halt:
	b halt
```

编译结果如下所示：

```sh
ding@linux:$ make
arm-linux-gcc -c -o start.o start.S
start.S: Assembler messages:
start.S:7: Error: invalid literal constant: pool needs to be closer
start.S:20: Error: invalid literal constant: pool needs to be closer
make: *** [Makefile:19：start.o] 错误 1
```

为什么会产生编译报错？下面是StackOverflow上的专业回答。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_6_4k.png)

问题2和问题3的修改方式：

```as
.text
.global _start

_start:
	b reset				/* vector 0 : reset */
	/* 注意，这里不是ldr pc, =und_addr，表示去und_addr这个地址读内存
	 * ldr pc, =und_addr，即ldr pc, =0x3000 0008
	 * ldr pc, un_addr，即ldr pc, [0x3000 0008]
	ldr pc, und_addr	/* vector 4 : und */

und_addr: .word do_und

do_und:
	/* sp_und未设置，先设置它 */
	ldr sp, =0x34000000		/* 0x3000 0000 + 64M，指向64M SDRAM的最高地址 */
```

反汇编文件如下所示。可以看到，现在不管代码段多大，一定符合在4K地址范围内读内存了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_7_goback.png)

### 4. 代码重定位后，应该立即跳到SDRAM执行，因为后面的代码可能超过4K

可以看到，在重定位和清除BSS段之后，还使用bl uart0_init相对跳转去执行串口初始化。如果这段代码超过4K，就会有问题。我们应该立即跳转到SDRAM去执行。

```as
	/* 重定位text, rodata, data段整个程序 */
	bl copy2sdram

	/* 清除BSS段 */
	bl clean_bss

	/* 初始化串口，还没进入main函数就发生了und异常，所以要先初始化uart */
	bl uart0_init

	/* 故意加入一条未定义指令 */
und_code:
	.word 0xdeadc0de

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */
```

应该要修改为：

```as
bl sdram_init	

	/* 重定位text, rodata, data段整个程序 */
	bl copy2sdram

	/* 清除BSS段 */
	bl clean_bss

	/* 初始化串口，还没进入main函数就发生了und异常，所以要先初始化uart */
	ldr pc, =sdram
sdram:
	bl uart0_init

	/* 故意加入一条未定义指令 */
und_code:
	.word 0xdeadc0de

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */
```

### 5. .string后面的指令要设置地址对齐

CPU一上电执行复位指令，进入SVC模式。此时执行ARM指令集，所有的指令必须4字节对齐。`.string`命令申请1个数组空间保存字符串（末尾有0），此时下一条指令不一定是地址对齐的，这样就会出错。

```as
und_string:
	.string "undefined instruction exception"

reset:
	/* 关闭看门狗 */
	ldr r0, =0x53000000
	ldr r1, =0
	str r1, [r0]
```

我们可以测试一下。下面的代码中，und_string申请了3字节，导致接下来的reset指令不是4字节地址对齐的，这样执行一定会出错。

```as
und_string:
	.string "12"

reset:
	/* 关闭看门狗 */
	ldr r0, =0x53000000
	ldr r1, =0
	str r1, [r0]
```

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_4_8_align.png)

修改办法：.align 4来实现4字节地址对齐




