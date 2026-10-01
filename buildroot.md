
## 下载 Buildroot
```bash
mx@DESKTOP-JPOAANO:~$ mkdir -p buildroot-lab
mx@DESKTOP-JPOAANO:~$ ls
buildroot-lab
mx@DESKTOP-JPOAANO:~$ cd buildroot-lab/
mx@DESKTOP-JPOAANO:~/buildroot-lab$ pwd
/home/mx/buildroot-lab
mx@DESKTOP-JPOAANO:~/buildroot-lab$ export BR_VER=2025.02.15
mx@DESKTOP-JPOAANO:~/buildroot-lab$ wget https://buildroot.org/downloads/buildroot-${BR_VER}.tar.xz
```

## 查找支持的板子

Buildroot 通过 `configs/` 目录下的 defconfig（默认配置）文件提供板子支持，每个文件对应一块开发板，命名格式为 `<板子名>_defconfig`。以 `buildroot-2025.02.15` 为例，共提供 **290 个**板子默认配置。

### 1. 直接列目录（最直观）

```bash
cd ~/buildroot-lab/buildroot-2025.02.15
ls configs/                       # 全部板子，命名 <板子>_defconfig
ls configs/ | grep -i raspberry   # 按关键字筛选（示例：树莓派）
```

示例输出（树莓派相关）：
```
raspberrypi0_defconfig
raspberrypi0w_defconfig
raspberrypi2_defconfig
raspberrypi3_defconfig
raspberrypi3_64_defconfig
raspberrypi4_defconfig
raspberrypi4_64_defconfig
raspberrypi5_defconfig
...
```

示例输出（全志/Allwinner 相关）：
```
bananapi_m2_berry_defconfig
orangepi_pc_defconfig
orangepi_zero3_defconfig
pine64_defconfig
...
```

### 2. 用 Buildroot 自带命令（分类更清晰）

```bash
make list-defconfigs              # 按厂商/平台分组列出所有支持的板子
```

### 3. 看 `board/` 目录

```bash
ls board/                         # 每个子目录是某厂商/板子的专属补丁、内核配置、启动脚本
```

只有出现在 `configs/` 里的板子才是「开箱即用」的；`board/` 里有些是给自定义构建参考用的。

### 4. 选好板子后怎么用

```bash
make raspberrypi4_64_defconfig    # 载入该板子的默认配置
make menuconfig                   # （可选）进一步定制
make                              # 开始编译，产出 images/ 下的固件
```

### 说明

- `configs/<name>_defconfig` 就是「官方支持的板子」清单。
- 若想找某块具体硬件，先在 `configs/` 用 `grep -i` 按 SoC/厂商名搜（如 `allwinner`、`rockchip`、`imx`、`qemu` 等）。
- 官方完整列表也可在 Buildroot 网站「Board Support」和手册中查到，内容与 `configs/` 一致。

## 选择 imx6ul 板子配置将其写入.config

```bash
mx@DESKTOP-JPOAANO:~/buildroot-lab/buildroot-2025.02.15$ make imx6ulevk_defconfig
mkdir -p /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/lxdialog
PKG_CONFIG_PATH="" make CC="/usr/bin/gcc" HOSTCC="/usr/bin/gcc" \
    obj=/home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config -C support/kconfig -f Makefile.br conf
make[1]: Entering directory '/home/mx/buildroot-lab/buildroot-2025.02.15/support/kconfig'
/usr/bin/gcc -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600  -DCURSES_LOC="<ncurses.h>" -DNCURSES_WIDECHAR=1 -DLOCALE  -I/home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config -DCONFIG_=\"\"  -MM *.c > /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/.depend 2>/dev/null || :
/usr/bin/gcc -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600  -DCURSES_LOC="<ncurses.h>" -DNCURSES_WIDECHAR=1 -DLOCALE  -I/home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config -DCONFIG_=\"\"   -c conf.c -o /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/conf.o
/usr/bin/gcc -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600  -DCURSES_LOC="<ncurses.h>" -DNCURSES_WIDECHAR=1 -DLOCALE  -I/home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config -DCONFIG_=\"\"  -I. -c /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/zconf.tab.c -o /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/zconf.tab.o
/usr/bin/gcc -D_DEFAULT_SOURCE -D_XOPEN_SOURCE=600  -DCURSES_LOC="<ncurses.h>" -DNCURSES_WIDECHAR=1 -DLOCALE  -I/home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config -DCONFIG_=\"\"   /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/conf.o /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/zconf.tab.o  -o /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/conf
rm /home/mx/buildroot-lab/buildroot-2025.02.15/output/build/buildroot-config/zconf.tab.c
make[1]: Leaving directory '/home/mx/buildroot-lab/buildroot-2025.02.15/support/kconfig'
#
# configuration written to /home/mx/buildroot-lab/buildroot-2025.02.15/.config
#
mx@DESKTOP-JPOAANO:~/buildroot-lab/buildroot-2025.02.15$
```

## 更换内核镜像源为国内镜像

Buildroot 的内核源码由配置项 `BR2_KERNEL_MIRROR` 控制（默认值 `https://cdn.kernel.org/pub`），需填「base 目录」，实际下载路径为 `$(BR2_KERNEL_MIRROR)/linux/kernel/vX.x/linux-X.tar.xz`。先载入板子配置生成 `.config`，再修改该项即可。

### 清华大学镜像（TUNA）

