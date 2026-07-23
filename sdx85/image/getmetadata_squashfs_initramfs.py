# Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries. 
# SPDX-License-Identifier: BSD-3-Clause-Clear

"""
Utility is used for DM-verity for eMMC device with Squash fs
Following are done in this file
    1. calculate the DM_veirty metadata
    2. append the metadata to system image
    3. repack and  generate the  new sparse image
    4. update the kernel cmdline with new arg with boot args
Note: currently the file is not touching the main images it only copies
      the image to /verity  and update the image over there .
      Going fwd thi will not be case and should be having only one set of image
      with noverity bootloader
      Known issue , as this offline process done on verity folder if any thing goes
      wrong during this script it is not going to block / stop main compilation
      this is except as per design and we still have non-verity images
"""
import os
import sys
import subprocess
import os
import shutil
import math
import shlex

FIXED_SALT="aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7"
SECTOR_SIZE=512
BLOCK_SIZE=4096
FEC_ROOTS=2
VERITY_ALGO="sha256"

def append_verity_metadata_to_system_image2(system_image_raw_path, system_images_dir,staging_dir_hostpkg ,rootfs_dir,kdir, initramfs_dir, sha_type):
    fc_path = rootfs_dir+'/etc/selinux/selinux-policy/contexts/files/file_contexts'
    if os.path.exists(fc_path):
        SELINUX_EXT4_OPTS = '-S '+rootfs_dir+'/etc/selinux/selinux-policy/contexts/files/file_contexts'
    else:
        SELINUX_EXT4_OPTS = ' '
    VERITY_ALGO = sha_type
    verity_hash_file =  system_images_dir +'/verity/verityHash'
    verity_fec_file  = system_images_dir +'/verity/verityFEC'
    verity_roothash_file  = system_images_dir +'/verity/roothash.bin'

    #  new image new metadata append and check
    if os.path.exists(system_images_dir +'/veritys/verity_meta_data.txt'):
        os.remove(system_images_dir +'/verity/verity_meta_data.txt')
        os.remove(system_images_dir +'/verity/verityHash')
        os.remove(system_images_dir +'/verity/verityFEC')
        os.remove(system_images_dir +'/verity/roothash.bin')


    # Root hash bin format for initramfs approach
    cmd = 'veritysetup format '+ system_images_dir+'/verity/system.squashfs' +' '+ verity_hash_file +' --fec-device ' +verity_fec_file+'  --fec-roots ' + str(FEC_ROOTS)+' --salt ' +FIXED_SALT + ' --hash ' + str(VERITY_ALGO + ' --root-hash-file ' + verity_roothash_file )
    print('cmd ->' +  str(cmd))
    proc = subprocess.Popen(shlex.split(cmd), shell=False, stdout=subprocess.PIPE)
    VERITY_META = proc.communicate()[0]
    hash_offset=os.path.getsize(system_image_raw_path)

    with open(system_image_raw_path, "ab") as img, open(verity_hash_file, "rb") as ht:
        img.write(ht.read())
        hash_size=os.path.getsize(verity_hash_file)
        fec_offset = (int(hash_offset) + int(hash_size)) // 4096
    with open(system_image_raw_path, "ab") as img, open(verity_fec_file, "rb") as ht:
        img.write(ht.read())
    with open(system_images_dir +'/verity/verity_meta_data.txt', 'w') as f_metadata:
        entries = VERITY_META.decode('utf-8').split("\n")[1:-1]
        for entry in entries:
           key, value = entry.split(": ")
           key = key.replace(" ", "")
           locals()[key] = value.strip()
#          print(key +'-> ' + value)
           if  key == 'Roothash':
               continue
           if  key == 'Datablocks':
               Datablocks = value.strip()
           f_metadata.write(key+'   '+ value+ '\n')
        f_metadata.close()

    ROOT_SECTORS = int(Datablocks) * 8

    cmd =  'openssl smime -sign -nocerts -noattr -binary  -in '+system_images_dir+'/verity/roothash.bin -inkey '+ system_images_dir+'/verity_key.pem  -signer '+system_images_dir+'/verity_cert.pem  -outform der -out '+ system_images_dir+'/verity/verity_sig.bin'
    ret = subprocess.call(shlex.split(cmd), shell=False)

    # need update the metadata file with this details
    #    print("Appending the images ")
    with open(system_images_dir+'/verity/verity_meta_data.txt', 'a') as u_metadata:
        u_metadata.write('fec_offset      '+ str(fec_offset))
        u_metadata.write('\nhash_offset      '+ str( hash_offset))
        u_metadata.close()

    #copy the metadata, Root hash and signature bins into initramfs
    system_image_verity_metadata_path = initramfs_dir+'/etc/verity_meta_data.txt'
    dest = shutil.copyfile(system_images_dir+'/verity/verity_meta_data.txt', system_image_verity_metadata_path)
    system_image_verity_sig_path = initramfs_dir+'/etc/verity_sig.bin'
    dest = shutil.copyfile(system_images_dir+'/verity/verity_sig.bin', system_image_verity_sig_path)
    system_image_roothash_path = initramfs_dir+'/etc/roothash.bin'
    dest = shutil.copyfile(system_images_dir+'/verity/roothash.bin', system_image_roothash_path)

