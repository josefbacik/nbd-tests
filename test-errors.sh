#!/bin/bash

OPTS=
[ $# -eq 1 ] && [ $1 = "netlink" ] && OPTS="-D 10 -L"

echo $OPTS
insmod ~/btrfs-next/drivers/block/nbd.ko
#echo none > /sys/block/nbd0/queue/scheduler
pkill -9 nbd-server
~/nbd/nbd-server -C ~/nbd/server.conf
~/nbd/nbd-client $OPTS -t 5 -N fail -C 4 -M localhost /dev/nbd1 &
~/nbd/nbd-client $OPTS -t 5 -N fail -C 4 -M localhost /dev/nbd0 &
sleep 10
mkfs.xfs -f /dev/nbd1
mount /dev/nbd1 /mnt/btrfs-test
~/fio/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
	--name=test --directory=/mnt/btrfs-test --nrfiles=48 --numjobs=12 \
	--bs=4M --iodepth=256 --size=4800M --io_size=400G --readwrite=randrw \
	--fsync=100
umount /mnt/btrfs-test
~/nbd/nbd-client -d /dev/nbd1
pkill -9 nbd-client
sleep 1
rmmod nbd
