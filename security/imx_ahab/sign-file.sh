#!/bin/sh
#
# Copyright (c) 2021 Foundries.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# stop on errors
set -e

CST_BINARY="cst"
CSF_TEMPLATE="u-boot-spl-sign.csf-template"
KEY_DIR="."
DISPLAY_USAGE=0
SIGN_SPL=0
SRK_INDEX=1
ENGINE=
OUT=/dev/null

parse_args()
{
    while [ ${#} -gt 0 ]
    do
        case ${1} in
        --cst)
            CST_BINARY=${2}
            shift
            shift
            ;;
        --csf-template)
            CSF_TEMPLATE=${2}
            shift
            shift
            ;;
        --spl)
            WORK_FILE=${2}
            SIGN_SPL=1
            shift
            shift
            ;;
        --key-dir)
            KEY_DIR=${2}
            shift
            shift
            ;;
        --srk-index)
            SRK_INDEX=${2}
            shift
            shift
            ;;
        -h)
            DISPLAY_USAGE=1
            shift
            ;;
        --help)
            DISPLAY_USAGE=1
            shift
            ;;
        --verbose)
            OUT=$(tty)
            shift
            ;;
        *)
            echo "Unknown param: '${1}'!"
            exit 1
            ;;
        esac
    done
}

parse_args "$@"

if [ "${DISPLAY_USAGE}" = "1" ]; then
    echo "usage for: ${0}"
    echo "  --cst: set cst binary path/filename   [default: ${CST_BINARY}]"
    echo "  --csf-template: set CSF template file [default: ${CSF_TEMPLATE}]"
    echo "  --spl: SPL binary to sign             [--spl is required]"
    echo "  --key-dir: location for key files     [default: ${KEY_DIR}]"
    echo "  --srk-index: the key to sign with     [default: 1]"
    echo "  --verbose: display output of cst tool"
    exit 0
fi

if [ -z "${WORK_FILE}" ]; then
    echo "ERROR: must specify --spl"
    echo 1
fi

echo ""
echo "SETTINGS FOR  : ${0}"
echo "--------------:"
echo "CST BINARY    : ${CST_BINARY}"
echo "CSF TEMPLATE  : ${CSF_TEMPLATE}"
echo "BINARY FILE   : ${WORK_FILE}"
echo "KEYS DIRECTORY: ${KEY_DIR}"
echo "KEYS INDEX    : ${SRK_INDEX}"
echo ""

# Transform template -> config
sed "s^@@KEY_ROOT@@^${KEY_DIR}^g" ${CSF_TEMPLATE} > ${CSF_TEMPLATE}.csf-config
sed -i~ "s^@@WORK_FILE@@^${WORK_FILE}^g" ${CSF_TEMPLATE}.csf-config

SRK_FILE=$(ls -t ${KEY_DIR}/SRK${SRK_INDEX}*_crt.pem 2> /dev/null | head -1)
if [ -n "${SRK_FILE}" ]; then
    sed -i~ "s^${KEY_DIR}/SRK1_sha384_secp384r1_v3_usr_crt.pem^${SRK_FILE}^" ${CSF_TEMPLATE}.csf-config
fi

if [ "${SRK_INDEX}" != "1" ]; then
    sed -i~ "s/^Source index =.*/Source index = $((${SRK_INDEX} - 1))/" ${CSF_TEMPLATE}.csf-config
fi

# working file used for signature
cp ${WORK_FILE} ${WORK_FILE}.mod

# generate the signatures, certificates, ... in the CSF binary
echo "Invoking CST to sign the binary"
${CST_BINARY} --o ${WORK_FILE}.signed --i ${CSF_TEMPLATE}.csf-config > $OUT

echo "Process completed successfully and signed file is ${WORK_FILE}.signed"

# Cleanup config / mod SPL
rm ${CSF_TEMPLATE}.csf-config
rm -f ${CSF_TEMPLATE}.csf-config~
rm ${WORK_FILE}_csf.bin
rm ${WORK_FILE}.mod
