#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR/lab/ansible" || exit
echo -e "\033[0;36m=== Starting Active Directory Provisioning ===\033[0m"
echo -n "Enter the Domain Admin Password: "
read -s LAB_PASSWORD
echo ""
ansible-playbook -i inventory.ini setup-ad.yml -e "ansible_password=$LAB_PASSWORD"