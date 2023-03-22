# _Linux常用命令_

## find

*查找文件或目录*

当前目录`test`下有两个文件
```sh
ding@linux:~$ ls test/
test1.txt  test2.txt
```
1. 按照文件名来查找

```sh
find path -name file_name   # 严格大小写
find path -iname file_name  # 忽略大小写
```
*测试结果*

```sh
ding@linux:~$ ls test
test1.txt  test2.txt
ding@linux:~$ find test -name test*.txt
test/test1.txt
test/test2.txt
ding@linux:~$ find test -iname TeSt*.txt
test/test1.txt
test/test2.txt
```

2. 按照文件类型来查找

```sh
find path -type d   # 查找目录
find path -type f   # 查找文件
find path -type l   # 查找软连接
```

*测试结果*

```sh
ding@linux:~$ find test -type d
test
ding@linux:~$ find test -type f
test/test1.txt
test/test2.txt
```

## file

*识别文件类型*

当前家目录下的文件

```sh
ding@linux:~$ ls -a
.       视频  音乐           .bashrc      .idea   .profile                   .viminfo
..      图片  桌面           .cache       .java   snap                       .wget-hsts
公共的  文档  .bash_history  .config      linux   .sudo_as_admin_successful
模板    下载  .bash_logout   .fontconfig  .local  test
```

*测试结果*

```sh
ding@linux:~$ file .bashrc 
.bashrc: ASCII text
ding@linux:~$ file .viminfo 
.viminfo: Unicode text, UTF-8 text
ding@linux:~$ file /bin/pwd
/bin/pwd: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=cf610477f0530f1dbeac1ed8f650f869fb610d10, for GNU/Linux 3.2.0, stripped
```

## which

*搜索PATH环境变量，并显示任何匹配的可执行文件的位置*

```sh
which exe
```

*测试结果*

```sh
ding@linux:~$ which pwd
/usr/bin/pwd
```

*`which -a`，如果有多个匹配的可执行文件，全部显示*

```sh
ding@linux:~$ which -a pwd
/usr/bin/pwd
/bin/pwd
```

## whereis

*找到命令的二进制、源和手册文件*

```sh
ding@linux:~$ whereis pwd
pwd: /usr/bin/pwd /usr/share/man/man1/pwd.1.gz
```