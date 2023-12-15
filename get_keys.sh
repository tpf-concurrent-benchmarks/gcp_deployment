key_pem=$(terraform -chdir=terraform output key_pem)
key_pub=$(terraform -chdir=terraform output key_pub)

mv key.pem key.pem.old -f
mv key.pub key.pub.old -f

# remove <<EOT and EOT from the key
key_pem=$(echo "$key_pem" | sed '1d;$d')
key_pub=$(echo "$key_pub" | sed '1d;$d')

echo "$key_pem" > key.pem
echo "$key_pub" > key.pub

chmod 400 key.pem
chmod 400 key.pub