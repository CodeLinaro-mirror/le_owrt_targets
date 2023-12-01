include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk
include generate-ubinize-cfg.mk
include generate-ab-rootfs.mk
include $(TOPDIR)/owrt-qti-bsp/include/ota-ext4.mk
include $(TOPDIR)/owrt-qti-bsp/include/ota-ubi.mk
include $(TOPDIR)/owrt-qti-bsp/include/abota-ext4.mk
include $(TOPDIR)/owrt-qti-bsp/include/abota-ubi.mk
include generate-build-prop.mk

KERNEL_BASEADDR = 0x80000000
EXT4_IMAGE_SIZE = 262144000
UBI_IMAGE_SIZE = 253952
UBIFS_OPTS = -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F
USERDATA_SIZE_EXT4 = 251658240
SYSTEMRW_IMAGE_ROOTFS_SIZE = 8192KB
UBINIZE_CFG = ubinize-$(BOARD).cfg
UBINIZE_CFG_AB = ubinize-$(BOARD)-ab.cfg
RECOVERY_UBINIZE_CFG = ubinize-recoveryfs.cfg
RECOVERY_UBIFS_IMAGE = recoveryfs.ubifs
RECOVERY_MKUBIFS_ARGS = -m 4096 -e 253952 -c 200 -F
RECOVERYFS_SIZE_EXT4 ?= 52428800
CACHE_SIZE_EXT4 = 52428800
OTA_SCRIPTS_PATH = ${BUILD_DIR}/OTA/ota-scripts
RELEASE_TOOLS_PATH = $(TOPDIR)/src/OTA/build/tools/releasetools
BUILD_PROP = build.prop
PERSIST_SIZE_EXT4 = 8192KB

ifeq ($(TARGET_VARIANT),debug)
KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates,/firmware/image service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat"
endif

ROOTFS_VOLUME_SIZE_AB = "90MiB"
SYSTEM_VOLUME_SIZE_G = "150MiB"
SYSTEM_VOLUME_SIZE = "110MiB"
SYSTEM_VOLUME_SIZE_512 = "66MiB"

ifeq ($(PROFILE),mbb-min)
ROOTFS_VOLUME_SIZE = $(SYSTEM_VOLUME_SIZE)
else ifeq ($(PROFILE),mbb-512)
ROOTFS_VOLUME_SIZE = $(SYSTEM_VOLUME_SIZE_512)
else
ROOTFS_VOLUME_SIZE = $(SYSTEM_VOLUME_SIZE_G)
endif


ifeq ($(TARGET_VARIANT),perf)
KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates,/firmware/image service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat no_console_suspend=1 loglevel=0"
endif

TARGET_SHA_TYPE = "sha256"

ifeq ($(PROFILE),recovery)
IMAGE_ROOTFS = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/recovery/root-$(BOARD)
else
IMAGE_ROOTFS = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/root-$(BOARD)
IMAGE_ROOTFS_AB = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/root-$(BOARD)-ab
endif

ifeq ($(USER_VARIANT),1)
IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/user/$(BOARD)/$(PROFILE)
IMAGE_PRODUCTS_DIR_AB = $(TOPDIR)/bin/targets/user/$(BOARD)/$(PROFILE)-ab
else
IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)
IMAGE_PRODUCTS_DIR_AB = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)-ab
endif

RECOVERY_IMGS_PATH = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/recovery
RECOVERY_ROOTFS_PATH = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/recovery/root-$(BOARD)

SELINUX_UBI_OPTS := --selinux=$(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts
SELINUX_EXT4_OPTS := -S $(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts

ifeq ($(PROFILE),recovery)
define Image/Prepare
	mkdir -p $(IMAGE_ROOTFS)/lib/modules/$(UNAME_VERSION)
	mkdir -p $(IMAGE_PRODUCTS_DIR)
	mkdir -p ${IMAGE_ROOTFS}/cache
	mkdir -p ${IMAGE_ROOTFS}/cache/recovery
	mkdir -p ${IMAGE_ROOTFS}/persist
	$(call Image/GenerateBuildProp)
endef

define Image/mkfs/ubifs
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}/etc/uci-defaults/13_fix-group-user; \
	)
	( 	echo \[recoveryfs_volume\] > $(RECOVERY_UBINIZE_CFG); \
		echo mode=ubi >> $(RECOVERY_UBINIZE_CFG); \
		echo image=\"$(RECOVERY_UBIFS_IMAGE)\" >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_id=0 >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_type=dynamic >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_name=rootfs >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_size=\"30MiB\" >> $(RECOVERY_UBINIZE_CFG); \
		$(CP) ./$(RECOVERY_UBINIZE_CFG) $(KDIR) \
	)
	( cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS)  -o $(RECOVERY_UBIFS_IMAGE) $(RECOVERY_MKUBIFS_ARGS); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o recoveryfs.ubi -m 4096 -p 256KiB -s 4096 $(RECOVERY_UBINIZE_CFG); \
	$(CP) $(KDIR)/recoveryfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	)
