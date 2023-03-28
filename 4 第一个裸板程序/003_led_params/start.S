
.text
.global _start

_start:
    // 设置内存栈: SP栈
    ldr sp, =4096   // nand启动

    ldr r0, =4      // 点亮LED4
    bl led_on

    ldr r0, =100000
    bl delay

    ldr r0, =5      // 点亮ELD5
    bl led_on

    // 死循环
halt:
    b halt
