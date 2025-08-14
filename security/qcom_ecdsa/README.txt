This folder contains the ECDSA keys and certificates used by the SecTools V2
package for signing boot images when enabling Secure Boot support.

The command used for the certificates/keys genearion:

# Generate Root CA certificate/keys
$ openssl ecparam -genkey -name secp384r1 -outform PEM -out qpsa_rootca0.key
$ openssl req -new -key qpsa_rootca0.key -sha384 -out rootca_pem0.crt -subj '/C=US/CN=Generated OEM Root CA/OU=CDMA Technologies/OU=General Use OEM Key (OEM should update all fields)/L=San Diego/O=SecTools/ST=California' -config opensslroot.cfg -x509 -days 7300 -set_serial 1
$ openssl x509 -in rootca_pem0.crt -inform PEM -out qpsa_rootca0.cer -outform DER

# Generate Attestation CA certificate/keys
$ openssl ecparam -genkey -name secp384r1 -outform PEM -out qpsa_attestca0.key
$ openssl req -new -key qpsa_attestca0.key -out ca0.CSR -subj '/C=US/ST=California/CN=Generated OEM Attestation CA/O=SecTools/L=San Diego' -config opensslroot.cfg -sha384
$ openssl x509 -req -in ca0.CSR -CA rootca_pem0.crt -CAkey qpsa_rootca0.key -out ca_pem0.crt -set_serial 1 -days 7300 -extfile v3.ext -sha384 -CAcreateserial
$ openssl x509 -inform PEM -in ca_pem0.crt -outform DER -out qpsa_attestca0.cer

# Calculate hash of Root CA certificate
$ openssl dgst -sha384 qpsa_rootca0.cer > sha384_roots_hash.txt