def generate_boot_images(kdir,kcmdline,kernel_baseaddr,out_images_path,ramdisk_path,ramdisk_offset):
     cmdline= kcmdline +' verity=enabled '

     # Regenrating Boot image by adding verity cmdline.
     cmd = kdir+ '/build-tools/mkbootimg/mkbootimg.py  --kernel '+ kdir + '/Image --cmdline  "' + cmdline+ '" --pagesize 4096 --base ' + str(kernel_baseaddr)+' '+' --header_version 2 --ramdisk '+ ramdisk_path + ' --ramdisk_offset '+ ramdisk_offset +' --dtb '+ kdir + '/dtb.img --output '+ out_images_path+'/boot.img'
     ret = subprocess.call(shlex.split(cmd), shell=False)
     if ret != 0:
          print("-->!!!!Generation of verity boot image failed .%s" % cmd)

     # Boot image is regenerated without verity.
     cmd = kdir+ '/build-tools/mkbootimg/mkbootimg.py  --kernel '+ kdir + '/Image --cmdline  "' + kcmdline+ '" --pagesize 4096 --base ' + str(kernel_baseaddr)+' '+' --header_version 2 --ramdisk '+ ramdisk_path + ' --ramdisk_offset '+ ramdisk_offset +' --dtb '+ kdir + '/dtb.img --output '+ out_images_path+'/boot.noverity.img'
     ret = subprocess.call(shlex.split(cmd), shell=False)
     if ret != 0:
          print("-->!!!!Generation of noverity boot image failed .%s" % cmd)


if __name__ == "__main__":
    # total arguments
    num_arg = len(sys.argv)
    # Arguments passed
    if num_arg < 3:
        print('-->wrong usage of utility ')
        sys.exit()
    elif num_arg == 7:
         print ('-->Generating verity boot images')
         for i in range(1, num_arg):
            print(sys.argv[i], end = "\n")
            kernel_dir = str(sys.argv[1])
            kernel_cmdline = str(sys.argv[2])
            kernel_baseaddr = str(sys.argv[3])
            out_images_path = str(sys.argv[4])
            ramdisk_path = str(sys.argv[5])
            ramdisk_offset = str(sys.argv[6])
            generate_boot_images(kernel_dir, kernel_cmdline,kernel_baseaddr, out_images_path, ramdisk_path, ramdisk_offset)
    elif num_arg == 8:
        print('--> Generating verity System image(eMMC Device)!')
        for i in range(1, num_arg):
            print(sys.argv[i], end = " \n")
        SYSTEM_IMAGE_ROOTFS_SIZE = sys.argv[1]
        staging_dir_hostpkg = sys.argv[2]
        system_images_dir = sys.argv[3]
        rootfs_dir = sys.argv[4]
        kdir = sys.argv[5]
        initramfs_dir = sys.argv[6]
        sha_type = sys.argv[7]
        if os.path.exists(system_images_dir+ '/verity'):
               shutil.rmtree(system_images_dir + '/verity')
        try:
            os.mkdir( system_images_dir + '/verity')
        except OSError as error:
            print(error)
        system_image_raw_path = system_images_dir + '/verity/system.squashfs'
        dest = shutil.copyfile(system_images_dir+'/system.squashfs', system_image_raw_path)
        system_image_raw_path = system_images_dir + '/verity/system.squashfs'
        append_verity_metadata_to_system_image2(system_image_raw_path, system_images_dir, staging_dir_hostpkg, rootfs_dir, kdir, initramfs_dir, sha_type )
        system_image_path = system_images_dir + '/system.squashfs'
        dest = shutil.copyfile(system_images_dir+'/verity/system.squashfs', system_image_path)
