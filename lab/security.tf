# -----------------------------------------------------------------------------
# Security Group Strategy: Base Security
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Security Group Strategy: Edge Controller
# -----------------------------------------------------------------------------

resource "aws_security_group" "edge_sg" {
  name        = "ad-lab-edge-sg"
  description = "Security Group for the Linux Controller (Ansible Node)"
  vpc_id      = aws_vpc.lab_vpc.id

  # OUTBOUND: Internet Access
  # Required for Ansible to reach external resources
  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-edge-lab"
  }
}

resource "aws_security_group" "base_sg" {
  name        = "ad-lab-base-sg"
  description = "Base Security Group: WinRM from Controller + SSM Access Only"
  vpc_id      = aws_vpc.lab_vpc.id

  # INBOUND: Management Only
  # Allow WinRM (TCP 5985) from the Linux Controller
  ingress {
    description     = "Allow WinRM (HTTP) from Linux Controller"
    from_port       = 5985
    to_port         = 5985
    protocol        = "tcp"
    security_groups = [aws_security_group.edge_sg.id]
  }

  # OUTBOUND: Internet Access
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
