OTA_TARGET_FILES_UBI = "target-files-ubi.zip"
IMAGE_SYSTEM_MOUNT_POINT_UBI = "/system"
OTA_TARGET_IMAGE_ROOTFS_UBI = ${BUILD_DIR}/OTA/ota-target-image-ubi
IMAGE_ROOTFS_UBI = $(TOPDIR)/build_dir/target-aarch64_cortex-a53_musl/root-sdx75
OTA_TARGET_FILES_UBI_PATH = $(IMAGE_PRODUCTS_DIR)/$(OTA_TARGET_FILES_UBI)
MACHINE_FILESMAP_FULL_PATH_UBI = $(TOPDIR)/owrt-qti-bsp/conf/machine/filesmap/sdx75-nand-filesmap
OTA_FULL_UPDATE_UBI = "full_update_ubi.zip"
OTA_FULL_UPDATE_UBI_PATH = $(IMAGE_PRODUCTS_DIR)/$(OTA_FULL_UPDATE_UBI)
SIGN_OTA_PACKAGE = ""

ifeq ($(CONFIG_OTA_PACKAGE_VERIFICATION), y)
	SIGN_OTA_PACKAGE = "--sign"
endif

define Ota/Build/gen_ota_full_zip_ubi
	cd $(BUILD_DIR)/OTA/ota-scripts; \
	rm -rf update_ubi.zip; \
	./full_ota.sh ${OTA_TARGET_FILES_UBI_PATH} ${IMAGE_ROOTFS_UBI} ubi --block --system_path ${IMAGE_SYSTEM_MOUNT_POINT_UBI} $(SIGN_OTA_PACKAGE); \
	if [[ -e update_ubi.zip ]]; then \
		cp update_ubi.zip ${OTA_FULL_UPDATE_UBI_PATH}; \
	else \
		echo "update_ubi.zip failed to create"; \
	fi
endef

define Ota/Build/target-files-zip-ubi
	rm -rf $(OTA_TARGET_IMAGE_ROOTFS_UBI)
	rm -rf $(OTA_TARGET_FILES_UBI_PATH)

	mkdir -p $(OTA_TARGET_IMAGE_ROOTFS_UBI)
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/BOOTABLE_IMAGES
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/OTA
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/SYSTEM
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RADIO
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/IMAGES
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/BOOT/RAMDISK

	echo "base image rootfs: $(IMAGE_ROOTFS)"
	echo "recovery image rootfs: ${IMAGE_ROOTFS}/../recovery/root-$(BOARD)"

	# if exists copy filesmap into RADIO directory
	[[ ! -z ${MACHINE_FILESMAP_FULL_PATH_UBI} ]] && install -m 755 ${MACHINE_FILESMAP_FULL_PATH_UBI} ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RADIO/filesmap

	cp $(IMAGE_PRODUCTS_DIR)/boot.img $(OTA_TARGET_IMAGE_ROOTFS_UBI)/BOOTABLE_IMAGES/boot.img
	cp $(IMAGE_PRODUCTS_DIR)/boot.img $(OTA_TARGET_IMAGE_ROOTFS_UBI)/BOOTABLE_IMAGES/recovery.img
	cp $(IMAGE_PRODUCTS_DIR)/sysfs.ubifs $(OTA_TARGET_IMAGE_ROOTFS_UBI)/BOOTABLE_IMAGES/system.img
	echo dm_verity_nand=1 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt
	if [ $(CONFIG_OTA_RECOVERY_UPDATE) == y ]; then \
		cp $(IMAGE_PRODUCTS_DIR)/../recovery/recoveryfs.ubi $(OTA_TARGET_IMAGE_ROOTFS_UBI)/BOOTABLE_IMAGES/recoveryfs.ubi; \
		echo recovery_upgrade_supported=1 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt; \
	fi

	# copy the contents of system rootfs
	cp -r $(IMAGE_ROOTFS)/. $(OTA_TARGET_IMAGE_ROOTFS_UBI)/SYSTEM/.
	#cd $(OTA_TARGET_IMAGE_ROOTFS_UBI)/SYSTEM
	#rm -rf var/run
	#ln -snf ../run var/run

	# copy the contents of recovery rootfs
	cp -r ${IMAGE_ROOTFS}/../recovery/root-$(BOARD)/. $(OTA_TARGET_IMAGE_ROOTFS_UBI)/RECOVERY/.

	#generate recovery.fstab which is used by the updater-script
	#echo #mount point fstype device [device2] >> $(OTA_TARGET_IMAGE_ROOTFS_UBI)/RECOVERY/recovery.fstab
	echo /boot     mtd     boot >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/recovery.fstab
	echo /cache    ubifs  cache >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/recovery.fstab
	echo /data     ubifs  userdata >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/recovery.fstab
	echo /recovery mtd    recovery >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/recovery.fstab

	#Getting content for OTA folder
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI}/OTA/bin
	cp ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/usr/bin/applypatch ${OTA_TARGET_IMAGE_ROOTFS_UBI}/OTA/bin/.
	cp ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/usr/bin/updater ${OTA_TARGET_IMAGE_ROOTFS_UBI}/OTA/bin/.

	echo /system   ubifs  system >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/RECOVERY/recovery.fstab

    # Pack releasetools.py into META folder itself.
    # This could also have been done by passing "--device_specific" to
    # ota_from_target_files.py but it would be hacky to find the absolute path there.
	cp ${TOPDIR}/src/OTA/device/qcom/common/releasetools.py ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/.

    # copy contents of META folder
    #recovery_api_version is from recovery module
	echo recovery_api_version=3 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #blocksize = BOARD_FLASH_BLOCK_SIZE
	echo blocksize=131072 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    # boot_size: Size of boot partition from partition.xml
	echo boot_size=43000000 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    # recovery_size : Size of recovery partition from partition.xml
	echo recovery_size=0x00C00000 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #system_size : Size of system partition from partition.xml
	echo system_size=0x00A00000 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #userdate_size : Size of data partition from partition.xml
	echo userdata_size=0x00A00000 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #cache_size : Size of data partition from partition.xml
	echo cache_size=0x00A00000 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #mkyaffs2_extra_flags : -c $(BOARD_KERNEL_PAGESIZE) -s $(BOARD_KERNEL_SPARESIZE)
	echo mkyaffs2_extra_flags=-c 4096 -s 16 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #extfs_sparse_flag : definition in build
	echo extfs_sparse_flags=-s >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

    #default_system_dev_certificate : Dummy location
	echo default_system_dev_certificate=build/abcd >> ${OTA_TARGET_IMAGE_ROOTFS_UBI}/META/misc_info.txt

	cd ${OTA_TARGET_IMAGE_ROOTFS_UBI} && zip -qry ${OTA_TARGET_FILES_UBI_PATH} *
endef
