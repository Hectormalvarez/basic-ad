# Omni-Identity Lab: Cloud-Agnostic Active Directory

## Architectural Vision
A modular, "Infrastructure-as-Data" implementation of an Active Directory environment. This project demonstrates the automation of a legacy identity standard (AD DS) using modern DevOps principles (Terraform, Cloud-Init, Server Core).

* **Network:** 10.10.0.0/16 (Non-overlapping Hybrid Design)
* **Compute:** Windows Server 2022 Core (Headless Optimization)
* **Logic:** PowerShell-driven "Zero Touch" provisioning

## Directory Structure
* `/modules`: Agnostic Logic (PowerShell & Abstracted TF)
* `/environments`: Provider-Specific Implementation (AWS/Azure)