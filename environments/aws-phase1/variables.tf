variable "project_name" {
  description = "Base name for resources, used in tagging"
  type        = string
  default     = "omni-identity-lab"
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