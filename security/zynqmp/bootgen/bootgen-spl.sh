#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#

if [ -d build ]; then
   rm -rf build
fi
read -p "Enter option:
 1) Build bootgen-spl from https://github.com/Xilinx/bootgen.git
 2) Build bootgen-spl from archive
 : " option
case $option in
    1)
	git clone https://github.com/Xilinx/bootgen.git build
	cd build
	git checkout -b xilinx_v2022.1 4eac958eb6c831ffa5768a0e2cd4be23c5efe2e0
	;;
    2)
	mkdir build
	cp bootgen-archive.tar build
	cd build
	tar xvf bootgen-archive.tar
	;;
    *)
	echo "Error, wrong option "
	exit 1
esac
make -j8
mv bootgen ../../bootgen-spl
cd ..
rm -rf build
