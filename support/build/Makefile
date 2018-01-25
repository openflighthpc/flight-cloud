#==============================================================================
# Copyright (C) 2018 Stephen F Norledge & Alces Software Ltd.
#
# This file is part of Alces Cloudware.
#
# Some rights reserved, see LICENSE.
#==============================================================================
# Image config
PLATFORM=azure # default to azure
IMAGE_TYPE="alces-cloudware-base"
IMAGE_VERSION="2018.1-alpha"
IMAGE_NAME=$(IMAGE_TYPE)-$(IMAGE_VERSION)-$(PLATFORM)

# Libvirt/Oz config
KICKSTART=$(IMAGE_TYPE)-$(PLATFORM).ks
KICKSTART_RENDERED=/tmp/$(IMAGE_NAME).ks
TDL=centos7.tdl
TDL_RENDERED=/tmp/$(IMAGE_NAME).tdl
OZ_CFG=oz.cfg
VM_DIR=/mnt/resource
QEMU_IMG_BIN=$(VM_DIR)/qemu-img
XML=domain.xml
XML_RENDERED=$(IMAGE_NAME).xml

all: setup build prepare convert upload

setup:
	[ -d $(VM_DIR)/converted ] || mkdir -p $(VM_DIR)/converted
	[ -d $(VM_DIR)/tmp ] || mkdir -p $(VM_DIR)/tmp
	[ -f $(QEMU_IMG_BIN) ] || echo "$(QEMU_IMG_BIN) not present" && exit

build:
	cp -v $(TDL) $(TDL_RENDERED)
	cp -v $(KICKSTART) $(KICKSTART_RENDERED)
	sed -i -e 's,c7,$(IMAGE_NAME),g' $(TDL_RENDERED)
	sed -i -e 's,%BUILD_RELEASE%,$(IMAGE_VERSION),g' $(KS_RENDERED)
	@echo "Building image $(IMAGE_NAME)"
	oz-install -d3 -u $(TDL_RENDERED) -x /tmp/$(IMAGE_NAME).xml \
				   -p -a $(KICKSTART_RENDERED) -c $(OZ_CFG) -t 1800

prepare:
	[ -f $(VM_DIR)/$(IMAGE_NAME).qcow2 ] || exit
	@echo "Preparing $(IMAGE_NAME)"
	virt-sysprep -a $(VM_DIR)/$(IMAGE_NAME).qcow2
