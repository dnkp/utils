#!/bin/bash

# title: csrgen.sh
# author: dnkp
# date: 20240403
# description: This script automates the generation of Certificate Signing Requests (CSRs) along with their corresponding private keys. The subject information for the CSRs is pre-defined.
# licence: MIT


# Initialize variables with default values
inventory_file="hosts.txt"

# Function to display usage/help message
display_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -i, --inventory <inventory_file>  Specify the file with domain names (default: hosts.txt)"
    echo "  -h, --help                            Display this help message"
    echo "This script reads a list of hostnames from the file (one hostname per line) and generates a CSR and a private key for each hostname."
    exit 0
}




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
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if provided inventory file exists
if [[ ! -f "$inventory_file" ]]; then
    echo "Inventory file '$inventory_file' does not exist in the directory."
    exit 1
fi

# Create array from the provided names
while read -r host; do
    hosts_array+=("$host")
done < $inventory_file 


# Iterate trough the list of hostnames and generate csr and private key 
for namehost in "${hosts_array[@]}"
do

    openssl req -new -newkey rsa:2048 -nodes -keyout ${namehost%%.*}.key -out ${namehost%%.*}.csr -subj "/C=SXX/ST=XXX/L=XXXXX/O=XXXXXX/OU=XX/CN=${namehost%%.*}" -addext "subjectAltName = DNS:$namehost" -addext "keyUsage = digitalSignature, dataEncipherment" -addext "extendedKeyUsage = serverAuth, clientAuth" 2>/dev/null

    echo "Generated for ${namehost%%.*}."

done

exit 0
