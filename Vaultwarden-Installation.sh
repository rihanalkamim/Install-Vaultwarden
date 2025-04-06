#!/bin/bash

#Ubuntu Version

#Enviroments
dir=/Vaultwarden
dircert=/Vaultwarden/Cert

#Functions
read_default() {
  local default=$1
  local input

  read -r input
  echo "${input:-$default}"
}

read_password() {
  local password1
  local password2

  echo -n "Type one password to your private key: " >&2
  read -s password1
  echo >&2

  echo -n "Type again: " >&2
  read -s password2
  echo >&2

  if [[ $password1 == $password2 ]]; then 
    echo "Perfect, now we go issue your private key and CA" >&2
  else
    while [[ $password1 != $password2 ]]; do
      echo -n "Password not match, try again: " >&2
      echo >&2
      read -s password1

      echo -n "Type again: " >&2
      echo >&2
      read -s password2
    done
    echo "Perfect, now we go issue your private key and CA" >&2
  fi

  echo "$password1"
}

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
country=$(read_default "AU")
echo -n "State or Province (Ex: Georgia) [Default: "N/A"]: "
state=$(read_default "NA")
echo -n "City (Ex: Atlanta) [Default: "N/A"]: "
city=$(read_default "NA")
echo -n "Organization (Ex: Atlanta) [Default: "N/A"]: "
organization=$(read_default "NA")
echo -n "Organization Unit (Ex: DIT) [Default: "N/A"]: "
ou=$(read_default "NA")
#echo -n "Common Name (Ex: intern.domain) [Default: "N/A"]: "
#cn=$(read_default "NA")
echo -n "Email Address (Ex: email@example.com) [Default: "N/A"]: "
email=$(read_default "NA")

#Creating CA
vaultdomain=vault.$domain

#Generate Private Key of CA

#openssl genrsa -out private/l$domain.key 2048 --> Without password in private key
passw=$(read_password)
openssl genrsa -aes256 -passout pass:$passw -out private/$domain.key 4096 #With password in private key
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
