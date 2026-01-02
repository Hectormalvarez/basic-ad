# Technical Design Document: SSM Session Audit Logging
**Date:** January 2, 2026
**Status:** Draft
**Author:** Hector Alvarez

## 1. Executive Summary
This document outlines the architecture for enabling comprehensive session logging. Currently, SSM sessions are secure but opaque; there is no record of commands executed. This upgrade implements **CloudWatch Logs** integration.

## 2. Problem Statement
* **Lack of Accountability:** No historical record of administrator actions.
* **Compliance Gap:** "Zero Trust" requires verifying actions, not just identity.

## 3. Proposed Architecture

### 3.1 Infrastructure Components
* **CloudWatch Log Group:** A dedicated log group (`/aws/ssm/ad-lab-sessions`).
* **IAM Permissions:** Update EC2 Instance Profile to allow `logs:PutLogEvents`.



### 3.2 Security Controls
* **Encryption:** Log data is encrypted in transit (TLS) and at rest.
* **Retention:** Logs expire after 30 days to manage costs.

## 4. Implementation Plan
1.  **Infrastructure:** Create `aws_cloudwatch_log_group` and update IAM policies.
2.  **Configuration:** Update SSM outputs to target the log group.
3.  **Validation:** Verify transcript generation in CloudWatch.
