# -----------------------------------------------------------------------------
# IAM ROLE: SSM MANAGED INSTANCE
# -----------------------------------------------------------------------------
# Allows EC2 instances to be managed by AWS Systems Manager (SSM)
# without requiring SSH/RDP keys or inbound ports.

resource "aws_iam_role" "ssm_role" {
  name = "ssm-managed-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# POLICY ATTACHMENT
# -----------------------------------------------------------------------------
# Attaches the AWS-managed "AmazonSSMManagedInstanceCore" policy to the role.
# Provides permissions for SSM Agent, Patch Manager, and Session Manager.

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------------------------
# INSTANCE PROFILE
# -----------------------------------------------------------------------------
# The container used to pass the IAM Role to an EC2 Instance.

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}