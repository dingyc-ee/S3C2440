# *NorFlash*

## *原理*

NorFlash和NandFlash的差异：

1. NorFlash：操作简单，容量小价格贵。适合保存u-boot、内核、文件系统等代码
2. NandFlash：操作复杂，容量大价格便宜。适合保存APP应用程序

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_1.png)

注意：如果想访问NorFlash，必须把2440设为Nor启动。如果设为Nand启动，NorFlash对CPU不可见不可访问。

## *使用u-boot体验NorFlash*

### 命令表

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_3.png)

NorFlash的读、写、擦除包含2个过程：解锁+发命令。

1. 解锁：向地址555H写入AAH
2. 解锁：向地址2AAH写入55H
3. 发命令：向地址< addr >写入< data >

### 读数据 md.b < addr >

这里读0地址的数据，跟Flash中的bin文件完全一样。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_2.png)

### 写数据 mw.w < addr > < data >

mw.b 单字节写入

mw.w 双字节写入

### 读ID

1. 往地址555H写AAH
2. 往地址2AAH写55H
3. 往地址555H写90H（发命令）
4. 读0地址得到厂家ID：C2H
5. 读1地址得到设备ID：22DAH或225BH

JZ2440开发板的NorFlash为16bit访问，硬件连接线上会错开一位，即2440的A1接到了NorFlash的A0线上。这导致我们2440发出的地址必须左移1位，才是能实际到达NorFlash的地址。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_4.png)

u-boot应该以下操作：

| 步骤 | 描述 | 命令 |
| ---- | ---- | --- |
| 1 | 往地址AAAH写AAH | mw.w aaa aa |
| 2 | 往地址554H写55H | mw.w 554 55 |
| 3 | 往地址AAAH写90H（发命令） | mw.w aaa 90 |
| 4 | 读0地址得到厂家ID：C2H | md.w 0 1 |
| 5 | 读2地址得到设备ID：22DAH或225BH | md.w 2 1 |

u-boot执行结果如下，厂家ID和设备ID都成功读到了。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_5.png)

再去读0地址，发现读到的值竟然不对。为什么？

因为此时还在读ID状态，需要先退出来。怎么退出？执行`Reset命令，往任意地址写入F0H。`

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_6.png)

新增推出读ID状态的过程：

1. 往地址555H写AAH
2. 往地址2AAH写55H
3. 往地址555H写90H（发命令）
4. 读0地址得到厂家ID：C2H
5. 读1地址得到设备ID：22DAH或225BH
6. 退出读ID状态：给任意地址写F0H

| 步骤 | 描述 | 命令 |
| ---- | ---- | --- |
| 1 | 往地址AAAH写AAH | mw.w aaa aa |
| 2 | 往地址554H写55H | mw.w 554 55 |
| 3 | 往地址AAAH写90H（发命令） | mw.w aaa 90 |
| 4 | 读0地址得到厂家ID：C2H | md.w 0 1 |
| 5 | 读2地址得到设备ID：22DAH或225BH | md.w 2 1 |
| 6 | 退出读ID状态 | mw.w 0 f0 |

执行完退出命令，再次读状态结果正确。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_7.png)

### JEDEC与CFI模式

NorFlash有两种规范：jedec和cfi(common flash interface)。老式的NorFlash支持jedec，对应的Linux内核`jedec_probe.c`中维护有数组，根据厂家ID和设备ID来匹配对应的型号。现在新的NorFlash都支持cfi规范，cfi包含容量、电压等参数信息。

### 读取CFI信息

如何进入CFI？往地址55H写入98H。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_8.png)

CFI支持哪些命令？

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_9.png)

#### 查询Query

| 序号 | 读写操作 | 描述 | 指令 |
| ---- | ---- | --- | -- |
|   1  | 往地址55H写入98H | 进入CFI模式 | mw.w aa 98 |
|   2  | 读10H得到0051 | 'Q' | md.w 20 1 |
|   3  | 读11H得到0052 | 'R' | md.w 22 1 |
|   4  | 读12H得到0059 | 'Y' | md.w 24 1 |
|   5  | 读27H得到容量 | 2^N bytes | md.w 4e 1 |
|   6  | 退出CFI模式   | 复位命令 | mw.w 0 f0 |

测试结果如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_10.png)

### 写入NorFlash

注意：我们写NorFlash时不能破坏u-boot，由于u-boot大小没有超过1M，所以可以向1M地址处写入数据。从结果可以看到，内存可以直接写，但NorFlash不能直接写入。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_11.png)

NorFlash写指令如下：

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_12.png)

| 步骤 | 读写操作 | 描述 | 指令 |
| ---- | ------- | ---- | ---- |
|  1  | 往地址555H写AAH | 解锁 | mw.w aaa aa |
|  2  | 往地址2AAH写55H | 解锁 | mw.w 554 55 |
|  3  | 往地址555H写A0H | 发出写命令 | mw.w aaa a0 |
|  4  | 往地址PA写PD    | 写数据 | mw.w 100000 1234 |

测试结果如下，数据正确写入。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_13.png)

### 擦除NorFlash

| 步骤 | 读写操作 | 描述 | 指令 |
| ---- | ------- | ---- | ---- |
|  1  | 往地址555H写AAH | 解锁 | mw.w aaa aa |
|  2  | 往地址2AAH写55H | 解锁 | mw.w 554 55 |
|  3  | 往地址555H写80H | 发出擦除命令 | mw.w aaa 80 |
|  4  | 往地址555H写AAH | 再次解锁 | mw.w aaa aa |
|  5  | 往地址2AAH写55H | 再次解锁 | mw.w 554 55 |
|  6  | 往地址100000H写30H | 擦除扇区 | mw.w 100000 30 |

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_14.png)

擦除测试的结果如下所示。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/13_1_15.png)
