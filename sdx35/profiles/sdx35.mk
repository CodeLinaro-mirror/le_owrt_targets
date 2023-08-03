include $(TOPDIR)/owrt-qti-conf/sdx.mk
include $(TOPDIR)/owrt-qti-ppat-prop/qtippatprop.mk

define Profile/mbb-128m
	NAME:=Qualcomm Technologies Inc., Kuno Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTIDATA) $(QTIDATAPROP) $(QTICTAINTERNAL) $(QTINTERNAL) $(QTISSDK) \
		$(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) \
		$(QTICOREINTERNAL) \
		$(QTIPPATPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb-128m/Description
	Mbb sdx35 package set configuration.
	Enables complete set of modules for sdx35 target.
endef

$(eval $(call Profile,mbb-128m))

define Profile/mbb
	NAME:=Qualcomm Technologies Inc., Kuno Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTIDATA) $(QTIDATAPROP) $(QTICTAINTERNAL) $(QTINTERNAL) $(QTISSDK) \
		$(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) $(QTIRILPROP) \
		$(QTIBT) $(QTIBTPROP) \
		$(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) \
		$(QTIWLAN) $(QTIWLANPROP) \
		$(QTICOREINTERNAL) \
		$(QTIPPATPROP) \
		$(QTIAUDIO) $(QTIARGS) $(QTIPAL) $(QTIAGM) $(QTIAUDIOPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb/Description
	Mbb sdx35 package set configuration.
	Enables complete set of modules for sdx35 target.
endef

$(eval $(call Profile,mbb))

define Profile/m2
	NAME:=Qualcomm Technologies Inc., Kuno Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTIDATA) $(QTIDATAPROP) \
		$(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) \
		$(QTICOREINTERNAL) \
		$(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) \
		$(QTIAUDIO) $(QTIARGS) $(QTIPAL) $(QTIAGM) $(QTIAUDIOPROP) \
		$(QTIPPATPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/m2/Description
	M.2 sdx35 package set configuration.
	Enables complete set of modules for sdx35 M.2 target.
endef

$(eval $(call Profile,m2))

define Profile/recovery
	NAME:=Qualcomm Technologies Inc., Kuno Recovery Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -postboot \
		-usb-composition usb-composition-recovery -initmss -sign_abl \
		-qmi-shutdown-modem
endef

define Profile/recovery/Description
	Recovery sdx35 package set configuration.
	Enables complete set of modules for sdx35 recovery filesystem.
endef

$(eval $(call Profile,recovery))
