
# $@ 目标文件: 此处为led，即最终要生成的文件
# $^ 所有依赖 此处为start.o led.o
# $< 第一个依赖 此处为start.o

clock: start.o clock.o
	@echo 开始编译...
	arm-linux-ld -Ttext 0 $^ -o $@.elf
	arm-linux-objcopy -O binary -S $@.elf $@.bin
	arm-linux-objdump -D $@.elf > $@.dis

start.o: start.S
	arm-linux-gcc -c -o $@ $<

clock.o: clock.c s3c2440_soc.h
	arm-linux-gcc -c -o $@ $<

clean:
	@echo 清理工程...
	rm -rf *.o *.bin *.elf *.dis
