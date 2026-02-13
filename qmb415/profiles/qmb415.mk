include $(TOPDIR)/owrt-qti-conf/qmb415.mk
#-include $(TOPDIR)/owrt-qti-msdc-prop/qtimsdcprop.mk
-include $(TOPDIR)/owrt-qti-emergencyalert-prop/qtiemergencyalertprop.mk
include $(TOPDIR)/owrt-qti-ipq-prop/qtiipqprop.mk
include $(TOPDIR)/owrt-qti-ipq/qtiipq.mk
include $(TOPDIR)/owrt-qti-perf-prop/qtiperfprop.mk
include $(TOPDIR)/owrt-qti-sensors-prop/qtisensorsprop.mk

# include mk files available only in internal builds
ifneq ($(EXTERNAL_BUILD),1)
	include $(TOPDIR)/owrt-qti-sensors-internal/qtisensorsinternal.mk
endif

ifeq ($(CONFIG_OTA_RECOVERY_UPDATE),y)
RECOVERYUPDATER=recovery-updater
endif

define Profile/mbb
	NAME:=Qualcomm Technologies Inc., QMB415  Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
                $(QTIAUDIO) $(QTIAUDIOALGOS) \
                $(QTICOREINTERNAL) $(QTISENSORSINTERNAL) $(QTISENSORSPROP)  \
		$(QTIDATA) $(QTIDATAPROP) $(QTIDATAINTERNAL) \
                $(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) \
                $(QTIBT) $(QTIBTPROP) $(QTINTERNAL) $(QTIWLAN) $(QTIWLANPROP) \
                $(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) \
                $(QTIPERFPROP) \
                $(QTIMSDCPROP) $(QTIEMERGENCYALERTPROP) \
                -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb/Description
	Mbb qmn415 package set configuration.
	Enables complete set of modules for qmb415 target.
endef

$(eval $(call Profile,mbb))

define Profile/recovery
        NAME:=Qualcomm Technologies Inc., Recovery Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) $(QTISENSORSPROP) \
                -ipa_fws -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -postboot \
                -usb-composition usb-composition-recovery -initmss -sign_abl applypatch bsdiff-ota edify \
                libdivsufsort librecovery-updater-msm recovery updater -rproc-tracing -lftp -kpigen
endef

define Profile/recovery/Description
        Recovery qmb415 package set configuration.
        Enables recovery set of modules for qmb415 target.
endef

$(eval $(call Profile,recovery))
