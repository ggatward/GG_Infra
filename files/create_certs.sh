#!/bin/bash
#
# Generate IPA Client Certs and PKCS12 bundle for MQTT clients

USER=$1
USERDIR=/root/certs/${USER}

read -p "Enter password for bundle: " PASS

ipa user-add ${USER} --first=${USER} --last=${USER}

mkdir -p ${USERDIR}
cat << EOF > ${USERDIR}/${USER}.inf
[ req ]
prompt = no
encrypt_key = no
distinguished_name = dn
req_extensions = exts

[ dn ]
commonName = "${USER}"

[ exts ]
subjectAltName=email:${USER}@ipa.home.gatwards.org
EOF

openssl genrsa -out ${USERDIR}/${USER}.key 2048
openssl req -new -key ${USERDIR}/${USER}.key -out ${USERDIR}/${USER}.csr -config ${USERDIR}/${USER}.inf

ipa cert-request ${USERDIR}/${USER}.csr --principal ${USER}

ipa cert-show $(ipa cert-find --users=${USER} | grep 'Serial number:' | awk '{ print $3 }') --out ${USERDIR}/${USER}.pem

openssl pkcs12 -export -in ${USERDIR}/${USER}.pem -inkey ${USERDIR}/${USER}.key -name "${USER} Cert" -out ${USERDIR}/${USER}.p12 -password pass:${PASS}
