# Basic AD: Automated Active Directory on AWS

This project automates the deployment of a fully functional Windows Active Directory (AD) environment on AWS using Terraform and PowerShell. It provisions a custom VPC, a Domain Controller (DC), and a Member Server (Client) with zero manual intervention.

The lab is designed to demonstrate **Infrastructure as Code (IaC)** principles and **Zero Trust** security by using AWS Systems Manager (SSM) instead of open RDP ports.

## 🏗 Architecture

The environment creates an isolated network topology:

* **VPC:** `10.10.0.0/16` (Custom non-default VPC)
* **Domain Controller (DC01):** `10.10.1.10` (Windows Server 2022 Core)
* **Member Server (Client01):** `10.10.2.20` (Windows Server 2022 Core)
* **Domain:** `corp.cloudlab.internal`
* **Security:** "Dark Node" configuration (No inbound internet access).

## 🚀 Getting Started

### Prerequisites

1.  **Terraform** (v1.0+)
2.  **AWS CLI** (Configured with `aws configure`)
3.  **Session Manager Plugin** ([Install Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

### 1. Clone the Repository

```bash
git clone [https://github.com/Hectormalvarez/basic-ad.git](https://github.com/Hectormalvarez/basic-ad.git)
cd basic-ad/environments/aws-phase1

```

### 2. Configure Variables

Create a `terraform.tfvars` file in the `aws-phase1` directory.

**⚠️ Password Warning:** Windows Server enforces strict complexity (Uppercase, Lowercase, Numbers).

```hcl
# terraform.tfvars

# The master password for the lab (Must be Complex!)
admin_password = "CloudL@b2026!"

# Optional: Change the instance size
instance_type = "t3.medium"

```

### 3. Deploy

Initialize Terraform and apply the configuration.

```bash
terraform init
terraform apply

```

The deployment takes approximately **15-20 minutes**.

* **Phase 1 (2 min):** Infrastructure provisioning.
* **Phase 2 (10-15 min):** Windows bootstrapping (DC Promotion & Reboot).

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

* **Check Domain Status:** `Get-ADDomain`
* **Check DNS:** `Get-DnsServerResourceRecord -ZoneName "corp.cloudlab.internal"`

---

## 🔧 Technical Details

### Zero Trust Access

We utilize **AWS Systems Manager (SSM)** to manage the instances.

* **No Open Ports:** Security Groups allow NO inbound traffic from the internet.
* **IAM Auth:** Access is controlled via AWS Identity and Access Management (IAM), not network firewalls.
* **DNS Handling:** Custom bootstrapping scripts inject DNS Forwarders to ensure the DC can communicate with AWS APIs even after promoting to a Domain Controller.

## 🧹 Clean Up

To destroy all resources:

```bash
terraform destroy
