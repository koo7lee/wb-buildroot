#############################################################
#
# SDC Supplicant
#
#############################################################

SDCSUPP_VERSION = local
SDCSUPP_SITE = package/lrd-closed-source/externals/wpa_supplicant
SDCSUPP_SITE_METHOD = local

SDCSUPP_DEPENDENCIES = libnl openssl sdcsdk
SDCSUPP_TARGET_DIR = $(TARGET_DIR)

SDCSUPP_PLATFORM := $(call qstrip,$(BR2_LRD_PLATFORM))
ifeq ($(SDCSUPP_PLATFORM),wb50n)
    SDCSUPP_RADIO_FLAGS := CONFIG_SDC_RADIO_QCA45N=y CONFIG_DRIVER_NL80211=y
    ifneq ($(BR2_PACKAGE_OPENSSL_FIPS),)
    SDCSUPP_FIPS = CONFIG_FIPS=y
    endif
else ifeq ($(SDCSUPP_PLATFORM),wb45n)
    SDCSUPP_RADIO_FLAGS := CONFIG_SDC_RADIO_QCA45N=y CONFIG_DRIVER_NL80211=y
    ifneq ($(BR2_PACKAGE_OPENSSL_FIPS),)
    SDCSUPP_FIPS = CONFIG_FIPS=y
    endif
else ifeq ($(SDCSUPP_PLATFORM),wb40n)
    SDCSUPP_RADIO_FLAGS := CONFIG_SDC_RADIO_BCM40N=y CONFIG_DRIVER_NL80211=y CONFIG_DRIVER_WEXT=y
else ifeq ($(BR2_PACKAGE_SDCSUPP),y)
    $(error "ERROR: Expected BR2_LRD_PLATFORM to be wb50n, wb45n or wb40n.")
endif

define SDCSUPP_BUILD_CMDS
    cp $(@D)/wpa_supplicant/wpa_supplicant/config_openssl $(@D)/wpa_supplicant/wpa_supplicant/.config
    $(MAKE) -C $(@D)/wpa_supplicant/wpa_supplicant clean
    CFLAGS="-I$(STAGING_DIR)/usr/include/libnl3 $(TARGET_CFLAGS) -MMD -Wall -g" \
        $(MAKE) -C $(@D)/wpa_supplicant/wpa_supplicant V=1 NEED_TLS_LIBDL=1 $(SDCSUPP_FIPS) \
            $(SDCSUPP_RADIO_FLAGS) CROSS_COMPILE="$(TARGET_CROSS)"
    $(TARGET_CROSS)objcopy -S $(@D)/wpa_supplicant/wpa_supplicant/wpa_supplicant $(@D)/wpa_supplicant/wpa_supplicant/sdcsupp
    #(cd $(@D)/wpa_supplicant/wpa_supplicant && CROSS_COMPILE=arm-sdc-linux-gnueabi ./sdc-build-linux.sh 4 1 2 3 1)
endef

ifeq ($(BR2_PACKAGE_SDCSUPP_WPA_CLI),y)
define SDCSUPP_INSTALL_WPA_CLI
	$(INSTALL) -D -m 755 $(@D)/wpa_supplicant/wpa_supplicant/wpa_cli $(SDCSUPP_TARGET_DIR)/usr/bin/wpa_cli
endef
endif

define SDCSUPP_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/wpa_supplicant/wpa_supplicant/sdcsupp $(SDCSUPP_TARGET_DIR)/usr/bin/sdcsupp
	$(SDCSUPP_INSTALL_WPA_CLI)
endef

define SDCSUPP_UNINSTALL_TARGET_CMDS
	rm -f $(SDCSUPP_TARGET_DIR)/usr/bin/sdcsupp
endef

$(eval $(generic-package))
