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

## gzip

```sh
gzip -k     # 保留原文件           
gzip        # 压缩文件
gzip -d     # 解压文件(DeCompress)
```

*测试结果*

```sh
# 解压缩文件
ding@linux:~/mypwd$ ls
pwd.1.gz
ding@linux:~/mypwd$ gzip -k -d pwd.1.gz 
ding@linux:~/mypwd$ ls
pwd.1  pwd.1.gz

# 压缩文件
ding@linux:~/mypwd$ cp pwd.1 pwd.2
ding@linux:~/mypwd$ ls
pwd.1  pwd.1.gz  pwd.2
ding@linux:~/mypwd$ gzip -k pwd.2 
ding@linux:~/mypwd$ ls -l
总计 16
-rw-r--r-- 1 ding ding 1477  3月 25 20:00 pwd.1
-rw-r--r-- 1 ding ding  868  3月 25 20:00 pwd.1.gz
-rw-r--r-- 1 ding ding 1477  3月 25 20:01 pwd.2
-rw-r--r-- 1 ding ding  874  3月 25 20:01 pwd.2.gz
```

*注意：同一个文件，文件名不同压缩后的大小也不同*

*注意：gzip只能压缩单个文件，不能压缩目录*

## bzip2

*与gzip命令参数一样*

```sh
bzip2 -k    # 保留原文件           
bzip2       # 压缩文件
bzip2 -d    # 解压文件(DeCompress)
```

*测试结果*

```sh
# 压缩文件
ding@linux:~/mypwd$ bzip2 -k pwd.1 
ding@linux:~/mypwd$ ls
pwd.1  pwd.1.bz2

# 解压文件
ding@linux:~/mypwd$ bzip2 -k -d pwd.1.bz2 
ding@linux:~/mypwd$ ls
pwd.1  pwd.1.bz2
```

*注意：bzip2只能压缩单个文件，不能压缩目录*

*通常小文件用gzip压缩，大文件用bzip2压缩*

## tar

常用选项

```sh
-c      # create  表示创建文件
-x      # extract 表示提取文件
-v      # verbose 显示详细过程
-z      # gzip    与c结合就是压缩，与x结合就是解压
-j      # bzip2   与c结合就是压缩，与x结合就是解压
-f      # file    表示文件
```

### tar 压缩

```sh
tar czvf 压缩文件名 目录名  # gzip压缩
tar cjvf 压缩文件名 目录名  # bzip2压缩
```

*测试结果*

```sh
# tar-gzip压缩
ding@linux:~$ tar czvf mydir.tar.gz mydir/
mydir/
mydir/test1.txt
mydir/test2.txt
mydir/test/
mydir/test/test1.txt
mydir/test/test2.txt
ding@linux:~$ ls
公共的  模板  视频  图片  文档  下载  音乐  桌面  mydir  mydir.tar.gz  snap

# tar-bzip2压缩
ding@linux:~$ tar cjvf mydir.tar.bz2 mydir/
mydir/
mydir/test1.txt
mydir/test2.txt
mydir/test/
mydir/test/test1.txt
mydir/test/test2.txt
ding@linux:~$ ls
公共的  视频  文档  音乐  mydir          mydir.tar.gz
模板    图片  下载  桌面  mydir.tar.bz2  snap

```

### tar 解压

```sh
tar xzvf 压缩文件名 目录名  # gzip解压
tar xjvf 压缩文件名 目录名  # bzip2解压
```

*测试结果*

```sh
# 解压tar.gz
ding@linux:~$ tar xzvf mydir.tar.gz 
mydir/
mydir/test1.txt
mydir/test2.txt
mydir/test/
mydir/test/test1.txt
mydir/test/test2.txt

# 解压tar.bz2
ding@linux:~$ tar xjvf mydir.tar.bz2 
mydir/
mydir/test1.txt
mydir/test2.txt
mydir/test/
mydir/test/test1.txt
mydir/test/test2.txt
```
