#!/bin/bash
# quickstart.sh - The "Easy Button" (Free Tier Edition)

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Basic AD Lab Setup ===${NC}"

# Check if we are in the right folder
if [ ! -d "lab" ]; then
    echo "Error: 'lab' directory not found. Are you in the root of the repo?"
    exit 1
fi

# ------------------------------------------------------------------
# 0. Auto-Install Terraform (If missing in CloudShell)
# ------------------------------------------------------------------
if ! command -v terraform &> /dev/null; then
    echo -e "${CYAN}Terraform not found. Installing...${NC}"
    curl -s -O https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip
    unzip -q terraform_1.9.5_linux_amd64.zip
    sudo mv terraform /usr/bin/
    rm terraform_1.9.5_linux_amd64.zip
    echo -e "${GREEN}Terraform installed successfully!${NC}"
fi

# 1. Ask for Password
echo ""
echo -e "Enter a ${GREEN}Domain Admin Password${NC}."
echo "(Must contain Uppercase, Lowercase, Numbers, Special Char)"
echo -n "Password: "
read -s LAB_PASSWORD
echo ""

# 2. Write Config (FIXED: Uses t3.micro for Free Tier)
echo -e "\nConfiguring secrets..."
cat <<EOF > lab/terraform.tfvars
admin_password = "$LAB_PASSWORD"
instance_type  = "t3.micro"
EOF

# 3. Deploy
echo -e "Initializing..."
cd lab
terraform init -input=false
terraform apply -auto-approve

echo -e "\n${GREEN}Deployment initiated!${NC}"
echo "Wait ~15 mins for AD promotion. Then run ./connect.sh"