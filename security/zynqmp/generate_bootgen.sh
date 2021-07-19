#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#
# Generate a version of bootgen that supports SPL
if [ ! -f bootgen-spl ]; then
    cd bootgen
    ./bootgen-spl.sh
    cd ..
fi
