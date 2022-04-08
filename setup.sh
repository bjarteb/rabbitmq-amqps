#!/bin/bash
set -euo pipefail

# directory layout
mkdir data log clients certs || true

# create environment file for RabbitMQ clients
cat > ./clients/python/env.sh <<EOF
export RABBITMQ_ENDPOINT="\$(hostname)"
export RABBITMQ_USERNAME=guest
export RABBITMQ_PASSWORD=guest
export RABBITMQ_VHOST=rs
EOF


# prepare certificate generation
mkdir ./certs/testca
cd ./certs/testca
mkdir certs private
chmod 700 private
echo 01 > serial
touch index.txt

# create ssl config file
cat > openssl.cnf <<EOF
[ ca ]
default_ca = testca

[ testca ]
dir = .
certificate = \$dir/ca_certificate.pem
database = \$dir/index.txt
new_certs_dir = \$dir/certs
private_key = \$dir/private/ca_private_key.pem
serial = \$dir/serial

default_crl_days = 7
default_days = 365
default_md = sha256

policy = testca_policy
x509_extensions = certificate_extensions

[ testca_policy ]
commonName = supplied
stateOrProvinceName = optional
countryName = optional
emailAddress = optional
organizationName = optional
organizationalUnitName = optional
domainComponent = optional

[ certificate_extensions ]
basicConstraints = CA:false

[ req ]
default_bits = 2048
default_keyfile = ./private/ca_private_key.pem
default_md = sha256
prompt = yes
distinguished_name = root_ca_distinguished_name
x509_extensions = root_ca_extensions

[ root_ca_distinguished_name ]
commonName = hostname

[ root_ca_extensions ]
basicConstraints = CA:true
keyUsage = keyCertSign, cRLSign

[ client_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.2

[ server_ca_extensions ]
basicConstraints = CA:false
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = 1.3.6.1.5.5.7.3.1
EOF


# generate CA
openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 365 \
    -out ca_certificate.pem -outform PEM -subj /CN=MyTestCA/ -nodes
# CA cert DER format
openssl x509 -in ca_certificate.pem -out ca_certificate.cer -outform DER

################################################################################
# create server certificate
################################################################################
cd ../..
ls
mkdir -p ./certs/server
cd ./certs/server
openssl genrsa -out private_key.pem 2048
openssl req -new -key private_key.pem -out req.pem -outform PEM \
    -subj /CN=$(hostname)/O=server/ -nodes
cd ../testca
openssl ca -config openssl.cnf -in ../server/req.pem -out \
    ../server/server_certificate.pem -notext -batch -extensions server_ca_extensions
cd ../server
openssl pkcs12 -export -out server_certificate.p12 -in server_certificate.pem -inkey private_key.pem \
    -passout pass:MySecretPassword

################################################################################
# create client certificate
################################################################################
cd ../..
ls
mkdir ./certs/client
cd ./certs/client
openssl genrsa -out private_key.pem 2048
openssl req -new -key private_key.pem -out req.pem -outform PEM \
    -subj /CN=localhost/O=client/ -nodes
cd ../testca
openssl ca -config openssl.cnf -in ../client/req.pem -out \
    ../client/client_certificate.pem -notext -batch -extensions client_ca_extensions
cd ../client
openssl pkcs12 -export -out client_certificate.p12 -in client_certificate.pem -inkey private_key.pem \
    -passout pass:MySecretPassword


################################################################################
# import server certifcate to keystore for java
################################################################################
cd ..

keytool \
  -import \
  -noprompt \
  -storepass changeit \
  -alias server1 \
  -file server/server_certificate.pem \
  -keystore ./my-truststore.jks
