IMAGE_SYSTEM_MOUNT_POINT_UBI = "/system"
OTA_TARGET_IMAGE_ROOTFS_UBI_AB = ${BUILD_DIR}/OTA/ota-target-image-ubi-ab
OTA_TARGET_FILES_UBI_AB = "target-files-ubi-ab.zip"
OTA_FULL_UPDATE_UBI_AB = "full_update_ubi_ab.zip"
OTA_FULL_UPDATE_UBI_AB_PATH = $(IMAGE_PRODUCTS_DIR)-ab/$(OTA_FULL_UPDATE_UBI_AB)
OTA_TARGET_FILES_UBI_AB_PATH = $(IMAGE_PRODUCTS_DIR)-ab/$(OTA_TARGET_FILES_UBI_AB)
MACHINE_FILESMAP_FULL_PATH_UBI = $(TOPDIR)/owrt-qti-bsp/conf/machine/filesmap/sdx75-nand-filesmap

SIGN_OTA_PACKAGE = ""

ifeq ($(CONFIG_OTA_PACKAGE_VERIFICATION), y)
	SIGN_OTA_PACKAGE = "--sign"
endif

define Ota/Build/gen_ota_full_zip_ubi_ab
	cd $(BUILD_DIR)/OTA/ota-scripts; \
	rm -rf update_ubi_ab.zip; \
	./full_ota.sh ${OTA_TARGET_FILES_UBI_AB_PATH} ${IMAGE_ROOTFS}-ab ubi --block --system_path ${IMAGE_SYSTEM_MOUNT_POINT_UBI} $(SIGN_OTA_PACKAGE); \
	cp update_ubi.zip ${OTA_FULL_UPDATE_UBI_AB_PATH}
endef

define Ota/Build/target-files-zip-ubi-ab
	rm -rf $(OTA_TARGET_IMAGE_ROOTFS_UBI_AB)
	rm -rf $(OTA_TARGET_FILES_UBI_AB_PATH)

	mkdir -p $(OTA_TARGET_IMAGE_ROOTFS_UBI_AB)
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/BOOTABLE_IMAGES
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/OTA
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/SYSTEM
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RADIO
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/IMAGES
	mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/BOOT/RAMDISK

	echo "base image rootfs: $(IMAGE_ROOTFS)-ab"
	#same as base image rootfs
	echo "recovery image rootfs: $(IMAGE_ROOTFS)-ab/../recovery/root-$(BOARD)"

    # if exists copy filesmap into RADIO directory
	[[ ! -z ${MACHINE_FILESMAP_FULL_PATH_UBI} ]] && install -m 755 ${MACHINE_FILESMAP_FULL_PATH_UBI} ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RADIO/filesmap

    cp $(IMAGE_PRODUCTS_DIR)-ab/boot.img ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/BOOTABLE_IMAGES/boot.img
    cp $(IMAGE_PRODUCTS_DIR)-ab/boot.img ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/BOOTABLE_IMAGES/recovery.img
	cp $(IMAGE_PRODUCTS_DIR)-ab/sysfs.ubifs ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/BOOTABLE_IMAGES/system.img
	echo dm_verity_nand=1 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt


    cp -r ${IMAGE_ROOTFS}-ab/. ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/SYSTEM/.
    #cd  ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/SYSTEM
    #rm -rf var/run
    #ln -snf ../run var/run

    cp -r ${IMAGE_ROOTFS}-ab/. ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/.

    #generate recovery.fstab which is used by the updater-script
    echo #mount point fstype device [device2] >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab
    echo /boot     mtd     boot >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab
    echo /cache    ubifs  cache >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab
    echo /data     ubifs  userdata >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab
    echo /recovery mtd     recovery >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab
    echo /system   ubifs     system >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/recovery.fstab

    #Getting content for OTA folder
    mkdir -p ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/OTA/bin
    cp   ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/usr/bin/applypatch ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/OTA/bin/.
    cp   ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/RECOVERY/usr/bin/updater ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/OTA/bin/.


    # Pack releasetools.py into META folder itself.
    # This could also have been done by passing "--device_specific" to
    # ota_from_target_files.py but it would be hacky to find the absolute path there.
    cp ${TOPDIR}/src/OTA/device/qcom/common/releasetools.py ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/.

    # copy contents of META folder
    #recovery_api_version is from recovery module
    echo recovery_api_version=3 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    #blocksize = BOARD_FLASH_BLOCK_SIZE
    echo blocksize=131072 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    #mkyaffs2_extra_flags : -c $(BOARD_KERNEL_PAGESIZE) -s $(BOARD_KERNEL_SPARESIZE)
    echo mkyaffs2_extra_flags=-c 4096 -s 16 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    #extfs_sparse_flag : definition in build
    echo extfs_sparse_flags=-s >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    #default_system_dev_certificate : Dummy location
    echo default_system_dev_certificate=build/abcd >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    echo le_target_supports_ab=1 >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    echo "blockimgdiff_versions=3" >> ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB}/META/misc_info.txt

    cd ${OTA_TARGET_IMAGE_ROOTFS_UBI_AB} && zip -qry ${OTA_TARGET_FILES_UBI_AB_PATH} *
endef
