OBJ := led_on

all:
	@echo 开始编译...
	arm-linux-gcc -c -o $(OBJ).o $(OBJ).S
	arm-linux-ld -Ttext 0 $(OBJ).o -o $(OBJ).elf
	arm-linux-objcopy -O binary -S $(OBJ).elf $(OBJ).bin
	arm-linux-objdump -D $(OBJ).elf > $(OBJ).dis

clean:
	@echo 清理工程...
	rm -rf $(OBJ).o $(OBJ).bin $(OBJ).elf $(OBJ).dis
