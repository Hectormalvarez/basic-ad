# -----------------------------------------------------------------------------
# Data Sources: Dynamic AMI Lookup
# -----------------------------------------------------------------------------

# Fetch the latest Windows Server 2022 Core AMI
data "aws_ami" "windows_core" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Compute Resource: The Domain Controller
# -----------------------------------------------------------------------------

resource "aws_instance" "domain_controller" {
  ami           = data.aws_ami.windows_core.id
  instance_type = var.instance_type

  # Networking
  subnet_id                   = aws_subnet.identity_subnet.id
  private_ip                  = var.dc_ip
  vpc_security_group_ids      = [aws_security_group.base_sg.id]
  associate_public_ip_address = true

  # Storage (Root Volume)
  root_block_device {
    volume_size = 35
    volume_type = "gp3"
    encrypted   = true
  }

  # Identity & Access Management (SSM Enabled)
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # ---------------------------------------------------------------------------
  # The Bootstrap Injection Strategy
  # ---------------------------------------------------------------------------
  user_data = templatefile("${path.module}/templates/dc-userdata.tftpl", {
    script_content = file("${path.module}/scripts/bootstrap-dc.ps1")
    domain_name    = var.domain_name
    admin_password = var.admin_password
    dc_ip          = var.dc_ip
  })

  tags = {
    Name = "DC01-Identity"
    Role = "Domain Controller"
  }
}

# -----------------------------------------------------------------------------
# Compute Resource: The Member Server (Client)
# -----------------------------------------------------------------------------

resource "aws_instance" "member_server" {
  ami           = data.aws_ami.windows_core.id
  instance_type = var.instance_type

  # Networking
  subnet_id                   = aws_subnet.client_subnet.id
  private_ip                  = var.client_ip
  vpc_security_group_ids      = [aws_security_group.base_sg.id]
  associate_public_ip_address = true

  # Storage
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # Identity & Access Management (SSM Enabled)
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  # ---------------------------------------------------------------------------
  # The Client Bootstrap Strategy
  # ---------------------------------------------------------------------------
  user_data = templatefile("${path.module}/templates/client-userdata.tftpl", {
    script_content = file("${path.module}/scripts/bootstrap-client.ps1")
    domain_name    = var.domain_name
    admin_password = var.admin_password
    dc_ip          = var.dc_ip
  })

  # Explicit Dependency: Ensure DC exists before Client starts
  depends_on = [aws_instance.domain_controller]

  tags = {
    Name = "Client01-Member"
    Role = "Member Server"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "ssm_dc_command" {
  description = "Run this command to open a PowerShell session to the DC"
  value       = "aws ssm start-session --target ${aws_instance.domain_controller.id}"
}

output "ssm_client_command" {
  description = "Run this command to open a PowerShell session to the Client"
  value       = "aws ssm start-session --target ${aws_instance.member_server.id}"
}

output "dc_private_ip" {
  description = "Private IP (Used by Clients for DNS)"
  value       = aws_instance.domain_controller.private_ip
}

output "client_private_ip" {
  description = "Private IP for Client"
  value       = aws_instance.member_server.private_ip
}