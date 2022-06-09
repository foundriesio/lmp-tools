#!/bin/sh
#
# Simple script that generates a set of keys and certificates for UEFI secure boot

set -e

CN="Custom"

# Check required tools
which openssl > /dev/null || { echo "E: You must have openssl" && exit 1; }
which cert-to-efi-sig-list > /dev/null || { echo "E: You must have cert-to-efi-sig-list (efitools)" && exit 1; }
which sign-efi-sig-list > /dev/null || { echo "E: You must have sign-efi-sig-list (efitools)" && exit 1; }
which uuidgen > /dev/null || { echo "E: You must have uuidgen" && exit 1; }

# Create PK
openssl req -x509 -sha256 -newkey rsa:2048 -subj "/CN=${CN} PK/" -keyout PK.key -out PK.crt -nodes -days 3650
# Create KEK
openssl req -x509 -sha256 -newkey rsa:2048 -subj "/CN=${CN} KEK/" -keyout KEK.key -out KEK.crt -nodes -days 3650
# Create DB
openssl req -x509 -sha256 -newkey rsa:2048 -subj "/CN=${CN} DB/" -keyout DB.key -out DB.crt -nodes -days 3650
# Create DBX
openssl req -x509 -sha256 -newkey rsa:2048 -subj "/CN=${CN} DBX/" -keyout DBX.key -out DBX.crt -nodes -days 3650

# No CSR is performed here, but can be done by the user (for KEK and DBs) if a valid CA is available

# Convert PEM certificates into DER format (most UEFI implementations require DER format)
openssl x509 -outform der -in PK.crt -out PK.cer
openssl x509 -outform der -in KEK.crt -out KEK.cer
openssl x509 -outform der -in DB.crt -out DB.cer
openssl x509 -outform der -in DBX.crt -out DBX.cer

# Convert certificates to ESL so they can be imported by EFI
cert-to-efi-sig-list -g "$(uuidgen)" PK.crt PK.esl
cert-to-efi-sig-list -g "$(uuidgen)" KEK.crt KEK.esl
cert-to-efi-sig-list -g "$(uuidgen)" DB.crt DB.esl
cert-to-efi-sig-list -g "$(uuidgen)" DBX.crt DBX.esl

# Generate AUTH files (some tools require signed ESL files even when secure boot is not enforced)
sign-efi-sig-list -c PK.crt -k PK.key PK PK.esl PK.auth
sign-efi-sig-list -c PK.crt -k PK.key KEK KEK.esl KEK.auth
sign-efi-sig-list -c KEK.crt -k KEK.key DB DB.esl DB.auth
sign-efi-sig-list -c KEK.crt -k KEK.key DBX DBX.esl DBX.auth
cp PK.esl PKnoauth.auth

echo "Keys and certificates created successfully"
echo "To sign an EFI image (bootloader/kernel): sbsign --key DB.key --cert DB.crt Image"
