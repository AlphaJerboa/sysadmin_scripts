#!/bin/bash

MyKey=MyEncryptionKey

# Encryption of the programme to be executed
EncryptedText=$(cat <<'EOF' | openssl enc -aes-128-cbc -a -salt -e -pass pass:$MyKey
#!/bin/bash

# Write the bash script you like to encrypt

exit 0
EOF
)

# Store the encrypted program
echo $EncryptedText # > myprog.sh.enc

# Uncrypted program and execute it
echo $EncryptedText | openssl enc -aes-128-cbc -a -salt -d -pass pass:$MyKey | bash

# Clear variable
unset MyKey

