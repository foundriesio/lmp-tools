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
	git checkout -b 2021.1 34c4313a09dd75cf6ff5b188136e1a077c5b0aa2
	git am ../zynqmp-spl.patch
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
