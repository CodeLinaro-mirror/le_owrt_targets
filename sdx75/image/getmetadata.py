# Copyright (c) 2023-2025 Qualcomm Innovation Center, Inc. All rights reserved
# SPDX-License-Identifier: BSD-3-Clause-Clear

"""
Utility is used for DM-verity for eMMC device with ext4 fs
Following are done in this file
    1. adjust_system_size_for_verity so that we can add meta data
    2. calculate the DM_veirty metadata
    3. append the metadata to system image
    4. repack and  generate the  new sparse image
    5. update the kernel cmdline with new arg with boot args
Note: currently the file is not touching the main images it only copies
      the image to /verity  and update the image over there .
      Going fwd thi will not be case and should be having only one set of image
      with noverity bootloader
      Kown issue , as this offline process done on verity folder if any thing goes
      wrong during this script it is not going to block / stop main compilation
      this is except as per desing and we still have non-verity images
"""
import os
import sys
import subprocess
import os
import shutil
import math

FIXED_SALT="aee087a5be3b982978c923f566a94613496b417f2af592639bc80d141e34dfe7"
SECTOR_SIZE=512
BLOCK_SIZE=4096
FEC_ROOTS=2
VERITY_ALGO = "sha256"

def adjust_system_size_for_verity (count):
#    print(str(count) +' ,'+ str(SYSTEM_IMAGE_ROOTFS_SIZE) )
    adjusted_size = int(int(SYSTEM_IMAGE_ROOTFS_SIZE) * count / 100)
#   Align to 4096 block size
    adjusted_size = (adjusted_size + 4095) // 4096 * 4096
#   print( 'adj_size :' + str(adjusted_size)+'..' + str(count))
    return(adjusted_size)

def append_verity_metadata_to_system_image2(system_image_raw_path, system_images_dir,staging_dir_hostpkg ,rootfs_dir,kdir):
    SELINUX_EXT4_OPTS = '-S '+rootfs_dir+'/etc/selinux/selinux-policy/contexts/files/file_contexts'
    verity_hash_file =  system_images_dir +'/verity/verityHash'
    verity_fec_file  = system_images_dir +'/verity/verityFEC'

    for count  in range(94, 0, -1):
        #  new image new metadata append and check
        if os.path.exists(system_images_dir +'/verity/verity_meta_data.txt'):
            os.remove(system_images_dir +'/verity/verity_meta_data.txt')
            os.remove(system_images_dir +'/verity/verityHash')
            os.remove(system_images_dir +'/verity/verityFEC')
        cmd = 'veritysetup format '+ system_images_dir+'/verity/system.img.raw' +' '+ verity_hash_file +' --fec-device ' +verity_fec_file+'  --fec-roots ' + str(FEC_ROOTS)+' --salt ' +FIXED_SALT
        proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        VERITY_META = proc.communicate()[0]
        with open(system_images_dir +'/verity/verity_meta_data.txt', 'w') as f_metadata:
            entries = VERITY_META.decode('utf-8').split("\n")[1:-1]
            for entry in entries:
                key, value = entry.split(": ")
                key = key.replace(" ", "")
                locals()[key] = value.strip()
#               print(key +'-> ' + value)
                if  key == 'Roothash':
                    Roothash = value.strip()
                if  key == 'Datablocks':
                    Datablocks = value.strip()
                f_metadata.write(key+'   '+ value+ '\n')
        f_metadata.close()

        # Append hash and fec data to the image
        with open(system_image_raw_path, 'ab') as file_raw:
           with open(system_images_dir +'/verity/verityHash', 'rb') as  hash_file:
                file_raw.write(hash_file.read())
                hash_file.close()
           with open(system_images_dir +'/verity/verityFEC', 'rb') as fec_file:
                file_raw.write(fec_file.read())
                fec_file.close()
        file_raw.close()


# Check if size is within the range
        systemSize = os.stat(system_image_raw_path).st_size
        print('--> done with new verity image --rechecking %d' %(systemSize))
        if int(systemSize) > int(SYSTEM_IMAGE_ROOTFS_SIZE) :
#           print('Size mismatch '+ str(systemSize) +' Vs '+ str(SYSTEM_IMAGE_ROOTFS_SIZE)+'...recreating unsparse image.')
            #os.remove(system_images_dir + '/verity/system.img.raw')
# creating new image with new size
            adjustedSystemSize= adjust_system_size_for_verity (count)
#           print( '-->'+str(count) +'.....' + str(adjustedSystemSize))
            cmd = 'fakeroot '+staging_dir_hostpkg+'/bin/make_ext4fs '+ SELINUX_EXT4_OPTS + ' -B ' +system_images_dir+'/system.map -a / -b 4096  -l '+ str(adjustedSystemSize)+' '+ system_image_raw_path +' ' + rootfs_dir
#           result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE )
            result = subprocess.run(cmd, shell=True)
#           print('result -->'+ str(result.returncode) +result.stdout.decode('utf-8'))
#           we see some time return code as  returncode=1, stdout=b'', stderr=b'failed to open block_list_file: Permission denied
            systemSize = os.stat(system_image_raw_path).st_size
            if systemSize != 0:
                print(' resizing of system image ..' )
                continue
        else:
#       Image meets the requirements so bailing out
            count = 0
            break

# Calculate offset
    hash_offset = adjustedSystemSize
    hash_size=os.path.getsize(system_images_dir +'/verity/verityHash')
    fec_offset = (int(hash_offset) + int(hash_size)) // 4096
