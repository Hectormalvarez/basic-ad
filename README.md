# Basic AD: Automated Active Directory on AWS

This project automates the deployment of a fully functional Windows Active Directory (AD) environment on AWS using Terraform and PowerShell. It provisions a custom VPC, a Domain Controller (DC), and a Member Server (Client) with zero manual intervention.

The lab is designed to demonstrate **Infrastructure as Code (IaC)** principles, specifically solving the "bootstrapping race condition" in Windows AD promotions using a dedicated `CloudAdmin` identity strategy.

## 🏗 Architecture

The environment creates an isolated network topology:

* **VPC:** `10.10.0.0/16` (Custom non-default VPC)
* **Domain Controller (DC01):** `10.10.1.10` (Windows Server 2022 Core)
* **Member Server (Client01):** `10.10.2.20` (Windows Server 2022 Core)
* **Domain:** `corp.cloudlab.internal`
* **Security:** Strict Security Groups locked to your specific public IP.

## 🚀 Getting Started

### Prerequisites

* **Terraform** (v1.0+)
* **AWS CLI** (configured with credentials)
* **Git**

### 1. Clone the Repository

```bash
git clone https://github.com/Hectormalvarez/basic-ad.git
cd basic-ad/environments/aws-phase1

```

### 2. Configure Variables

Create a `terraform.tfvars` file in the `aws-phase1` directory to set your secrets.

**⚠️ Password Warning:** Windows Server enforces strict complexity requirements. Your password must contain Uppercase, Lowercase, and Numbers (e.g., `CloudL@b2025!`). If the password is too simple, the bootstrap scripts will fail silently.

```hcl
# terraform.tfvars

# Your Public IP for RDP access (visit ifconfig.me to find it)
my_ip = "123.45.67.89/32"

# The master password for the lab (Must be Complex!)
admin_password = "YourComplexPassword123!"

# Optional: Change the instance size (Default: t3.small)
instance_type = "t3.medium"

```

### 3. Deploy

Initialize Terraform and apply the configuration.

```bash
terraform init
terraform apply

```

The deployment takes approximately **15-20 minutes**.

* **Phase 1 (2 min):** Infrastructure provisioning (VPC, EC2s).
* **Phase 2 (10-15 min):** Windows bootstrapping. The Client will enter a wait loop until the DC finishes promoting and reboots.

### 4. Access the Lab

Once Terraform completes, it will output the Public IPs:

```text
Outputs:

client_public_ip = "54.123.45.67"
dc_public_ip     = "3.98.76.54"

```

Connect via RDP using the **CloudAdmin** credentials (this user is created to bypass AWS password randomization):

* **Username:** `CloudAdmin` (or `CORP\CloudAdmin`)
* **Password:** *(The value you set in `admin_password`)*

---

## 🔧 Technical Details

### The "CloudAdmin" Strategy

A common issue in automating Active Directory on AWS is that the EC2Launch agent randomizes the built-in `Administrator` password upon the post-promotion reboot. This breaks downstream automation (like client domain joins) that relies on the initial password.

**Solution:**

1. **UserData Injection:** We create a dedicated user `CloudAdmin` during the initial boot.
2. **Persistence:** Since the AWS agent only manages the built-in `Administrator` account, `CloudAdmin` retains its password through the promotion reboot.
3. **Elevation:** When the server becomes a Domain Controller, all local Administrators (including `CloudAdmin`) automatically become **Domain Admins**.
4. **Convergence:** The Client script is configured to authenticate against the domain using `CloudAdmin@corp.cloudlab.internal`.

### Directory Structure

```text
.
├── environments/
│   └── aws-phase1/          # Main Terraform configuration
│       ├── compute.tf       # EC2 instances & UserData templating
│       ├── network.tf       # VPC, Subnets, DHCP Options
│       ├── security.tf      # Security Groups
│       └── templates/       # PowerShell injection templates
└── modules/
    └── identity-core/
        └── scripts/         # Reusable PowerShell logic
            ├── bootstrap-dc.ps1      # Rename, IP, & Promote logic
            └── bootstrap-client.ps1  # DNS set, Wait Loop, & Join logic

```

## 🧹 Clean Up

To destroy all resources and stop incurring costs:

```bash
terraform destroy

```