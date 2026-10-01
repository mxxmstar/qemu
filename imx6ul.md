## QEMU限制
### 1、i.mx6ul-evk 的 sd 卡容量必须为 2 的幂次
根文件系统为 60M，因此 sd 卡容量必须为 2 的幂次，否则无法启动。

```bash
truncate -s 64M ./output/images/rootfs.ext2
```

### 创建启动脚本
run-qemu-original.sh
```bash
qemu-system-arm -M mcimx6ul-evk -m 512M -kernel zImage -dtb imx6ul-14x14-evk.dtb  \
-drive file=rootfs.ext2,if=sd,format=raw -append "console=ttymxc0 root=/dev/mmcblk0 rw rootwait" -nographic -no-reboot
```


### 编辑设备树
反编译为dts
dtc -I dtb -O dts -o imx6ul-14x14-evk-qemu.dts imx6ul-14x14-evk.dtb

### 设备树在 QEMU 下需要修改的原因

Buildroot 生成的 `imx6ul-14x14-evk.dtb` 来自**真实开发板** `imx6ul-14x14-evk` 的设备树。但 QEMU 的 `mcimx6ul-evk` 机器只模拟了 i.MX6UL 中的部分外设（CPU、UART、GPIO、I²C、以太网、SD/MMC、ChipIdea USB 核心等），并不会实现另一些在真实板子上存在的 IP。

如果设备树仍把“未被模拟”的节点标为 `status = "okay"`，内核驱动就会去访问 QEMU 没实现的 MMIO 寄存器，导致 `Unhandled write`/`unimplemented device` 警告、驱动初始化失败或启动卡顿。因此本目录的 `imx6ul-14x14-evk-qemu.dts`（`-bak` 为原版）针对 QEMU 做了裁剪适配。

#### 修改对照表

| 序号 | 设备节点 | 原版 | 修改后 | 类别 |
|------|----------|------|--------|------|
| 1 | `usbmisc@2184800`（USB 杂项/OTG 控制块） | 默认启用 | 新增 `status = "disabled"` | 禁用未模拟硬件 |
| 2 | `usb@2184000`（USB1） | 含 `fsl,usbmisc = <0x21 0x00>`；`dr_mode = "otg"` | 删除 `fsl,usbmisc`；`dr_mode = "host"` | 适配部分模拟的 USB |
| 3 | `usb@2184200`（USB2） | 含 `fsl,usbmisc = <0x21 0x01>`；`dr_mode = "otg"` | 删除 `fsl,usbmisc`；`dr_mode = "host"` | 适配部分模拟的 USB |
| 4 | `memory-controller@21b0000`（MMDC DDR 控制器） | `compatible = "fsl,imx6ul-i2c\0fsl,imx6q-mmdc"`；启用 | `compatible = "qemu,disabled-mmdc"`；`status = "disabled"` | 禁用未模拟硬件 |
| 5 | `efuse@21bc000`（OCOTP / eFUSE） | `compatible = "fsl,imx6ul-ocotp\0syscon"`；启用 | `compatible = "qemu,disabled-ocotp"`；`status = "disabled"` | 禁用未模拟硬件 |
| 6 | `lcdif@21c8000`（LCD 显示控制器） | `status = "okay"` | `status = "disabled"` | 禁用无对应设备的显示 |
| 7 | `qspi@21e0000`（QuadSPI 闪存控制器） | `status = "okay"` | `status = "disabled"` | 禁用未模拟/不需要的存储 |
| 8 | `backlight-display`（PWM 背光） | `status = "okay"` | `status = "disabled"` | 禁用无对应设备的显示 |
| 9 | `panel`（innolux LCD 面板） | 默认启用 | 新增 `status = "disabled"` | 禁用无对应设备的显示 |

#### 逐项说明

**1. USB：禁用 usbmisc，强制 host 模式（最关键）**

i.MX6UL 的 USB 基于 ChipIdea 内核，其驱动通过 `fsl,usbmisc` 属性指向 `usbmisc` 模块，由它完成 OTG ID/角色检测、VBUS 控制、PHY 复位、过流保护等。但 QEMU 只模拟了 ChipIdea USB 核心，**没有实现 `usbmisc` 寄存器块**。因此：

- 把 `usbmisc@2184800` 设为 `status = "disabled"`，避免内核探测不存在的模块；
- 从两个 `usb@2184x00` 删除 `fsl,usbmisc = <0x21 ...>`，否则 USB 驱动初始化时会解引用被禁用的节点而失败；
- 把 `dr_mode` 由 `"otg"` 改为 `"host"`，因为虚拟机里没有真实 OTG ID 引脚，强制 Host 角色最实用（可挂键盘/存储等）。USB2 节点原本已带 `disable-over-current`，也说明虚拟机里没有过流检测 GPIO。

> 保留 USB 核心（`fsl,imx6ul-usb`）本身可用，只是绕开它所依赖、而 QEMU 未实现的 usbmisc，并固定为 host 模式。

**2. MMDC 内存控制器（`memory-controller@21b0000`）**

MMDC 是真实 DDR 内存控制器。QEMU 中内存由板级模型直接提供（`memory@80000000`，即 `-m 512M`），**不模拟 MMDC 这个 IP**。把 `compatible` 改成虚构的 `qemu,disabled-mmdc` 并 `status = "disabled"`，确保没有任何真实驱动去匹配它。

**3. OCOTP / eFUSE（`efuse@21bc000`）**

OCOTP 是芯片内部一次性可编程熔丝，原版 `compatible` 还带 `syscon`，其它节点（如以太网 MAC 地址）可能通过 `nvmem-cells` 引用它。QEMU 不模拟 OCOTP 寄存器，保留启用会导致内核读取熔丝而访问未实现 MMIO。改为 `qemu,disabled-ocotp` + `status = "disabled"` 后相关读取被跳过（MAC 地址由 QEMU 命令行/设备树显式指定即可）。

**4. 显示相关：LCDIF / 背光 / 面板**

`lcdif@21c8000`、`backlight-display`、`panel`（innolux AT043TN24）是真实 EVK 接 LCD 屏的整套链路。QEMU 没有显示输出设备也没有面板，让它们启用会触发无意义的 LCD 驱动探测。全部禁用后内核不会加载显示/帧缓冲驱动，保持串口控制台启动。

**5. QuadSPI（`qspi@21e0000`）**

QuadSPI 在真实板子上用于挂载 SPI NOR 启动闪存。本场景中内核直接由 `-kernel zImage` 加载、根文件系统走 SD 卡镜像，且 QEMU 未模拟该控制器，故禁用以避免无谓探测。

#### 重新编译为 dtb

修改 `.dts` 后 QEMU 实际使用的是 `.dtb`，需重新编译覆盖原文件：

```bash
dtc -I dts -O dtb -o imx6ul-14x14-evk.dtb imx6ul-14x14-evk-qemu.dts
```

然后用已 `chmod +x` 的 `run-qemu-original.sh` 启动即可。

#### 结论

这些修改的核心目的只有一个：**让“真实开发板”的设备树适配 QEMU 只模拟了部分外设的现实**——对完全没模拟的硬件（MMDC、OCOTP、LCDIF/背光/面板、QuadSPI）直接禁用；对模拟了核心但没模拟其依赖模块的 USB，则删掉对 `usbmisc` 的引用并固定 `dr_mode = "host"`，让可用部分继续工作。这样内核启动不会访问不存在的 MMIO 寄存器，启动更干净可靠。