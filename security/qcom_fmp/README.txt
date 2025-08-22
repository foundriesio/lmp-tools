This folder contains Firmware Management Protocol (FMP) keys for the UEFI
Capsule Generation process [1].

Details about keys generation can be found at [2].
To generate keys the cmds below were used:

The demoCA directory should be initialized:
$ mkdir -p demoCA
$ mkdir -p demoCA/newcerts
$ touch demoCA/index.rst
$ echo 01 > demoCA/serial

Generate a Root Key/Certificate:
$ openssl genrsa -aes256 -out QcFMPRoot.key 2048
$ openssl req -new -x509 -days 3650 -key QcFMPRoot.key -out QcFMPRoot.crt
$ openssl x509 -in QcFMPRoot.crt -out QcFMPRoot.cer -outform DER
$ openssl x509 -inform DER -in QcFMPRoot.cer -outform PEM -out QcFMPRoot.pub.pem

Generate the Intermediate Key/Certificate:
$ openssl genrsa -aes256 -out QcFMPSub.key 2048
$ openssl req -new -days 3650 -key QcFMPSub.key -out QcFMPSub.csr
$ openssl ca -extensions v3_ca -in QcFMPSub.csr -days 3650 -out QcFMPSub.crt -cert QcFMPRoot.crt -keyfile QcFMPRoot.key
$ openssl x509 -in QcFMPSub.crt -out QcFMPSub.cer -outform DER
$ openssl x509 -inform DER -in QcFMPSub.cer -outform PEM -out QcFMPSub.pub.pem

Generate User Key Pair/Certificate for Data Signing:
$ openssl genrsa -aes256 -out QcFMPCert.key 2048
$ openssl req -new -days 3650 -key QcFMPCert.key -out QcFMPCert.csr
$ openssl ca -in QcFMPCert.csr -days 3650 -out QcFMPCert.crt -cert QcFMPSub.crt -keyfile QcFMPSub.key
$ openssl x509 -in QcFMPCert.crt -out QcFMPCert.cer -outform DER
$ openssl x509 -inform DER -in QcFMPCert.cer -outform PEM -out QcFMPCert.pub.pem

Convert the User Key and Certificate:
$ openssl pkcs12 -export -out QcFMPCert.pfx -inkey QcFMPCert.key -in QcFMPCert.crt
$ openssl pkcs12 -in QcFMPCert.pfx -nodes -out QcFMPCert.pem

[1] https://github.com/quic/cbsp-boot-utilities/tree/main/uefi_capsule_generation
[2] https://github.com/tianocore/tianocore.github.io/wiki/Capsule-Based-System-Firmware-Update-Generate-Keys
