
.text
.global _start

_start:
    // 关闭看门狗
    ldr r0, =0
    ldr r1, =0x53000000
    str r0, [r1]

    // 设置LOCKTIME为默认最大值
    ldr r0, =0xFFFFFFFF
    ldr r1, =0x4C000000
    str r0, [r1]

    // 设置分频为HCLK=FCLK/4=400M/4=100M，PCLK=HCLK/2=100M/2=50M
    ldr r0, =5
    ldr r1, =0x4c000014
    str r0, [r1]

    // 设置CPU工作于异步总线模式
    mrc p15,0,r0,c1,c0,0
    orr r0,r0,#0xc0000000       // R1_nF:OR:R1_iA
    mcr p15,0,r0,c1,c0,0

    // 设置MPLL输出400MHz
    ldr r0, =(92<<12)|(1<<4)|(1<<0)
    ldr r1, =0x4c000004
    str r0, [r1]

    // 设置内存栈: SP栈
    // 分辨时nor/nand启动
    // 写0到0地址再读出来，如果得到0，表示0地址的内容被修改，对应ram，即nand启动，否则是nor启动
    ldr r0, =0
    ldr r1, [r0]    // 原来0地址的内容保存在r1
    str r0, [r0]    // 0写入0地址
    ldr r2, [r0]    // 0地址内容读到r2
    ldr sp, =0x40000000 + 4096  // 先假设是nor启动
    cmp r0, r2
    ldreq sp, =4096 // 设置栈
    streq r1, [r0]  // 恢复原来0地址的内容

    bl main

    // 死循环
halt:
    b halt
