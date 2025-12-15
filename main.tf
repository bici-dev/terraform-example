###########################################
# Terraform Configuration
# Updeate Terraform 
###########################################
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
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

provider "cloudflare" {
  api_token = var.cloudflare_api_key
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

variable "github_token" {
  description = "GitHub personal access token for private repos"
  type        = string
  sensitive   = true
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

variable "odoo_admin_email" {
  description = "Odoo admin email/login"
  type        = string
  default     = "admin@example.com"
}

variable "odoo_db_password" {
  description = "Odoo database password"
  type        = string
  sensitive   = true
}

variable "odoo_db_name" {
  description = "Odoo database name to create automatically"
  type        = string
  default     = "odoo"
}

variable "ssl_endpoint_api_key" {
  description = "SSL endpoint API key for Odoo"
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

variable "orbit_webhook_secret" {
  description = "Shared secret for Orbit webhook validation"
  type        = string
  sensitive   = true
}

variable "odoo_webhook_secret" {
  description = "Webhook secret for Odoo integrations (generated per-tenant)"
  type        = string
  sensitive   = true
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
# Odoo EC2 instance with cloud-init configuration
resource "aws_instance" "odoo" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.default.id]
  key_name               = var.ssh_key_name

  # Cloud-init configuration with variable substitution
  user_data = templatefile("${path.module}/cloud-init.yml", {
    # Git Configuration
    github_repo   = var.github_repo
    github_branch = var.github_branch
    github_token  = var.github_token

    # Odoo Configuration
    odoo_admin_password = var.odoo_admin_password
    odoo_admin_email    = var.odoo_admin_email
    odoo_db_password    = var.odoo_db_password
    odoo_db_name        = var.odoo_db_name
    odoo_jwt_secret     = var.odoo_jwt_secret
    ssl_endpoint_api_key = var.ssl_endpoint_api_key

    # Domain Configuration (combine subdomain + domain)
    domain_name = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name

    # Odoo Base URL (http for now, https when SSL is configured)
    odoo_base_url = var.subdomain != "" ? "http://${var.subdomain}.${var.domain_name}" : "http://${var.domain_name}"

    # Orbit Integration
    backend_url  = var.backend_url
    frontend_url = var.frontend_url

    # Orbit Webhook Configuration
    orbit_webhook_url    = "${var.backend_url}/webhooks/odoo-tenant-created"
    orbit_webhook_secret = var.odoo_webhook_secret

    # Tenant Information
    tenant_name = var.tenant_name

    # AWS Configuration for S3 access
    aws_access_key = var.aws_access_key
    aws_secret_key = var.aws_secret_key
    aws_region     = var.region
  })

  tags = {
    Name        = "${var.tenant_name}-odoo"
    Tenant      = var.tenant_name
    Subdomain   = var.subdomain
    ManagedBy   = "Terraform"
  }
}

###########################################
# Cloudflare DNS Record
###########################################
resource "cloudflare_record" "tenant_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "A"
  value   = aws_instance.odoo.public_ip
  ttl     = 300
  proxied = false # CRITICAL: must be false for Origin Certificates to work
  comment = "Managed by Terraform for tenant ${var.tenant_name}"
}

###########################################
# Outputs
###########################################
output "public_ip" {
  description = "Odoo server public IP"
  value       = aws_instance.odoo.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.odoo.id
}

output "full_domain" {
  description = "Full domain name for this deployment"
  value       = var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name
}
