# environments/00-bootstrap-iam/main.tf

# -----------------------------------------------------------------------------
# IAM Group: The Lab Operators
# -----------------------------------------------------------------------------
resource "aws_iam_group" "lab_admins" {
  name = "terraform-group"
}

# -----------------------------------------------------------------------------
# Policy 1: Lab Infrastructure (Current State: VPC & EC2)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "infra_policy" {
  name        = "Terraform-Lab-Infrastructure"
  description = "Allows provisioning of EC2 and VPC resources for the current Lab"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CoreInfrastructure"
        Effect = "Allow"
        Action = [
          "ec2:*",              # Required for VPC, Subnets, NAT, Instances
          "s3:*",               # Required for Terraform State storage
          "dynamodb:*",         # Required for Terraform State locking
          "kms:*",              # Required for EBS Encryption
          "ssm:GetParameter",   # Required to read AMI IDs
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassRoleToEC2"
        Effect = "Allow"
        Action = "iam:PassRole"
        # Strictly limited: Can only pass roles to EC2 instances
        Resource = "*" 
        Condition = {
            StringEquals = {
                "iam:PassedToService": "ec2.amazonaws.com"
            }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Policy 2: IAM Enabler (Current State: SSM Role Creation)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "iam_enabler_policy" {
  name        = "Terraform-IAM-Enabler"
  description = "Specific permissions to create the Lab's SSM Roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageSSMRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListInstanceProfilesForRole"
        ]
        # Strict Scope: Can only touch the specific role we use in the lab
        Resource = "arn:aws:iam::*:role/ssm-managed-instance-role"
      },
      {
        Sid    = "ManageInstanceProfiles"
        Effect = "Allow"
        Action = [
          "iam:CreateInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile"
        ]
        Resource = "arn:aws:iam::*:instance-profile/ssm-instance-profile"
      },
      {
        Sid    = "ReadManagedPolicies"
        Effect = "Allow"
        Action = [
          "iam:ListPolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Policy 3: Operations (Current State: Connectivity Only)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "ops_policy" {
  name        = "Terraform-Lab-Operations"
  description = "Allows the human user to connect via SSM Session Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSMConnection"
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession"
        ]
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell", # Default shell doc
          "arn:aws:ssm:*:*:session/*"
        ]
      },
      {
        Sid    = "AllowMetadataDiscovery"
        Effect = "Allow"
        Action = [
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Attachments
# -----------------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "attach_infra" {
  group      = aws_iam_group.lab_admins.name
  policy_arn = aws_iam_policy.infra_policy.arn
}

resource "aws_iam_group_policy_attachment" "attach_iam" {
  group      = aws_iam_group.lab_admins.name
  policy_arn = aws_iam_policy.iam_enabler_policy.arn
}

resource "aws_iam_group_policy_attachment" "attach_ops" {
  group      = aws_iam_group.lab_admins.name
  policy_arn = aws_iam_policy.ops_policy.arn
}