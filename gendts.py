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
    self.mem_size_lower = hex(self.mem_size_bytes & 0xFFFFFFFF)
    self.mem_size_upper = hex(self.mem_size_bytes >> 32)

  def gendts(self):

    print('''
/dts-v1/;

/ {{
    #address-cells = <2>;
    #size-cells = <2>;
    compatible = "blackparrot,riscv64";
    cpus {{
        #address-cells = <1>;
        #size-cells = <0>;
        timebase-frequency = <10000000>;
    '''.format()
    )

    for i in range(0, self.ncpus):
      print('''
        CPU{0}: cpu@{0} {{
            clocks = <&clk0>;
            device_type = "cpu";
            reg = <{0}>;
            status = "okay";
            compatible = "riscv";
            riscv,isa = "rv64imafdc";
            mmu-type = "riscv,sv39";
            CPU{0}_intc: interrupt-controller {{
                #interrupt-cells = <1>;
                interrupt-controller;
                compatible = "riscv,cpu-intc";
            }};
        }};
      '''.format(format(i, 'x'))
      )

    print('''
    }};
      clocks {{
          clk0: osc {{
              compatible = "fixed-clock";
              #clock-cells = <0>;
              clock-frequency = <66667000>;
          }};
      }};
    '''.format()
    );

    print('''
    memory@80000000 {{
        device_type = "memory";
        reg = <0x0 0x80000000 {0} {1}>;
    }};
    soc {{
        #address-cells = <2>;
        #size-cells = <2>;
        compatible = "blackparrot,chipset", "simple-bus";
        ranges;
        uart0: uart@101000 {{
            compatible = "blackparrot,uart";
            status = "okay";
        }};

        clint0: clint@300000 {{
            compatible = "blackparrot,clint";
            interrupts-extended = <
    '''.format(self.mem_size_upper, self.mem_size_lower)
    )

    for i in range(0, self.ncpus):
      print('''                &CPU{0}_intc 3 &CPU{0}_intc 7'''.format(format(i, 'x')))

    print('''            >;
            reg = <0x0 0x300000 0x0 0xc0000>;
        }};
    }};
    chosen {{
        bootargs = "console=hvc0 loglevel=8 root=/dev/ram0";
    }};
}};
    '''.format()
    )


if __name__ == "__main__":

  parser = argparse.ArgumentParser()
  parser.add_argument('--ncpus', type=int, default=1, help='number of BlackParrot cores')
  parser.add_argument('--mem-size', type=int, dest='mem_size', default=64, help='DRAM size in MiB')
  args = parser.parse_args()

  generator = DTS(args.ncpus, args.mem_size)
  generator.gendts()
