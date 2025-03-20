include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk
include $(TOPDIR)/owrt-qti-bsp/include/ota-ubi.mk
include $(TOPDIR)/owrt-qti-bsp/include/abota-ubi.mk
include generate-ab-rootfs.mk
include generate-build-prop.mk

KERNEL_BASEADDR = 0x80000000
EXT4_IMAGE_SIZE = 209715200
UBI_IMAGE_SIZE = 253952
PAGE_SIZE = 4096
UBI_PEB_SIZE = 256KiB
USERDATA_SIZE_EXT4 = 251658240
SYSTEMRW_IMAGE_ROOTFS_SIZE = 8192KB
RECOVERY_UBINIZE_CFG = ubinize-recoveryfs.cfg
RECOVERY_UBIFS_IMAGE = recoveryfs.ubifs
RECOVERY_MKUBIFS_ARGS = -m 4096 -e 253952 -c 200 -F
RECOVERY_UBINIZE_CFG_2K = ubinize-recoveryfs-2k.cfg
RECOVERY_UBIFS_IMAGE_2K = recoveryfs-2k.ubifs
RECOVERY_MKUBIFS_ARGS_2K = -m 2048 -e 126976 -c 200 -F
BUILD_PROP = build.info

KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat pci=pcie_bus_perf"
TARGET_SHA_TYPE = "sha256"

ifeq ($(PROFILE),recovery)
	IMAGE_ROOTFS = $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/recovery/root-$(BOARD)
else
	IMAGE_ROOTFS = $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-$(BOARD)
ifeq ($(PROFILE),mbb)
	IMAGE_ROOTFS_AB = $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-$(BOARD)-ab
endif
endif

ifeq ($(USER_VARIANT),1)
	IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/user/$(BOARD)/$(PROFILE)
ifeq ($(PROFILE),mbb)
	IMAGE_PRODUCTS_DIR_AB = $(TOPDIR)/bin/targets/user/$(BOARD)/$(PROFILE)-ab
endif

else
	IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)
ifeq ($(PROFILE),mbb)
	IMAGE_PRODUCTS_DIR_AB = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)-ab
endif

endif

RECOVERY_IMGS_PATH = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/recovery
RECOVERY_ROOTFS_PATH = $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/recovery/root-$(BOARD)

ifeq ($(BUILD_WITH_MEMOPT),1)
	UBI_IMAGE_SIZE = 126976
	PAGE_SIZE = 2048
	UBI_PEB_SIZE = 128KiB
endif

define Image/Prepare
	mkdir -p $(IMAGE_ROOTFS)/lib/modules/$(UNAME_VERSION)
	mkdir -p $(IMAGE_PRODUCTS_DIR)
	mkdir -p $(IMAGE_ROOTFS)/cache
	mkdir -p $(IMAGE_ROOTFS)/persist
	$(SED_BIN_PATH) -i 's/enforcing/disabled/g'  $(RECOVERY_ROOTFS_PATH)/etc/selinux/config
	$(call Image/GenerateBuildProp)
endef

