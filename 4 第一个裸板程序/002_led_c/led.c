
int main(void)
{
    unsigned int *pGPFCON = (unsigned int *)0x56000050;
    unsigned int *pGPFDAT = (unsigned int *)0x56000054;

    *pGPFCON = 0X100;   // 配置GPF4为输出引脚
    *pGPFDAT = 0;       // GPF4输出低电平

    return 0;
}
