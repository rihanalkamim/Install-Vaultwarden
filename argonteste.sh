argon_token() {
  local passw="$1"
  local token

  token=$(echo -n "$passw" | argon2 somesalt -t 2 -m 16 -p 1 | grep Encoded | awk '{print $2}')
  echo "$token"
}

read_password(){
  local pass

  echo -n "Type your password: " >&2
  read -s pass

  echo "$pass"
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


