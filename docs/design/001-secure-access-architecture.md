# Technical Design Document: Secure Access for Ephemeral Active Directory Labs
**Date:** January 2, 2026
**Status:** Implemented (v1.1.0)
**Author:** Hector Alvarez

## 1. Executive Summary
This document outlines the architectural changes required to transition the `basic-ad` lab environment from a "Public Ingress" model to a "Zero Trust" access model. 

## 2. Problem Statement
The previous architecture presented the following risks:
* **Security Risk:** Port 3389 exposed to the public internet.
* **Operational Overhead:** Manual IP allow-listing required.

## 3. Implemented Architecture ("Dark Mode")

### 3.1 Overview
The Domain Controller is deployed in a "Dark" state:
* **Inbound Traffic:** Deny All from Internet. Allow All from VPC (10.10.0.0/16).
* **Outbound Traffic:** Allow HTTPS (443) to AWS Systems Manager endpoints.
* **Connectivity:** Access is tunneled via AWS Systems Manager.

### 3.2 Key Technical Decisions
* **Identity over Network:** Security Groups were stripped of ingress rules. Access is now controlled via IAM Roles (`AmazonSSMManagedInstanceCore`).
* **DNS Resolution Fix:** To resolve the "Split-Brain" DNS issue on Windows Server 2022 DCs, we injected a logic step in the bootstrap script to add a specific DNS Forwarder (`10.10.0.2`) immediately post-promotion.
* **Server Core Identity:** The `ssm-user` is pre-provisioned via User Data to allow Shell access on Domain Controllers.

## 4. Rollback Strategy
If SSM connectivity fails, the Security Group change can be reverted to re-enable Public IP RDP access for debugging.
