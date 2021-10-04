#!/bin/sh
qemu-system-x86_64 \
  -M pc \
  -kernel bzImage \
  -initrd rootfs.cpio.gz \
  -append "rootwait root=/dev/vda console=tty1 console=ttyS0" \
  -monitor /dev/null \
  -serial stdio \
  -nographic
