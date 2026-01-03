# -----------------------------------------------------------------------------
# Security Group Strategy: Base Security
# -----------------------------------------------------------------------------

resource "aws_security_group" "base_sg" {
  name        = "ad-lab-base-sg"
  description = "Base Security Group: Intranet Trust + SSM Access Only"
  vpc_id      = aws_vpc.lab_vpc.id

  # 1. INBOUND: Internal Only
  # Allow all traffic from within the VPC.
  ingress {
    description = "Allow all internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # 2. OUTBOUND: Internet Access
  # Required for SSM Agent to reach AWS API and for patching.
  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-base-lab"
  }
}