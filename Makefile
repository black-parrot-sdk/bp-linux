
export LINUX_TARGET ?= riscv64-unknown-linux-gnu

TOP                ?= $(shell git rev-parse --show-toplevel)
BP_SDK_DIR         ?= $(TOP)/..
BP_SDK_INSTALL_DIR ?= $(BP_SDK_DIR)/install
BP_SDK_BIN_DIR     ?= $(BP_SDK_INSTALL_DIR)/bin
BP_LINUX_DIR       := $(BP_SDK_DIR)/linux
PATH               := $(BP_SDK_BIN_DIR):$(PATH)

OPENSBI_NCPUS ?= 1
GENDTS_PY     ?= $(BP_LINUX_DIR)/gendts.py

opensbi_srcdir   := $(BP_SDK_DIR)/opensbi
linux_srcdir     := $(BP_LINUX_DIR)/linux
buildroot_srcdir := $(BP_LINUX_DIR)/buildroot

wrkdir           := $(BP_LINUX_DIR)/work

buildroot_wrkdir        := $(wrkdir)/buildroot
buildroot_sysroot       := $(wrkdir)/sysroot
buildroot_sysroot_stamp := $(wrkdir)/.buildroot_sysroot_stamp
buildroot_tar           := $(buildroot_wrkdir)/images/rootfs.tar
buildroot_config        := $(BP_LINUX_DIR)/cfg/buildroot_initramfs_config

linux_wrkdir     := $(wrkdir)/linux
linux_defconfig  := $(BP_LINUX_DIR)/cfg/linux_defconfig
linux_patch      := $(BP_LINUX_DIR)/cfg/linux.patch
vmlinux          := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_binary   := $(linux_wrkdir)/vmlinux.bin

opensbi_wrkdir   := $(wrkdir)/opensbi
fw_payload       := $(opensbi_wrkdir)/platform/blackparrot/firmware/fw_payload.elf

$(buildroot_wrkdir)/.config: $(buildroot_srcdir)
	mkdir -p $(dir $@)
	cp $(buildroot_config) $@
	$(MAKE) -C $< RISCV=$(BP_SDK_INSTALL_DIR) PATH=$(PATH) O=$(buildroot_wrkdir) olddefconfig CROSS_COMPILE=$(LINUX_TARGET)-

$(buildroot_tar): $(buildroot_srcdir) $(buildroot_wrkdir)/.config
	$(MAKE) -C $< RISCV=$(BP_SDK_INSTALL_DIR) PATH=$(PATH) O=$(buildroot_wrkdir)

$(buildroot_sysroot_stamp): $(buildroot_tar)
	mkdir -p $(buildroot_sysroot)
	tar -xpf $< -C $(buildroot_sysroot) --exclude ./dev --exclude ./usr/share/locale
ifdef WITH_SHELL
	sed "s/INITSHELL/$(notdir $(WITH_SHELL))/g" $(BP_LINUX_DIR)/cfg/inittab > $(buildroot_sysroot)/etc/inittab
	cp $(WITH_SHELL) $(buildroot_sysroot)/$(notdir $(WITH_SHELL))
endif
	touch $@

$(linux_wrkdir)/.config: $(linux_srcdir)
	cd $(linux_srcdir); git stash
	mkdir -p $(dir $@)
	cp -p $(linux_defconfig) $@
	$(MAKE) -C $< O=$(linux_wrkdir) ARCH=riscv olddefconfig

$(vmlinux): $(linux_srcdir) $(linux_wrkdir)/.config $(buildroot_sysroot_stamp)
	echo "n" | $(MAKE) -j 4 -C $< O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_SOURCE="$(BP_LINUX_DIR)/cfg/initramfs.txt $(buildroot_sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		CROSS_COMPILE=$(LINUX_TARGET)- \
		ARCH=riscv \
		vmlinux

$(vmlinux_stripped): $(vmlinux)
	$(LINUX_TARGET)-strip -o $@ $<

$(vmlinux_binary): $(vmlinux_stripped)
	$(LINUX_TARGET)-objcopy -O binary $< $@

$(fw_payload): $(opensbi_srcdir) $(vmlinux_binary)
	mkdir -p $(opensbi_wrkdir)/platform/blackparrot
	python $(GENDTS_PY) --ncpus=$(OPENSBI_NCPUS) | dtc -O dtb -o $(opensbi_wrkdir)/platform/blackparrot/blackparrot.dtb
	$(MAKE) -C $< O=$(opensbi_wrkdir) \
		PLATFORM=blackparrot \
		PLATFORM_RISCV_ISA=rv64imafd \
		PLATFORM_HART_COUNT=$(OPENSBI_NCPUS) \
		CROSS_COMPILE=$(LINUX_TARGET)- \
		FW_PAYLOAD_PATH=$(vmlinux_binary)

linux.riscv: $(fw_payload)
	cp $< $@

buildroot: $(buildroot_tar)
sysroot: $(buildroot_sysroot_stamp)
vmlinux: $(vmlinux_stripped)
opensbi: $(fw_payload)

clean:
	rm -rf $(wrkdir)/*

clean_opensbi:
	rm -rf $(opensbi_wrkdir)

clean_vmlinux: clean_opensbi
	rm -rf $(linux_wrkdir)

clean_sysroot: clean_vmlinux
	rm -rf $(buildroot_sysroot) $(buildroot_sysroot_stamp)

clean_buildroot: clean
