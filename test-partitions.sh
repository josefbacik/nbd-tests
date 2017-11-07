#!/bin/bash

_fail () {
	echo $*
	wipefs -a /dev/nbd0
	~/nbd/nbd-client -d /dev/nbd0
	exit 1
}

insmod ~/btrfs-next/drivers/block/nbd.ko
pkill -9 nbd-server
#echo none > /sys/block/nbd0/queue/scheduler
~/nbd/nbd-server -C server.conf
~/nbd/nbd-client -N blah localhost /dev/nbd0 > /dev/null 2>&1
parted -s /dev/nbd0 mklabel msdos > /dev/null 2>&1
parted -s /dev/nbd0 mkpart primary 0 100 > /dev/null 2>&1
~/nbd/nbd-client -d /dev/nbd0 > /dev/null 2>&1

sleep 1

stat /dev/nbd0p1 > /dev/null 2>&1 && _fail "Partition exists after disconnect"

# Do it with ioctls

echo "Testing IOCTL path"

~/nbd/nbd-client -N blah localhost /dev/nbd0 > /dev/null 2>&1
sleep 1
stat /dev/nbd0p1 > /dev/null 2>&1 || _fail "Partition doesn't exist after connect"
~/nbd/nbd-client -d /dev/nbd0 > /dev/null 2>&1

sleep 1

stat /dev/nbd0p1 > /dev/null 2>&1 && _fail "Partition exists after disconnect"

# Do it with netlink
echo "Testing the netlink path"
~/nbd/nbd-client -L -N blah localhost /dev/nbd0 > /dev/null 2>&1
sleep 1
stat /dev/nbd0p1 >/dev/null 2>&1 || _fail "Partition doesn't exist after connect"
~/nbd/nbd-client -L -d /dev/nbd0 > /dev/null 2>&1

sleep 1

stat /dev/nbd0p1 > /dev/null 2>&1 && _fail "Partition exists after disconnect"

rmmod nbd || _fail "Couldn't rmmod nbd"
