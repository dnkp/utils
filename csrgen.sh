#!/bin/bash

# title: csrgen.sh
# author: dnkp
# date: 20240430
# description: This script automates the generation of Certificate Signing Requests (CSRs) along with their corresponding private keys.
# Generated key is rsa:2048, CSR includes SAN fields
# The subject information for the CSRs is pre-defined.
# licence: MIT

# Initialize variables with default values
inventory_file="hosts.txt"
hostname=""

# Define variables for subject parameters
country="SX"
state="XX"
locality="XXXXX"
organization="XXXXXX"
organizational_unit="XX"

# Function to display usage/help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --inventory <inventory_file>  Specify the file with domain names (default: hosts.txt)"
    echo "  -h, --help                        Display this help message"
    echo "  --hostname <hostname>             Specify the hostname for which CSR and private key will be generated"
    echo "This script generates a CSR and a private key for the specified hostname."
    exit 0
}

# Check if OpenSSL is installed
if ! command -v openssl &>/dev/null; then
    echo "Error: OpenSSL is not installed. Please install it before running this script."
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--inventory)
            shift
            inventory_file="$1"
            ;;
        -h|--help)
            display_help
            ;;
        --hostname)
            shift
            hostname="$1"
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if hostname is provided
if [[ -z "$hostname" ]]; then
    # Check if provided inventory file exists
    if [[ ! -f "$inventory_file" ]]; then
        echo "Inventory file '$inventory_file' does not exist in the directory."
        display_help
        exit 1
    fi

    # Create array from the provided names
    hosts_array=()
    while read -r host; do
        hosts_array+=("$host")
    done < "$inventory_file"

    # Iterate through the list of hostnames and generate CSR and private key
    for namehost in "${hosts_array[@]}"; do
        generate_csr_and_key "$namehost"
    done
else
    generate_csr_and_key "$hostname"
fi

exit 0

# Function to generate CSR and Private Key
generate_csr_and_key() {
    local namehost="$1"

    # Cover the case when provided hostname is longer than 64 characters
    local cn_namehost="$namehost"
    if [[ ${#namehost} -gt 64 ]]; then
        echo "Hostname '$namehost' is longer than maximum allowed 64 characters. Hostname stripped to '${namehost%%.*}'."
        cn_namehost="${namehost%%.*}"
    fi

    openssl req -new -newkey rsa:2048 -nodes -keyout "${namehost%%.*}.key" -out "${namehost%%.*}.csr" -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizational_unit/CN=${cn_namehost}" -addext "subjectAltName = DNS:$namehost" -addext "keyUsage = digitalSignature, dataEncipherment" -addext "extendedKeyUsage = serverAuth, clientAuth" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "Generated CSR and private key for ${cn_namehost}."
    else
        echo "Failed to generate CSR and private key for ${cn_namehost}."
    fi
}
