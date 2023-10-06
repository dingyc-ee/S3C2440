
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = NorFlash
OBJ = start.o uart.o init.o main.o led.o exception.o interrupt.o timer.o my_printf.o nor_flash.o string_utils.o lib1funcs.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -T sdram.lds $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

# 如果不加-march=armv4选项，对Nor的16bit写入会被编译成2次strb写入，导致Nor写入出错。-march=armv4来自u-boot
%.o: %.c
	arm-linux-gcc -march=armv4 -c -o $@ $<

%.o: %.S
	arm-linux-gcc -march=armv4 -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
