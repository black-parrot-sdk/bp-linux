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

  def __init__(self, ncpus, mem_size):
    self.ncpus = ncpus
    self.mem_size_bytes = mem_size * 1024 * 1024
    if self.mem_size_bytes < 0x100000000:
      self.mem_size_upper = 0
      self.mem_size_lower = self.mem_size_bytes
    else:
      self.mem_size_lower = self.mem_size_bytes & 0xFFFFFFFF
      self.mem_size_upper = self.mem_size_bytes >> 32

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
\t\t\treg = <0x{0}>;
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
      .format(format(i, 'x'))
      )

    print('''
\t}};
\tmemory@80000000 {{
\t\tdevice_type = "memory";
\t\treg = <0x0 0x80000000 0x{0} 0x{1}>;
\t}};
\tsoc {{
\t\t#address-cells = <2>;
\t\t#size-cells = <2>;
\t\tcompatible = "ucbbar,spike-bare-soc", "simple-bus";
\t\tranges;
\t\tclint@300000 {{
\t\t\tcompatible = "riscv,clint0";
\t\t\tinterrupts-extended = <'''
    .format(format(self.mem_size_upper, 'x'), format(self.mem_size_lower, 'x'))
    )

    for i in range(0, self.ncpus):
      print('''\t\t\t\t&CPU{0}_intc 3 &CPU{0}_intc 7'''.format(format(i, 'x')))

    print('''\t\t\t>;
\t\t\treg = <0x0 0x300000 0x0 0xc0000>;
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
  parser.add_argument('--mem-size', type=int, dest='mem_size', default=64, help='DRAM size in MiB')
  args = parser.parse_args()

  generator = DTS(args.ncpus, args.mem_size)
  generator.gendts()