endef

define Image/mkfs/ext4
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}/etc/uci-defaults/13_fix-group-user; \
	)
	( cd $(IMAGE_PRODUCTS_DIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs $(SELINUX_EXT4_OPTS) -l $(RECOVERYFS_SIZE_EXT4) recoveryfs.img -a / $(IMAGE_ROOTFS) \
	)
endef

else

define Image/Prepare
	mkdir -p $(IMAGE_ROOTFS)/lib/modules/$(UNAME_VERSION)
	mkdir -p $(IMAGE_PRODUCTS_DIR)
	mkdir -p ${IMAGE_ROOTFS}/cache
	mkdir -p ${IMAGE_ROOTFS}/cache/recovery
	mkdir -p ${IMAGE_ROOTFS}/persist
	mkdir -p $(IMAGE_PRODUCTS_DIR_AB)
	$(call Image/AB/GenerateABRootfs)
	$(call Image/GenerateBuildProp)
endef

define Image/GenerateUbiImages
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}$(1)/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}$(1)/etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS)$(1) -o sysfs.ubifs -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(IMAGE_ROOTFS)$(1)/data -o userfs.ubifs -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F; \
	$(call Image/Build/generate-ubinize-cfg$(1))
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize \
		-o sysfs.ubi -m 4096 -p 256KiB -s 4096 \
		ubinize-$(BOARD)$(1).cfg \
	)
	( $(CP) $(KDIR)/sysfs.ubifs $(IMAGE_PRODUCTS_DIR)$(1)/; \
	  $(CP) $(KDIR)/sysfs.ubi $(IMAGE_PRODUCTS_DIR)$(1)/; \
	  $(CP) $(KDIR)/userfs.ubifs $(IMAGE_PRODUCTS_DIR)$(1)/; \
	  $(CP) $(KDIR)/ubinize-$(BOARD)$(1).cfg $(IMAGE_PRODUCTS_DIR)$(1)/; \
	)
endef

ifeq ($(and $(wildcard $(RECOVERY_IMGS_PATH)/recoveryfs.ubi), $(wildcard $(RECOVERY_ROOTFS_PATH))),)
define Ota/Build/ubi
	$(warning "WARNING: Preconditions for OTA Package generation not met. Please ensure the recovery profile has been built!")
endef
endif

define Image/mkfs/ubifs
	$(call Image/GenerateUbiImages)
	$(call Image/GenerateUbiImages,-ab)
	$(call Ota/Build/ubi,4k)
	$(call Ota/Build/ubi_ab,4k)
endef

define Image/GenerateExt4Images
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}$(1)/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}$(1)/etc/uci-defaults/13_fix-group-user; \
	)
	if [ $(CONFIG_PACKAGE_dmverity-utils) == y ]; then \
		$(CP) $(TOPDIR)/src/kernel-$(LINUX_VERSION)/out/msm-kernel-$(KERNEL_PLATFORM_TARGET)-$(TARGET_VARIANT)_defconfig/msm-kernel/certs/verity* \
		$(IMAGE_PRODUCTS_DIR)$(1) ; \
	fi
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -B userdata.map -a /data -b 4096 -s -l $(USERDATA_SIZE_EXT4) userdata.img $(IMAGE_ROOTFS)$(1)/data \
	)
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -a /systemrw -s -b 4096 -l $(SYSTEMRW_IMAGE_ROOTFS_SIZE) systemrw.img $(IMAGE_ROOTFS)$(1)/overlay \
	)
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -a /cache -s -b 4096 -l $(CACHE_SIZE_EXT4) cache.img $(IMAGE_ROOTFS)$(1)/cache \
	)
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
                fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -a /persist -s -b 4096 -l $(PERSIST_SIZE_EXT4) persist.img $(IMAGE_ROOTFS)$(1)/persist \
        )
	if [ $(CONFIG_OTA_RECOVERY_UPDATE) == y ]; then \
		$(call Ota/Build/compute_sha1); \
	fi
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs $(SELINUX_EXT4_OPTS) -B system.map -a / -b 4096 -s -l $(EXT4_IMAGE_SIZE) system.img $(IMAGE_ROOTFS)$(1) \
	)
	( cd $(IMAGE_PRODUCTS_DIR)$(1); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs $(SELINUX_EXT4_OPTS) -B system.map -a / -b 4096  -l $(EXT4_IMAGE_SIZE) system.img.raw $(IMAGE_ROOTFS)$(1) \
	)
	if [ $(CONFIG_PACKAGE_dmverity-utils) == y ]; then \
		python getmetadata.py  $(EXT4_IMAGE_SIZE) $(STAGING_DIR_HOSTPKG) $(IMAGE_PRODUCTS_DIR)$(1) $(IMAGE_ROOTFS)$(1)  $(KDIR); \
		while [ ! -f  $(IMAGE_PRODUCTS_DIR)$(1)/system.img ]; do sleep 1; done; \
	fi
