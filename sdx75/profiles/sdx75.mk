include $(TOPDIR)/owrt-qti-conf/sdx.mk
include $(TOPDIR)/owrt-qti-msdc-prop/qtimsdcprop.mk
include $(TOPDIR)/owrt-qti-perf-prop/qtiperfprop.mk
include $(TOPDIR)/owrt-qti-sensors-prop/qtisensorsprop.mk

# include mk files available only in internal builds
ifneq ($(EXTERNAL_BUILD),1)
	include $(TOPDIR)/owrt-qti-sensors-internal/qtisensorsinternal.mk
endif
include $(TOPDIR)/owrt-qti-ipq-prop/qtiipqprop.mk

define Profile/mbb
	NAME:=Qualcomm Technologies Inc., Pinnacles Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTIAUDIO) $(QTIARGS) $(QTIPAL) $(QTIAGM) $(QTIAUDIOPROP) \
		$(QTIDATA) $(QTIDATAPROP) $(QTIRILPROP) $(QTICTAINTERNAL) \
		$(QTIWLAN) $(QTIWLANPROP) $(QTIBT) $(QTIBTPROP) $(QTISSDK) \
		$(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) $(QTINTERNAL) \
		$(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) $(QTIDATAINTERNAL) \
		$(QTICOREINTERNAL) $(QTIPERFPROP) $(QTISENSORSINTERNAL) $(QTISENSORSPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb/Description
	Mbb sdx75 package set configuration.
	Enables complete set of modules for sdx75 target.
endef

$(eval $(call Profile,mbb))

define Profile/cpe
	NAME:=Qualcomm Technologies Inc., Pinnacles' CPE Profile
	PACKAGES:=$(OPENWRT_STANDARD) \
		$(COREBSP_UTILS) $(UTILS) \
		$(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
		$(QTIDATA) $(QTIDATAPROP) $(QTIRILPROP) $(QTICTAINTERNAL) \
		$(QTIIPQPROP) $(QTISSDK) \
		$(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) $(QTINTERNAL) \
		$(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) $(QTIDATAINTERNAL) \
		$(QTICOREINTERNAL) $(QTIPERFPROP) $(QTISENSORSPROP) \
		-edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/cpe/Description
	CPE sdx75 package set configuration.
	Enables complete set of modules for sdx75 target.
endef

$(eval $(call Profile,cpe))

define Profile/mbb-min
        NAME:=Qualcomm Technologies Inc., Pinnacles' MBB Minimal Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) \
                $(QTIDATA) $(QTIDATAPROP) $(QTIRILPROP) $(QTICTAINTERNAL) $(QTISSDK) \
                $(QTILOCATION) $(QTILOCATIONPROP) $(QTILOCATIONINTERNAL) $(QTINTERNAL) \
                $(QTISECURITY) $(QTISECURITYPROP) $(QTISECURITYINTERNAL) $(QTIDATAINTERNAL) $(QTISENSORSPROP) \
                -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig
endef

define Profile/mbb-min/Description
        MBB Minimal sdx75 package set configuration.
        Enables mbb-min set of modules for sdx75 target.
endef

$(eval $(call Profile,mbb-min))

define Profile/recovery
        NAME:=Qualcomm Technologies Inc., Recovery Profile
        PACKAGES:=$(OPENWRT_STANDARD) \
                $(COREBSP_UTILS) $(UTILS) \
                $(QTIBSP) $(QTIBSPPROP) $(QTICORE) $(QTICOREPROP) $(QTISSMGR) $(QTISSMGRPROP) $(QTISENSORSPROP) \
                -ipa_fws -edk2 -mkbootimg -linux-msm-5.4_dt -lacpd libtirpc -swconfig -postboot \
                -usb-composition usb-composition-recovery -initmss
endef

define Profile/recovery/Description
        Recovery sdx75 package set configuration.
        Enables recovery set of modules for sdx75 target.
endef

$(eval $(call Profile,recovery))
