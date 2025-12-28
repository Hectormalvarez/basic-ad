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
  instance_type = "t3.micro" # Free Tier Eligible (2 vCPU, 1 GB RAM)
  
  # Networking
  subnet_id                   = aws_subnet.identity_subnet.id
  private_ip                  = var.dc_ip
  vpc_security_group_ids      = [aws_security_group.dc_sg.id]
  associate_public_ip_address = true # Required for updates since we have no NAT Gateway
  
  # Storage (Root Volume)
  root_block_device {
    volume_size = 35 # GB (Minimum recommended for Windows)
    volume_type = "gp3"
    encrypted   = true
  }

  # ---------------------------------------------------------------------------
  # The Bootstrap Injection Strategy
  # ---------------------------------------------------------------------------
  # We read the PS1 script from our modules folder, then wrap it in a 
  # <powershell> block so the EC2 instance executes it.
  # We also execute the script with the arguments from our Terraform variables.
  
  user_data = <<POWERSHELL
<powershell>
# 1. Save the script logic to disk (Architecture: Persistence)
$ScriptContent = @"
${file("../../modules/identity-core/scripts/bootstrap-dc.ps1")}
"@
Set-Content -Path C:\bootstrap-dc.ps1 -Value $ScriptContent

# 2. Execute the script with injected variables
C:\bootstrap-dc.ps1 -DomainName "${var.domain_name}" -SafeModePassword "${var.admin_password}" -StaticIP "${var.dc_ip}"
</powershell>
POWERSHELL

  tags = {
    Name = "DC01-Identity"
    Role = "Domain Controller"
  }
}

# -----------------------------------------------------------------------------
# Outputs: Information we need after deployment
# -----------------------------------------------------------------------------

output "dc_public_ip" {
  description = "Public IP for RDP Access (Use with caution)"
  value       = aws_instance.domain_controller.public_ip
}

output "dc_private_ip" {
  description = "Private IP (Used by Clients for DNS)"
  value       = aws_instance.domain_controller.private_ip
}