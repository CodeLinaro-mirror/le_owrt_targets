# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-3-Clause-Clear

#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
import math
import shlex
import hashlib
import struct
import logging
from pathlib import Path
from enum import Enum

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes

# -----------------------------------
# Logging
# -----------------------------------
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# -----------------------------------
# Constants
# -----------------------------------
SECTOR_SIZE = 512

# -----------------------------------
# Cipher Enum
# -----------------------------------
class CipherAlgorithm(Enum):
    AES_XTS = "aes-xts"
    AES_CBC = "aes-cbc"
    AES_ECB = "aes-ecb"
    AES_CTR = "aes-ctr"

# -----------------------------------
# Config
# -----------------------------------
class EncryptionConfig:
    SUPPORTED = {
        CipherAlgorithm.AES_XTS: [256, 512],
        CipherAlgorithm.AES_CBC: [128, 192, 256],
        CipherAlgorithm.AES_ECB: [128, 192, 256],
        CipherAlgorithm.AES_CTR: [128, 192, 256],
    }

    def __init__(self, algo, keysize):
        self.algorithm = CipherAlgorithm(algo)
        if keysize not in self.SUPPORTED[self.algorithm]:
            raise ValueError("Unsupported key size")

        self.keysize = keysize
        self.key_bytes = keysize // 8

# -----------------------------------
# Base Encryptor
# -----------------------------------
class BaseEncryptor:
    def __init__(self, config, key):
        self.config = config
        self.key = key

    def encrypt_sector(self, data, sector):
        raise NotImplementedError

    def encrypt_image(self, infile, outfile):
        with open(infile, "rb") as fin, open(outfile, "wb") as fout:
            sector = 0
            while True:
                chunk = fin.read(SECTOR_SIZE)
                if not chunk:
                    break

                if len(chunk) < SECTOR_SIZE:
                    chunk += b"\x00" * (SECTOR_SIZE - len(chunk))

                enc = self.encrypt_sector(chunk, sector)
                fout.write(enc)
                sector += 1

# -----------------------------------
# AES-XTS
# -----------------------------------
class AESXTSEncryptor(BaseEncryptor):
    def __init__(self, config, key):
        super().__init__(config, key)

        if config.keysize == 256:
            self.k1, self.k2 = key[:16], key[16:]
        else:
            self.k1, self.k2 = key[:32], key[32:]

    def mul2(self, tweak):
        t = int.from_bytes(tweak, "little")
        t = ((t << 1) & ((1 << 128) - 1)) ^ (0x87 if (t >> 127) else 0)
        return t.to_bytes(16, "little")

    def encrypt_sector(self, data, sector):
        tweak_cipher = AES.new(self.k2, AES.MODE_ECB)
        tweak = tweak_cipher.encrypt(struct.pack("<Q", sector) + b"\x00" * 8)

        aes = AES.new(self.k1, AES.MODE_ECB)
        out = b""

        for i in range(0, SECTOR_SIZE, 16):
            block = data[i:i+16]
            x = bytes(a ^ b for a, b in zip(block, tweak))
            y = aes.encrypt(x)
            c = bytes(a ^ b for a, b in zip(y, tweak))
            out += c
            tweak = self.mul2(tweak)

        return out

# -----------------------------------
# AES-CBC
# -----------------------------------
class AESCBCEncryptor(BaseEncryptor):
    def encrypt_sector(self, data, sector):
        iv = struct.pack("<Q", sector) + b"\x00" * 8
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return cipher.encrypt(data)

# -----------------------------------
# AES-ECB
# -----------------------------------
class AESECBEncryptor(BaseEncryptor):
    def encrypt_sector(self, data, sector):
        cipher = AES.new(self.key, AES.MODE_ECB)
        return cipher.encrypt(data)

# -----------------------------------
# AES-CTR
# -----------------------------------
class AESCTREncryptor(BaseEncryptor):
    def encrypt_sector(self, data, sector):
        nonce = struct.pack("<Q", sector)
        cipher = AES.new(self.key, AES.MODE_CTR, nonce=nonce)
        return cipher.encrypt(data)

# -----------------------------------
# Factory
# -----------------------------------
def get_encryptor(config, key):
    if config.algorithm == CipherAlgorithm.AES_XTS:
        return AESXTSEncryptor(config, key)
    if config.algorithm == CipherAlgorithm.AES_CBC:
        return AESCBCEncryptor(config, key)
    if config.algorithm == CipherAlgorithm.AES_ECB:
        return AESECBEncryptor(config, key)
    if config.algorithm == CipherAlgorithm.AES_CTR:
        return AESCTREncryptor(config, key)

# -----------------------------------
# MAIN
# -----------------------------------
def main():

    # Positional args
    if len(sys.argv) != 7:
        print("Usage:")
        print("python3 encrypt_image_cryptsetup.py <input> <output> <key> <algo> <keysize> <outdir>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    key_file = sys.argv[3]
    algo = sys.argv[4]
    keysize = int(sys.argv[5])
    system_images_dir = sys.argv[6]

    # create encrypt folder
    outdir = os.path.join(system_images_dir, "encrypt")
    os.makedirs(outdir, exist_ok=True)
    output_file = os.path.join(outdir, os.path.basename(output_file))

    # validations
    if not os.path.exists(input_file):
        print(" Input file missing")
        sys.exit(1)

    if not os.path.exists(key_file):
        print(" Key file missing")
        sys.exit(1)

    config = EncryptionConfig(algo, keysize)

    key = Path(key_file).read_bytes()

    if len(key) != config.key_bytes:
        print(" Key size mismatch")
        sys.exit(1)

    logger.info(f"Input: {input_file}")
    logger.info(f"Output: {output_file}")

    encryptor = get_encryptor(config, key)
    encryptor.encrypt_image(input_file, output_file)

    system_image_path = system_images_dir + '/system.squashfs'
    dest = shutil.copyfile(system_images_dir+'/encrypt/system_encrypt.squashfs', system_image_path)
#    print("\n Encryption complete")
#    print("\n Use this to open:")

    #  correct cipher mapping for cryptsetup
    cipher_name = algo
    if algo == "aes-xts":
        cipher_name = "aes-xts-plain64"

#    print(f"sudo cryptsetup open --type plain --cipher {cipher_name} "
#          f"--key-size {keysize} --key-file {key_file} {output_file} sys_dec")


if __name__ == "__main__":
    main()