ifneq ($(CONFIG_TARGET_ROOTFS_SECURITY_LABELS),)
SELINUX_UBI_OPTS := --selinux=$(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts
SELINUX_EXT4_OPTS := -S $(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts
endif

ifeq ($(and $(wildcard $(RECOVERY_IMGS_PATH)/recoveryfs.ubi), $(wildcard $(RECOVERY_ROOTFS_PATH))),)
define Ota/Build/ubi
	$(warning "WARNING: Preconditions for OTA Package generation not met. Please ensure the recovery profile has been built!")
endef

endif
ifeq ($(PROFILE),recovery)

define Image/Build/ubifs
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' $(IMAGE_ROOTFS)/etc/passwd; \
		rm -rf $(IMAGE_ROOTFS)/etc/uci-defaults/13_fix-group-user; \
	)
	( 	echo \[recoveryfs_volume\] > $(RECOVERY_UBINIZE_CFG); \
		echo mode=ubi >> $(RECOVERY_UBINIZE_CFG); \
		echo image=\"$(RECOVERY_UBIFS_IMAGE)\" >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_id=0 >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_type=dynamic >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_name=rootfs >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_flags = autoresize >> $(RECOVERY_UBINIZE_CFG); \
		$(CP) ./$(RECOVERY_UBINIZE_CFG) $(KDIR); \
		echo \[recoveryfs_volume\] > $(RECOVERY_UBINIZE_CFG_2K); \
		echo mode=ubi >> $(RECOVERY_UBINIZE_CFG_2K); \
		echo image=\"$(RECOVERY_UBIFS_IMAGE_2K)\" >> $(RECOVERY_UBINIZE_CFG_2K); \
		echo vol_id=0 >> $(RECOVERY_UBINIZE_CFG_2K); \
		echo vol_type=dynamic >> $(RECOVERY_UBINIZE_CFG_2K); \
		echo vol_name=rootfs >> $(RECOVERY_UBINIZE_CFG_2K); \
		echo vol_flags = autoresize >> $(RECOVERY_UBINIZE_CFG_2K); \
		$(CP) ./$(RECOVERY_UBINIZE_CFG_2K) $(KDIR); \
	)
	( cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS)  -o $(RECOVERY_UBIFS_IMAGE) $(RECOVERY_MKUBIFS_ARGS); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o recoveryfs.ubi -m 4096 -p 256KiB -s 4096 $(RECOVERY_UBINIZE_CFG); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS)  -o $(RECOVERY_UBIFS_IMAGE_2K) $(RECOVERY_MKUBIFS_ARGS_2K); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o recoveryfs-2k.ubi -m 2048 -p 128KiB -s 2048 $(RECOVERY_UBINIZE_CFG_2K); \
	$(CP) $(KDIR)/recoveryfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	$(CP) $(KDIR)/recoveryfs-2k.ubi $(IMAGE_PRODUCTS_DIR)/; \
	$(CP) $(KDIR)/ubinize-recoveryfs.cfg $(IMAGE_PRODUCTS_DIR)/; \
	$(CP) $(KDIR)/ubinize-recoveryfs-2k.cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
endef

else

ifneq ($(CONFIG_TARGET_ROOTFS_UBIFS),)

ifneq ($(CONFIG_TARGET_sdx35_m2),)

define Image/Build/ubifs
	$(CP) ./ubinize-sdx35-M2.cfg $(KDIR)
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' $(IMAGE_ROOTFS)/etc/passwd; \
		rm -rf $(IMAGE_ROOTFS)/etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS) -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(IMAGE_ROOTFS)/data -o userfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-M2.cfg; \
	)
	( $(CP) $(KDIR)/sysfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35-M2.cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
	$(call Ota/Build/releasetools-native)
	$(call Ota/Build/ubi,2k)
endef

else

define Image/Build/ubifs
	$(CP) ./ubinize-sdx35.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-2k.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-128m.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-128m-2k.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-m2-128m-2k.cfg $(KDIR)
ifeq ($(PROFILE), mbb)
	$(call Image/AB/GenerateABRootfs)
	$(CP) ./ubinize-sdx35-ab.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-ab-2k.cfg $(KDIR)
endif
	$(CP) ./ubinize-sdx35-2k-squashfs.cfg $(KDIR)
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' $(IMAGE_ROOTFS)/etc/passwd; \
		rm -rf $(IMAGE_ROOTFS)etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS) -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS) -o sysfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(IMAGE_ROOTFS)/data -o userfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(IMAGE_ROOTFS)/data -o userfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOST)/bin/mksquashfs4 $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 sysfs-2k.squashfs -noappend -comp xz -noI -b 64K -processors 1; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 -o sysfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/data -o userfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/data -o userfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-2k.cfg; \
		fakeroot $(STAGING_DIR_HOST)/bin/ubinize -o sysfs-2k-squash.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-2k-squashfs.cfg; \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs.ubi -m 4096 -p 256KiB -s 4096 ubinize-sdx35.cfg; \
	)
	( if [ "$(PROFILE)" == "mbb-128m" ]; then \
	(cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-128m-2k.cfg; \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs.ubi -m 4096 -p 256KiB -s 4096 ubinize-sdx35-128m.cfg; \
	); \
	fi; \
	)
	( if [ "$(PROFILE)" == "m2-128m" ]; then \
	(cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-m2-128m-2k.cfg; \
	); \
	fi; \
	)
	( $(CP) $(KDIR)/sysfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k.squashfs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k-squash.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35.cfg $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35-2k.cfg $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35-2k-squashfs.cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
	( if [ "$(PROFILE)" == "mbb" ]; then \
	(cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' $(IMAGE_ROOTFS_AB)/etc/passwd; \
		rm -rf $(IMAGE_ROOTFS_AB)/etc/uci-defaults/13_fix-group-user; \
	); \
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS_AB) -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS_AB) -o sysfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-ab-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-ab-2k.cfg; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-ab.ubi -m 4096 -p 256KiB -s 4096 ubinize-sdx35-ab.cfg; \
	$(CP) $(KDIR)/sysfs.ubifs $(IMAGE_PRODUCTS_DIR_AB)/; \
	$(CP) $(KDIR)/sysfs-2k.ubifs $(IMAGE_PRODUCTS_DIR_AB)/; \
	$(CP) $(KDIR)/sysfs-ab.ubi $(IMAGE_PRODUCTS_DIR_AB)/sysfs.ubi; \
	$(CP) $(KDIR)/sysfs-ab-2k.ubi $(IMAGE_PRODUCTS_DIR_AB)/sysfs-2k.ubi; \
	$(CP) $(KDIR)/userfs-2k.ubifs $(IMAGE_PRODUCTS_DIR_AB)/; \
	$(CP) $(KDIR)/userfs.ubifs $(IMAGE_PRODUCTS_DIR_AB)/; \
	$(CP) $(KDIR)/ubinize-sdx35-ab.cfg $(IMAGE_PRODUCTS_DIR_AB)/; \
	$(CP) $(KDIR)/ubinize-sdx35-ab-2k.cfg $(IMAGE_PRODUCTS_DIR_AB)/; \
	fi ; \
	)
	$(call Ota/Build/releasetools-native)
	$(call Ota/Build/ubi,2k)
	$(call Ota/Build/ubi,4k)
ifeq ($(PROFILE),mbb)
	$(call Ota/Build/ubi_ab,2k)
	$(call Ota/Build/ubi_ab,4k)
endif
endef
endif

endif

ifneq ($(CONFIG_TARGET_sdx35),)
define Image/Build/ext4
	( cd $(TOPDIR)/src/kernel-5.15/kernel_platform && BUILD_CONFIG=msm-kernel/$(BUILD_CONFIG_NAME) OUT_DIR=../out/$(OUT_DIR_NAME)/ \
		./build/android/merge_dtbs.sh \
		$(KDIR)/kernel_dtbs \
		$(KDIR)/techpack-dtbos $(KDIR)/merged_dtbs; \
		$(CP) $(KDIR)/merged_dtbs/dtb.img $(KDIR)/; \
	)
	( cd $(KDIR); \
		$(CP) $(KDIR)/vmlinux $(IMAGE_PRODUCTS_DIR); \
		$(KDIR)/build-tools/mkbootimg/mkbootimg.py --kernel $(KDIR)/zImage \
		--cmdline $(KERNEL_CMDLINE) --pagesize 4096 --base $(KERNEL_BASEADDR) --header_version 2 --ramdisk /dev/null --ramdisk_offset 0x0 --dtb $(KDIR)/dtb.img --output boot.img \
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
		if [ "$(PROFILE)" == "mbb" ]; then \
		mkdir -p $(IMAGE_PRODUCTS_DIR_AB); \
		$(CP) $(KDIR)/vmlinux $(IMAGE_PRODUCTS_DIR_AB); \
		$(CP) $(KDIR)/boot.img $(IMAGE_PRODUCTS_DIR_AB); \
		$(CP) $(IMAGE_PRODUCTS_DIR)/abl.elf $(IMAGE_PRODUCTS_DIR_AB); \
		fi ; \
	)
endef
endif

endif

define Image/Build
	$(call Image/Build/$(1),$(1))
endef

$(eval $(call BuildImage))
