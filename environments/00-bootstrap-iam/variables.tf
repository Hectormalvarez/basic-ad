variable "region" {
  description = "AWS Region to initialize the provider (IAM is global, but Terraform needs an entry point)"
  type        = string
  default     = "us-east-1"
}