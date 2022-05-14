#!/bin/sh

#zImage_head           16478
#payload(
#  vmlinux.bin         x
#  padding             0xf00000-x
#  vmlinux.bin size    4
#)                     0xf00004
#zImage_tail           114538
#crc32                 4

# Adapted from: scripts/Makefile.lib
# Usage: size_append FILE [FILE2] [FILEn]...
# Output: LE HEX with size of file in bytes (to STDOUT)
file_size_le () {
  printf $(
    dec_size=0;
    for F in "${@}"; do
      fsize=$(stat -c "%s" $F);
      dec_size=$(expr $dec_size + $fsize);
    done;
    printf "%08x\n" $dec_size |
      sed 's/\(..\)/\1 /g' | {
        read ch0 ch1 ch2 ch3;
        for ch in $ch3 $ch2 $ch1 $ch0; do
          printf '%s%03o' '\' $((0x$ch));
        done;
      }
  )
}

size_le () {
  printf $(
    printf "%08x\n" "${@}" |
      sed 's/\(..\)/\1 /g' | {
        read ch0 ch1 ch2 ch3;
        for ch in $ch3 $ch2 $ch1 $ch0; do
          printf '%s%03o' '\' $((0x$ch));
        done;
      }
  )
}
SCRIPT_DIR=`dirname $0`
VMLINUX_MOD=$PWD/vmlinux.bin
ZIMAGE_MOD=$PWD/zImage
gzip -cd $SCRIPT_DIR/zImage_template_v3.gz > $ZIMAGE_MOD

dd if=$VMLINUX_MOD of=$ZIMAGE_MOD bs=16478 seek=1 conv=notrunc
file_size_le $VMLINUX_MOD | dd of=$ZIMAGE_MOD bs=15745118 seek=1 conv=notrunc
# cksum $ZIMAGE_MOD # https://blog.box.com/crc32-checksums-the-good-the-bad-and-the-ugly
size_le $(($((16#$(php $PWD/crc32.php $ZIMAGE_MOD))) ^ 0xFFFFFFFF)) | dd of=$ZIMAGE_MOD conv=notrunc oflag=append