#!/bin/sh

# Description
# -----------
# testcase for cache resume

T=$1

. ../../config

# echo create test data
# dd if=/dev/urandom of=./1sec-1 bs=512 count=1
# dd if=/dev/urandom of=./1sec-2 bs=512 count=1

echo making expected data
dd if=/dev/zero of=./expect.dump bs=512 count=8 oflag=direct
dd if=./1sec-1 of=./expect.dump bs=512 count=1 conv=notrunc oflag=direct
dd if=./1sec-2 of=./expect.dump bs=512 count=1 seek=1 conv=notrunc oflag=direct
#dd if=./1sec-1 of=./expect.dump conv=notrunc oflag=append bs=512 count=1 oflag=direct

echo 7 > /proc/sys/kernel/printk

echo Clear backing
dd if=/dev/zero of=${BACKING} bs=512 count=8

echo Kill cache
dd if=/dev/zero of=${CACHE} bs=512 count=1 oflag=direct

echo Making device
sz=`blockdev --getsize ${BACKING}`
if [ $T -eq 0 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 0 ${BACKING} ${CACHE} 4 rambuf_pool_amount 8192 segment_size_order 7 6 enable_migration_modulator 0 allow_migrate 0 sync_interval 0"
elif [ $T -eq 1 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 1 ${BACKING} ${CACHE} ${PLOG} 4 rambuf_pool_amount 8192 segment_size_order 7 6 enable_migration_modulator 0 allow_migrate 0 sync_interval 0"
fi

echo Suspend and Resume
dmsetup suspend writeboost-vol
dmsetup resume writeboost-vol

echo Write to seek 1
dd if=./1sec-2 of=/dev/mapper/writeboost-vol bs=512 count=1 seek=1 oflag=direct

echo Suspend and Resume
dmsetup suspend writeboost-vol
dmsetup resume writeboost-vol

echo Write to seek 0
dd if=./1sec-1 of=/dev/mapper/writeboost-vol bs=512 count=1 oflag=direct

echo 3 > /proc/sys/vm/drop_caches

echo Suspend and Resume
dmsetup suspend writeboost-vol
dmsetup resume writeboost-vol

echo Remove and Build
dmsetup remove writeboost-vol
if [ $T -eq 0 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 0 ${BACKING} ${CACHE} 4 rambuf_pool_amount 8192 segment_size_order 7 6 enable_migration_modulator 0 allow_migrate 0 sync_interval 0"
elif [ $T -eq 1 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 1 ${BACKING} ${CACHE} ${PLOG} 4 rambuf_pool_amount 8192 segment_size_order 7 6 enable_migration_modulator 0 allow_migrate 0 sync_interval 0"
fi

echo Read the device
dd if=/dev/mapper/writeboost-vol of=./actual.dump bs=512 count=8

diff ./actual.dump ./expect.dump
if [ $? -ne 0 ]; then
    echo BUG: Dump NOT expected!!!
fi

dmsetup remove writeboost-vol