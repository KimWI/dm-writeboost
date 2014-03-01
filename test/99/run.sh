#!/bin/sh

# Description
# -----------
# what if disk fails?

T=$1

. ../../config

echo 7 > /proc/sys/kernel/printk

dd if=/dev/zero of=${CACHE} bs=512 count=1 oflag=direct

sz=`blockdev --getsize ${CACHE}`
dmsetup create cache-flakey --table "0 ${sz} flakey ${CACHE} 0 5 1"
CACHE=/dev/mapper/cache-flakey

sz=`blockdev --getsize ${BACKING}`
dmsetup create backing-flakey --table "0 ${sz} flakey ${BACKING} 0 20 0"
BACKING=/dev/mapper/backing-flakey

if [ $T -eq 0 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 0 ${BACKING} ${CACHE} 2 segment_size_order 10 8 enable_migration_modulator 1 sync_interval 1 update_record_interval 600 barrier_deadline_ms 3"
elif [ $T -eq 1 ]; then
    dmsetup create writeboost-vol --table "0 ${sz} writeboost 1 ${BACKING} ${CACHE} ${PLOG} 2 segment_size_order 10 8 enable_migration_modulator 1 sync_interval 0 update_record_interval 600 barrier_deadline_ms 3"
fi

dd if=/dev/urandom of=/dev/mapper/writeboost-vol
if [ $? -eq 0 ]; then
    echo BUG: dd should fail
fi

dmsetup remove writeboost-vol
if [ $? -ne 0 ]; then
    echo BUG: remove failed
fi