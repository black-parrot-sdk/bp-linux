# Linux on BlackParrot
This is the repository for building a RISC-V Linux binary for BlackParrot.
We use Buildroot to generate a BusyBox root filesystem and we use OpenSBI as the machine-mode firmware.
The following commands are run within this directory.

## Build
```
make linux.riscv [WITH_SHELL=<path_to_sh_script>] [OPENSBI_NCPUS=<n>] [MEM_SIZE=<s>] [WITH_OVERLAY=<path_to_rootfs-overlay>] [FDT_ADDR=<addr>]
```
* OPENSBI\_NCPUS: Number of harts that boot linux (default: 1)
* WITH\_SHELL: If set, at the end of the boot, runs the given shell script instead of creating the BusyBox login shell.
* MEM\_SIZE: size in MB of memory (default: 64), sets memory size in device tree; current BP max is 2048
* WITH\_OVERLAY: If set, applies the contents of the given directory as a root filesystem overlay (see Adding Executables below)
* FDT\_ADDR: sets the address used by OpenSBI for FDT placement. Must be at an address that does not overlap with the Linux image payload.

**default login:** user="root", password=""

### Build Steps
The build order is [Buildroot -> sysroot generation -> Linux -> OpenSBI], so each step can be done seperately in the following order:
```
make buildroot [WITH_OVERLAY=<path_to_rootfs-overlay>]
make sysroot [WITH_SHELL=<path_to_sh_script>]
make vmlinux
make opensbi [OPENSBI_NCPUS=<n>] [FDT_ADDR=<addr>]
```

## Adding Executables
To add your custom binaries and files to the root filesystem you can either use a Buildroot root
filesystem overlay or add the binaries directly into the sysroot work directory.

### Option 1 - Root Filesystem Overlay
- First, create a root filesystem overlay directory structure containing your binaries
- Next, specify the `WITH_OVERLAY` option when invoking `make linux.riscv`.

See the [Buildroot documentation](https://buildroot.org/downloads/manual/manual.html) for more details.

**Example:** Adding custom binaries to a quad-core SMP Linux wit huser terminal:
```
mkdir -p ./my-overlay/bin
cp <binaries> ./my-overlay/bin/
make linux.riscv WITH_OVERLAY=./my-overlay
```

Note: rebuilding with a new root filesystem overlay requires cleaning the entire linux build with `make clean`

### Option 2 - Manually copy files into the sysroot work directory
- First, generate the work/sysroot directory by running `make sysroot`.
- Next, add the binaries to the work/sysroot directory.
- Finally, proceed with the linux and opensbi build by running `make linux.riscv`.

**Example:** Adding custom binaries to a quad-core SMP Linux with user terminal:
```
make sysroot
cp <binaries> work/sysroot/bin/.
make linux.riscv OPENSBI_NCPUS=4
```

### Maximum Linux Image Size
The maximum size of the Linux image, including all added binaries and files, is limited by the size
of physical memory and the placement of the Flattened Device Tree (FDT) blob in the OpenSBI generated
binary. The FW\_PAYLOAD approach is used to build BlackParrot's Linux image, which results in the
FDT being placed **after** the Linux kernel image (which includes all added binaries and files).
The maximum payload size is a [known limitation](https://github.com/riscv-software-src/opensbi/issues/169)
of this OpenSBI approach, which we plan to remedy in the future.

By default, the Linux image may be no larger than 32 MiB. If your platform has sufficient physical
memory, the placement of the FDT can adjusted to a higher address to accomodate a larger Linux
image. This is done by setting the `FDT_ADDR` option when executing the OpenSBI build step. The
OpenSBI payload binary (our Linux image) is placed at an address of 0x80200000 by default.

Example:
```
# Provide 128 MiB for Linux image
make opensbi FDT_ADDR=0x88200000
```

## Clean
The following commands can be used to clean the work directory. Cleaning each step also wipes the next steps.
```
make clean
make clean_buildroot
make clean_sysroot
make clean_vmlinux
make clean_opensbi
```

For example, to rebuild linux for a different OPENSBI\_NCPUS value you can wipe the opensbi build and rebuild with the new number of cores:
```
make clean_opensbi
make linux.riscv OPENSBI_NCPUS=<new_n>
```

Or to change the initial shell script, you can wipe the sysroot folder and regenerate it with the new script:
```
make clean_sysroot
make linux.riscv WITH_SHELL=<new_shell>
```
