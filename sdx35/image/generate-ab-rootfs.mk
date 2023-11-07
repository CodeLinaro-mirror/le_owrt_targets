opkg_install_cmd = \
  IPKG_NO_SCRIPT=1 \
  IPKG_INSTROOT=$(IMAGE_ROOTFS_AB) \
  TMPDIR=$(IMAGE_ROOTFS_AB)/tmp \
  $(STAGING_DIR_HOST)/bin/opkg \
  --offline-root $(IMAGE_ROOTFS_AB) \
  --force-postinstall \
  --force-overwrite \
  --force-maintainer \
  --add-dest root:/  \
  --add-arch all:100 \
  --add-arch $(if $(ARCH_PACKAGES),$(ARCH_PACKAGES),$(BOARD)):200

opkg_remove_cmd = \
  IPKG_NO_SCRIPT=1 \
  IPKG_INSTROOT=$(IMAGE_ROOTFS_AB) \
  TMPDIR=$(IMAGE_ROOTFS_AB)/tmp \
  $(STAGING_DIR_HOST)/bin/opkg \
  --offline-root $(IMAGE_ROOTFS_AB) \
  --force-remove \
  --force-depends \
  --add-dest root:/  \
  --add-arch all:100 \
  --add-arch $(if $(ARCH_PACKAGES),$(ARCH_PACKAGES),$(BOARD)):200


define Image/AB/GenerateABRootfs
	rm -rf $(IMAGE_ROOTFS_AB)
	mkdir -p $(IMAGE_ROOTFS_AB)
	$(CP) $(IMAGE_ROOTFS)/* $(IMAGE_ROOTFS_AB)/

	echo "Removing ABPackages_remove packages from rootfs_ab"; \
	$(foreach pkg,$(shell cat ABPackages_Remove),
		echo "$(pkg)"; \
		$(opkg_remove_cmd) remove $(pkg); \
	)

	mkdir -p $(IMAGE_ROOTFS_AB)/var/lock

	echo "Installing packages from ABPackages_Install in rootfs_ab"; \
	$(foreach pkg,$(shell cat ABPackages_Install),
		echo "$(pkg)"; \
		$(if $(shell find $(TOPDIR)/bin/packages/$(ARCH_PACKAGES) -iname \*$(pkg)\* | awk '{print $1}'), \
			$(opkg_install_cmd) install $(shell find $(TOPDIR)/bin/packages/$(ARCH_PACKAGES) -iname \*$(pkg)\* | awk '{print $1}');

			IPKG_INSTROOT=$(IMAGE_ROOTFS_AB) $$(command -v bash) $(IMAGE_ROOTFS_AB)/usr/lib/opkg/info/$(pkg).postinst; \

			$(foreach installed_file,$(shell cat $(IMAGE_ROOTFS_AB)/usr/lib/opkg/info/$(pkg).list),
				if echo $(installed_file) | grep -q "init"; then \
					echo "Enabling init "; \
					IPKG_INSTROOT=$(IMAGE_ROOTFS_AB) $$(command -v bash) $(IMAGE_ROOTFS_AB)/etc/rc.common $(IMAGE_ROOTFS_AB)/$(installed_file) enable; \
				fi
		) ) \
	)
	rm -rf $(IMAGE_ROOTFS_AB)/var/lock/*.lock

endef