endef

define Image/GenerateBootImage
	( cd $(TOPDIR)/src/kernel-$(LINUX_VERSION)/kernel_platform && BUILD_CONFIG=msm-kernel/build.config.msm.$(KERNEL_PLATFORM_TARGET) OUT_DIR=../out/msm-kernel-$(KERNEL_PLATFORM_TARGET)-$(TARGET_VARIANT)_defconfig/ \
		./build/android/merge_dtbs.sh \
		$(KDIR)/kernel_dtbs \
		$(KDIR)/techpack-dtbos $(KDIR)/merged_dtbs; \
		$(CP) $(KDIR)/merged_dtbs/dtb.img $(KDIR)/; \
	)
	( cd $(KDIR); \
		$(CP) $(KDIR)/vmlinux $(IMAGE_PRODUCTS_DIR); \
		$(CP) $(KDIR)/vmlinux $(IMAGE_PRODUCTS_DIR_AB); \
		$(KDIR)/build-tools/mkbootimg/mkbootimg.py --kernel $(KDIR)/Image \
		--cmdline $(KERNEL_CMDLINE) --pagesize 4096 --base $(KERNEL_BASEADDR) --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb $(KDIR)/dtb.img --output boot.img; \
	)
	( cd $(KDIR); \
		$(CP) boot.img boot.img.nonsecure; \
		openssl dgst -$(TARGET_SHA_TYPE) -binary boot.img.nonsecure > boot.img.$(TARGET_SHA_TYPE); \
		openssl pkeyutl -sign -in boot.img.$(TARGET_SHA_TYPE) \
				-inkey $(TOPDIR)/owrt-qti-bsp-prop/support-packages/sectool5/sigkeys/vble-qti.key \
				-out boot.img.sig -pkeyopt digest:$(TARGET_SHA_TYPE) -pkeyopt rsa_padding_mode:pkcs1; \
		dd if=/dev/zero of=boot.img.sig.padded bs=2048 count=1 ;\
		dd if=boot.img.sig of=boot.img.sig.padded conv=notrunc; \
		cat boot.img.nonsecure boot.img.sig.padded > boot.img.secure; \
		rm -rf boot.img.${TARGET_SHA_TYPE} boot.img.sig boot.img.sig.padded boot.img.nonsecure; \
		mv -f boot.img.secure boot.img; \
		$(CP) $(KDIR)/boot.img $(IMAGE_PRODUCTS_DIR); \
		$(CP) $(KDIR)/boot.img $(IMAGE_PRODUCTS_DIR_AB); \
		$(CP) $(IMAGE_PRODUCTS_DIR)/abl.elf $(IMAGE_PRODUCTS_DIR_AB); \
	)

endef


ifeq ($(and $(wildcard $(RECOVERY_IMGS_PATH)/recoveryfs.img), $(wildcard $(RECOVERY_ROOTFS_PATH))),)
define Ota/Build/ext4
	$(warning "WARNING: Preconditions for OTA Package generation not met. Please ensure recovery profile has been built!")
endef
endif

define Image/mkfs/ext4
	$(call Image/GenerateBootImage)
	$(call Image/GenerateExt4Images)
	if [ $(CONFIG_PACKAGE_dmverity-utils) == y ]; then \
		python  getmetadata.py $(KDIR) $(KERNEL_CMDLINE) $(KERNEL_BASEADDR) $(IMAGE_PRODUCTS_DIR);\
		while [ ! -f  $(IMAGE_PRODUCTS_DIR)/boot.img ]; do sleep 1; done; \
	fi
	$(call Image/GenerateExt4Images,-ab)
	if [ $(CONFIG_PACKAGE_dmverity-utils) == y ]; then \
		python  getmetadata.py $(KDIR) $(KERNEL_CMDLINE) $(KERNEL_BASEADDR) $(IMAGE_PRODUCTS_DIR_AB);\
		while [ ! -f  $(IMAGE_PRODUCTS_DIR_AB)/boot.img ]; do sleep 1; done; \
	fi
	$(call Ota/Build/releasetools-native)
	$(call Ota/Build/ext4)
	$(call Ota/Build/target-files-zip-ext4-ab)
	$(call Ota/Build/gen_ota_full_zip_ext4_ab)
endef

endif

define Image/Build
	$(call Image/Build/$(1))
endef

$(eval $(call BuildImage))
