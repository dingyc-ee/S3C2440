# _烧录程序_

## oflash烧录

1. 在bin文件目录下，按住`shift+鼠标右键`，打开PowerShell。输入`oflash xxx.bin`

![oflash1](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.1_oflash1.png)

2. 选择`OpenJTAG` `S3C2440` `Nand Flash`，烧录到0地址

![oflash2](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/6.2_oflash2.png)

3. 关闭JTAG，选择Nand启动，重新上电复位。

