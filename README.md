# Basic AD: Automated Active Directory on AWS

[![Terraform](https://img.shields.io/badge/Terraform-v1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-SSM%20Enabled-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Automated Windows Active Directory lab environment on AWS with zero manual configuration**

This project automates the deployment of a fully functional Windows Active Directory (AD) environment on AWS using Terraform and PowerShell. It provisions a custom VPC, a Domain Controller (DC), and a Member Server (Client) with zero manual intervention.

⚠️ **Estimated Cost:** ~$0.50-1.00/hour (~$12-24/day) when running t3.medium instances

The lab demonstrates **Infrastructure as Code (IaC)** principles and **Zero Trust** security by using AWS Systems Manager (SSM) instead of open RDP ports.

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Phase 0: Identity Bootstrap](#2-phase-0-identity-bootstrap-run-once)
  - [Phase 1: Deploy Infrastructure](#3-phase-1-deploy-infrastructure)
  - [Access the Lab](#4-access-the-lab)
- [Technical Details](#-technical-details)
- [Clean Up](#-clean-up)

## 🏗 Architecture

The environment creates an isolated network topology:

| Component | Details |
|-----------|---------|
| **VPC** | `10.10.0.0/16` (Custom non-default VPC) |
| **Domain Controller (DC01)** | `10.10.1.10` (Windows Server 2022 Core) |
| **Member Server (Client01)** | `10.10.2.20` (Windows Server 2022 Core) |
| **Domain** | `corp.cloudlab.internal` |
| **Security** | "Dark Node" configuration (No inbound internet access) |

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed and configured:

- [ ] **Terraform** (v1.0 or higher) - [Download](https://www.terraform.io/downloads)
- [ ] **AWS CLI** - Configured with `aws configure` - [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [ ] **AWS Session Manager Plugin** - [Install Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [ ] **AWS Account** with appropriate permissions (see Phase 0)

### 1. Clone the Repository

```bash
git clone https://github.com/Hectormalvarez/basic-ad.git
cd basic-ad
```

### 2. Phase 0: Identity Bootstrap (Run Once)

*Security Best Practice:* Instead of running as Root/Admin, we first create a restricted "Lab Operator" persona.

#### ⚠️ Pre-requisite for Non-Root Users

If you are running this as a restricted user (e.g., `terraform-user`), you must temporarily grant your user the right to create IAM policies.

**Steps:**

1. Log into the AWS Console as Admin/Root
2. Add a temporary **Inline Policy** to your user with this JSON:

<details>
<summary>Click to view JSON Policy</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": [
            "iam:CreateGroup", "iam:GetGroup", "iam:DeleteGroup", "iam:UpdateGroup",
            "iam:CreatePolicy", "iam:GetPolicy", "iam:GetPolicyVersion",
            "iam:DeletePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
            "iam:AttachGroupPolicy", "iam:DetachGroupPolicy", "iam:List*"
        ],
        "Resource": "*"
    }]
}
```

</details>

#### Deployment

1. Initialize the identity module:

```bash
cd environments/00-bootstrap-iam
terraform init && terraform apply
```

2. Add your user to the new secure group:

```bash
# Replace <YOUR_USER> with your actual AWS IAM username
aws iam add-user-to-group --user-name <YOUR_USER> --group-name terraform-group
```

3. **Clean Up:** Delete the temporary Inline Policy you created in the pre-requisite step.

### 3. Phase 1: Deploy Infrastructure

Navigate to the main lab environment:

```bash
cd ../aws-phase1
```

Create a `terraform.tfvars` file to configure your secrets:

⚠️ **Password Warning:** Windows Server enforces strict complexity (Uppercase, Lowercase, Numbers).

```hcl
# environments/aws-phase1/terraform.tfvars

# The master password for the lab (Must be Complex!)
admin_password = "CloudL@b2026!"

# Optional: Change the instance size
instance_type = "t3.medium"
```

Initialize and deploy:

```bash
terraform init
terraform apply
```

#### Deployment Timeline

The deployment takes approximately **15-20 minutes**:

- **Step 1 (2 min):** Infrastructure provisioning
- **Step 2 (10-15 min):** Windows bootstrapping (DC Promotion & Reboot)

### 4. Access the Lab

This lab uses **AWS Systems Manager** for secure access. You do not need RDP or a Public IP.

Run the commands output by Terraform to verify connectivity:

**Connect to Domain Controller:**

```bash
# Copy the command from Terraform output 'ssm_dc_command'
aws ssm start-session --target i-0123456789abcdef0
```

**Connect to Client:**

```bash
# Copy the command from Terraform output 'ssm_client_command'
aws ssm start-session --target i-09876543210abcdef
```

Once inside the PowerShell session:

- **Check Domain Status:** `Get-ADDomain`
- **Check DNS:** `Get-DnsServerResourceRecord -ZoneName "corp.cloudlab.internal"`

---

## 🔧 Technical Details

### Zero Trust Access & Least Privilege

- **RBAC Identity:** The `00-bootstrap-iam` module creates a custom IAM Group (`terraform-group`) with restricted permissions, ensuring the lab operator cannot accidentally modify billing or root settings.
- **No Open Ports:** Security Groups allow NO inbound traffic from the internet.
- **IAM Auth:** Access is controlled via AWS Identity and Access Management (IAM), not network firewalls.
- **DNS Handling:** Custom bootstrapping scripts inject DNS Forwarders to ensure the DC can communicate with AWS APIs even after promoting to a Domain Controller.

## 🧹 Clean Up

To destroy the lab infrastructure:

```bash
# From environments/aws-phase1/
terraform destroy
```