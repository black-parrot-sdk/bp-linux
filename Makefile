
export LINUX_TARGET ?= riscv64-unknown-linux-gnu

TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_LINUX_DIR       := $(BP_SDK_DIR)/linux
PATH               := $(BP_SDK_BIN_DIR):$(PATH)

PYTHON ?= python
DTC ?= dtc
WGET ?= wget
TAR ?= tar
MKDIR ?= mkdir -p

opensbi_srcdir   := $(BP_LINUX_DIR)/opensbi
linux_srcdir     := $(BP_LINUX_DIR)/linux
uboot_srcdir     := $(BP_LINUX_DIR)/u-boot

workdir           := $(BP_LINUX_DIR)/work

linux_workdir    := $(workdir)/linux
linux_binary     := $(linux_workdir)/vmlinux
linux_defconfig  := defconfig

opensbi_workdir  := $(workdir)/opensbi
opensbi_binary   := $(opensbi_workdir)/platform/blackparrot/firmware/fw_dynamic.elf

uboot_spl_workdir   := $(workdir)/u-boot-spl
uboot_spl_binary    := $(uboot_spl_workdir)/u-boot-nodtb.bin
uboot_spl_defconfig := qemu-riscv64_spl_defconfig

uboot_workdir   := $(workdir)/u-boot
uboot_binary    := $(uboot_workdir)/u-boot-nodtb.bin
uboot_defconfig := qemu-riscv64_smode_defconfig

$(workdir) $(linux_workdir) $(uboot_workdir) $(opensbi_workdir):
	$(MKDIR) $@

$(linux_workdir)/.config: | $(linux_workdir)
	$(MAKE) -C $(linux_srcdir) $(linux_defconfig) O=$(linux_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-
	
$(linux_binary): $(linux_workdir)/.config
	$(MAKE) -C $(linux_srcdir) $(@F) O=$(linux_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-

OPENSSL_VERSION := 1.1.1w
OPENSSL := openssl-$(OPENSSL_VERSION)
OPENSSL_URL := https://www.openssl.org/source/$(OPENSSL).tar.gz
OPENSSL_INSTALL := $(workdir)/openssl-install
$(OPENSSL_INSTALL): | $(workdir)
	cd $(workdir); $(WGET) -qO- $(OPENSSL_URL) | $(TAR) xzv
	cd $(workdir)/$(OPENSSL); \
		./config --prefix=$(OPENSSL_INSTALL); \
		$(MAKE) install

$(uboot_workdir)/.config: $(OPENSSL_INSTALL) | $(uboot_workdir) 
	$(MAKE) -C $(uboot_srcdir) $(uboot_defconfig) O=$(uboot_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-

$(uboot_binary): $(uboot_workdir)/.config
	cd $(uboot_srcdir); $(MAKE) $(@F) O=$(uboot_workdir) \
		CROSS_COMPILE=$(LINUX_TARGET)- ARCH=riscv DTC=$(DTC) \
		HOSTCFLAGS_bmp_logo.o="-I$(uboot_srcdir)/include" \
		HOSTCFLAGS_ecdsa-libcrypto.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTCFLAGS_sunxi_toc0.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTCFLAGS_mxsimage.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTCFLAGS_kwbimage.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTCFLAGS_mkimage.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTCFLAGS_rsa-sign.o="-I$(OPENSSL_INSTALL)/include" \
		HOSTLDLIBS_mkimage="-L$(OPENSSL_INSTALL)/lib -lssl -lcrypto" \
		HOSTLDLIBS_kwbimage="-L$(OPENSSL_INSTALL)/lib -lssl -lcrypto" \
		HOSTLDLIBS_dumpimage="-L$(OPENSSL_INSTALL)/lib -lssl -lcrypto" \
		HOSTLDLIBS_aes-decrypt="-L$(OPENSSL_INSTALL)/lib -lssl -lcrypto" \
		HOSTLDLIBS_aes-encrypt="-L$(OPENSSL_INSTALL)/lib -lssl -lcrypto"

$(opensbi_binary): $(uboot_binary) | $(opensbi_workdir) 
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)- \
		FW_PAYLOAD=y \
		PLATFORM=generic \
		FW_PAYLOAD_PATH=$(uboot_binary)
#
#$(uboot_spl_binary): $(uboot_spl_srcdir) $(opensbi_binary)
#	cd $<; $(MAKE) $(uboot_spl_defconfig) \
		CROSS_COMPILE=$(LINUX_TARGET)- ARCH=riscv DTC=$(DTC) \
#		HOST_EXTRACFLAGS="-stdc++-17 -D_LINUX_TYPES_H -nostdinc -I$(OPENSSL_INSTALL)/include -I$(uboot_srcdir)/include" \
#		HOSTLDLIBS="-L$(OPENSSL_INSTALL)/lib"
#	cd $<; $(MAKE) O=$(uboot_spl_workdir) \
#		CROSS_COMPILE=$(LINUX_TARGET)- \
#		ARCH=riscv \
#		DTC=$(DTC) \
#		HOST_EXTRACFLAGS="-stdc++-17 -D_LINUX_TYPES_H -nostdinc -I$(OPENSSL_INSTALL)/include -I$(uboot_srcdir)/include" \
#		HOSTLDLIBS="-L$(OPENSSL_INSTALL)/lib"

vmlinux: $(linux_binary)
spl: $(uboot_spl_binary)
opensbi: $(opensbi_binary)
u-boot: $(uboot_binary)
u-boot-spl: $(uboot_spl_binary)

clean: clean_buildroot

clean_opensbi:
	rm -rf $(opensbi_workdir)

clean_vmlinux: clean_opensbi
	rm -rf $(linux_workdir)

clean_sysroot: clean_vmlinux
	rm -rf $(buildroot_sysroot) $(buildroot_sysroot_stamp)

clean_buildroot:
	rm -rf $(workdir)

