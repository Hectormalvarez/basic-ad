# Technical Design Document: Hybrid Cloud Architecture (Local KVM)
**Date:** January 2, 2026
**Status:** Draft
**Author:** Hector Alvarez

## 1. Executive Summary
This design outlines the architectural evolution of the `basic-ad` lab from a single-provider model (AWS) to a **Cloud-Agnostic** model. By introducing a local development environment using KVM/Libvirt, we aim to reduce operational costs and accelerate the feedback loop for lab development while maintaining "Infrastructure as Code" fidelity.

## 2. Problem Statement
The current architecture presents the following constraints:
* **Vendor Lock-in:** The provisioning logic (`bootstrap-dc.ps1`) contains hardcoded AWS-specific network values (e.g., `10.10.0.2` for DNS, `10.10.1.1` for Gateway).
* **Cost Barrier:** Developing and testing new features requires running paid EC2 instances.
* **Missing Abstraction:** There is no mechanism to simulate the AWS `user_data` injection process locally, preventing true offline development.

## 3. Proposed Architecture

### 3.1 The "Image Factory" Pattern
To replicate the behavior of AWS AMIs locally, we will implement an immutable image build pipeline using **HashiCorp Packer**.
* **Source:** Windows Server 2022 Evaluation ISO.
* **Enabler:** **Cloudbase-Init**. This open-source agent will be baked into the image to emulate `EC2Launch`. It allows the local VM to ingest Terraform `user_data` scripts just like an AWS instance.
* **Artifact:** `qcow2` disk image stored locally.

### 3.2 Modularization Strategy
We will decouple **Infrastructure** (Providers) from **Logic** (Scripts).

| Layer | AWS Implementation | Local Implementation |
| :--- | :--- | :--- |
| **Provider** | `hashicorp/aws` | `dmacvicar/libvirt` |
| **Compute** | `aws_instance` | `libvirt_domain` |
| **Storage** | EBS Volume | QCOW2 Volume |
| **Bootstrapping** | `user_data` (EC2) | `cloudinit` (ConfigDrive) |
| **Scripts** | Shared (Modules) | Shared (Modules) |

## 4. Technical Implementation Details

### 4.1 Phase 1: Script Parameterization (Refactor)
The PowerShell bootstrapping scripts must be upgraded to accept network topology as arguments rather than static values.
* **Change:** `bootstrap-dc.ps1` will accept `-GatewayIP` and `-DnsForwarderIP` parameters.
* **AWS Impact:** The existing Terraform `templatefile` calls must be updated to pass the VPC values (`10.10.1.1`, `10.10.0.2`) explicitly.

### 4.2 Phase 2: The Packer Pipeline
A new directory `images/windows-server-2022` will be created to house the build logic.
* **Automation:** An `autounattend.xml` file will handle the OOBE (Out-of-Box Experience) to ensure a zero-touch build.
* **Transport:** WinRM will be temporarily enabled to allow Packer to install Cloudbase-Init.

### 4.3 Phase 3: The Libvirt Environment
A new environment `environments/local-kvm` will be established.
* **Network:** Uses the default Libvirt NAT bridge (`virbr0`).
* **DNS:** Since no VPC Resolver exists, the script will be passed a public upstream DNS (e.g., `8.8.8.8`) or the local bridge IP.

## 5. Rollback & Risk Strategy
* **Risk:** Parameterization breaks the stable AWS build.
* **Mitigation:** Changes will be implemented on a feature branch (`refactor/agnostic-scripts`). We will verify the AWS deployment succeeds *before* merging the refactor, ensuring the "Golden Path" remains stable.

## 6. Future Value
This architecture paves the way for:
* **CI/CD:** Automated testing of AD logic in GitHub Actions (using nested virtualization).
* **Cost Savings:** Users can learn Terraform and AD concepts completely offline.