# *CPU模式与状态寄存器*

## 1. 7种模式

ARM架构CPU有7种模式：usr模式 + 6种特权模式。usr模式不能直接进入其他模式，而6种特权模式之间可以互相随意切换（操作CPSR寄存器）。

1. usr : 正常
2. sys : 兴奋
3. und : 未定义指令模式
4. svc : 管理模式
5. abt : 中止

    1. 指令预取中止
    2. 数据访问中止

6. IRQ : 中断
7. FIQ : 快中断

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_1_3_int_mode.png)

## 2. 不同模式的寄存器

### 1. r0-r15

下图所示为7种模式下的寄存器，白色部分为公共的寄存器，灰色部分为此模式下的备份寄存器。

例如，`mov r0, r8`这条指令，在usr模式下为`mov r0, r8`，在fiq模式下为`mov r0, r8_fiq`，`r8`和`f8_fiq`是两个不同的寄存器，保持的值不一样。

简介

1. usr和sys模式基本一样，唯一的功能区别在于sys模式能直接切换到其他特权模式
2. FIQ模式有r8-r14的备份寄存器，其他特权模式都只有`r13(sp)`和`r14(lr)`这2个备份寄存器。所以，在保存现场时，要把`r0-r12`保存到堆栈
3. 发生异常时，CPU会自动把发生异常时的指令地址，保存在异常模式下的`lr_bak`备份寄存器

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_3_int_reg.png)

### 2. PSR（程序状态寄存器）

CPSR = 当前状态寄存器

SPSR = 保存的状态寄存器，用来保存“被中断模式的CPSR”

注意：每种模式只能看到自己的寄存器，不能访问其他模式的寄存器。所以，在CPU发生中断从Usr进入IRQ时，`CPU必须把Usr的返回地址，保存在lr_irq，而不是lr中`。IRQ只能访问`lr_irq`不能访问`lr`，所以要通过`lr_irq`保存的Usr返回地址，跳回到Usr继续执行。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_3_PSR.png)

### 3. 异常处理流程（硬件自动完成）

发生异常时，CPU硬件必须要自动做一些事情，我们才能去执行中断处理函数。

`进入异常的处理（硬件自动完成）`

1. 把下一条指令的地址，保存到`lr_异常`寄存器中，作为返回地址
2. 把异常前的程序状态寄存器，保存到`spcr_异常`中，即`spsr_异常 = cpsr`
3. 修改cpsr寄存器的bit0-4，进入异常模式
4. 强制从中断向量表取1条指令给PC指针，即跳到向量表

`离开异常的处理（依靠软件实现）`

1. 把`LR_异常`寄存器减去偏移值，再赋值给PC指针。即`pc = lr_异常 - oddset`，减多少看下图
2. `CPSR = SPSR_异常`
3. 清除中断标志位

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_4_int_proces.png)

为什么这里不同异常类型的返回地址不一样？答案如下。

[ARM异常中断返回的几种情况](https://blog.csdn.net/u013562393/article/details/51661003)

[ARM异常处理](https://www.cnblogs.com/edwardliu2000/p/15029540.html)

[arm处理器异常处理-swi](http://www.360doc.com/content/11/0616/16/7152758_127383892.shtml)


区别1：部分指令是在执行过程中跳转的（PC不变），部分指令是在执行执行完成后跳转的（PC=PC+4）

区别2：部分异常发生后，会跳转回来重新执行异常的原指令（PC=PC-4）

1. BL 软中断 未定义指令，都是在执行过程中跳转的，而执行没结束时PC地址不变，所以下一条指令的地址，就是LR
2. IRQ FIQ两种中断，都是在当前指令执行完后检测到，此时已经PC+4了（也有LR+4）。所以下一条指令的地址，就是LR-4
3. 预取中止时，CPU将指令标记为无效，但在执行时才进入异常（不立即产生异常的原因是，如果CPU发生分支而没有执行，就不用产生多余的异常）。由于是在执行时跳转，下一条指令的地址就是LR，但预取中止的指令要重复执行，而不是继续下一条指令，所以实际要返回当前地址LR-4
4. 数据中止时，当前指令已经执行完，此时已经PC+4了（也有LR+4）。但数据中止的指令要重复执行，而不是继续下一条指令，所以实际要返回当前地址LR-4-4=LR-8

## 2. 异常分类

[ARM异常处理](https://blog.csdn.net/challenglistic/article/details/128315233)

注意要把异常的类型，和异常模式区分开来，复位 / 软中断异常都会进入SVC模式。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_2_int_type.png)

ARM异常响应的流程：

1. 硬件设置PSR寄存器，保存异常返回地址
2. 软件处理异常服务函数
3. 软件处理异常返回

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_5.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_6.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_6.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_7.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_8.png)

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/12_2_9.png)
