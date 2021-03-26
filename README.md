# Linux on BlackParrot

[![Join the chat at https://gitter.im/black-parrot/linux](https://badges.gitter.im/black-parrot/linux.svg)](https://gitter.im/black-parrot/linux?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This is the repository for building a RISC-V Linux binary for BlackParrot.
We use Buildroot to generate a BusyBox root filesystem and we use OpenSBI as the machine-mode firmware.
The following commands are run within this directory.

## Build
```
make linux.riscv [WITH_SHELL=<path_to_sh_script>] [OPENSBI_NCPUS=<n>]
```
* OPENSBI\_NCPUS: Number of harts that boot linux(default: 1)
* WITH\_SHELL: If set, at the end of the boot, runs the given shell script instead of creating the BusyBox login shell.

**default login:** user="root", password=""

### Build Steps
The build order is [Buildroot -> sysroot generation -> Linux -> OpenSBI], so each step can be done seperately in the following order:
```
make buildroot
make sysroot [WITH_SHELL=<path_to_sh_script>]
make vmlinux
make opensbi [OPENSBI_NCPUS=<n>]
```

## Adding Executables
To add your custom binaries and files to the root filesystem:
- First, generate the work/sysroot directory by running `make sysroot`.
- Next, add the binaries to the work/sysroot directory.
- Finally, proceed with the linux and opensbi build by running `make linux.riscv`.

**Example:** Adding custom binaries to a quad-core SMP Linux with user terminal:
```
make sysroot
cp <binaries> work/sysroot/bin/.
make linux.riscv OPENSBI_NCPUS=4
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
