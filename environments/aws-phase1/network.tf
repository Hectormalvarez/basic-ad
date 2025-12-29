# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------

# Define the Virtual Private Cloud (VPC) with a custom CIDR block to avoid
# overlapping with standard home networks (192.168.x.x) or default corporate ranges.
resource "aws_vpc" "lab_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Required for Active Directory DNS record registration
  
  tags = {
    Name = "omni-identity-vpc"
  }
}

# -----------------------------------------------------------------------------
# DHCP Options (The DNS Fix for Active Directory)
# -----------------------------------------------------------------------------

resource "aws_vpc_dhcp_options" "ad_lab_dhcp" {
  domain_name = var.domain_name

  # CRITICAL: 
  # 1. First DNS Server = Your Domain Controller (var.dc_ip)
  # 2. Second DNS Server = Amazon (Backup/Internet resolution)
  domain_name_servers = [var.dc_ip, "AmazonProvidedDNS"]

  ntp_servers = ["169.254.169.123"] # Sync time with AWS infrastructure

  tags = {
    Name = "omni-ad-dhcp"
  }
}

resource "aws_vpc_dhcp_options_association" "ad_lab_assoc" {
  vpc_id          = aws_vpc.lab_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_lab_dhcp.id
}

# -----------------------------------------------------------------------------
# Connectivity (Internet Gateway & Routing)
# -----------------------------------------------------------------------------

# Internet Gateway required for outbound traffic (OS updates, package installation).
# In a production environment, this would typically be replaced by a NAT Gateway 
# for private subnets, but is used here for cost optimization.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "omni-lab-igw"
  }
}

# Public Route Table routing 0.0.0.0/0 traffic to the Internet Gateway.
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "omni-public-rt"
  }
}

# -----------------------------------------------------------------------------
# Subnet definitions (Zones of Trust)
# -----------------------------------------------------------------------------

# Gateway Subnet: Reserved for future Edge services (VPN, Bastion).
# Currently configured with public IP assignment for simplified lab access.
resource "aws_subnet" "gateway_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = var.subnet_cidrs["gateway"]
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-sn-gateway-1a"
  }
}

# Identity Subnet: Dedicated hosting zone for Domain Controllers.
# Separated from client traffic to allow for strict NACL/Security Group rules.
resource "aws_subnet" "identity_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = var.subnet_cidrs["identity"]
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-sn-identity-1a"
  }
}

# Client Subnet: Hosting zone for Member Servers and Workstations.
# Simulates the "User" segment of a corporate network.
resource "aws_subnet" "client_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = var.subnet_cidrs["client"]
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-sn-client-1a"
  }
}

# -----------------------------------------------------------------------------
# Route Table Associations
# -----------------------------------------------------------------------------

# Associate all subnets with the Public Route Table to ensure connectivity
# during the bootstrapping phase.

resource "aws_route_table_association" "gateway_assoc" {
  subnet_id      = aws_subnet.gateway_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "identity_assoc" {
  subnet_id      = aws_subnet.identity_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "client_assoc" {
  subnet_id      = aws_subnet.client_subnet.id
  route_table_id = aws_route_table.public_rt.id
}