#!/bin/bash

# Generate the FPGA signed image.
# Input  : bifs/fpga.bif
# Output : fpga.bit.bin
#
# This image needs to be added to the FIT so SPL can
# load the bitstream before u-boot proper runs.
#
# An authenticated FPGA can be loaded via u-boot proper using the
# loadsecure fpga command (only for Xilinx).
#
# ie: For fpga.bit.bin placed at 0x10000000 with a size of 0x70000
# 1 = DDR authentication, 2 = no encryption:
# $ fpga loads 0 0x10000000 0x70000 1 2
#
echo "
 Inputs:
  - keys/SSK.pem
  - keys/PPK.pem
  - fpga.bit
  Outputs:
  - fpga.bit.bin

"
read -p "Generate [enter] " foo
./bootgen-spl -arch zynqmp -image bifs/fpga.bif -o fpga.bit.bin -w on -log error
