#
#   gendts.py
#
#   Generates the device tree source information for BlackParrot
#

import sys
import argparse
import math
import os
import subprocess

class DTS:

  def __init__(self, ncpus):
    self.ncpus = ncpus

  def gendts(self):

    print(
'''
/dts-v1/;

/ {
\t#address-cells = <2>;
\t#size-cells = <2>;
\tcompatible = "ucbbar,spike-bare-dev";
\tmodel = "ucbbar,spike-bare";
\tcpus {
\t\t#address-cells = <1>;
\t\t#size-cells = <0>;
\t\ttimebase-frequency = <10000000>;'''
    )

    for i in range(0, self.ncpus):
      print('''
\t\tCPU{0}: cpu@{0} {{
\t\t\tdevice_type = "cpu";
\t\t\treg = <{0}>;
\t\t\tstatus = "okay";
\t\t\tcompatible = "riscv";
\t\t\triscv,isa = "rv64imafdc";
\t\t\tmmu-type = "riscv,sv39";
\t\t\tclock-frequency = <1000000000>;
\t\t\tCPU{0}_intc: interrupt-controller {{
\t\t\t\t#interrupt-cells = <1>;
\t\t\t\tinterrupt-controller;
\t\t\t\tcompatible = "riscv,cpu-intc";
\t\t\t}};
\t\t}};'''
      .format(str(i))
      )

    print('''
\t};
\tmemory@80000000 {
\t\tdevice_type = "memory";
\t\treg = <0x0 0x80000000 0x0 0x04000000>;
\t};
\tsoc {
\t\t#address-cells = <2>;
\t\t#size-cells = <2>;
\t\tcompatible = "ucbbar,spike-bare-soc", "simple-bus";
\t\tranges;
\t\tclint@300000 {
\t\t\tcompatible = "riscv,clint0";
\t\t\tinterrupts-extended = <'''
    )

    for i in range(0, self.ncpus):
      print('''\t\t\t\t&CPU{0}_intc 3 &CPU{0}_intc 7'''.format(str(i)))

    print('''\t\t\t>;
\t\t\treg = <0x0 0x300000 0x0 0xc0000>;
\t\t};

\t\tplic: interrupt-controller@20000000 {
\t\t\t#address-cells = <0>;
\t\t\t#interrupt-cells = <1>;
\t\t\tcompatible = "sifive,plic-1.0.0";
\t\t\tinterrupt-controller;
\t\t\tinterrupts-extended = <&CPU0_intc 9>;
\t\t\treg = <0x0 0x20000000 0x0 0x4000000>;
\t\t\triscv,ndev = <1>;
\t\t};

\t\tethernet@10001000 {
\t\t\tcompatible = "litex,liteeth";
\t\t\tlocal-mac-address = [dc a6 32 bb 7d a4];
\t\t\treg=<0x0 0x10001000 0x0 0x100>,
\t\t\t\t<0x0 0x10000000 0x0 0x1000>;
\t\t\treg-names="mac", "buffer";
\t\t\tlitex,rx-slots = <1>;
\t\t\tlitex,tx-slots = <1>;
\t\t\tlitex,slot-size = <0x800>;
\t\t\tinterrupt-parent=<&plic>;
\t\t\tinterrupts=<1>;
\t\t};

\t};
\thtif {
\t\tcompatible = "ucb,htif0";
\t};
\tchosen {
\t\tbootargs = "console=hvc0 loglevel=8";
\t};
};'''
    )


if __name__ == "__main__":

  parser = argparse.ArgumentParser()
  parser.add_argument('--ncpus', type=int, default=1, help='number of BlackParrot cores')
  args = parser.parse_args()

  generator = DTS(args.ncpus)
  generator.gendts()
