
export LINUX_TARGET ?= riscv64-unknown-linux-gnu

TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_SDK_LIB_DIR     ?= $(BP_SDK_INSTALL_DIR)/lib
BP_SDK_LIB_DIR64   ?= $(BP_SDK_INSTALL_DIR)/lib64
BP_SDK_INCLUDE_DIR ?= $(BP_SDK_INSTALL_DIR)/include
BP_LINUX_DIR       ?= $(BP_SDK_DIR)/linux
PATH               := $(BP_SDK_BIN_DIR):$(PATH)

PYTHON ?= python
DTC ?= dtc
GIT ?= git
WGET ?= wget
TAR ?= tar
MKDIR ?= mkdir -p
MV ?= mv

OPENSBI_NCPUS ?= 1
# memory size in MiB
MEM_SIZE      ?= 64
GENDTS_PY     ?= $(BP_LINUX_DIR)/gendts.py
WITH_SHELL    ?=

opensbi_srcdir   := $(BP_LINUX_DIR)/opensbi
linux_srcdir     := $(BP_LINUX_DIR)/linux
buildroot_srcdir := $(BP_LINUX_DIR)/buildroot

wrkdir           := $(BP_LINUX_DIR)/work

buildroot_wrkdir        := $(wrkdir)/buildroot
buildroot_sysroot       := $(wrkdir)/sysroot
buildroot_sysroot_stamp := $(wrkdir)/.buildroot_sysroot_stamp
buildroot_tar           := $(buildroot_wrkdir)/images/rootfs.tar
buildroot_config        := $(BP_LINUX_DIR)/cfg/buildroot_defconfig

vmlinux          := $(buildroot_wrkdir)/images/vmlinux
vmlinux_stripped := $(buildroot_wrkdir)/images/vmlinux-stripped
vmlinux_binary   := $(buildroot_wrkdir)/images/vmlinux.bin

opensbi_wrkdir   := $(wrkdir)/opensbi
fw_payload       := $(opensbi_wrkdir)/platform/generic/blackparrot/firmware/fw_payload.elf
bp_dts           := $(opensbi_wrkdir)/platform/generic/blackparrot/blackparrot.dts
bp_dtb           := $(opensbi_wrkdir)/platform/generic/blackparrot/blackparrot.dtb

$(buildroot_wrkdir)/.config: $(buildroot_srcdir)
	mkdir -p $(dir $@)
	cp $(buildroot_config) $@
	cp -r $(BP_LINUX_DIR)/rootfs $(buildroot_sysroot)
ifneq ($(WITH_SHELL),)
	cp $(WITH_SHELL) $(buildroot_sysroot)/etc/init.d/S100$(notdir $(WITH_SHELL))
endif
	$(MAKE) -C $< RISCV=$(BP_SDK_INSTALL_DIR) PATH=$(PATH) O=$(buildroot_wrkdir) olddefconfig CROSS_COMPILE=$(LINUX_TARGET)-

$(vmlinux): $(buildroot_srcdir) $(buildroot_wrkdir)/.config
	$(MAKE) -C $< RISCV=$(BP_SDK_INSTALL_DIR) PATH=$(PATH) O=$(buildroot_wrkdir)

$(vmlinux_stripped): $(vmlinux)
	$(LINUX_TARGET)-strip -o $@ $<

$(vmlinux_binary): $(vmlinux_stripped)
	$(LINUX_TARGET)-objcopy -O binary $< $@

$(bp_dts):
	mkdir -p $(@D)
	$(PYTHON) $(GENDTS_PY) --ncpus=$(OPENSBI_NCPUS) --mem-size=$(MEM_SIZE) > $(bp_dts)

$(bp_dtb): $(bp_dts)
	mkdir -p $(@D)
	$(DTC) -O dtb -o $(bp_dtb) $<

$(fw_payload): $(opensbi_srcdir) $(vmlinux_binary) $(bp_dtb)
	$(MAKE) -C $< O=$(opensbi_wrkdir) \
		CROSS_COMPILE=$(LINUX_TARGET)- \
		PLATFORM=generic/blackparrot \
		PLATFORM_FDT_PATH=$(bp_dtb) \
		PLATFORM_ADDITIONAL_CFLAGS="-DPLATFORM_HART_COUNT=$(OPENSBI_NCPUS) -I$(BP_SDK_INCLUDE_DIR)" \
		FW_PAYLOAD=y \
		PAYLOAD_PATH=$(vmlinux_binary)

linux.riscv: $(fw_payload)
	cp $< $@

buildroot: $(buildroot_tar)
sysroot: $(buildroot_sysroot_stamp)
vmlinux: $(vmlinux_stripped)
opensbi: $(fw_payload)

clean: clean_buildroot
	rm -rf linux.riscv

clean_opensbi:
	rm -rf $(opensbi_wrkdir)

clean_vmlinux: clean_opensbi
	rm -rf $(linux_wrkdir)

clean_sysroot: clean_vmlinux
	rm -rf $(buildroot_sysroot)

clean_buildroot:
	rm -rf $(wrkdir)
