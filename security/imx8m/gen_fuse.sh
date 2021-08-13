#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#

DIR=$(dirname $0)
FILE=${FUSE_DEST:-${DIR}/fuse.uuu}
FUSEBIN=${FUSEBIN:-cst-3.3.1/crts/SRK_1_2_3_4_fuse.bin}
TORADEX=

usage() {
    echo -e "Usage: $0 [-s source_file] [-d destination_file] [-t]
where:
   -t adds Toradex PIDs for Fastboot in u-boot
   source_file defaults to cst-3.3.1/crts/SRK_1_2_3_4_fuse.bin
   destination file defaults to ${DIR}/fuse.uuu
" 1>&2
    exit 1
}

while getopts ":s:d:t" arg; do
    case "${arg}" in
        s)
            FUSEBIN="${OPTARG}"
            ;;
        d)
            FILE="${OPTARG}"
            ;;
        t)
            if [ -f $DIR/../toradex.cfg ]
            then
              TORADEX=$(cat $DIR/../toradex.cfg)
            else
              echo "No toradex config available"
              usage
            fi
            ;;
        *)
            usage
            ;;
    esac
done

DIR=$(dirname ${FILE})
shift $((OPTIND-1))

if [ $# -gt 0 ]
then
    echo "Too many arguments" 1>&1
    usage
fi

if [ ! -f "${FUSEBIN}" ]
then
    echo "source file '${FUSEBIN}' not found" 1>&2
    usage
fi

mkdir -p "${DIR}"

if [ ! -d "${DIR}" ]
then
    echo "destination directory '${DIR}' missing"
fi


(cat << EOF
uuu_version 1.2.39
$TORADEX

SDP: boot -f imx-boot-mfgtool.signed

SDPU: delay 1000
SDPV: write -f u-boot-mfgtool.itb
SDPU: jump

EOF
HASH=($(hexdump -e '/4 "0x"' -e '/4 "%X""\n"' ${FUSEBIN}))
OFFSET=0
for bank in 6 7
do
    for idx in $(seq 0 3)
    do
        echo "FB: ucmd fuse prog -y ${bank} ${idx} ${HASH[$((${idx}+${OFFSET}))]}"
    done
    OFFSET=4
done
echo
echo "FB: acmd reset"
echo
echo "FB: DONE") > ${FILE}
