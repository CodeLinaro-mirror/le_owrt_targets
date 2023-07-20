define Image/Build/generate-ubinize-cfg
	(	echo \[sysfs_volume\] > $(UBINIZE_CFG); \
		echo mode=ubi >> $(UBINIZE_CFG); \
		echo image=\"sysfs.ubifs\" >> $(UBINIZE_CFG); \
		echo vol_id=0 >> $(UBINIZE_CFG); \
		echo vol_type=dynamic >> $(UBINIZE_CFG); \
		echo vol_name=rootfs >> $(UBINIZE_CFG); \
		echo vol_size=\"$(ROOTFS_VOLUME_SIZE)\" >> $(UBINIZE_CFG); \
		echo \[usrfs_volume\] >> $(UBINIZE_CFG); \
		echo mode=ubi >> $(UBINIZE_CFG); \
		echo image=\"userfs.ubifs\" >> $(UBINIZE_CFG); \
		echo vol_id=1 >> $(UBINIZE_CFG); \
		echo vol_type=dynamic >> $(UBINIZE_CFG); \
		echo vol_name=usrfs >> $(UBINIZE_CFG); \
		echo vol_flags=autoresize >> $(UBINIZE_CFG); \
		echo \[cache_volume\] >> $(UBINIZE_CFG); \
		echo mode=ubi >> $(UBINIZE_CFG); \
		echo vol_id=2 >> $(UBINIZE_CFG); \
		echo vol_type=dynamic >> $(UBINIZE_CFG); \
		echo vol_name=cachefs >> $(UBINIZE_CFG); \
		echo vol_size=\"15MiB\" >> $(UBINIZE_CFG); \
		echo \[systemrw_volume\] >> $(UBINIZE_CFG); \
		echo mode=ubi >> $(UBINIZE_CFG); \
		echo vol_id=3 >> $(UBINIZE_CFG); \
		echo vol_type=dynamic >> $(UBINIZE_CFG); \
		echo vol_name=systemrw >> $(UBINIZE_CFG); \
		echo vol_size=\"6MiB\" >> $(UBINIZE_CFG); \
		echo \[persist_volume\] >> $(UBINIZE_CFG); \
		echo mode=ubi >> $(UBINIZE_CFG); \
		echo vol_id=4 >> $(UBINIZE_CFG); \
		echo vol_type=dynamic >> $(UBINIZE_CFG); \
		echo vol_name=persist >> $(UBINIZE_CFG); \
		echo vol_size=\"6MiB\" >> $(UBINIZE_CFG); \
	)
endef
