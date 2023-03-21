# _环境搭建_

## 1. 编译器arm-linux-gcc

1. 解压编译器
```sh
sudo tar -jxf arm-linux-gcc-3.4.5-glibc-2.3.6.tar.bz2
```
2. 创建arm文件夹
```sh
sudo mkdir /usr/local/arm
```
3. 移动编译器到arm文件夹下
```sh
mv gcc-3.4.5-glibc-2.3.6/ /usr/local/arm/
```
4. 在/etc/profile文件中，添加环境变量
```sh
sudo vim /etc/profile
```
5. 在profile文件尾部添加环境变量
```sh
export PATH=$PATH:/usr/local/arm/gcc-3.4.5-glibc-2.3.6/bin
```
*下图安装了2个编译器，所以环境变量包含2个路径*


![环境变量](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/1.1%20PATH.png)


6. 安装32位库
```sh
# 因为ubuntu是64位系统，arm-linux-gcc是32位的，需要安装32位支持库
sudo apt install lib32z1
```
7. 重启
```sh
sudo reboot
```
8. 查看arm-linux-gcc版本号
```sh
ding@linux:~$ arm-linux-gcc -v
Reading specs from /usr/local/arm/gcc-3.4.5-glibc-2.3.6/bin/../lib/gcc/arm-linux/3.4.5/specs
Configured with: /work/tools/create_crosstools/crosstool-0.43/build/arm-linux/gcc-3.4.5-glibc-2.3.6/gcc-3.4.5/configure --target=arm-linux --host=i686-host_pc-linux-gnu --prefix=/work/tools/gcc-3.4.5-glibc-2.3.6 --with-float=soft --with-headers=/work/tools/gcc-3.4.5-glibc-2.3.6/arm-linux/include --with-local-prefix=/work/tools/gcc-3.4.5-glibc-2.3.6/arm-linux --disable-nls --enable-threads=posix --enable-symvers=gnu --enable-__cxa_atexit --enable-languages=c,c++ --enable-shared --enable-c99 --enable-long-long
Thread model: posix
gcc version 3.4.5
```


![arm-linux-gcc版本号](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/1.2%20arm-linux-gcc%20version.png)


