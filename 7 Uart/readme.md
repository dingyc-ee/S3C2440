# *UART*

## JZ2440串口原理图

### 1. 使用UART0 管脚为GPH2 GPH3

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.1_uart_board.png)

设置GPIO管脚复用为串口，并使能内部上拉

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.2_uart_gpio.png)

### 2. 设置波特率

1. 波特率计算方式。其中UART clock可以选择为PCLK FCLK 或外部时钟。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.3_uart_clk.png)

2. 如何选择？

根据UCON0控制寄存器，选择串口时钟源。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/7.4_uart_pclk.png)
