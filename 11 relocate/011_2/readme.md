# *链接脚本*

## NorFlash重定位

上一届提到，Nor启动时，由于全局变量保存在Nor上，导致全局变量不能修改。如何解决？

*既然全局变量要求可修改，那就保存在内存中啊，可以把全局变量保存在SDRAM，这样就可读可写了。*

### 内存布局

之前数据段保存在了0x800位置上，现在修改如下。.text和.rodata 代码段和只读数据段仍然保存在Nor的0地址起始处，但把.data数据段的全局变量g_Char保存到SDRAM中（起始地址0x30000000）。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.2.1_memory.png)

### 修改Makefile  -Tdata 0x30000000

在Makefile中把 .data 的起始地址设置为0x30000000

```mk
TARGET = RELOCATE
OBJ = start.o main.o uart.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 -Tdata 0x30000000 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

有个很可怕的情况出现了，编译出来的bin文件竟然有800+MB，805306369 = 0x30000001，刚好就是从0地址开始，到SDRAM的起始地址处保存了1个字节g_Char。

```sh
ding@linux:~/s3c2440/011_2_relocate$ ls -l RELOCATE.bin 
-rwxrwxr-x 1 ding ding 805306369  8月 16 23:56 RELOCATE.bin
```

下面是反汇编文件和实际的bin文件内容。

可以看到，虽然全局变量确实保存到了SDRAM中，但整个bin文件的中间部分，全部被0填充了。我们的Nor总共才2M，而bin文件就有800+M，怎么可能烧的进去。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.2.2_bin.png)

### 解决办法

第一种解决办法：最终的代码段和全局变量之间有空洞。

1. bin文件中，让全局变量和代码段靠在一起
2. 把bin文件烧写到Nor上，布局和bin文件完全一样
3. 运行时，前面的代码需要把g_Char复制到0x3000 0000位置上（只重定位了全局变量）

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.2.4_1.png)

第二种解决办法：最终的代码段和全局变量之间没有空隙。

1. bin文件代码段的链接地址，从0x3000 0000开始
2. 把bin文件烧写到Nor的0地址，布局和bin文件一样
3. 运行时，前面的代码把代码段和全局变量，整个都复制到0x3000 0000位置上（重定位了整个程序）

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.2.5_2.png)

### 实现方式

如果我们直接修改Makefile，添加 -Tdata 0x30000000，编译出来的bin文件竟然有800+MB。这些复杂的功能，通过简单的指定参数已经无法实现，所以要引入链接脚本。

[官方链接](https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html)

链接脚本格式：

```ld
SECTIONS {
...
secname start BLOCK(align) (NOLOAD) : AT ( ldadr )
  { contents } >region :phdr =fill
...
}
```

Makefile中指定链接脚本 -T xxx.ld

```mk
TARGET = RELOCATE
OBJ = start.o main.o uart.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -T sdram.ld $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```

链接脚本实例：`sdram.ld`

```ld
SECTIONS {
    .text 0 : 
        {*(.text) }
    .rodata :
        { *(.rodata) }
    .data 0x30000000 :
        { *(.data) }
    .bss :
        { *(.bss) *(.COMMON) }
}
```

问题仍然存在，编译出来的文件还是有800+MB（805306369 = 0x3000 0001）。

```sh
ding@linux:~/s3c2440/011_2_2_relocate$ ls -l RELOCATE.bin 
-rwxrwxr-x 1 ding ding 805306369  8月 17 23:47 RELOCATE.bin
```

我们需要修改链接脚本，把.data的加载地址放在0x800处（  增加 AT (0x800)  ）。

```mk
SECTIONS {
    .text 0 : 
        {*(.text) }
    .rodata :
        { *(.rodata) }
    .data 0x30000000 : AT (0x800)
        { *(.data) }
    .bss :
        { *(.bss) *(.COMMON) }
}
```

重新编译，得到的bin文件变为2049字节，大小正常。

```sh
ding@linux:~/s3c2440/011_2_2_relocate$ ls -l RELOCATE.bin 
-rwxrwxr-x 1 ding ding 2049  8月 17 23:53 RELOCATE.bin
```

现在main函数可以从0x3000 0000处读取变量了。但我们并没有设置0x3000 0000这个地方，让他的值等于'A'，所以我们的代码缺少了重定位。我们需要把g_Char从0x800的地方，复制到0x3000 0000的地方。

在`start.S`启动文件中，进入main函数之前，重定位数据段（把数据段从Nor加载地址，复制到SDRAM链接地址）。所以，在重定位前必须要先初始化SDRAM。

```mk
// 重定位data段
ldr r1, =0x800
ldr r0, [r1]
ldr r1, =0x30000000
str r0, [r1]

bl main
```

反汇编和bin文件对比如下所示。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/11.2.6_ld.png)

现在我们已经能够正常运行了，但重定位代码看起来很费解，因此我们需要写更加通用的重定位代码。

### 重定位代码

1. 链接脚本中的常量，改写为变量

```ld
SECTIONS {
   .text   0  : { *(.text) }
   .rodata  : { *(.rodata) }
   .data 0x30000000 : AT(0x800)
   { 
      data_loadaddr = LOADADDR(.data);
      data_start = .;
      *(.data) 
      data_end = .;
   }
   .bss  : { *(.bss) *(.COMMON) }
}
```

2. start.S启动文件中，复制.data段数据

```mk

# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = RELOCATE
OBJ = start.o main.o led.o uart.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -T sdram.ld $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
```
