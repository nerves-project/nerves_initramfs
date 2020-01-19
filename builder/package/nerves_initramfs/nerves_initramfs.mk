#############################################################
#
# nerves_initramfs
#
#############################################################

NERVES_INITRAMFS_SITE = $(TOPDIR)/../../src
NERVES_INITRAMFS_SITE_METHOD = local
NERVES_INITRAMFS_LICENSE = Apache-2.0
NERVES_INITRAMFS_LICENSE_FILES = LICENSE
NERVES_INITRAMFS_DEPENDENCIES = host-bison host-flex

ifdef BR2_PACKAGE_NERVES_INITRAMFS_DEBUG
NERVES_INITRAMFS_MAKE_OPTS = DEBUG=1
endif

define NERVES_INITRAMFS_BUILD_CMDS
	$(MAKE1) \
	    $(NERVES_INITRAMFS_MAKE_OPTS) \
	    $(TARGET_CONFIGURE_OPTS) \
	    BISON="$(HOST_DIR)/bin/bison" \
	    FLEX="$(HOST_DIR)/bin/flex" \
	    -C $(@D)
endef

define NERVES_INITRAMFS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/init $(TARGET_DIR)/init
endef

$(eval $(generic-package))
