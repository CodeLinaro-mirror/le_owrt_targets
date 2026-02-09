define Image/GenerateBuildProp
	cd $(TOPDIR); \
	rm -rf $(BUILD_PROP); \
	echo "##########################" >> $(BUILD_PROP); \
	echo "#### BUILD PROPERTIES ####" >> $(BUILD_PROP); \
	echo "##########################" >> $(BUILD_PROP); \
	echo VENDOR_AU=$(shell cd $(TOPDIR)/../.repo/manifests; git describe --always 2>&1) >> $(BUILD_PROP); \
	echo VENDOR_TARGET=$(BOARD) >> $(BUILD_PROP); \
	echo VENDOR_PROFILE=$(PROFILE) >> $(BUILD_PROP); \
	echo KERNEL_TARGET=$(KERNEL_PLATFORM_TARGET) >> $(BUILD_PROP); \
	echo KERNEL_VARIANT=$(TARGET_VARIANT) >> $(BUILD_PROP); \
	if [ "$(USER_VARIANT)" == "1" ]; then \
		echo BUILD_VARIANT=user >> $(BUILD_PROP); \
	else \
		echo BUILD_VARIANT=$(TARGET_VARIANT) >> $(BUILD_PROP); \
	fi; \
	cd -; \
	rm -rf $(IMAGE_ROOTFS)/$(BUILD_PROP); \
	fakeroot cp $(TOPDIR)/$(BUILD_PROP) $(IMAGE_ROOTFS);
endef
