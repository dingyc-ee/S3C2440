# *代码重定位与位置无关码*

## 位置无关码及程序设计方法

[参考链接](http://www.360doc.com/content/14/0518/18/15377983_378812804.shtml)

### 1. 基本概念与实现原理

在设计BootLoader程序时，必须在裸机环境中进行。通常情况下，首先将BootLoader下载到ROM的0地址进行启动。而在大多数应用系统中，为了快速启动，首先将BootLoader程序拷贝到SDRAM在运行。一般情况下，这两者的地址不相同，程序在SDRAM中的地址重定位过程需要程序员来完成。

由于BootLoader是系统上电后运行的第一段程序，BootLoader程序的拷贝和在这之前的所有工作，都必须由其自身来完成，而这些指令都是在ROM中进行的。也就是说，这些代码即使不在链接地址空间，也可以正确执行，这就是位置无关码。

位置无关码：他是一段加载到任意地址空间都能正常执行的特殊代码。常用于以下场合：动态链接库，BootLoader程序。

### 2. 程序设计要点

ARM程序的位置无关可执行文件主要包括两部分：位置无关代码和位置无关数据。在程序设计中，*一般不必考虑data和bss这种可读写段的位置无关性*，因为data和bss段直接就分配在SDRAM中。*text和rodata段*，为保证程序能在ROM和SDRAM中都能正确执行，必须采用位置无关码程序设计。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.1_part1.png)

### 3. 程序设计规范1

1. 位置无关的跳转：相对跳转指令 b 或 bl
2. ldr 读取常量到非 pc 寄存器，可实现位置无关的常量访问（可以使用 equ 对常量赋值）

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.2_part2.png)

### 4. 程序设计规范2

1. ldr pc, XXX 位置相关码。把XXX的链接地址，复制到pc然后跳转过去

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.3_part3.png)

### 3. 位置无关码在BootLoader设计中的应用

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.4_demo1.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.5_demo2.png)

## S3C2440

### 1. 参考u-boot写链接脚本

```ld
SECTIONS {
   . = 0x30000000;

   . = ALIGN(4);
   .text :
   {
      *(.text)
   }

   . = ALIGN(4);
   .rodata  : { *(.rodata) }

   . = ALIGN(4);
   .data  : { *(.data) }

   . = ALIGN(4);
   __bss_start = .;
   .bss  : { *(.bss) *(.COMMON) }
   _end = .;
}
```

### 2. start.S启动文件 复制整个程序

```asm
/* 重定位text, rodata, data段整个程序 */
	ldr r1, =0
	ldr r2, =_start			/* 第1条指令运行时的地址 */
	ldr r3, =__bss_start	/* bss段的起始地址 */
copy:
	ldr r4, [r1]
	str r4, [r2]
	add r1, r1, #4
	add r2, r2, #4
	cmp r2, r3
	ble copy

	/* 清除BSS段 */
	ldr r1, =__bss_start
	ldr r2, =_end
	ldr r3, =0
```

### 3. 反汇编分析

这里设置了2个链接地址：0x3000 0000和0x3200 0000。比较反汇编文件如下所示。

1. sdram_init还没执行，怎么能跳转到0x3000 0000处？
2. 可以看到，相同的一条机器码，左边跳转到了0x3000 0558，右边跳转到了0x3200 0558，为什么？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.6_dis.png)

地址不一样，为什么机器码一样？

所以，并不是跳转到0x3000 0558或0x3200 0558地址处，而是跳转到 当前PC指针 + Offset 地址处。类似的，如果地址从0运行（NorFlash），就会跳转到0x0000 0558地址处。

*反汇编里写出这个地址值，只是为了方便分析，不是跳到这个地址。*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.6_bl.png)

继续分析启动文件，可以看到，启动文件中bl main使用了相对跳转。这会造成一个什么问题？