```bash
cd ~/buildroot-lab/buildroot-2025.02.15
make imx6ulevk_defconfig                                   # 先载入板子配置（换成你自己的 <board>_defconfig）
# 注意：./utils/config 对含 / 的 URL 有 sed 分隔符 bug，下面用 | 作分隔符直接写 .config
grep -q '^BR2_KERNEL_MIRROR=' .config && \
  sed -i "s|^BR2_KERNEL_MIRROR=.*|BR2_KERNEL_MIRROR=\"https://mirrors.tuna.tsinghua.edu.cn/kernel\"|" .config || \
  echo 'BR2_KERNEL_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/kernel"' >> .config
grep BR2_KERNEL_MIRROR .config                             # 确认生效
```

### 中国科学技术大学镜像（USTC）

```bash
cd ~/buildroot-lab/buildroot-2025.02.15
make imx6ulevk_defconfig                                   # 先载入板子配置
grep -q '^BR2_KERNEL_MIRROR=' .config && \
  sed -i "s|^BR2_KERNEL_MIRROR=.*|BR2_KERNEL_MIRROR=\"https://mirrors.ustc.edu.cn/kernel\"|" .config || \
  echo 'BR2_KERNEL_MIRROR="https://mirrors.ustc.edu.cn/kernel"' >> .config
grep BR2_KERNEL_MIRROR .config                             # 确认生效
```

```bash
sed -i 's|^BR2_KERNEL_MIRROR=.*|BR2_KERNEL_MIRROR=\"https://mirrors.tuna.tsinghua.edu.cn/kernel\"|' .config
grep BR2_KERNEL_MIRROR .config
```
### 说明

- 也可用交互方式：`make menuconfig` → `Build options` → `Mirrors and download locations` → `Kernel.org mirror` 填入 base 地址。
- 仅当内核来自 kernel.org 的 tarball（Linux 内核选 "Custom version"）时 `BR2_KERNEL_MIRROR` 才生效；若板子配置用 git 仓库获取内核（`BR2_LINUX_KERNEL_CUSTOM_REPO_URL`），需改为对应的国内 git 镜像。

## 预下载内核源码到 dl 目录（WSL 内）

当前 `imx6ulevk_defconfig` 使用的内核版本为 **6.6.48**，tarball 为 `linux-6.6.48.tar.xz`。

> 注意：在当前 WSL 环境实测，TUNA 对该 tarball 返回 404、USTC 返回 403（对 wget 类自动化请求做了拦截），国内镜像取不到。因此下面直接从官方 CDN 下载；下载到 `dl/` 后，`make` 会自动复用本地文件，不再联网。

```bash
cd ~/buildroot-lab/buildroot-2025.02.15
mkdir -p dl
wget -4 -P dl "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.48.tar.xz"
ls -lh dl/linux-6.6.48.tar.xz                 # 确认已下载（约 134M）
```

等价做法（用 Buildroot 自带的下载方式，需先把 `BR2_KERNEL_MIRROR` 指向可达的源，例如官方 CDN）：

```bash
cd ~/buildroot-lab/buildroot-2025.02.15
# 将镜像源切回可用的官方 CDN（当前环境 TUNA/USTC 被拦截）
grep -q '^BR2_KERNEL_MIRROR=' .config && \
  sed -i "s|^BR2_KERNEL_MIRROR=.*|BR2_KERNEL_MIRROR=\"https://cdn.kernel.org/pub\"|" .config || \
  echo 'BR2_KERNEL_MIRROR="https://cdn.kernel.org/pub"' >> .config
make linux-source                                # 仅下载内核源码到 dl/，不编译
```

下载完成后，`dl/linux-6.6.48.tar.xz` 已存在于 WSL 中，后续 `make` 会直接用它。

## 编译内核

```bash
make -j$(nproc)
```

在 Buildroot 中，「内核」对应 `linux` 这个包。常用目标（都在 `buildroot-2025.02.15` 目录下执行）：

```bash
cd ~/buildroot-lab/buildroot-2025.02.15

make linux            # 仅编译内核：解压 dl/linux-6.6.48.tar.xz，套用 imx6ulevk 内核配置后编译
make linux-menuconfig # 图形化（ncurses）修改内核配置，改完保存退出
make linux-rebuild    # 在 linux-menuconfig 改完配置后，仅重新编译内核
make                  # 编译整套系统（内核 + bootloader + 根文件系统等），最常用
```

产物位置：

- 内核构建目录：`output/build/linux-6.6.48/`
- 最终镜像目录：`output/images/`
  - imx6ul（imx6ulevk）默认产出 `zImage` 及对应设备树 `*.dtb`（如 `imx6ul-14x14-evk.dtb`），外加 `rootfs.*` 等。

说明：

- 当前配置内核版本为 **6.6.48**，`dl/` 中已有 tarball，`make` 会直接复用，不再联网下载。
- 第一次完整 `make` 耗时较长：需先构建宿主机工具链（host-*-）、交叉编译工具链等。
- 若在 WSL 中构建时遇到 `Clock skew detected` 导致某包（如 `host-libopenssl`）报 `build_libs Error 2`，多为 WSL2 时钟漂移所致（`make` 看到“未来”时间戳后依赖判断错乱）。处理：
  - 先 `date` 确认时间；必要时 `sudo hwclock -s` 同步时钟，或 `wsl --shutdown` 后重进 WSL。
  - 时钟正常后直接重跑 `make` 即可继续（它只补编未完成的目标）。
  - 反复出现可执行 `find output -exec touch {} +` 把时间戳归一化后再 `make`；状态太乱则用 `make clean` 彻底重来（`dl/` 缓存保留，源码无需重下）。


