# 🔐 Phase 0: IAM Group Bootstrap (Local CLI)

[![Terraform](https://img.shields.io/badge/Terraform-Automation-623CE4?logo=terraform)](https://www.terraform.io/)

> **The "Admin Workstation" Solution:** Use this method if you already have AWS Access Keys configured on your laptop and want to organize your permissions securely.

This module creates a dedicated IAM Group (`terraform-group`) with the exact least-privilege permissions needed to deploy the lab.

## 🛠 Setup Instructions

### Prerequisites
* **Terraform** installed locally.
* **AWS CLI** configured with a user that has permission to create IAM Groups/Policies.

### 1. Deploy the Group
Navigate to this directory and apply the Terraform configuration:

```bash
# Initialize Terraform
terraform init

# Apply the configuration
terraform apply

```

### 2. Assign Permissions

Once the group is created, add your IAM user to it using the AWS CLI:

```bash
# Replace <YOUR_USER> with your actual AWS username
aws iam add-user-to-group --user-name <YOUR_USER> --group-name terraform-group

```

*Note: You may need to log out and log back in (or refresh your credentials) for the new group permissions to take effect.*

### 3. Verification

Verify you are in the group:

```bash
aws iam get-group --group-name terraform-group

```
