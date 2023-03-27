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