## Creating the verity cmdline that is requried .
    ROOT_SECTORS = int(Datablocks) * 8
    with open(system_images_dir +'/verity/cmdline', 'w') as cmdline_file:
        vcmdline = 'verity=\\"'+ str(ROOT_SECTORS)+' '+ str(Datablocks.strip())+' '+  str((Roothash).strip()) + ' '+ str(fec_offset) + ' 1\\"'
        cmdline_file.write(vcmdline)
        cmdline_file.close()

# need update the metadata file with this details
#    print("Appending the images ")
    with open(system_images_dir+'/verity/verity_meta_data.txt', 'a') as u_metadata:
         u_metadata.write('fec_offset      '+ str(fec_offset))
         u_metadata.write('\nhash_offset      '+ str( hash_offset))
         u_metadata.close()
# Convert to sparse image
    img2simg = staging_dir_hostpkg + '/bin/img2simg'
    cmd =  img2simg + " %s %s " % (system_images_dir+'/verity/system.img.raw', system_images_dir + '/system.img')
    ret = subprocess.call(cmd, shell=True)
    if ret != 0:
            print("-->!!!Repacking of system image to  Sparse Failed cmd:%s" % cmd)
#Sign the hash withe know key ,
    with open(system_images_dir+'/verity/roothash.txt', 'w' ) as  hash_text:
        hash_text.write(Roothash)
        hash_text.close()
#copy the certs which keep updating with kernel build
    cmd =  'openssl smime -sign -nocerts -noattr -binary  -in '+system_images_dir+'/verity/roothash.txt -inkey '+ system_images_dir+'/verity_key.pem  -signer '+system_images_dir+'/verity_cert.pem  -outform der -out '+ system_images_dir+'/verity/verity_sig.txt'
    ret = subprocess.call(cmd, shell=True)



def generate_boot_images(kdir,kcmdline,kernel_baseaddr, out_images_path):
     with open(out_images_path+'/verity/cmdline', 'r') as c_file:
           vcmdline = c_file.read()
           c_file.close()
     print("Veritycmdline =" + vcmdline)
     cmdline= kcmdline +' '+'dm-mod.waitfor=/dev/dm-0'+' '+vcmdline
   #  os.chdir(kdir)
   #  cmd = 'build-tools/mkbootimg/mkbootimg.py --kernel Image 	--cmdline "' +cmdline+'" --pagesize 4096 --base '+kernel_baseaddr + ' --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb ' + 'dtb.img --output '+ out_images_path+'/boot.img'
     cmd = kdir+ '/build-tools/mkbootimg/mkbootimg.py  --kernel '+ kdir + '/Image --cmdline  "' + cmdline+ '" --pagesize 4096 --base ' + str(kernel_baseaddr)+' '+' --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb '+ kdir + '/dtb.img --output '+ out_images_path+'/boot.img'
     ret = subprocess.call(cmd, shell=True)
     if ret != 0:
          print("-->!!!!Generation of verity boot image failed .%s" % cmd)

   #  cmd = 'build-tools/mkbootimg/mkbootimg.py --kernel Image 	--cmdline "' +kcmdline+'" --pagesize 4096 --base '+kernel_baseaddr + ' --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb ' + 'dtb.img --output '+ out_images_path+'/boot.noverity.img'
     cmd = kdir+ '/build-tools/mkbootimg/mkbootimg.py  --kernel '+ kdir + '/Image --cmdline  "' + kcmdline+ '" --pagesize 4096 --base ' + str(kernel_baseaddr)+' '+' --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb '+ kdir + '/dtb.img --output '+ out_images_path+'/boot.noverity.img'
     ret = subprocess.call(cmd, shell=True)
     if ret != 0:
          print("-->!!!!Generation of noverity boot image failed .%s" % cmd)


if __name__ == "__main__":
    # total arguments
    num_arg = len(sys.argv)
    # Arguments passed
    if num_arg < 3:
        print('-->wrong usage of utility ')
        sys.exit()
    elif num_arg == 5:
         print ('-->Generating verity boot images')
         for i in range(1, num_arg):
            print(sys.argv[i], end = "\n")
            kernel_dir = str(sys.argv[1])
            kernel_cmdline = str(sys.argv[2])
            kernel_baseaddr = str(sys.argv[3])
            out_images_path = str(sys.argv[4])
            generate_boot_images(kernel_dir, kernel_cmdline,kernel_baseaddr, out_images_path)
    elif num_arg == 6:
        print('--> Generating verity System image(eMMC Device)!')
        for i in range(1, num_arg):
            print(sys.argv[i], end = " \n")
        SYSTEM_IMAGE_ROOTFS_SIZE = sys.argv[1]
        staging_dir_hostpkg = sys.argv[2]
        system_images_dir = sys.argv[3]
        rootfs_dir = sys.argv[4]
        kdir = sys.argv[5]
        if os.path.exists(system_images_dir+ '/verity'):
               shutil.rmtree(system_images_dir + '/verity')
        try:
            os.mkdir( system_images_dir + '/verity')
        except OSError as error:
            print(error)
        system_image_raw_path = system_images_dir + '/verity/system.img.raw'
        dest = shutil.copyfile(system_images_dir+'/system.img.raw', system_image_raw_path)
        system_image_raw_path = system_images_dir + '/verity/system.img.raw'
        append_verity_metadata_to_system_image2(system_image_raw_path, system_images_dir, staging_dir_hostpkg, rootfs_dir,kdir )

