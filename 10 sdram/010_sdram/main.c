
#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"
#include "my_printf.h"

int main(int which)
{
    led_init();
    uart0_init();
    sdram_init();

    my_printf("SDRAM test!\n");

    if (sdram_test() == 0) {
		while(1) {
			led_loop();
		}
	}

    return 0;
}
