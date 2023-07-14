
#include "s3c2440_soc.h"
#include "uart.h"

int main(int which)
{
    uart0_init();
    unsigned char c;

    puts("Hello world\r\n");

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
