# QEMU 环境搭建（WSL 基础工具）

在 WSL 的 Ubuntu 24.04 分发版（`ub24`）中安装编译 QEMU 所需的基础工具。

wsl安装Ubuntu 24.04
```bash
wsl --install -d Ubuntu-24.04 --name ub24 --location E:\WSL\ub24 --no-launch --web-download
wsl.exe -d ub24”
```
root 用户密码：123456

## 环境信息

- WSL 分发版：`ub24`（Ubuntu 24.04，Noble）
- 默认用户：`mx`（uid 1000，非 root）
- 进入方式：`wsl -d ub24`
- 以 root 执行：`wsl -d ub24 -u root <command>`

> 说明：`sudo` 需要密码，因此使用 `wsl -d ub24 -u root` 直接以 root 身份执行安装命令。

## 安装命令

```bash
# 更新软件源
wsl -d ub24 -u root bash -c "apt-get update"

# 安装基础编译工具、git、wget
wsl -d ub24 -u root bash -c "apt-get install -y build-essential git wget"
```

合并写法：

```bash
wsl -d ub24 -u root bash -c "apt-get update && apt-get install -y build-essential git wget curl"
```

## 已安装组件

- `build-essential`：包含 `gcc`、`g++`、`make` 及 libc 开发头文件等编译工具链
- `git`：版本控制
- `wget`：下载工具

## 验证

```bash
wsl -d ub24 -u root bash -c "gcc --version; make --version; git --version; wget --version"
```

预期输出（示例）：

```
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
GNU Make 4.3
git version 2.43.0
GNU Wget 1.21.4 built on linux-gnu.
```
### 安装 qemu dts
```bash
sudo apt-get install -y device-tree-compiler qemu-system-arm
```
验收
```bash
root@DESKTOP-JPOAANO:/home/mx# qemu-system-arm --version
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.18)
Copyright (c) 2003-2023 Fabrice Bellard and the QEMU Project developers

root@DESKTOP-JPOAANO:/home/mx# gcc --version
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
Copyright (C) 2023 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

root@DESKTOP-JPOAANO:/home/mx# dtc --version
Version: DTC 1.7.0
root@DESKTOP-JPOAANO:/home/mx# qemu-system-arm -machine help | grep '^mcimx6ul-evk'
mcimx6ul-evk         Freescale i.MX6UL Evaluation Kit (Cortex-A7)

```

### 安装 Buildroot依赖

```bash
wsl -d ub24 -u root bash -c "apt-get install -y bash binutils build-essential bzip2 cpio diffutils findutils g++ gcc gawk git gzip make patch perl pkg-config sed tar unzip wget ncurses-dev python3 python-is-python3 rsync"
```

### 修改配置文件
```bash
vi /etc/wsl.conf

# 添加以下内容
[interop]
appendWindowsPath = false
```
修改后需要重启设备
