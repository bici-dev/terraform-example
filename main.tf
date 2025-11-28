###########################################
# Terraform Configuration
###########################################
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###########################################
# Provider
###########################################
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

###########################################
# Variables
###########################################

# AWS Configuration
variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1" # São Paulo
}

variable "ami_id" {
  description = "AMI for EC2"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key name for EC2 instances"
  type        = string
}

# Cloudflare Configuration
variable "cloudflare_api_key" {
  description = "Cloudflare API key"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

# Git Repository Configuration
variable "github_repo" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

# Odoo Configuration
variable "odoo_jwt_secret" {
  description = "JWT secret for Odoo SSO"
  type        = string
  sensitive   = true
}

variable "odoo_admin_password" {
  description = "Odoo admin password"
  type        = string
  sensitive   = true
}

variable "odoo_db_password" {
  description = "Odoo database password"
  type        = string
  sensitive   = true
}

# Orbit Integration
variable "backend_url" {
  description = "Backend URL for Orbit integration"
  type        = string
}

variable "frontend_url" {
  description = "Frontend URL for Orbit integration"
  type        = string
}

# Tenant Information (Dynamic variables from Lambda)
variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for tenant (dynamic from Lambda)"
  type        = string
}

variable "tenant_name" {
  description = "Tenant name (dynamic from Lambda)"
  type        = string
}

###########################################
# Resources
###########################################
# Basic EC2 instance for testing connectivity
resource "aws_instance" "test" {
  ami                    = var.ami_id
  instance_type          = "t3.micro" # free-tier eligible (if supported in sa-east-1)
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.default.id]

  tags = {
    Name = "terraform-test"
  }
}

###########################################
# Outputs
###########################################
output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.test.public_ip
}
