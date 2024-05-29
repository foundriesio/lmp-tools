#!/bin/sh
#
# Copyright (C) 2023 Foundries.io
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Authors:
#    Tim Anderson <tim.anderson@foundries.io>
set -e

if [ "$(basename $PWD)" != "lmp-manifest" ]
then
	echo "run in lmp-manifest directory"
	exit 1
fi

TOOLS=$(realpath ${1:-../../lmp-tools})
if [ ! -d $TOOLS ]
then
	echo "checkout lmp-tools to this directory '$TOOLS'"
	exit 1
fi
if [ ! -d factory-keys ]
then
	mkdir factory-keys
fi

# ubootdev
echo "making ubootdev key"
openssl genpkey -algorithm RSA -out factory-keys/ubootdev.key \
	-pkeyopt rsa_keygen_bits:2048 \
	-pkeyopt rsa_keygen_pubexp:65537
openssl req -batch -new -x509 -key factory-keys/ubootdev.key -out factory-keys/ubootdev.crt

# spldev
echo "making spldev key"
openssl genpkey -algorithm RSA -out factory-keys/spldev.key \
	-pkeyopt rsa_keygen_bits:2048 \
	-pkeyopt rsa_keygen_pubexp:65537
openssl req -batch -new -x509 -key factory-keys/spldev.key -out factory-keys/spldev.crt

# optee
echo "making optee key"
openssl genpkey -algorithm RSA -out factory-keys/opteedev.key \
	-pkeyopt rsa_keygen_bits:2048 \
	-pkeyopt rsa_keygen_pubexp:65537
openssl req -batch -new -x509 -key factory-keys/opteedev.key -out factory-keys/opteedev.crt

# kernel module
echo "making kernel module key"
GENKEY=factory-keys/x509.genkey
if [ ! -f $GENKEY ]
then
	if [ ! conf/keys/x509.genkey ]
	then
		cat > factory-keys/x509.genkey <<EOF
[ req ]
default_bits = 4096
distinguished_name = req_distinguished_name
prompt = no
string_mask = utf8only
x509_extensions = myexts

[ req_distinguished_name ]
#O = Unspecified company
CN = Factory kernel module signing key
#emailAddress = unspecified.user@unspecified.company

[ myexts ]
basicConstraints=critical,CA:FALSE
keyUsage=digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
EOF
	else
		cp conf/keys/x509.genkey $GENKEY
	fi
fi
openssl req -new -nodes -utf8 -sha256 -days 36500 -batch -x509 \
	-config $GENKEY -outform PEM \
	-out factory-keys/x509_modsign.crt \
	-keyout factory-keys/privkey_modsign.pem

echo "making tf-a key"
mkdir -p factory-keys/tf-a
openssl ecparam -name prime256v1 -genkey -out factory-keys/tf-a/privkey_ec_prime256v1.pem

echo "making uefi keys"
mkdir -p factory-keys/uefi
cd factory-keys/uefi
$TOOLS/security/uefi/gen_uefi_certs.sh
