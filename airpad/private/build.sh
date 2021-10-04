#!/bin/sh

FAKE_FLAG="The flag is on the remote box! Go get it!!!"
REAL_FLAG="The flag is: tstlss{g1v3_fl4g_plx_ktxhbai!}"

unset PERL_MM_OPT

rm -r ../public
mkdir -p ../public/qemu
cp ./qemu/run.sh ../public/qemu
rm ./qemu_private.tar.gz


#wget 'https://buildroot.org/downloads/buildroot-2021.02.4.tar.gz'
tar -xvf buildroot-2021.02.4.tar.gz
mv buildroot-2021.02.4 buildroot
cp buildroot_files/buildroot_config ./buildroot/.config

echo $FAKE_FLAG > ./buildroot_files/rootfs_overlay/home/user2/flag.txt
cd buildroot && make -j$(nproc) && cd -
cp buildroot/output/images/bzImage ../public/qemu
cp buildroot/output/images/rootfs.cpio.gz ../public/qemu

echo $REAL_FLAG > ./buildroot_files/rootfs_overlay/home/user2/flag.txt
cd buildroot && make -j$(nproc) && cd -
cp buildroot/output/images/bzImage ./qemu
cp buildroot/output/images/rootfs.cpio.gz ./qemu

tar -cvf qemu_private.tar ./qemu/* && gzip qemu_private.tar
cd ../public && tar -cvf qemu.tar ./qemu/* && gzip qemu.tar
