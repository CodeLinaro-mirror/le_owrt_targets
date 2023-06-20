include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

KERNEL_BASEADDR = 0x80000000
EXT4_IMAGE_SIZE = 220715200
UBI_IMAGE_SIZE = 253952
UBIFS_OPTS = -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F
USERDATA_SIZE_EXT4 = 251658240
SYSTEMRW_IMAGE_ROOTFS_SIZE = 8192KB
RECOVERY_UBINIZE_CFG = ubinize-recoveryfs.cfg
RECOVERY_UBIFS_IMAGE = recoveryfs.ubifs
RECOVERY_MKUBIFS_ARGS = -m 4096 -e 253952 -c 200 -F
RECOVERYFS_SIZE_EXT4 ?= 52428800
CACHE_SIZE_EXT4 = 26214400

ifeq ($(TARGET_VARIANT),debug)
KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates,/firmware/image service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat pci=pcie_bus_perf"
endif

ifeq ($(TARGET_VARIANT),perf)
KERNEL_CMDLINE = "ro rootwait console=ttyMSM0,115200,n8 androidboot.hardware=qcom msm_rtb.filter=0x237 androidboot.console=ttyMSM0 lpm_levels.sleep_disabled=1 firmware_class.path=/lib/firmware/updates,/firmware/image service_locator.enable=1 net.ifnames=0 atlantic_fwd.rx_ring_size=512 atlantic_fwd.rx_linear=1 pcie_ports=compat pci=pcie_bus_perf no_console_suspend=1 loglevel=0"
endif

TARGET_SHA_TYPE = "sha256"

ifeq ($(PROFILE),recovery)
IMAGE_ROOTFS = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/recovery/root-$(BOARD)
else
IMAGE_ROOTFS = $(TOPDIR)/build_dir/target-$(ARCH)_$(CPU_TYPE)_musl/root-$(BOARD)
endif

ifeq ($(USER_VARIANT),1)
IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/user/$(BOARD)/$(PROFILE)
else
IMAGE_PRODUCTS_DIR = $(TOPDIR)/bin/targets/$(TARGET_VARIANT)/$(BOARD)/$(PROFILE)
endif

SELINUX_UBI_OPTS := --selinux=$(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts
SELINUX_EXT4_OPTS := -S $(IMAGE_ROOTFS)/etc/selinux/selinux-policy/contexts/files/file_contexts

define Image/Prepare
	mkdir -p $(IMAGE_ROOTFS)/lib/modules/$(UNAME_VERSION)
	mkdir -p $(IMAGE_PRODUCTS_DIR)
	mkdir -p ${IMAGE_ROOTFS}/cache
	mkdir -p ${IMAGE_ROOTFS}/persist
endef

ifeq ($(PROFILE),recovery)

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
		echo vol_flags = autoresize >> $(RECOVERY_UBINIZE_CFG); \
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

define Image/mkfs/ubifs
	$(CP) ./ubinize-$(BOARD).cfg $(KDIR)
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}/etc/uci-defaults/13_fix-group-user; \
	)
	cd $(KDIR); \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs $(SELINUX_UBI_OPTS) -r $(IMAGE_ROOTFS) -o sysfs.ubifs -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F; \
	fakeroot $(STAGING_DIR_HOSTPKG)/bin/mkfs.ubifs -r $(IMAGE_ROOTFS)/data -o userfs.ubifs -m 4096 -e $(UBI_IMAGE_SIZE) -c 2146 -F; \
	( cd $(KDIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/ubinize \
		-o sysfs.ubi -m 4096 -p 256KiB -s 4096 \
		ubinize-$(BOARD).cfg \
	)
	( $(CP) $(KDIR)/sysfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/sysfs.ubi $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/userfs.ubifs $(IMAGE_PRODUCTS_DIR)/; \
	  $(CP) $(KDIR)/ubinize-$(BOARD).cfg $(IMAGE_PRODUCTS_DIR)/; \
	)
endef

define Image/mkfs/ext4
	( cd $(TOPDIR); \
		./build_dir/host/sed-4.8/sed/sed -i 's/ubus:x:81:81:ubus:\/var\/run\/ubus:\/bin\/false//' ${IMAGE_ROOTFS}/etc/passwd; \
		rm -rf ${IMAGE_ROOTFS}/etc/uci-defaults/13_fix-group-user; \
	)
	( cd $(IMAGE_PRODUCTS_DIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs $(SELINUX_EXT4_OPTS) -B system.map -a / -b 4096 -s -l $(EXT4_IMAGE_SIZE) system.img $(IMAGE_ROOTFS) \
	)
	( cd $(IMAGE_PRODUCTS_DIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -B userdata.map -a /data -b 4096 -s -l $(USERDATA_SIZE_EXT4) userdata.img $(IMAGE_ROOTFS)/data \
	)
	( cd $(IMAGE_PRODUCTS_DIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -a /systemrw -s -b 4096 -l $(SYSTEMRW_IMAGE_ROOTFS_SIZE) systemrw.img $(IMAGE_ROOTFS)/overlay \
	)
	( cd $(IMAGE_PRODUCTS_DIR); \
		fakeroot $(STAGING_DIR_HOSTPKG)/bin/make_ext4fs -a /cache -s -b 4096 -l $(CACHE_SIZE_EXT4) cache.img $(IMAGE_ROOTFS)/cache \
	)

	( cd $(TOPDIR)/src/kernel-$(LINUX_VERSION)/kernel_platform && BUILD_CONFIG=msm-kernel/build.config.msm.$(KERNEL_PLATFORM_TARGET) OUT_DIR=../out/msm-kernel-$(KERNEL_PLATFORM_TARGET)-$(TARGET_VARIANT)_defconfig/ \
		./build/android/merge_dtbs.sh \
		$(KDIR)/kernel_dtbs \
		$(KDIR)/techpack-dtbos $(KDIR)/merged_dtbs; \
		$(CP) $(KDIR)/merged_dtbs/dtb.img $(KDIR)/; \
	)
	( cd $(KDIR); \
		$(CP) $(KDIR)/vmlinux $(IMAGE_PRODUCTS_DIR); \
		$(KDIR)/build-tools/mkbootimg/mkbootimg.py --kernel $(KDIR)/Image \
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

define Image/Build
	$(call Image/Build/$(1))
endef

$(eval $(call BuildImage))
