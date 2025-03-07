#!/bin/bash

#Ubuntu Version

#Enviroments
dir=/Vaultwarden
dircert=/Vaultwarden/Cert

#Installation of dependencies
#apt update -y && apt upgrade -y --> Descomment 
	#Install Docker
#	apt install -y docker docker-compose --> Descomment 
	#Install OpenSSL and Nginx (Reverse Proxy) 
#	apt install -y openssl nginx --> Descomment
  mkdir -p $dircert/newcerts && cd $dircert && cp -r /etc/ssl/* ./
  touch index.txt
  echo "1000" > serial

#Input of domain
echo -n "Your domain (Ex: intern.domain) [*]: "
read -r domain
#Verify domain input
while [[ -z $domain || $domain == " " ]]; do
  echo -en "Your domain its necessary (Ex: alk.local):"
  read -r domain
done
echo "Perfect, let's go issue your certificate."

#Inputs of certificate
echo -n "Country Name (Ex: US) [Default: "AU"]: "
read -r country
echo -n "State or Province (Ex: Georgia) [Default: " "]: "
read -r state
echo -n "City (Ex: Atlanta) [Default: " "]: "
read -r city
echo -n "Organization (Ex: Atlanta) [Default: " "]: "
read -r organization
echo -n "Organization Unit (Ex: DIT) [Default: " "]: "
read -r ou
#echo -n "Common Name (Ex: intern.domain) [Default: " "]: "
#read -r cn
echo -n "Email Address (Ex: email@example.com) [Default: " "]: "
read -r email

#Validate if variables its different of " "
variables=(country, state, city, organization, ou, email)

#Creating CA
vaultdomain=vault.$domain

#Generate Private Key of CA
#openssl genrsa -out private/l$domain.key 2048 --> Without password in private key
echo -n "Type one password to your private key..."
openssl genrsa -aes256 -out private/$domain.key 4096
#Generate Root CA
openssl req -new -x509 -days 3650 -key private/$domain.key -out $domain.pem -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$ou/CN=$domain"
#Editing openssl.cnf
sed -i -e "s|./demoCA|$dircert|g" openssl.cnf
sed -i -e "s|cacert.pem|$domain.pem|g" openssl.cnf
sed -i -e "s|cakey.pem|$domain.key|g" openssl.cnf
#Generate CA
openssl genrsa -out $vaultdomain.key 2048
openssl req -new -key $vaultdomain.key -out $vaultdomain.csr -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$ou/CN=$domain"
openssl ca -config openssl.cnf -in $vaultdomain.csr -out $vaultdomain.pem

#Install Vaultwarden

cd $dir
printf \
"services:\t
   vaultwarden:\t
     image: vaultwarden/server:latest\t
     container_name: vaultwarden\t
     restart: unless-stopped\t
     environment:\t
       DOMAIN: $vaultdomain\t
     volumes:\t
       - ./vw-data/:/data/\t
     ports:\t
       - 80:80" \
> compose.yaml
