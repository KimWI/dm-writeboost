# NAME=writeboost_4_32_t1_ram # _numjobs_iodepth
NAME=tmp # tmp
mkdir -p result/$NAME
fio randw4k.fio > result/$NAME/fio &
sar -A 1 5 -o result/$NAME/sar &
# blktrace -w 15 -I devlist -D $NAME/blktrace &
