
export LINUX_TARGET ?= riscv64-unknown-linux-gnu

TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_SDK_LIB_DIR     ?= $(BP_SDK_INSTALL_DIR)/lib
BP_SDK_LIB_DIR64   ?= $(BP_SDK_INSTALL_DIR)/lib64
BP_SDK_INCLUDE_DIR ?= $(BP_SDK_INSTALL_DIR)/include
BP_LINUX_DIR       := $(BP_SDK_DIR)/linux
PATH               := $(BP_SDK_BIN_DIR):$(PATH)

GIT ?= git
DTC ?= dtc
WGET ?= wget
TAR ?= tar
MKDIR ?= mkdir -p
MV ?= mv

workdir := $(BP_LINUX_DIR)/work

linux_srcdir     := $(BP_LINUX_DIR)/linux
linux_workdir    := $(workdir)/linux
linux_ibinary    := $(linux_workdir)/vmlinux
linux_obinary    := $(workdir)/vmlinux
linux_defconfig  := defconfig

uboot_srcdir    := $(BP_LINUX_DIR)/u-boot
uboot_workdir   := $(workdir)/u-boot
uboot_ibinary   := $(uboot_workdir)/u-boot-nodtb.bin
uboot_obinary   := $(workdir)/u-boot.bin
uboot_defconfig := qemu-riscv64_smode_defconfig

opensbi_srcdir   := $(BP_LINUX_DIR)/opensbi
opensbi_workdir  := $(workdir)/opensbi
opensbi_ibinary  := $(opensbi_workdir)/platform/blackparrot/firmware/fw_dynamic.elf
opensbi_obinary  := $(workdir)/fw_dynamic.elf

uboot_spl_srcdir    := $(BP_LINUX_DIR)/u-boot
uboot_spl_workdir   := $(workdir)/u-boot-spl
uboot_spl_ibinary   := $(uboot_spl_workdir)/u-boot-nodtb.bin
uboot_spl_obinary   := $(workdir)/u-boot-spl.bin
uboot_spl_defconfig := qemu-riscv64_spl_defconfig

$(workdir) $(linux_workdir) $(uboot_workdir) $(opensbi_workdir) $(uboot_spl_workdir):
	$(MKDIR) $@

checkout: $(workdir) $(linux_workdir) $(uboot_workdir) $(opensbi_workdir) $(uboot_spl_workdir)
	$(GIT) submodule update --init --recursive $(BP_LINUX_DIR)

$(linux_workdir)/.config:
	$(MAKE) -C $(linux_srcdir) $(linux_defconfig) O=$(linux_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-
	
$(linux_obinary): $(linux_workdir)/.config
	$(MAKE) -C $(linux_srcdir) $(@F) O=$(linux_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-
	$(MV) $(linux_ibinary) $(linux_obinary)

$(uboot_workdir)/.config: $(BP_SDK_INSTALL_DIR) | $(uboot_workdir)
	$(MAKE) -C $(uboot_srcdir) clean $(uboot_defconfig) O=$(uboot_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-

$(uboot_obinary): $(uboot_workdir)/.config
	cd $(uboot_srcdir); $(MAKE) $(@F) O=$(uboot_workdir) \
		CROSS_COMPILE=$(LINUX_TARGET)- ARCH=riscv DTC=$(DTC) \
		HOSTCFLAGS_bmp_logo.o="-I$(uboot_srcdir)/include" \
		HOSTCFLAGS_ecdsa-libcrypto.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_sunxi_toc0.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_mxsimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_kwbimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_mkimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_rsa-sign.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTLDLIBS_mkimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_kwbimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_dumpimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_aes-decrypt="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_aes-encrypt="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto"
	$(MV) $(uboot_ibinary) $(uboot_obinary)

$(opensbi_obinary): $(uboot_obinary) | $(opensbi_workdir) 
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)- \
		FW_PAYLOAD=y \
		PLATFORM=generic \
		FW_PAYLOAD_PATH=$(uboot_obinary)
	$(MV) $(opensbi_ibinary) $(opensbi_obinary)

$(uboot_spl_workdir)/.config: $(BP_SDK_INSTALL_DIR) | $(uboot_spl_workdir)
	$(MAKE) -C $(uboot_spl_srcdir) clean $(uboot_spl_defconfig) O=$(uboot_spl_workdir) \
		ARCH=riscv CROSS_COMPILE=$(LINUX_TARGET)-

$(uboot_spl_obinary): $(uboot_spl_workdir)/.config
	cd $(uboot_spl_srcdir); $(MAKE) $(@F) O=$(uboot_spl_workdir) \
		CROSS_COMPILE=$(LINUX_TARGET)- ARCH=riscv DTC=$(DTC) \
		HOSTCFLAGS_bmp_logo.o="-I$(uboot_spl_srcdir)/include" \
		HOSTCFLAGS_ecdsa-libcrypto.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_sunxi_toc0.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_mxsimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_kwbimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_mkimage.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTCFLAGS_rsa-sign.o="-I$(BP_SDK_INCLUDE_DIR)" \
		HOSTLDLIBS_mkimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_kwbimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_dumpimage="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_aes-decrypt="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto" \
		HOSTLDLIBS_aes-encrypt="-L$(BP_SDK_LIB_DIR64) -lssl -lcrypto"
	$(MV) $(uboot_spl_ibinary) $(uboot_spl_obinary)

vmlinux: $(linux_obinary)
uboot: $(uboot_obinary)
opensbi: $(opensbi_obinary)
uboot-spl: $(uboot_spl_obinary)

all: vmlinux opensbi uboot-spl

clean_linux: clean_opensbi
	rm -rf $(linux_workdir)

clean_uboot:
	rm -rf $(uboot_workdir)

clean_opensbi:
	rm -rf $(opensbi_workdir)

clean_uboot_spl:
	rm -rf $(uboot_spl_workdir)

clean_all: clean_uboot_spl clean_opensbi clean_uboot clean_linux
	rm -rf $(workdir)

