#!/bin/bash
# quickstart.sh - The "Easy Button" for Deploy & Destroy

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------------------------------------
# 1. DESTROY MODE
#    Usage: ./quickstart.sh destroy
# ------------------------------------------------------------------
if [[ "$1" == "destroy" ]]; then
    echo -e "${RED}=== DESTROYING LAB ENVIRONMENT ===${NC}"
    
    # Check if we are in the right folder
    if [ ! -d "lab" ]; then
        echo "Error: 'lab' directory not found. Are you in the root of the repo?"
        exit 1
    fi

    echo "⚠️  This will delete all Lab resources (VPC, DC01, Client01)."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
    
    echo -e "\nDestroying..."
    cd lab
    terraform destroy -auto-approve
    echo -e "${GREEN}Cleanup Complete!${NC}"
    exit 0
fi

# ------------------------------------------------------------------
# 2. DEPLOY MODE
#    Usage: ./quickstart.sh [instance_type]
# ------------------------------------------------------------------
INSTANCE_TYPE=${1:-t3.micro}

echo -e "${CYAN}=== Basic AD Lab Setup ===${NC}"
echo -e "Target Instance Type: ${GREEN}$INSTANCE_TYPE${NC}"

# Add helpful tip if using the slow default
if [[ "$INSTANCE_TYPE" == "t3.micro" ]]; then
    echo -e "💡 Tip: You are using the Free Tier default. For better performance (~$0.04/hr), run:"
    echo -e "        ${CYAN}./quickstart.sh t3.small${NC}"
fi

# Check if we are in the right folder
if [ ! -d "lab" ]; then
    echo "Error: 'lab' directory not found. Are you in the root of the repo?"
    exit 1
fi

# ------------------------------------------------------------------
# 3. Auto-Install Terraform (If missing)
# ------------------------------------------------------------------
if ! command -v terraform &> /dev/null; then
    echo -e "\n${CYAN}Terraform not found. Installing...${NC}"
    curl -s -O https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip
    unzip -q terraform_1.9.5_linux_amd64.zip
    sudo mv terraform /usr/bin/
    rm terraform_1.9.5_linux_amd64.zip
    echo -e "${GREEN}Terraform installed successfully!${NC}"
fi

# 4. Ask for Password
echo ""
echo -e "Enter a ${GREEN}Domain Admin Password${NC}."
echo "(Must contain Uppercase, Lowercase, Numbers, Special Char)"
echo -n "Password: "
read -s LAB_PASSWORD
echo ""

# 5. Write Config
echo -e "\nConfiguring secrets..."
cat <<EOF > lab/terraform.tfvars
admin_password = "$LAB_PASSWORD"
instance_type  = "$INSTANCE_TYPE"
EOF

# 6. Deploy
echo -e "Initializing..."
cd lab
terraform init -input=false
terraform apply -auto-approve

echo -e "\n${GREEN}Deployment initiated!${NC}"
echo "Wait ~15 mins for AD promotion. Then run ./connect.sh"