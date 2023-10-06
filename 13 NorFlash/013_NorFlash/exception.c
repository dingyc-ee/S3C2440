
#include "uart.h"

void printException(unsigned int cpsr, char *str)
{
    puts("exception! cpsr = ");
    printHex(cpsr);
    puts(" ");
    puts(str);
    puts("\r\n");
}

void printSWIVal(unsigned int *pSWI)
{
    unsigned int val = (*pSWI) & (~0xff000000);
    puts("SWI val = ");
    printHex(val);
    puts("\r\n");
}
