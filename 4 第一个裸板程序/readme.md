# _第一个裸板程序_

## _汇编点亮LED_

### _硬件说明_

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

### _几条汇编指令_

1. ldr 读内存

```asm
ldr r0, [r1]            # 假如r1的值为x，读取地址x上的数据(4字节)，保存到r0中
ldr r0, =0x12345678     # 伪指令，最终会被拆分成几条真正的arm指令
```

2. str 写内存
   
```asm
str r0, [r1]            # 假如r1的值为x，把r0的值写道地址x(4字节)中
```

3. b 跳转

4. mov 移动

```asm
mov r0, r1              # 把r1的值赋给r0
mov r0, #0x100          # r0的值等于0x100
```

### _第一个汇编程序_

`led_on.S`

```s
/*
 * 点亮LED:GPF4
 */
.text
.global _start

_start:

/* 配置GPF4为输出引脚
 * 把(0b01 << 8)写入到GPFCON(0x5600 0050)地址处
 */
ldr r0, =0x100          // 0x100 = 0b01 << 8
ldr r1, =0x56000050
str r0, [r1]

/* 设置GPF4输出低电平
 * 把(0b0 << 4)写入到GPFDAT(0x5600 0054)地址处
 */
ldr r0, =0x0            //
ldr r1, =0x56000054
str r0, [r1]

halt:
    b halt              // 死循环
```

`Makefile`

```mk
OBJ := led_on

all:
	@echo 开始编译...
	arm-linux-gcc -c -o $(OBJ).o $(OBJ).S
	arm-linux-ld -Ttext 0 $(OBJ).o -o $(OBJ).elf
	arm-linux-objcopy -O binary -S $(OBJ).elf $(OBJ).bin

clean:
	@echo 清理工程...
	rm -rf $(OBJ).o $(OBJ).bin $(OBJ).elf
```

### _反汇编_

```
led_on.elf:     file format elf32-littlearm

Disassembly of section .text:

00000000 <_start>:
   0:	e3a00c01 	mov	r0, #256	; 0x100
   4:	e59f1010 	ldr	r1, [pc, #16]	; 1c <.text+0x1c>
   8:	e5810000 	str	r0, [r1]
   c:	e3a00000 	mov	r0, #0	; 0x0
  10:	e59f1008 	ldr	r1, [pc, #8]	; 20 <.text+0x20>
  14:	e5810000 	str	r0, [r1]

00000018 <halt>:
  18:	eafffffe 	b	18 <halt>
  1c:	56000050 	undefined
  20:	56000054 	undefined
```

*ARM寄存器说明*

| 寄存器 | 代号 | 说明 |
|--------|-----|------|
| r0  | a1 | argument, result registers, r0 to r3 |
| r1  | a2 | |
| r2  | a3 | |
| r3  | a4 | |
| r4  | v1 | variable registers, r4 to r11, 必须保护 |
| r5  | v2 | --- |
| r6  | v3 | |
| r7  | v4 | |
| r8  | v5 | |
| r9  | v6 | |
| r10 | sl | |
| r11 | fp | 用来做栈回溯 |
| r12 | ip | 内部过程调用寄存器 |
| r13 | sp | stack pointer |
| r14 | lr | link register |
| r15 | pc | program counter = 当前指令地址 + 8 |

*可以看到：在CPU的角度，GPFCON和GPFDAT这些寄存器，其实就是内存，没有区别！*

## *C语言点亮LED*

启动文件`start.S`

```s
.text
.global _start

_start:
    // 设置内存栈: SP栈
    ldr sp, =4096   // nand启动

    // 调用main
    bl main

    // 死循环
halt:
    b halt
```

C源文件`led.c`

```c
int main(void)
{
    unsigned int *pGPFCON = (unsigned int *)0x56000050;
    unsigned int *pGPFDAT = (unsigned int *)0x56000054;

    *pGPFCON = 0X100;   // 配置GPF4为输出引脚
    *pGPFDAT = 0;       // GPF4输出低电平

    return 0;
}
```

`Makefile`

```mk
# $@ 目标文件: 此处为led，即最终要生成的文件
# $^ 所有依赖 此处为start.o led.o
# $< 第一个依赖 此处为start.o

led: start.o led.o
	@echo 开始编译...
	arm-linux-ld -Ttext 0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

start.o: start.S
	arm-linux-gcc -c -o start.o start.S

led.o: led.c
	arm-linux-gcc -c -o led.o led.c

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

*测试结果：编译得到的反汇编文件`led.dis`*

```s
led.elf:     file format elf32-littlearm

Disassembly of section .text:

00000000 <_start>:
   0:	e3a0da01 	mov	sp, #4096	; 0x1000
   4:	eb000000 	bl	c <main>

00000008 <halt>:
   8:	eafffffe 	b	8 <halt>

0000000c <main>:
   c:	e1a0c00d 	mov	ip, sp
  10:	e92dd800 	stmdb	sp!, {fp, ip, lr, pc}
  14:	e24cb004 	sub	fp, ip, #4	; 0x4
  18:	e24dd008 	sub	sp, sp, #8	; 0x8
  1c:	e3a03456 	mov	r3, #1442840576	; 0x56000000
  20:	e2833050 	add	r3, r3, #80	; 0x50
  24:	e50b3010 	str	r3, [fp, #-16]
  28:	e3a03456 	mov	r3, #1442840576	; 0x56000000
  2c:	e2833054 	add	r3, r3, #84	; 0x54
  30:	e50b3014 	str	r3, [fp, #-20]
  34:	e51b2010 	ldr	r2, [fp, #-16]
  38:	e3a03c01 	mov	r3, #256	; 0x100
  3c:	e5823000 	str	r3, [r2]
  40:	e51b2014 	ldr	r2, [fp, #-20]
  44:	e3a03000 	mov	r3, #0	; 0x0
  48:	e5823000 	str	r3, [r2]
  4c:	e3a03000 	mov	r3, #0	; 0x0
  50:	e1a00003 	mov	r0, r3
  54:	e24bd00c 	sub	sp, fp, #12	; 0xc
  58:	e89da800 	ldmia	sp, {fp, sp, pc}
Disassembly of section .comment:

00000000 <.comment>:
   0:	43434700 	cmpmi	r3, #0	; 0x0
   4:	4728203a 	undefined
   8:	2029554e 	eorcs	r5, r9, lr, asr #10
   c:	2e342e33 	mrccs	14, 1, r2, cr4, cr3, {1}
  10:	Address 0x10 is out of bounds.
```

