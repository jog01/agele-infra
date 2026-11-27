terraform {
  required_version = ">= 1.10"
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
    tailscale  = { source = "tailscale/tailscale", version = "~> 0.21" }
  }
  # terraform init -backend-config=../backend.hcl -backend-config="key=global/terraform.tfstate"
  backend "s3" {}
}

# CLOUDFLARE_API_TOKEN: Zone DNS/WAF/Settings edit on agele.xyz, Account Cloudflare Tunnel edit.
provider "cloudflare" {}

# TAILSCALE_OAUTH_CLIENT_ID / TAILSCALE_OAUTH_CLIENT_SECRET with policy_file and oauth_keys scopes.
provider "tailscale" {
  tailnet = var.tailnet
}
