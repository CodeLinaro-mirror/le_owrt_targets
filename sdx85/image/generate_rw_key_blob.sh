#!/bin/bash

#
# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#

CLIENT="$1"
KEY_SIZE=${2:-32}
IMAGE_ROOTFS_LOCAL="$3"
SEC_PATH_LOCAL="$4"
SEC_PROFILE_LOCAL=$5
PUBLIC_KEY_LOCAL=$6

# Generate RAW binary key
openssl rand "$KEY_SIZE" > key_rw.bin

CLIENT_LEN=${#CLIENT}

: > buffer_rw.bin

# client length
perl -e "print pack('V',$CLIENT_LEN)" >> buffer_rw.bin

# client name
printf "%s" "$CLIENT" >> buffer_rw.bin

# key length
perl -e "print pack('V',$KEY_SIZE)" >> buffer_rw.bin

# key bytes
cat key_rw.bin >> buffer_rw.bin

$SEC_PATH_LOCAL/sectools elf-tool generate --data buffer_rw.bin --outfile buffer_rw.elf

$SEC_PATH_LOCAL/sectools secure-image buffer_rw.elf  --security-profile $SEC_PROFILE_LOCAL  --image-id 'IP-PROTECTOR' --feature-id 0x7 --outfile $IMAGE_ROOTFS_LOCAL/data/wrapped_key.mbn --sign --signing-mode TEST --anti-rollback-version 0x0 --encrypt --encryption-mode LOCAL --l1-key $PUBLIC_KEY_LOCAL

$SEC_PATH_LOCAL/sectools secure-image buffer_rw.elf  --security-profile $SEC_PROFILE_LOCAL  --image-id 'IP-PROTECTOR' --feature-id 0x7 --outfile $IMAGE_ROOTFS_LOCAL-ab/data/wrapped_key.mbn --sign --signing-mode TEST --anti-rollback-version 0x0 --encrypt --encryption-mode LOCAL --l1-key $PUBLIC_KEY_LOCAL
