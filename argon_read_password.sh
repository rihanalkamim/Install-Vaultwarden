argon_token() {
  local passw="$1"
  local token

  token=$(echo -n "$passw" | argon2 somesalt -t 2 -m 16 -p 1 | grep Encoded | awk '{print $2}')
  echo "$token"
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

#  #Verify if password is null
#  if [[ -z "${password1// }" || -z "${password2// }" ]]; then
#    while [[ -z "${password1// }" || -z "${password2// }" ]]; do
#      echo -n "Password is null, try again: " >&2
#      read -s password1
#      echo >&2
#
#      echo -n "Type again: " >&2
#      read -s password2
#      echo >&2
#    done
#  fi

  if [[ $password1 == $password2 ]]; then 
    echo "Match" >&2
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

  echo -n "$password2"
}

password=$(read_password)
echo "Senha atual: $password"
password_token=$(argon_token "$password")
echo "Senha com token: $password_token"

echo -n "Comparação com o token acima: "
printf "%s" "$password" | argon2 somesalt -t 2 -m 16 -p 1 | grep Encoded | awk '{print $2}'

echo -n "Sem interpolação no YAML: "
password_interpolation=$(echo "$password_token" | sed -e 's|\$|$$|g')
echo $password_interpolation


