# Linux on BlackParrot
This is the repository for building a RISC-V Linux binary for BlackParrot.
We use Buildroot to generate the root filesystem and OpenSBI to act as the firmware.

## Build
```
make linux.riscv [WITH_SHELL=<path_to_sh_script>] [OPENSBI_NCPUS=<n>]
```
* OPENSBI\_NCPUS: Number of harts that boot linux(default: 1)
* WITH\_SHELL: If set, at the end of the boot, runs the given shell script instead of creating the user terminal.

### Build Steps
The build order is [Buildroot -> sysroot generation -> Linux -> OpenSBI], so each step can be done seperately in the following order:
```
make buildroot
make sysroot
make vmlinux
make opensbi
```

## Adding Executables
To add your custom binaries and files to the root filesystem:
- First, generate the /work/sysroot directory by running `make sysroot`.
- Next, add the binaries to the /work/sysroot directory.
- Finally, proceed with the linux and opensbi build by running `make linux.riscv`.

## Clean
The following commands can be used to clean the work directory. Cleaning each step also wipes the next steps.
```
make clean
make clean_buildroot
make clean_sysroot
make clean_vmlinux
make clean_opensbi
```
