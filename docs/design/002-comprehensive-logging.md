# Technical Design Document: Comprehensive Security Observability
**Date:** January 2, 2026
**Status:** Draft
**Author:** Hector Alvarez

## 1. Executive Summary
This design implements a "Defense in Depth" monitoring strategy for the Active Directory Lab. We will move beyond simple connectivity to full observability by implementing the **Trinity of Logging**:

1.  **Session Activity:** Full shell transcripts of administrator actions.
2.  **OS & AD Events:** Windows Security and Directory Service logs.
3.  **Network Traffic:** VPC Flow Logs to visualize accepted/rejected traffic.

This establishes the **Data Plane** required for future security projects (SIEM, Threat Hunting, Incident Response).

## 2. Architecture Overview

We will centralize all telemetry into **Amazon CloudWatch Logs** for a "Single Pane of Glass" experience.

### 2.1 The Three Pillars of Data

| Pillar | Source | Mechanism | Destination Log Group |
| :--- | :--- | :--- | :--- |
| **Activity** | SSM Shell | SSM Document Preference | `/aws/ssm/ad-lab-sessions` |
| **Endpoint** | Windows Server | CloudWatch Agent (Unified) | `/aws/ec2/windows-events` |
| **Network** | VPC Interfaces | VPC Flow Logs Service | `/aws/vpc/ad-lab-flow` |

## 3. Technical Implementation Details

### 3.1 Pillar 1: SSM Session Logging (Server-Side Enforcement)
* **Objective:** Force all shell sessions to be recorded.
* **Resource:** `aws_ssm_document` (Global Preference).
* **Config:** `cloudWatchStreamingEnabled: true`, `cloudWatchLogGroupName: /aws/ssm/ad-lab-sessions`.

### 3.2 Pillar 2: Windows Event Logging (OS Level)
* **Objective:** Capture AD changes (e.g., User Created, Login Failed) and System health.
* **Agent:** **Amazon CloudWatch Agent** (Must be installed and configured).
* **Configuration Strategy:**
    * Store the JSON config in **SSM Parameter Store** (`/ad-lab/cw-agent-config`).
    * Use an **SSM Association** to automatically apply this config to any instance tagged `Role: Domain Controller` or `Role: Member Server`.
* **Captured Channels:**
    * `System`
    * `Application`
    * `Security` (Critical for Audit)
    * `Directory Service` (Critical for AD)

### 3.3 Pillar 3: VPC Flow Logs (Network Level)
* **Objective:** Audit network traffic metadata (Source IP, Dest IP, Port, Action).
* **Resource:** `aws_flow_log`.
* **Scope:** Attached to the `aws_vpc` ID to capture all ENIs.
* **Format:** Standard AWS format (Version 2).

## 4. Infrastructure Requirements (Terraform)

### 4.1 IAM Permissions (The "Keys")
The existing `ssm_role` needs expanded permissions. We will attach the managed policy `CloudWatchAgentServerPolicy` and add custom inline policies for Flow Logs.
* `logs:CreateLogGroup`
* `logs:CreateLogStream`
* `logs:PutLogEvents`
* `logs:DescribeLogStreams`

### 4.2 Resources to Provision
1.  **Log Groups:** Three distinct groups with 30-day retention.
2.  **SSM Config:** `aws_ssm_parameter` to hold the CloudWatch Agent JSON.
3.  **Agent Deployment:** `aws_ssm_association` to install the agent via `AWS-ConfigureCloudWatch`.
4.  **Network Audit:** `aws_flow_log` resource attached to the VPC.

## 5. Operational Workflow

### 5.1 Verification
1.  **Session:** Connect via SSM, run commands. Check `/aws/ssm/ad-lab-sessions`.
2.  **Events:** Generate a "Failed Login" (try bad password). Check `/aws/ec2/windows-events` for Event ID 4625.
3.  **Network:** Ping the DC from a non-allowed IP (simulated). Check `/aws/vpc/ad-lab-flow` for `REJECT` records.

## 6. Future Value
This architecture is the prerequisite for:
* **Dashboards:** Visualizing "Failed Logins per Hour".
* **Alarms:** SNS Notification on "Domain Admin Group Modification".