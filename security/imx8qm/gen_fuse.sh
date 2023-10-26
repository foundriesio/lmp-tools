#!/bin/bash
#
# Copyright (C) 2023 Foundries.IO
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
uuu_version 1.3.102

SDPS: boot -f imx-boot-mfgtool.signed
$TORADEX

SDPU: delay 1000
SDPU: write -f u-boot-mfgtool.itb
SDPU: jump

# These commands will be run when use SPL and will be skipped if no spl
# if (SPL support SDPV)
# {
SDPV: delay 1000
SDPV: write -f u-boot-mfgtool.itb
SDPV: jump
# }

EOF
HASH=($(hexdump -e '/4 "0x"' -e '/4 "%08X""\n"' ${FUSEBIN}))
OFFSET=722
bank=0
for idx in $(seq 722 737)
do
    echo "FB: ucmd fuse prog -y ${bank} ${idx} ${HASH[$((${idx}-${OFFSET}))]}"
done
echo
echo "FB: acmd reset"
echo "FB: DONE") > ${FILE}
