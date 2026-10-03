#! /usr/bin/env bash

if [ "$(stat -c%s rootfs.ext2)" -lt $((64 * 1024 * 1024)) ]; then
    echo "rootfs.ext2 is too small, resize it to at 64MB"
    truncate -s 64M rootfs.ext2
fi

qemu-system-arm -M mcimx6ul-evk -m 512M -kernel zImage -dtb imx6ul-14x14-evk-qemu.dtb  \
    -drive file=rootfs.ext2,if=sd,format=raw -append "console=ttymxc0 root=/dev/mmcblk0 rw rootwait" -nographic -no-reboot