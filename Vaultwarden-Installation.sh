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

  #Verify if passowrd is null
  if [[ -z "${password1// }" || -z "${password2// }" ]]; then
    while [[ -z "${password1// }" || -z "${password2// }" ]]; do
      echo -n "Password is null, try again: " >&2
      read -s password1
      echo >&2

      echo -n "Type again: " >&2
      read -s password2
      echo >&2
    done
  fi

  if [[ $password1 == $password2 ]]; then 
    echo "Match"
  else
    while [[ $password1 != $password2 ]]; do
      echo -n "Password not match, try again: " >&2
      read -s password1
      echo >&2

      echo -n "Type again: " >&2
      read -s password2
      echo >&2
    done
  fi

  echo "$password1"
}

argon_token() {
  local passw=$1
  local token

  token=$(echo -n "$passw" | argon2 somesalt -t 2 -m 16 -p 1 | grep Encoded | awk '{print $2}')
  echo "$token"
}

#Installation of dependencies
#apt update -y && apt upgrade -y --> Descomment 
	#Install Docker
#	apt install -y docker docker-compose --> Descomment 
	#Install OpenSSL and Nginx (Reverse Proxy) 
#	apt install -y openssl nginx argon2 --> Descomment
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

#Without password in private key
#openssl genrsa -out private/l$domain.key 2048

passw=$(read_password)
echo -e "--\nPerfect, now we go issue your private key and CA.\nWait a few seconds.\n" 
#With password in private key
openssl genrsa -aes256 -passout pass:"$passw" -out private/$domain.key 4096 
#Generate Root CA
openssl req -new -x509 -days 3650 -key private/$domain.key -passin pass:"$passw" -out $domain.pem -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$ou/CN=$domain"
#Editing openssl.cnf
sed -i -e "s|./demoCA|$dircert|g" openssl.cnf
sed -i -e "s|cacert.pem|$domain.pem|g" openssl.cnf
sed -i -e "s|cakey.pem|$domain.key|g" openssl.cnf
#Generate CA
openssl genrsa -out $vaultdomain.key 2048
openssl req -new -key $vaultdomain.key -passin pass:"$passw" -out $vaultdomain.csr -subj "/C=$country/ST=$state/L=$city/O=$organization/OU=$ou/CN=$domain"
openssl ca -config openssl.cnf -in $vaultdomain.csr -out $vaultdomain.pem -passin pass:"$passw"
#Create fullchain
cat $vaultdomain.pem >> fullchain.pem
cat $domain.pem >> fullchain.pem

#Install Vaultwarden
cd $dir

#Create Argon Token
token=$(argon_token "$passw")
echo $token

#Create compose.yaml
cat <<EOF > compose.yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: https://$vaultdomain
      ADMIN_TOKEN: '$token'
      #WEBSOCKET_ENABLED: true
    volumes:
      - ./vw-data/:/data/
    ports:
      - 8000:80
EOF

#Create nginx conf
cat <<EOF > /etc/nginx/conf.d/$vaultdomain.conf
# The "upstream" directives ensure that you have a http/1.1 connection
# This enables the keepalive option and better performance
#
# Define the server IP and ports here.
upstream $vaultdomain {
#  zone vaultwarden-default 64k;
  server 127.0.0.1:8000;
  keepalive 2;
}

# Needed to support websocket connections
# See: https://nginx.org/en/docs/http/websocket.html
# Instead of "close" as stated in the above link we send an empty value.
# Else all keepalive connections will not work.
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      "";
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $vaultdomain;

    return 301 https://\$host\$request_uri;
}

server {
    # For older versions of nginx appended http2 to the listen line after ssl and remove "http2 on"
    listen 443 ssl;
    listen [::]:443 ssl;
    #http2 on;
    server_name $vaultdomain;

    #access_log  /var/log/nginx/$vaultdomain.access.log main;
    #error_log   /var/log/nginx/$vaultdomain.error.log;

    # Specify SSL Config when needed
    ssl_trusted_certificate $dircert/fullchain.pem;
    ssl_certificate_key $dircert/$vaultdomain.key;
    ssl_certificate $dircert/fullchain.pem;
    add_header Strict-Transport-Security "max-age=31536000;";

    client_max_body_size 525M;

    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    location / {
      proxy_pass http://$vaultdomain/;
    }

    # Optionally add extra authentication besides the ADMIN_TOKEN
    # Remove the comments below `#` and create the htpasswd_file to have it active
    #
    #location /admin {
      # See: https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/
      #auth_basic "Private";
      #auth_basic_user_file /app/vault/htpasswd;
      #
      #proxy_pass http://$vaultdomain/;
    #}
}
EOF

#Removing variable interpolation in compose.yaml
sed -i -e '/ADMIN_TOKEN/ s|\$|$$|g' compose.yaml

#Start docker-compose
docker-compose up -d
nginx -t
nginx -s reload