```asm
bl sdram_init	

	/* 重定位text, rodata, data段整个程序 */
	ldr r1, =0
	ldr r2, =_start			/* 第1条指令运行时的地址 */
	ldr r3, =__bss_start	/* bss段的起始地址 */
copy:
	ldr r4, [r1]
	str r4, [r2]
	add r1, r1, #4
	add r2, r2, #4
	cmp r2, r3
	ble copy

	/* 清除BSS段 */
	ldr r1, =__bss_start
	ldr r2, =_end
	ldr r3, =0
clean:
	str r3, [r1]
	add r1, r1, #4
	cmp r1, r2
	ble clean

	bl main         /* 这里又是相对跳转 */

halt:
	b halt
```

当前我们的内存布局是，NorFlash（0地址）上有main函数，SDRAM（0x3000 0000地址）上也复制了main函数。我们应该跳转到SDRAM上的main去执行，但由于bl main是相对跳转，NorFlash启动时，bl main实际上还是在Nor上执行，并没有跳转到SDRAM。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.5.7_bl_main.png)

使用bl main相对跳转，程序仍然在Nor上执行。我们想跳转到SDRAM，必须使用绝对跳转`ldr pc, =main`，这条命令才能使程序跳到SDRAM去执行。

修改后的启动文件`start.S`

```asm
	/* 重定位text, rodata, data段整个程序 */
	ldr r1, =0
	ldr r2, =_start			/* 第1条指令运行时的地址 */
	ldr r3, =__bss_start	/* bss段的起始地址 */
copy:
	ldr r4, [r1]
	str r4, [r2]
	add r1, r1, #4
	add r2, r2, #4
	cmp r2, r3
	ble copy

	/* 清除BSS段 */
	ldr r1, =__bss_start
	ldr r2, =_end
	ldr r3, =0
clean:
	str r3, [r1]
	add r1, r1, #4
	cmp r1, r2
	ble clean

	ldr pc, =main			/* 绝对跳转, 跳到SDRAM */
```

使用初始值不为0的数组，也有问题，看下面的代码。

```c
int b1;
int b2 = 100;

void main (){
    int a1;
    int a2 = 100;

    unsigned long *p = (unsigned long *)0x32000000;    
    p[0] = 0x1111111;        
    p[1] = 0x2222222;    
    p[3] = 0x333333;

    unsigned int arr[] = {
        0x444,     
        0x555,     
        0x666,
    };
}
```

反汇编文件如下所示。初始化数组时所用的初始值0x444,0x555,0x666都存储在.rodata段，在.text段执行到初始化数组这一部分时，命令会去.rodata段取得对应的值。

但因为.text中对.data和.rodata的引用依然是以0x30000000为基地址的，将无法找到对应的值，如果按照链接脚本规定将其烧录在0x30000000起始的位置，那么当运行到初始化数组时，去0x30000090寻找初始化数据以及使用全局变量都是可以正常完成的。

为什么数组的反汇编会出现绝对地址，而变量不会？答案很简单，数组是连续存放的。`ldr r3, [pc, #16]`先找到数组首地址，再根据地址+偏移对数组元素遍历访问，而这个首地址是链接地址（位于SDRAM中），我们在没初始化SDRAM，没完成重定位前，链接地址就不能访问啊！！！

```asm
.text......
30000074:    e59f3010     ldr    r3, [pc, #16]    ; 3000008c <.text+0x8c>  //找到.rodata段的指引指令位置
30000078:    e24bc024     sub    ip, fp, #36    ; 0x24
3000007c:    e8930007     ldmia    r3, {r0, r1, r2}
30000080:    e88c0007     stmia    ip, {r0, r1, r2}
30000084:    e24bd00c     sub    sp, fp, #12    ; 0xc
30000088:    e89da800     ldmia    sp, {fp, sp, pc}
3000008c:    30000090     mulcc    r0, r0, r0   //通过该指令找到.rodata段的位置
Disassembly of section .rodata:

30000090 <.rodata>:
30000090:    00000444     andeq    r0, r0, r4, asr #8
30000094:    00000555     andeq    r0, r0, r5, asr r5
30000098:    00000666     andeq    r0, r0, r6, ror #12
```

## 怎么写位置无关码？

1. 使用相对跳转命令：b bl
2. 重定位前，不可使用绝对地址，最根本的办法是看反汇编

	1. 不可访问全局变量，静态变量
	2. 不可访问有初始值的数组（rodata，data）

3. 重定位后，使用`ldr pc, =xxx`跳转到运行时地址
