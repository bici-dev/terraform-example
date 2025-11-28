###########################################
# Cloudflare Provider Configuration
###########################################
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_key
}

###########################################
# Cloudflare DNS Records
###########################################
# A record pointing subdomain to EC2 instance
resource "cloudflare_record" "odoo" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  value   = aws_instance.odoo.public_ip
  type    = "A"
  ttl     = 1  # Auto (Cloudflare proxy)
  proxied = true  # Enable Cloudflare proxy (SSL, DDoS protection, etc.)

  comment = "Managed by Terraform - ${var.tenant_name} Odoo instance"
}

###########################################
# Outputs
###########################################
output "cloudflare_record_hostname" {
  description = "Full hostname created in Cloudflare"
  value       = cloudflare_record.odoo.hostname
}

output "cloudflare_proxied" {
  description = "Whether Cloudflare proxy is enabled"
  value       = cloudflare_record.odoo.proxied
}
