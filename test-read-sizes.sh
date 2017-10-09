#!/bin/bash

insmod ~/btrfs-next/drivers/block/nbd.ko
pkill -9 nbd-server
echo none > /sys/block/nbd0/queue/scheduler
~/nbd/nbd-server -C ~/nbd/server.conf
~/nbd/nbd-client -D 10 -L -t 5 -N blah -C 4 localhost /dev/nbd0
sleep 5
echo none > /sys/block/nbd0/queue/scheduler
echo 4096 > /sys/block/nbd0/queue/max_sectors_kb
#blockdev --setra 4096 /dev/nbd0
mkfs.btrfs -f /dev/nbd0
mount /dev/nbd0 /mnt/btrfs-test
dd if=/dev/urandom of=/mnt/btrfs-test/file1 bs=1M count=256
dd if=/dev/urandom of=/mnt/btrfs-test/file2 bs=1M count=256
dd if=/dev/urandom of=/mnt/btrfs-test/file3 bs=1M count=256
dd if=/dev/urandom of=/mnt/btrfs-test/file4 bs=1M count=256
umount /mnt/btrfs-test
echo 3 > /proc/sys/vm/drop_caches
mount /dev/nbd0 /mnt/btrfs-test/

python ~/bcc/tools/blk-request-sizes.py -d /dev/nbd0 &
PID=$!
sleep 5
~/fio/fio 2mbreads.fio
kill -SIGINT $PID
wait
umount /mnt/btrfs-test
~/nbd/nbd-client -d /dev/nbd0
pkill -9 nbd-client
sleep 1
rmmod nbd
