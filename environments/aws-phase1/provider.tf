terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
# Region selection targets us-east-1 for broad service availability
provider "aws" {
  region = "us-east-1"

  # Default tags apply metadata to all resources for cost tracking and project identification
  default_tags {
    tags = {
      Project     = "Omni-Identity-Lab"
      Environment = "Development"
      ManagedBy   = "Terraform"
    }
  }
}