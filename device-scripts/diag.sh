#!/bin/sh
#
# Copyright (C) 2023 Foundries.io
#
# SPDX-License-Identifier: Apache-2.0
#
# Suggested setting with vim:
# set ai ts=4 sw=4 et
#
# Authors:
#    Tim Anderson <tim.anderson@foundries.io>
#    Vanessa Maegima <vanessa.maegima@foundries.io>
#    Caio Pereira <caio.pereira@foundries.io>

VERSION=1.0

SPEED=0
while [ ${#} -gt 0 ]; do
    case ${1} in
    -s|--speedtest)
        SPEED=1
        shift
        ;;
    -*)
        echo "Invalid option '${1}'"
        exit 1
        ;;
    *)
        echo "Invalid argument '${1}'"
        exit 1
        ;;
    esac
done

echo "*** diag tool version ***"
echo "Version: $VERSION"
echo

echo "*** os-release ***"
cat /etc/os-release
echo

if [ -f /var/sota/current-target ]; then
      echo "*** current_target ***"
      cat /var/sota/current-target
fi
echo

echo "*** active networks ***"
ip -family inet addr
echo

echo "*** Name servers ***"
ls -l /etc/resolv.conf
grep "^nameserver" /etc/resolv.conf
echo

echo "*** iptable configuration ***"
    iptables -L -v
echo

echo "*** /var/sota content ***"
CONTENT=$(ls -l /var/sota 2> /dev/null)
echo "$CONTENT"
echo

bad=0
if [ -f /var/sota/sota.toml ]; then
    CFG=/var/sota/sota.toml
    SERV=$(grep -m 1 "^server" $CFG | \
        sed 's|^.*= "https://\(.*\)"|\1|')
    PIN=$(grep "^pass" $CFG | sed 's/^.*= "//;s/"$//')
    MODULE=$(grep "^module" $CFG | sed 's/^.*= "//;s/"$//')
    ROOT_CERT_DIR=$(grep "^tls_cacert_path" $CFG | sed 's/^.*= "//;s/"$//')
    if grep -q 'pkey_source = "file"' /var/sota/sota.toml; then
        for FILE in client.pem root.crt pkey.pem; do
            if [ ! -f /var/sota/${FILE} ]; then
                echo "### missing /var/sota/$FILE ###"
                bad=1
            fi
        done
        if [ $bad -eq 0 ]; then
            echo "*** checking certs ***"
            openssl s_client -cert /var/sota/client.pem \
                -CAfile $ROOT_CERT_DIR \
                -key /var/sota/pkey.pem \
                -connect $SERV < /dev/null || echo "### Failed ###"
        else
            echo "*** no cert checking connectivity ***"
            openssl s_client -connect $SERV < /dev/null || echo "### Failed ###"
        fi
    elif which pkcs11-tool > /dev/null; then
        CLIENT_ID=$(grep "^tls_clientcert_id" $CFG | sed 's/^.*= "//;s/"$//')
        PKEY_ID=$(grep "^tls_pkey_id" $CFG | sed 's/^.*= "//;s/"$//')
        if [ "$ROOT_CERT_DIR" = "/var/sota/root.crt" ]
        then
            echo "*** checking HSM certs ***"
        else
            echo "*** checking HSM+EL2GO certs ***"
        fi
        cat > /tmp/engine.cnf <<EOF
openssl_conf = oc
[oc]
engines = eng
[eng]
pkcs11 = p11
[p11]
engine_id = pkcs11
dynamic_path = /usr/lib/engines-3/pkcs11.so
MODULE_PATH = $MODULE
init = 0
PIN = $PIN
EOF
        pkcs11-tool --module $MODULE --login \
            --pin $PIN --token-label aktualizr --id $CLIENT_ID \
            --read-object --type cert | \
            openssl x509 -inform DER -outform PEM > /tmp/client.pem
        OPENSSL_CONF=/tmp/engine.cnf openssl s_client \
            -engine pkcs11 \
            -keyform engine \
            -key "pkcs11:token=aktualizr;id=%$PKEY_ID;type=private;pin-value=$PIN" \
            -cert /tmp/client.pem -CAfile $ROOT_CERT_DIR \
            -connect $SERV < /dev/null
        rm -f /tmp/client.pem /tmp/engine.cnf
    fi
else
    echo "*** not registered import version ***"
    cat /var/sota/import/installed_versions
fi
echo

echo "*** Aktualizr-lite status ***"
systemctl status aktualizr-lite | cat
echo

echo "*** Docker images ***"
docker images
echo

echo "*** Docker containers ***"
docker ps -sa
echo

echo "*** Docker usage ***"
du -d 1 /var/lib/docker/
echo

echo "*** Number of zero length files in /var/lib/docker ***"
find /var/lib/docker -size 0 | wc -l
echo

echo "*** sha256sum of /var/sota/reset-apps ***"
sha256sum $(find /var/sota/reset-apps -type f) < /dev/null
echo

echo "*** Domain access check ***"
res=0
for domain in hub.foundries.io ota-lite.foundries.io ostree.foundries.io; do
    nslookup "$domain"
    res=$(($res + $?))
done
echo

if [ $res -eq 0 ]; then
    echo "*** domain latency ***"
    for target in hub.foundries.io ota-lite.foundries.io ostree.foundries.io; do
        echo "$target latency $(ping -c 5 "$target" | sed -nE 's|rtt min/avg/max/mdev = [0-9]+.[0-9]+/||;s|/.*$| ms|p')"
    done
else
    echo "*** domain access error no latency ***"
fi
echo

if [ ${SPEED} -eq 1 ]; then
    echo "*** speed test ***"
    server_host="http://speedtest.ftp.otenet.gr/files/test10Mb.db"
    result=$(/usr/bin/time -p wget -O /dev/null -o /dev/stdout $server_host 2>&1)
    if [ $? -eq 0 ]; then
        dem=$(echo "$result" | sed -n 's/real //p')
        i=$(echo "10485760 / $dem" | bc)
        d="" s=0 S=" KMGTPEYZ"
        while [ $i -gt 1024 ]; do
            d=$(printf ".%02d" $((i % 1024 * 100 / 1024)))
            i=$((i / 1024))
            s=$((s + 1))
        done
	r=$(echo $S | awk "{print substr(\$0,$s,1)}")
        echo "Download Speed: $i$d ${r}B/s"
    else
        echo "### Failed with $? ###"
    fi
fi
