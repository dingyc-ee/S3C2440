# S3C2440使用ICache

S3C2440可以在任意条件下，使能指令Cache，代码很简单如下：

```asm
enable_icache:
/* 设置协处理器使能icache */
mrc p15, 0, r0, c1, c0, 0
orr r0, r0, #(1 << 12)  /* r0 = r0 | (1 << 12) */
mcr p15, 0, r0, c1, c0, 0

mov pc, lr
```