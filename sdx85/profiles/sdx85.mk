include $(TOPDIR)/owrt-qti-conf/sdx.mk
include $(TOPDIR)/owrt-qti-msdc-prop/qtimsdcprop.mk
include $(TOPDIR)/owrt-qti-perf-prop/qtiperfprop.mk
include $(TOPDIR)/owrt-qti-sensors-prop/qtisensorsprop.mk

# include mk files available only in internal builds
ifneq ($(EXTERNAL_BUILD),1)
	include $(TOPDIR)/owrt-qti-sensors-internal/qtisensorsinternal.mk
endif
include $(TOPDIR)/owrt-qti-ipq-prop/qtiipqprop.mk
include $(TOPDIR)/owrt-qti-ipq/qtiipq.mk

ifeq ($(CONFIG_OTA_RECOVERY_UPDATE),y)
RECOVERYUPDATER=recovery-updater
endif

define Profile/mbb
	NAME:=Qualcomm Technologies Inc., Kobuk Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
                $(QTICOREINTERNAL) $(QTISENSORSINTERNAL) $(QTISENSORSPROP)  \
                $(QTIBT) $(QTIBTPROP) \
                -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb/Description
	Mbb sdx85 package set configuration.
	Enables complete set of modules for sdx85 target.
endef

$(eval $(call Profile,mbb))

define Profile/cpe
	NAME:=Qualcomm Technologies Inc., Kobuk' CPE Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTICOREINTERNAL) $(QTISENSORSPROP)  \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig \
		-iw-full
endef

define Profile/cpe/Description
	CPE sdx85 package set configuration.
	Enables complete set of modules for sdx85 target.
endef

$(eval $(call Profile,cpe))

define Profile/mbb-min
        NAME:=Qualcomm Technologies Inc., Kobuk' MBB Minimal Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
                $(QTIDATA) $(QTIDATAPROP) $(QTICTAINTERNAL) $(QTISSDK) \
                $(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) $(QTINTERNAL) \
                $(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) $(QTIDATAINTERNAL) $(QTISENSORSPROP) $(QTIMSDCPROP) \
                -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -lftp $(RECOVERYUPDATER)
endef

define Profile/mbb-min/Description
        MBB Minimal sdx85 package set configuration.
        Enables mbb-min set of modules for sdx85 target.
endef

$(eval $(call Profile,mbb-min))

define Profile/mbb-512
        NAME:=Qualcomm Technologies Inc., Kobuk' MBB 512MB Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) $(QTINTERNAL) \
                $(QTISENSORSPROP) $(QTIDATA512M) $(QTIDATAPROP512M) \
                $(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) \
                -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -qdss_config -lftp $(RECOVERYUPDATER)
endef

define Profile/mbb-512/Description
        MBB 512MB sdx85 package set configuration.
        Enables mbb-512 set of modules for sdx85 target.
endef

$(eval $(call Profile,mbb-512))

define Profile/recovery
        NAME:=Qualcomm Technologies Inc., Recovery Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) $(QTISENSORSPROP) \
                -ipa_fws -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -postboot \
                -usb-composition usb-composition-recovery -initmss -sign_abl applypatch bsdiff-ota edify \
                libdivsufsort librecovery-updater-msm recovery updater -rproc-tracing -lftp
endef

define Profile/recovery/Description
        Recovery sdx85 package set configuration.
        Enables recovery set of modules for sdx85 target.
endef

$(eval $(call Profile,recovery))
