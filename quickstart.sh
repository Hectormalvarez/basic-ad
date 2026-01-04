#!/bin/bash
# quickstart.sh - The "Easy Button"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Basic AD Lab Setup ===${NC}"

# Check if we are in the right folder (the flat structure)
if [ ! -d "lab" ]; then
    echo "Error: 'lab' directory not found. Are you in the root of the repo?"
    exit 1
fi

# 1. Ask for Password
echo ""
echo -e "Enter a ${GREEN}Domain Admin Password${NC}."
echo "(Must contain Uppercase, Lowercase, Numbers, Special Char)"
echo -n "Password: "
read -s LAB_PASSWORD
echo ""

# 2. Write Config
echo -e "\nConfiguring secrets..."
cat <<EOF > lab/terraform.tfvars
admin_password = "$LAB_PASSWORD"
instance_type  = "t3.medium"
EOF

# 3. Deploy
echo -e "Initializing..."
cd lab
terraform init -input=false
terraform apply -auto-approve

echo -e "\n${GREEN}Deployment initiated!${NC}"
echo "Wait ~15 mins for AD promotion. Then run ./connect.sh"