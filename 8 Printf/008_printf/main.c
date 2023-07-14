
#include "s3c2440_soc.h"
#include "uart.h"
#include "my_printf.h"

int main(int which)
{
    uart0_init();
    unsigned char c;

    puts("Hello world\r\n");
    my_printf_test();

    while (1) {
        c = getchar();
        if (c == '\r') {
            putchar('\n');
        }
        if (c == '\n') {
            putchar('\r');
        }
        putchar(c);
    }

    return 0;
}
