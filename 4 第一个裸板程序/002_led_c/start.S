
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
