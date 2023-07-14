
# $@ 目标文件: 此处为led，即最终要生成的文件
# $^ 所有依赖 此处为start.o led.o
# $< 第一个依赖 此处为start.o

TARGET = UART
OBJ = start.o main.o uart.o

$(TARGET): $(OBJ)
	@echo 开始编译...
	arm-linux-ld -Ttext 0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

%.o: %.c
	arm-linux-gcc -c -o $@ $<

%.o: %.S
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
