# -----------------------------------------------------------------------------
# Security Group Strategy: "The Hard Shell"
# -----------------------------------------------------------------------------

resource "aws_security_group" "dc_sg" {
  name        = "dc-security-group"
  description = "Allow Management from Home and Internal AD Traffic"
  vpc_id      = aws_vpc.lab_vpc.id

  # 1. Management Access (RDP & WinRM) - STRICTLY LIMITED to your IP
  ingress {
    description = "Allow RDP from Admin IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Allow WinRM (HTTPs) from Admin IP"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  # Allow HTTP WinRM for initial lab bootstrap (Optional but helpful for debugging)
  ingress {
    description = "Allow WinRM (HTTP) from Admin IP"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # 2. Intranet Traffic (Active Directory Ports)
  # Allowing ALL internal traffic from the VPC CIDR (10.10.0.0/16)
  # avoids listing 20+ ports (DNS, Kerberos, RPC, SMB, LDAP, etc.)
  ingress {
    description = "Allow all internal VPC traffic (Identity & Client communication)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means "All Protocols"
    cidr_blocks = [var.vpc_cidr]
  }

  # 3. Outbound Traffic (Patches & Updates)
  egress {
    description = "Allow outbound traffic to the internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-identity-dc"
  }
}