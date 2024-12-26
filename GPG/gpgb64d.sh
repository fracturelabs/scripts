#!/bin/bash

# Constants
GPG_PATH=$(which gpg)
IMPORTANT_FORMAT="\033[32m"
RESET_FORMAT="\033[0m"

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

# Decode the Base64-encoded input
decoded_message=$(echo -n "$user_input" | base64 --decode 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo -e "${IMPORTANT_FORMAT}Error: Invalid Base64 input${RESET_FORMAT}"
    exit 1
fi

echo -e "\n******************************\n"
echo -e "${IMPORTANT_FORMAT}${decoded_message}${RESET_FORMAT}"
echo -e "\n******************************\n"

# Decrypt the message using GPG
decrypted_message=$($GPG_PATH --decrypt --batch --yes <<< "$decoded_message" 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo -e "${IMPORTANT_FORMAT}Error: GPG decryption failed${RESET_FORMAT}"
    exit 1
fi

echo -e "\n******************************\n"
echo -e "${IMPORTANT_FORMAT}${decrypted_message}${RESET_FORMAT}"
echo -e "\n******************************\n"
