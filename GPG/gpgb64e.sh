#!/bin/bash

# Constants
GPG_PATH=$(which gpg)
SUCCESS_FORMAT="\033[42m"
IMPORTANT_FORMAT="\033[32m"
HIGHLIGHT_FORMAT="\033[33m"
RESET_FORMAT="\033[0m"

# Get the default GPG key ID
output=$($GPG_PATH --list-keys)
fingerprint=$(echo "$output" | grep -oE '[0-9A-F]{40}')
key_id=${fingerprint: -16}

echo -e "Using GPG Key ID: $key_id"

# Initialize an empty string to store the user's input
user_input=""

# Ask the user for input in a loop until two empty lines are entered
echo "Please enter your input (press Enter twice on empty lines to finish):"
empty_line_count=0
while [[ $empty_line_count -lt 2 ]]; do
    read -r line
    if [[ -z $line ]]; then
        empty_line_count=$((empty_line_count + 1))
        user_input+=$'\n'
    else
        empty_line_count=0
        user_input+="$line"$'\n'
    fi
done

# Trim trailing newlines
user_input=$(echo -n "$user_input")
echo "Encrypting value: $user_input"

# GPG Encrypt the input
encrypted_message=$($GPG_PATH --encrypt --sign --armor --batch -r "$key_id" --yes <<< "$user_input")
echo "Encrypted message: $encrypted_message"

# Encode the GPG-encrypted message in Base64
encoded_message=$(echo -n "$encrypted_message" | base64)

# Reverse the process to make sure everything worked
decoded_message=$(echo -n "$encoded_message" | base64 --decode)
decrypted_message=$($GPG_PATH --decrypt --batch --yes <<< "$decoded_message")

# Verify input and check hashes
input_hash=$(echo -n "$user_input" | sha256sum | awk '{print $1}')
decrypted_hash=$(echo -n "$decrypted_message" | sha256sum | awk '{print $1}')

echo -e "\n******************************\n"
echo -e "${HIGHLIGHT_FORMAT}Verify this matches your input:${RESET_FORMAT}"
echo -e "${HIGHLIGHT_FORMAT}${decrypted_message}${RESET_FORMAT}"
echo -e "\n******************************\n"

if [[ "$input_hash" == "$decrypted_hash" ]]; then
    echo -e "${SUCCESS_FORMAT}Hashes: MATCHED${RESET_FORMAT}"
else
    echo "Hashes: DID NOT MATCH!!!" >&2
    exit 1
fi

echo "Input: Length=${#user_input} | Hash=$input_hash"
echo "Check: Length=${#decrypted_message} | Hash=$decrypted_hash"
echo -e "\n******************************\n"
echo -e "Encoded Message: \n"
echo -e "${IMPORTANT_FORMAT}${encoded_message}${RESET_FORMAT}"
echo -e "\n******************************\n"
