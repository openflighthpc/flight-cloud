#==============================================================================
# Copyright (C) 2018 Stephen F Norledge & Alces Software Ltd.
#
# This file is part of Alces Cloudware.
#
# Some rights reserved, see LICENSE.
#==============================================================================
# Image config
PLATFORM=azure # default to azure
IMAGE_TYPE=alces-cloudware-base
IMAGE_VERSION=2018.2.1
IMAGE_NAME=$(IMAGE_TYPE)-$(IMAGE_VERSION)-$(PLATFORM)

# Libvirt/Oz config
KICKSTART=$(IMAGE_TYPE)-$(PLATFORM).ks
KICKSTART_RENDERED=/tmp/$(IMAGE_NAME).ks
TDL=centos7.tdl
TDL_RENDERED=/tmp/$(IMAGE_NAME).tdl
OZ_CFG=oz.cfg
VM_DIR=/mnt/resource
QEMU_IMG_BIN=/usr/bin/qemu-img
XML=domain.xml
XML_RENDERED=$(IMAGE_NAME).xml

# AWS config
AWS_BUCKET=alces-cloudware
AWS_BUCKET_DIR=images
AWS_REGION=eu-west-1

# Azure config
AZURE_STORAGE_ACCOUNT=alcescloudware
AZURE_STORAGE_CONTAINER=images
AZURE_RESOURCE_GROUP=alces-cloudware
AZURE_IMAGE_URL="https://$(AZURE_STORAGE_ACCOUNT).blob.core.windows.net/$(AZURE_STORAGE_CONTAINER)/$(IMAGE_NAME).vhd"

image: setup build prepare upload

setup:
	[ -d $(VM_DIR)/converted ] || mkdir -p $(VM_DIR)/converted
	[ -d $(VM_DIR)/tmp ] || mkdir -p $(VM_DIR)/tmp
	[ -f $(QEMU_IMG_BIN) ] || exit

build:
	cp -v $(TDL) $(TDL_RENDERED)
	cp -v $(KICKSTART) $(KICKSTART_RENDERED)
	sed -i -e 's,c7,$(IMAGE_NAME),g' $(TDL_RENDERED)
	sed -i -e 's,%BUILD_RELEASE%,$(IMAGE_VERSION),g' $(KICKSTART_RENDERED)
	@echo "Building image $(IMAGE_NAME)"
	oz-install -d3 -u $(TDL_RENDERED) -x /tmp/$(IMAGE_NAME).xml \
				   -p -a $(KICKSTART_RENDERED) -c $(OZ_CFG) -t 1800

prepare:
	[ -f $(VM_DIR)/$(IMAGE_NAME).qcow2 ] || exit
	@echo "Preparing $(IMAGE_NAME)"
	virt-sysprep -a $(VM_DIR)/$(IMAGE_NAME).qcow2
	@echo "Sparsifying $(IMAGE_NAME)"
	virt-sparsify --tmp $(VM_DIR)/tmp \
		--compress --format qcow2 \
		$(VM_DIR)/$(IMAGE_NAME).qcow2 \
		$(VM_DIR)/converted/$(IMAGE_NAME).qcow2

upload:
	if [ $(PLATFORM) = "aws" ]; then $(MAKE) upload-aws; fi
	if [ $(PLATFORM) = "azure" ]; then $(MAKE) upload-azure; fi

upload-azure:
	@echo "Converting $(IMAGE_NAME) to RAW format"
	$(QEMU_IMG_BIN) convert -f qcow2 -O raw \
		$(VM_DIR)/converted/$(IMAGE_NAME).qcow2 \
		$(VM_DIR)/$(IMAGE_NAME).raw
	@echo "Converting $(IMAGE_NAME) to VHD format"
	$(QEMU_IMG_BIN) convert -f raw -O vpc -o subformat=fixed,force_size \
		$(VM_DIR)/$(IMAGE_NAME).raw \
		$(VM_DIR)/$(IMAGE_NAME).vhd
	@echo "Uploading $(IMAGE_NAME) to $(AZURE_IMAGE_URL)"
	az storage blob upload --account-name $(AZURE_STORAGE_ACCOUNT) \
		--container-name $(AZURE_STORAGE_CONTAINER) \
		--type page \
		--file $(VM_DIR)/$(IMAGE_NAME).vhd \
		--name $(IMAGE_NAME).vhd
	az image create --resource-group $(AZURE_RESOURCE_GROUP) \
		--name $(IMAGE_NAME) \
	  	--location uksouth \
	    --os-type Linux \
	   	--source $(AZURE_IMAGE_URL)

upload-aws:
	$(QEMU_IMG_BIN) convert -f qcow2 -O raw \
		$(VM_DIR)/converted/$(IMAGE_NAME).qcow2 \
		$(VM_DIR)/$(IMAGE_NAME).raw
	cp container.json /tmp/$(IMAGE_NAME).json
	sed -i -e 's/%IMAGE_NAME%/$(IMAGE_NAME)/g' \
	       -e 's/%AWS_BUCKET_NAME%/$(AWS_BUCKET)/g' \
		   -e 's/%AWS_BUCKET_DIR%/$(AWS_BUCKET_DIR)/g' \
		   /tmp/$(IMAGE_NAME).json
	aws --region $(AWS_REGION) s3 cp $(VM_DIR)/$(IMAGE_NAME).raw s3://$(AWS_BUCKET)/$(AWS_BUCKET_DIR)/$(IMAGE_NAME).raw
	aws ec2 import-image --architecture x86_64 \
		--region $(AWS_REGION) \
		--description "$(IMAGE_NAME)" \
		--disk-containers "file:///tmp/$(IMAGE_NAME).json" \
		--platform Linux \
		--license-type BYOL
