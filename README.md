# ☁️ Basic AD: The Simplest Active Directory Lab

**Learn Active Directory on AWS in minutes.**

🛑 **Read this before starting:** This lab creates real AWS resources. By default, it uses `t3.micro` (Free Tier eligible) but can be upgraded to `t3.small` (~$0.04/hr) for better performance. **Always run the Cleanup step when finished.**

---

## 🗺️ What You Are Building

You are deploying a professional Identity Lab directly from your browser.

```text
       (You)
         |
    [ AWS CloudShell ]  <--- (Free Browser Terminal)
         |
         | (Deploys "Hardware" via Terraform)
         v
  +-----------------------------------------+
  |      PRIVATE LAB NETWORK (VPC)          |
  |                                         |
  |   +-----------------+                   |
  |   | Linux Controller|                   |
  |   | 10.10.0.10      |                   |
  |   +-----------------+                   |
  |          |   ^                          |
  |          v   |                          |
  |   +-------------+     +--------------+  |
  |   | Domain      |<--->| Member       |  |
  |   | Controller  |     | Server       |  |
  |   | (DC01)      |     | (Client01)   |  |
  |   +-------------+     +--------------+  |
  +-----------------------------------------+

```

* **Zero Setup:** No local tools to install. No configuration files.
* **Secure:** Uses AWS Systems Manager (SSM) for access. No public IP addresses required.

---

## 🚀 Step-by-Step Guide

### Phase 1: Launch the Lab

> This phase only provisions the "Hardware" infrastructure. Configuration happens after you connect to the controller.

#### Time: ~7 Minutes

1. **Log in to AWS:**

* Go to the [AWS Console](https://console.aws.amazon.com/).
* Ensure you are in **US East (N. Virginia)** or your preferred region.

1. **Open CloudShell:**

* Click the **CloudShell icon** (`>_`) in the top navigation bar (near the bell icon).
* *Or press `Alt` + `S` (Windows) / `Option` + `S` (Mac).*
* Wait for the terminal to prepare.

1. **Run the Deployment:**

* Paste the following commands into the terminal and hit Enter:

```bash
git clone https://github.com/Hectormalvarez/basic-ad.git
cd basic-ad

# Run with default settings (Free Tier / t3.micro (1GB RAM))
./quickstart.sh

# Recommended: Run with better performance (~$0.04/hr (2GB RAM))
./quickstart.sh t3.small

```

**Note:** running `.\quickstart.sh` without a parameter will default to `t3.micro` (Free Tier) with only 1GB of RAM.
To use a faster instance, run: `./quickstart.sh LARGER_INSTANCE_TYPE`

1. **Enter a Password:**

* When prompted, type a secure password (e.g., `SuperSecurePass123!`).
* *Note: Characters will not appear while typing.*

1. **Wait for Completion:**

* Terraform will build the network and servers.
* The lab takes about **10-15 minutes** (Windows needs to reboot twice to promote the Domain Controller).
* Look for the green message: `Deployment Complete!`

### Phase 2: Configure Active Directory

1. **Connect to the Linux Controller**

From CloudShell, run:
```bash
./connect.sh controller
```

2. **Run the Ansible Provisioning**

Inside the controller terminal, run:
```bash
./provision.sh
```

This will execute the Ansible playbook to promote the Domain Controller and configure the lab environment.

### Phase 3: Access the Domain Controller

Once provisioning finishes, you can connect directly from CloudShell.

1. **Connect to DC01:**

* Run this command in your CloudShell terminal:

```bash
./connect.sh

```

* *This uses AWS Systems Manager to open a secure PowerShell session on the Domain Controller.*

1. **Verify Active Directory:**

* Once connected (you will see a `PS C:\>` prompt), try these commands:

```powershell
# Check the domain details
Get-ADDomain

# Check DNS records
Get-DnsServerResourceRecord -ZoneName "corp.cloudlab.internal"

```

### Phase 4: Access the Client (Optional)

1. Open a **new** CloudShell tab (Click the `+` icon).
2. Navigate to the folder: `cd basic-ad`
3. Connect to the member server:

```bash
./connect.sh client

```

---

## ❓ Troubleshooting

### "CloudShell says 'command not found'"

Ensure you are in the correct directory. Run `cd ~/basic-ad` and try again.

### "Connection failed / Target not connected"

If you try `./connect.sh` immediately after deployment, the server might still be booting. Wait 2 minutes and try again.

### "Terraform Error: 403 Forbidden / Access Denied"

Your AWS user permissions might be too restricted. Ensure you are using an Admin user or have full EC2/VPC permissions.

---

## 🧹 Cleanup (Crucial!)

**Do not skip this.** If you leave this running, AWS will charge you for the Linux Controller, Domain Controller, and Member Server.

1. Go back to your **CloudShell** terminal.
2. Run this command:

```bash
./quickstart.sh destroy

```

1. Wait for the confirmation: `Cleanup Complete!`

> **Tip:** If you close CloudShell, your lab is **NOT** deleted. You must reopen CloudShell, navigate to the folder, and run the destroy command. All lab resources including the Controller will be removed.
