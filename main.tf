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
variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "AMI for EC2"
  type        = string
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
