
#include "s3c2440_soc.h"
#include "uart.h"
#include "init.h"
#include "my_printf.h"

int main(int which)
{
    led_init();
    uart0_init();
    unsigned char c;

    my_printf("Enter the Nor Tacc value:\r\n");

    while (1)
    {
        c = getchar();
        putchar(c);

        if (c >= '0' && c <= '7')
        {
            bank0_tacc_set(c - '0');
            while (1)
            {
                led_loop();
            }
        }
        else
        {
            my_printf("Error:Input must range from 0 to 7\r\n");
            my_printf("Enter the Nor Tacc value again:\r\n");
        }
    }
    return 0;
}
