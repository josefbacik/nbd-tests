#!/bin/bash

insmod ~/btrfs-next/drivers/block/nbd.ko
pkill -9 nbd-server
#echo none > /sys/block/nbd0/queue/scheduler
~/nbd/nbd-server -C ~/nbd/server.conf
~/nbd/nbd-client -M -D 10 -L -t 5 -N blah -C 4 localhost /dev/nbd0 &
sleep 5
#echo none > /sys/block/nbd0/queue/scheduler
mkfs.btrfs -f /dev/nbd0
mount /dev/nbd0 /mnt/btrfs-test
~/fio/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
	--name=test --directory=/mnt/btrfs-test --nrfiles=48 --numjobs=12 \
	--bs=4M --iodepth=256 --size=4800M --io_size=4G --readwrite=randrw \
	--fsync=100
umount /mnt/btrfs-test
~/nbd/nbd-client -d /dev/nbd0
pkill -9 nbd-client
sleep 1
rmmod nbd
