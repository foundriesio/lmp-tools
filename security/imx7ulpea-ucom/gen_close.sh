#!/bin/bash
#
# Copyright (C) 2021 Foundries.IO
#
# SPDX-License-Identifier: MIT
#

DIR=$(dirname $0)
FILE=${CLOSE_DEST:-${DIR}/close.uuu}
FUSEBIN=${FUSEBIN:-cst-3.3.1/crts/SRK_1_2_3_4_fuse.bin}

usage() {
    echo -e "Usage: $0 [-s source_file] [-d destination_file]
where:
   source_file defaults to cst-3.3.1/crts/SRK_1_2_3_4_fuse.bin
   destination file defaults to ${DIR}/close.uuu
" 1>&2
    exit 1
}

while getopts ":s:d:" arg; do
    case "${arg}" in
        s)
            FUSEBIN="${OPTARG}"
            ;;
        d)
            FILE="${OPTARG}"
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

SDP: boot -f SPL-mfgtool.signed

SDPU: delay 1000
SDPV: write -f u-boot-mfgtool.itb
SDPU: jump

FB: ucmd if mmc dev 0; then setenv fiohab_dev 0; else setenv fiohab_dev 1; fi;

EOF
HASH=($(hexdump -e '/4 "0x"' -e '/4 "%X""\n"' ${FUSEBIN}))
for offset in 0 8
do
    for idx in $(seq 0 7)
    do
        echo "FB: ucmd setenv srk_$((${idx}+${offset})) ${HASH[${idx}]}"
    done
    echo
done
cat << EOF
FB: ucmd if fiohab_close; then echo Platform Secured; else echo Error, Can Not Secure the Platform; fi
FB: acmd reset

FB: DONE
EOF
) > ${FILE}
