# Technical Design Document: High-Level Logging Strategy

**Date:** January 14, 2026
**Status:** Draft / TBD
**Author:** Hector Alvarez

## 1. Executive Summary
This document outlines the high-level requirements for centralized logging within the lab environment. As we move toward a hybrid Windows/Linux architecture, comprehensive visibility into authentication events and system changes is critical for security analysis.

## 2. Requirements
The logging solution must eventually support the following data sources:

### 2.1 Identity (Windows Domain Controller)
* **Security Event Log:** Tracking Event IDs 4624 (Logon), 4625 (Failed Logon), 4720 (User Created), etc.
* **System Event Log:** Tracking service status changes and reboots.
* **PowerShell Logs:** Script block logging to detect malicious administrative activity.

### 2.2 Infrastructure (Linux Controller)
* **Auth.log:** Tracking SSH logins and sudo usage.
* **Ansible Logs:** Tracking playbook execution results and configuration changes.

## 3. Potential Strategies (TBD)
Implementation details are deferred until the Ansible refactor is complete. Potential paths include:

* **Option A: Cloud-Native (CloudWatch)**
    * *Pros:* Zero maintenance, easy integration with AWS IAM.
    * *Cons:* AWS-specific, costs money per GB.
* **Option B: Self-Hosted (ELK / Loki)**
    * *Pros:* Industry standard for DevOps, "Free" (except compute costs).
    * *Cons:* High maintenance overhead to manage the stack.
* **Option C: SaaS Forwarder (Datadog / Splunk)**
    * *Pros:* Best UI, real-world enterprise tools.
    * *Cons:* Trial licenses expire, agents can be heavy.

## 4. Decision
**Status:** Deferred.
We will revisit this architecture after the Ansible Controller is successfully orchestrating the environment (Design Doc 003).