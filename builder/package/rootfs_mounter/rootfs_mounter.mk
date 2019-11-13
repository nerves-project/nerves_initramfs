#############################################################
#
# rootfs_mounter
#
#############################################################

ROOTFS_MOUNTER_SITE = $(TOPDIR)/../../src
ROOTFS_MOUNTER_SITE_METHOD = local
ROOTFS_MOUNTER_LICENSE = Apache-2.0
ROOTFS_MOUNTER_LICENSE_FILES = LICENSE
ROOTFS_MOUNTER_DEPENDENCIES = host-bison host-flex

define ROOTFS_MOUNTER_BUILD_CMDS
	$(MAKE1) $(TARGET_CONFIGURE_OPTS) BISON="$(HOST_DIR)/bin/bison" FLEX="$(HOST_DIR)/bin/flex" -C $(@D)
endef

define ROOTFS_MOUNTER_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/init $(TARGET_DIR)/init
endef

$(eval $(generic-package))
