#!/bin/bash
# provision.sh - Wrapper script to execute the Ansible playbook from the Linux Controller

# Ensure we are running from the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR/lab/ansible" || exit

echo -e "\033[0;36m=== Starting Active Directory Provisioning ===\033[0m"

# Ask for the password so it doesn't have to be hardcoded in the inventory
echo -n "Enter the Domain Admin Password you set during quickstart: "
read -s LAB_PASSWORD
echo ""

echo -e "\nRunning Ansible Playbook..."
ansible-playbook -i inventory.ini setup-ad.yml -e "ansible_password=$LAB_PASSWORD"

echo -e "\n\033[0;32mProvisioning Complete!\033[0m"