#!/bin/bash

#
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#

CLIENT="$1"
KEY_SIZE=${2:-32}
INITRAMFS_ROOTFS_LOCAL="$3"
SEC_PATH_LOCAL="$4"
SEC_PROFILE_LOCAL=$5
PUBLIC_KEY_LOCAL=$6

# Generate RAW binary key
openssl rand "$KEY_SIZE" > key.bin

CLIENT_LEN=${#CLIENT}

: > buffer.bin

# client length
perl -e "print pack('V',$CLIENT_LEN)" >> buffer.bin

# client name
printf "%s" "$CLIENT" >> buffer.bin

# key length
perl -e "print pack('V',$KEY_SIZE)" >> buffer.bin

# key bytes
cat key.bin >> buffer.bin

$SEC_PATH_LOCAL/sectools elf-tool generate --data buffer.bin --outfile buffer.elf

$SEC_PATH_LOCAL/sectools secure-image buffer.elf  --security-profile $SEC_PROFILE_LOCAL  --image-id 'IP-PROTECTOR' --feature-id 0x7 --outfile $INITRAMFS_ROOTFS_LOCAL/lib/firmware/wrapped_key.mbn --sign --signing-mode TEST --anti-rollback-version 0x0 --encrypt --encryption-mode LOCAL --l1-key $PUBLIC_KEY_LOCAL
