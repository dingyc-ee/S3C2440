# *GCC编译选项*

## 测试文件

`hello.c`

```c
#include <stdio.h>

#define MAX     20
#define MIN     10

#define _DEBUG
#define SetBit(x)   (1 << x)

int main(int argc, char *argv)
{
    printf("Hello World\n");
    printf("MAX = %d, MIN = %d, MAX + MIN = %d\n", MAX, MIN, MAX + MIN);

#ifdef _DEBUG
    printf("SetBit(5) = %d, SetBit(6) = %d\n", SetBit(5), SetBit(6));
    printf("SetBit( SetBit(2) ) = %d\n", SetBit( SetBit(2) ));
#endif

    return 0;
}
```

## 常用编译选项

```sh
ding@linux:gcc --help
Usage: gcc [options] file...
Options:
  -v                       Display the programs invoked by the compiler.
  -###                     Like -v but options quoted and commands not executed.
  -E                       Preprocess only; do not compile, assemble or link.
  -S                       Compile only; do not assemble or link.
  -c                       Compile and assemble, but do not link.
  -o <file>                Place the output into <file>.
```

### *gcc -v*

*查询GCC软件版本，显示GCC编译的详细过程*

### *gcc -o <file>*

*指定输出文件名<file>，不过不能与源文件同名*

```sh
gcc -o hello hello.c
```

### *gcc -E*

*只预处理，不编译、汇编和链接,，最后生成.i文件*

```sh
gcc -E -o hello.i hello.c
```

预处理前后的文本比较。可以看到，宏定义都已经直接被替换，条件编译和注释均为空行。

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/5.1_gcc-E.png)


### *gcc -S*

*只编译，不汇编和链接，最后生成.s文件*

```sh
gcc -S -o hello.s hello.i 
```

### *gcc-c*

*编译+汇编，不链接*

```sh
gcc -c -o hello.o hello.s
```

### *gcc -o*

*输出文件*

```sh
gcc -o hello hello.o
```

## 什么是链接

*链接就是将编译得到的obj目标文件，系统库的obj文件库文件链接起来，最终生成可以在特定平台运行的可执行程序。*

```sh
ding@linux:~/s3c2440/006_gcc$ gcc -c -o hello.o hello.c 
ding@linux:~/s3c2440/006_gcc$ gcc -v -o hello hello.o
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/lib/gcc/x86_64-linux-gnu/11/lto-wrapper
OFFLOAD_TARGET_NAMES=nvptx-none:amdgcn-amdhsa
OFFLOAD_TARGET_DEFAULT=1
Target: x86_64-linux-gnu
Configured with: ../src/configure -v --with-pkgversion='Ubuntu 11.3.0-1ubuntu1~22.04' --with-bugurl=file:///usr/share/doc/gcc-11/README.Bugs --enable-languages=c,ada,c++,go,brig,d,fortran,objc,obj-c++,m2 --prefix=/usr --with-gcc-major-version-only --program-suffix=-11 --program-prefix=x86_64-linux-gnu- --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --enable-bootstrap --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-plugin --enable-default-pie --with-system-zlib --enable-libphobos-checking=release --with-target-system-zlib=auto --enable-objc-gc=auto --enable-multiarch --disable-werror --enable-cet --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-offload-targets=nvptx-none=/build/gcc-11-xKiWfi/gcc-11-11.3.0/debian/tmp-nvptx/usr,amdgcn-amdhsa=/build/gcc-11-xKiWfi/gcc-11-11.3.0/debian/tmp-gcn/usr --without-cuda-driver --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu --with-build-config=bootstrap-lto-lean --enable-link-serialization=2
Thread model: posix
Supported LTO compression algorithms: zlib zstd
gcc version 11.3.0 (Ubuntu 11.3.0-1ubuntu1~22.04) 
COMPILER_PATH=/usr/lib/gcc/x86_64-linux-gnu/11/:/usr/lib/gcc/x86_64-linux-gnu/11/:/usr/lib/gcc/x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/11/:/usr/lib/gcc/x86_64-linux-gnu/
LIBRARY_PATH=/usr/lib/gcc/x86_64-linux-gnu/11/:/usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu/:/usr/lib/gcc/x86_64-linux-gnu/11/../../../../lib/:/lib/x86_64-linux-gnu/:/lib/../lib/:/usr/lib/x86_64-linux-gnu/:/usr/lib/../lib/:/usr/lib/gcc/x86_64-linux-gnu/11/../../../:/lib/:/usr/lib/
COLLECT_GCC_OPTIONS='-v' '-o' 'hello' '-mtune=generic' '-march=x86-64' '-dumpdir' 'hello.'
 /usr/lib/gcc/x86_64-linux-gnu/11/collect2 -plugin /usr/lib/gcc/x86_64-linux-gnu/11/liblto_plugin.so -plugin-opt=/usr/lib/gcc/x86_64-linux-gnu/11/lto-wrapper -plugin-opt=-fresolution=/tmp/ccN2Wg0Z.res -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lgcc_s -plugin-opt=-pass-through=-lc -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lgcc_s --build-id --eh-frame-hdr -m elf_x86_64 --hash-style=gnu --as-needed -dynamic-linker /lib64/ld-linux-x86-64.so.2 -pie -z now -z relro -o hello /usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu/Scrt1.o /usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu/crti.o /usr/lib/gcc/x86_64-linux-gnu/11/crtbeginS.o -L/usr/lib/gcc/x86_64-linux-gnu/11 -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../../lib -L/lib/x86_64-linux-gnu -L/lib/../lib -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib -L/usr/lib/gcc/x86_64-linux-gnu/11/../../.. hello.o -lgcc --push-state --as-needed -lgcc_s --pop-state -lc -lgcc --push-state --as-needed -lgcc_s --pop-state /usr/lib/gcc/x86_64-linux-gnu/11/crtendS.o /usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu/crtn.o
COLLECT_GCC_OPTIONS='-v' '-o' 'hello' '-mtune=generic' '-march=x86-64' '-dumpdir' 'hello.'
```

