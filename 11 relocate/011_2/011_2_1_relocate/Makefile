
# $@ 目标文件
# $^ 所有依赖
# $< 第一个依赖

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
