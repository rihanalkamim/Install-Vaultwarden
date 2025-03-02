#!/bin/bash

#Ubuntu Version

#Installation of dependencies
apt update -y && apt upgrade -y
	#Install Docker
	apt install -y docker docker-compose
	#Install OpenSSL and Nginx (Reverse Proxy)
	apt install -y openssl nginx

#Inputs
echo -n "Your domain (Ex: intern.domain): "
read -r domain

#Enviroments

#Install Vaultwarden
mkdir -p /Vaultwarden && cd /Vaultwarden

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
