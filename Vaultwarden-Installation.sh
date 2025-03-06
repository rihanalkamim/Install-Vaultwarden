#!/bin/bash

#Ubuntu Version

#Enviroments
dir=/Vaultwarden
dircert=/Vaultwarden/Cert

#Installation of dependencies
apt update -y && apt upgrade -y
	#Install Docker
	apt install -y docker docker-compose
	#Install OpenSSL and Nginx (Reverse Proxy)
	apt install -y openssl nginx
  mkdir -p $dircert && cd $dircert && cp -r /etc/ssl/* ./
  touch index.txt
  echo "1000" > serial

#Inputs
echo -n "Your domain (Ex: intern.domain) [*]: "
read -r domain
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


#Creating CA

#Generate Private Key of CA
#openssl genrsa -out $domain.key 2048 --> Without password in private key
echo -n "Type one password to your private key"
openssl genrsa -aes256 -out $domain.key 4096
#Generate Root CA
openssl req -new -x509 -days 3650 -key $domain.key -out $domain.csr -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$ou/CN=$domain"

#Install Vaultwarden

cd $dir
printf \
"services:\t
   vaultwarden:\t
     image: vaultwarden/server:latest\t
     container_name: vaultwarden\t
     restart: unless-stopped\t
     environment:\t
       DOMAIN: $domain\t
     volumes:\t
       - ./vw-data/:/data/\t
     ports:\t
       - 80:80" \
> compose.yaml