*链接详细说明*

![](https://ding-aliyun.oss-cn-shenzhen.aliyuncs.com/s3c2440/5.2_link.png)

上图中的crt1.o crti.o crtBeginS.o是gcc加入的系统标准启动文件，对于一般的应用程序，这些启动是必须的。

-lc: 链接libc库文件，其中ligc库文件中就实现了printf等函数。

### -nostdlib选项

```sh
ding@linux:~/s3c2440/006_gcc$ gcc -v -nostdlib -o hello hello.o
COLLECT_GCC_OPTIONS='-v' '-nostdlib' '-o' 'hello' '-mtune=generic' '-march=x86-64' '-dumpdir' 'hello.'
 /usr/lib/gcc/x86_64-linux-gnu/11/collect2 -plugin /usr/lib/gcc/x86_64-linux-gnu/11/liblto_plugin.so -plugin-opt=/usr/lib/gcc/x86_64-linux-gnu/11/lto-wrapper -plugin-opt=-fresolution=/tmp/ccQNxw3T.res --build-id --eh-frame-hdr -m elf_x86_64 --hash-style=gnu --as-needed -dynamic-linker /lib64/ld-linux-x86-64.so.2 -pie -z now -z relro -o hello -L/usr/lib/gcc/x86_64-linux-gnu/11 -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../x86_64-linux-gnu -L/usr/lib/gcc/x86_64-linux-gnu/11/../../../../lib -L/lib/x86_64-linux-gnu -L/lib/../lib -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib -L/usr/lib/gcc/x86_64-linux-gnu/11/../../.. hello.o
/usr/bin/ld: 警告: 无法找到项目符号 _start; 缺省为 0000000000001050
/usr/bin/ld: hello.o: in function `main':
hello.c:(.text+0x1e): undefined reference to `puts'
/usr/bin/ld: hello.c:(.text+0x41): undefined reference to `printf'
/usr/bin/ld: hello.c:(.text+0x5f): undefined reference to `printf'
/usr/bin/ld: hello.c:(.text+0x78): undefined reference to `printf'
collect2: error: ld returned 1 exit status
```

`gcc -v -nostdlib -o hello hello.o`会提示因为没有链接系统标准启动文件和标准库文件，而链接失败。

`-nostdlib`选项常用于裸机、bootloader、linux内核等程序，因为他们不需要启动文件，也不需要标准库文件。

### 动/静态链接

```sh
# gcc默认是动态链接
ding@linux:~/s3c2440/006_gcc$ gcc -o hello hello.o

# file命令查看文件类型: dynamically linked
ding@linux:~/s3c2440/006_gcc$ file hello
hello: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=374985d122bfa5085e5a71c280a83927ae198087, for GNU/Linux 3.2.0, not stripped

# ldd命令: 查看程序的共享库
ding@linux:~/s3c2440/006_gcc$ ldd hello
        linux-vdso.so.1 (0x00007ffdabf43000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fb0ea200000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fb0ea60f000)
```

```sh
# 默认动态链接
ding@linux:~/s3c2440/006_gcc$ gcc -o hello_dynamic hello.o  # 或者 gcc -dynamic -o hello_dynamic hello.o
# 静态链接
ding@linux:~/s3c2440/006_gcc$ gcc -static -o hello_static hello.o
ding@linux:~/s3c2440/006_gcc$ ls -l
-rw-rw-r-- 1 ding ding    410  3月 29 22:21 hello.c
-rwxrwxr-x 1 ding ding  16000  4月 10 22:32 hello_dynamic   # 动态链接文件大小
-rw-rw-r-- 1 ding ding   1880  4月 10 21:53 hello.o
-rwxrwxr-x 1 ding ding 900400  4月 10 22:32 hello_static    # 静态链接文件大小
# 静态链接文件类型:statically linked
ding@linux:~/s3c2440/006_gcc$ file hello_static 
hello_static: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=81785290b929d7065cc167d2ed2fc2b0528cacbc, for GNU/Linux 3.2.0, not stripped
# 没有共享库
ding@linux:~/s3c2440/006_gcc$ ldd hello_static 
        不是动态可执行文件
```
