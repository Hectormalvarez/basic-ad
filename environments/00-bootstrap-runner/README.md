# ☁️ Phase 0: Bootstrap Runner (Cloud-Native)

[![CloudFormation](https://img.shields.io/badge/AWS-CloudFormation-FF9900?logo=amazon-aws)](https://aws.amazon.com/cloudformation/)

> **The "Jump Box" Solution:** Use this method if you do not want to configure AWS Access Keys on your local machine.

This module deploys a disposable **Bootstrap Runner** instance. This runner is pre-configured with the permissions (`AdministratorAccess`) and tools (`terraform`, `git`) needed to deploy the main lab.

## 🚀 Setup Instructions

### 1. Launch the Runner
1.  Download the [bootstrap.yaml](bootstrap.yaml) file from this folder.
2.  Log into the [AWS Console](https://console.aws.amazon.com/).
3.  Navigate to **CloudFormation** > **Create stack** > **With new resources (standard)**.
4.  **Template source:** Upload `bootstrap.yaml`.
5.  **Stack name:** `Lab-Bootstrap`.
6.  **Parameters:** Keep defaults (`t3.micro`) or adjust as needed.
7.  **Capabilities:** Check "I acknowledge that AWS CloudFormation might create IAM resources" and click **Submit**.

### 2. Connect
Once the stack status is `CREATE_COMPLETE`:
1.  Go to the **EC2 Console**.
2.  Select the instance named **Bootstrap-Runner**.
3.  Click **Connect** > **Session Manager** > **Connect**.

### 3. Deploy the Lab
You are now inside the secure runner.

```bash
# 1. Get the code
cd /home/ec2-user
git clone https://github.com/Hectormalvarez/basic-ad.git
cd basic-ad/environments/aws-phase1

# 2. Configure Secrets
echo 'admin_password = "ComplexPassword123!"' > terraform.tfvars

# 3. Deploy
terraform init
terraform apply

```

## 🧹 Cleanup

When you are done with the project:

1. Run `terraform destroy` from inside the runner.
2. Delete the `Lab-Bootstrap` stack from the CloudFormation console to terminate the runner.
