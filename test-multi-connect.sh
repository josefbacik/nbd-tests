#!/bin/bash

_exit() {
	echo $1
	exit 1
}

insmod ~/btrfs-next/drivers/block/nbd.ko
pkill -9 nbd-server
~/nbd/nbd-server -C ~/nbd/server.conf

echo "netlink then ioctl"
~/nbd/nbd-client -L -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1 \
	|| _exit "WE FUCKED UP"
~/nbd/nbd-client -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1
[ $? -eq 0 ] && _exit "Allowed two connections!"

~/nbd/nbd-client -d /dev/nbd0

echo "ioctl then netlink"
~/nbd/nbd-client -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1 \
	|| _exit "WE FUCKED UP"
~/nbd/nbd-client -L -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1
[ $? -eq 0 ] && _exit "Allowed two connections!"

~/nbd/nbd-client -d /dev/nbd0

echo "two netlink"
~/nbd/nbd-client -L -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1 \
	|| _exit "WE FUCKED UP"
~/nbd/nbd-client -L -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1
[ $? -eq 0 ] && _exit "Allowed two connections!"

~/nbd/nbd-client -d /dev/nbd0

echo "two ioctl"
~/nbd/nbd-client -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1 \
	|| _exit "WE FUCKED UP"
~/nbd/nbd-client -t 5 -N fail -C 4 localhost /dev/nbd0 > /dev/null 2>&1
[ $? -eq 0 ] && _exit "Allowed two connections!"

~/nbd/nbd-client -d /dev/nbd0
sleep 1
rmmod nbd
