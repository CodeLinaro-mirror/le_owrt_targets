include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

KERNEL_BASEADDR = 0x80000000
EXT4_IMAGE_SIZE = 209715200
UBI_IMAGE_SIZE = 253952
PAGE_SIZE = 4096
UBI_PEB_SIZE = 256KiB
USERDATA_SIZE_EXT4 = 251658240
SYSTEMRW_IMAGE_ROOTFS_SIZE = 8192KB
RECOVERY_UBINIZE_CFG = ubinize-recoveryfs.cfg
RECOVERY_UBIFS_IMAGE = recoveryfs.ubifs
RECOVERY_MKUBIFS_ARGS = -m 4096 -e 61440 -c 200 -F
KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat pci=pcie_bus_perf"
TARGET_SHA_TYPE = "sha256"

IMAGE_ROOTFS = $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-$(BOARD)
IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)

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
endef

ifneq ($(CONFIG_TARGET_ROOTFS_SECURITY_LABELS),)
SELINUX_UBI_OPTS := --selinux=$(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/selinux/selinux-policy/contexts/files/file_contexts
SELINUX_EXT4_OPTS := -S $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/selinux/selinux-policy/contexts/files/file_contexts
endif

ifeq ($(PROFILE),recovery)

define Image/Build/ubifs
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' build_dir/$(TARGET_DIR_NAME)/root-$(BOARD)/etc/passwd; \
		rm -rf build_dir/$(TARGET_DIR_NAME)/root-$(BOARD)/etc/uci-defaults/13_fix-group-user; \
	)
	( 	echo \[recoveryfs_volume\] > $(RECOVERY_UBINIZE_CFG); \
		echo mode=ubi >> $(RECOVERY_UBINIZE_CFG); \
		echo image=\"$(RECOVERY_UBIFS_IMAGE)\" >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_id=0 >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_type=dynamic >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_name=rootfs >> $(RECOVERY_UBINIZE_CFG); \
		echo vol_flags = autoresize >> $(RECOVERY_UBINIZE_CFG); \
		$(CP) ./$(RECOVERY_UBINIZE_CFG) $(KDIR) \
	)
	( cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS)  -o $(RECOVERY_UBIFS_IMAGE) $(RECOVERY_MKUBIFS_ARGS); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o recoveryfs.ubi -m 4096 -p 256KiB -s 4096 $(RECOVERY_UBINIZE_CFG); \
	$(CP) $(KDIR)/recoveryfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	)
endef

else

ifneq ($(CONFIG_TARGET_ROOTFS_UBIFS),)

ifneq ($(CONFIG_TARGET_sdx35_m2),)

define Image/Build/ubifs
	$(CP) ./ubinize-sdx35-M2.cfg $(KDIR)
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/passwd; \
		rm -rf build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/data -o userfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-M2.cfg; \
	)
	( $(CP) $(KDIR)/sysfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35-M2.cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
endef

else

define Image/Build/ubifs
	$(CP) ./ubinize-sdx35.cfg $(KDIR)
	$(CP) ./ubinize-sdx35-2k.cfg $(KDIR)
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/passwd; \
		rm -rf build_dir/$(TARGET_DIR_NAME)/root-sdx35/etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 -o sysfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35 -o sysfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/data -o userfs-2k.ubifs -m 2048 -e 126976 -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(TOPDIR)/build_dir/$(TARGET_DIR_NAME)/root-sdx35/data -o userfs.ubifs -m 4096 -e 253952 -c 2146 -F; \
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs-2k.ubi -m 2048 -p 128KiB -s 2048 ubinize-sdx35-2k.cfg; \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize -o sysfs.ubi -m 4096 -p 256KiB -s 4096 ubinize-sdx35.cfg; \
	)
	( $(CP) $(KDIR)/sysfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs-2k.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs-2k.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35.cfg $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-sdx35-2k.cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
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
	)
endef
endif

endif

define Image/Build
	$(call Image/Build/$(1),$(1))
endef

$(eval $(call BuildImage))
