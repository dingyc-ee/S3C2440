
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

TARGET = SDRAM
OBJ = start.o lib1funcs.o main.o led.o uart.o my_printf.o init.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 -Tdata 0xfb0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
