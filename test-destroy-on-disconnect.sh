#!/bin/bash

insmod ~/btrfs-next/drivers/block/nbd.ko nbds_max=0
pkill -9 nbd-server
~/nbd/nbd-server -C ~/nbd/server.conf
~/nbd/nbd-client -L -e -t 5 -N fail -C 4 localhost &
sleep 10
#echo none > /sys/block/nbd0/queue/scheduler
mkfs.btrfs -f /dev/nbd0
mount /dev/nbd0 /mnt/btrfs-test
~/fio/fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
	--name=test --directory=/mnt/btrfs-test --nrfiles=48 --numjobs=12 \
	--bs=4M --iodepth=256 --size=4800M --io_size=400G --readwrite=randrw \
	--fsync=100 &
sleep 5
~/nbd/nbd-client -d /dev/nbd0
stat /dev/nbd0 > /dev/null 2>&1
[ $? -ne 0 ] && echo "WE FUCKED UP PART 1" && exit 1
umount /mnt/btrfs-test
stat /dev/nbd0 > /dev/null 2>&1
[ $? -eq 0 ] && echo "WE FUCKED UP PART 2" && exit 1
sleep 1
rmmod nbd
