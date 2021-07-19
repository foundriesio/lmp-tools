#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#
# Generate the PPK fuse data and the boot.bin
# Input  : bifs/boot.bif -> ie u-boot-spl.bin and pmu.bin
# Output : boot.bin
#          fusePPK.txt
#
echo "
 Inputs:
  - keys/*
  - pmu.bin
  - u-boot-spl.bin
  Outputs:
  - boot.bin [bootheader + pmu_fw + spl + spl.dtb]
  - fusePPK.txt [PPK fuse sha384]
"
read -p "Generate [enter] " foo
./bootgen-spl -arch zynqmp -image bifs/boot.bif -w on -o boot.bin -efuseppkbits fusePPK.txt
echo "
NOTE: make sure that the generated fusePPK.txt matches the one in keys/fusePPK.txt

      However, if you generated new keys, then replace keys/fusePPK.txt with the new one.
      Once the fuse has been burnt, do not regenerate the keys (or lose them)
"
