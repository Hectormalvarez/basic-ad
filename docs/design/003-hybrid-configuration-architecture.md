# Technical Design Document: Hybrid Configuration Architecture

> **Context for AI Assistants:**
> This project (`basic-ad`) is a Terraform-based Active Directory lab on AWS. 
> We are actively refactoring it from a static "User Data" deployment to a hybrid "Ansible" configuration workflow.
> The current focus is the `feat/ansible-integration` branch.
> Use the "Implementation Tracker" below to determine the current state of development.

**Date:** January 14, 2026
**Status:** In Progress
**Branch:** `feat/ansible-integration`
**Author:** Hector Alvarez

## 1. Executive Summary
This document outlines the architectural shift from "User Data" (boot-time scripting) to "Ansible" (configuration management). We are introducing a dedicated **Linux Controller Node** to orchestrate the configuration of Windows resources. This moves the lab from a static "deploy and wait" model to an interactive "deploy and provision" workflow.

## 2. Problem Statement
The previous architecture relied on complex, 100+ line PowerShell scripts embedded in Terraform `user_data`. This presented two challenges:
* **Observability:** If the script failed, the server required a full destroy/rebuild cycle to retry.
* **Realism:** Production environments rarely use "Black Box" boot scripts for complex domain configuration.

## 3. Proposed Architecture: "The Controller & The Target"

### 3.1 The Controller (The Brain)
* **OS:** Amazon Linux 2023
* **Size:** `t3.nano` (Cost-optimized)
* **Location:** Gateway Subnet (Public/Edge)
* **Role:** Holds the Ansible Playbooks and orchestrates the lab. It is the specific "Management Station" for the environment.

### 3.2 The Target (The Identity Vault)
* **OS:** Windows Server 2022 Core
* **Size:** `t3.small`
* **Location:** Identity Subnet (Private)
* **Role:** Receives commands. It runs a minimal listener allowing it to be managed, but has no self-contained logic.

## 4. Security Model: Tiered Administration
We are moving from a strict "Zero Trust" (SSM Only) model to a "Privileged Access Workstation" (PAW) model.

* **Ingress (Windows):** The Domain Controller Security Group will allow **TCP 5985 (WinRM)**.
* **Restriction:** This port is open **ONLY** to the Private IP of the Linux Controller.
* **Result:** The Windows server remains "Dark" to the internet and the rest of the VPC, trusting only the management node.

## 5. Implementation Tracker
*Mark completed steps with [x].*

### Phase 1: Infrastructure Hardware
- [x] **Commit 1:** `feat: add linux controller and instance variables`
    * Split `instance_type` into `linux_instance_type` / `windows_instance_type`.
    * Define `aws_instance.edge_gateway` (Amazon Linux 2023) in Terraform.
- [ ] **Commit 2:** `feat: enable winrm connectivity`
    * Create `edge_sg`.
    * Allow TCP 5985 Inbound to `base_sg` from `edge_sg`.
- [ ] **Commit 3:** `refactor: replace dc bootstrap with winrm listener`
    * Replace heavy PowerShell bootstrap with minimal WinRM configuration script.

### Phase 2: Configuration Logic (Ansible)
- [ ] **Commit 4:** `feat: initialize ansible project structure`
    * Create `lab/ansible/` directory, `ansible.cfg`, and `inventory.ini`.
- [ ] **Commit 5:** `feat: add domain controller promotion playbook`
    * Port `bootstrap-dc.ps1` logic to `setup-ad.yml` playbook.

### Phase 3: Integration & Documentation
- [ ] **Commit 6:** `feat: add provisioning wrapper script`
    * Update Linux `user_data` to install Ansible/Git.
    * Create `provision.sh` helper script.
- [ ] **Commit 7:** `docs: update workflow for ansible integration`
    * Update README to reflect the new Deploy -> Connect -> Provision workflow.