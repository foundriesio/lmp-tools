#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#

read -p "Show the bootheader information [enter] " foo
./bootgen-spl -arch zynqmp -read boot.bin

read -p "Verify the bootable image [enter] "
./bootgen-spl -arch zynqmp -verify boot.bin

