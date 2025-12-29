variable "project_name" {
  description = "Base name for resources, used in tagging"
  type        = string
  default     = "basic-ad"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidrs" {
  description = "Map of subnet names to CIDR blocks for clear segmentation"
  type        = map(string)
  default = {
    gateway  = "10.10.0.0/24"
    identity = "10.10.1.0/24"
    client   = "10.10.2.0/24"
  }
}

variable "az" {
  description = "Availability Zone to anchor resources (simplifies lab latency)"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance size for Lab Servers"
  type        = string
  default     = "t3.small"
}

variable "admin_password" {
  description = "Administrator password for the Domain Controller (Sensitive)"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "Your public IP address in CIDR format (e.g., 1.2.3.4/32) for RDP/WinRM access"
  type        = string
}

variable "domain_name" {
  description = "The FQDN of the Active Directory Domain"
  type        = string
  default     = "corp.cloudlab.internal"
}

variable "dc_ip" {
  description = "Static Private IP for the Domain Controller"
  type        = string
  default     = "10.10.1.10"
}

variable "client_ip" {
  description = "Static Private IP for the Member Server (Client)"
  type        = string
  default     = "10.10.2.20"
}