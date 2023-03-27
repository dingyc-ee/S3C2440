
# $@ 目标文件: 此处为led，即最终要生成的文件
# $^ 所有依赖 此处为start.o led.o
# $< 第一个依赖 此处为start.o

led: start.o led.o
	@echo 开始编译...
	arm-linux-ld -Ttext 0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

start.o: start.S
	arm-linux-gcc -c -o start.o start.S

led.o: led.c
	arm-linux-gcc -c -o led.o led.c

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
