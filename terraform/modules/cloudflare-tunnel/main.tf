terraform {
  required_version = ">= 1.10"
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
}

variable "account_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "name" {
  description = "Tunnel name, e.g. agele-production."
  type        = string
}

variable "web_hostname" {
  description = "Hostname for agele-web, e.g. agele.xyz or staging.agele.xyz."
  type        = string
}

variable "api_hostname" {
  description = "Hostname for the REST API and websocket, e.g. api.agele.xyz."
  type        = string
}

variable "extra_web_hostnames" {
  description = "More hostnames served by agele-web, e.g. www.agele.xyz."
  type        = list(string)
  default     = []
}

variable "namespace" {
  type    = string
  default = "agele"
}

locals {
  svc = "svc.cluster.local"
  web = "http://agele-web.${var.namespace}.${local.svc}:3000"
  api = "http://agele-api.${var.namespace}.${local.svc}:4000"
  ws  = "http://agele-ws.${var.namespace}.${local.svc}:4001"
}

# Remotely managed tunnel: cloudflared in the cluster only needs the token, routes live here.
resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.account_id
  name       = var.name
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config = {
    ingress = concat(
      [
        # The websocket server lives at /ws on the API hostname.
        { hostname = var.api_hostname, path = "^/ws", service = local.ws },
        { hostname = var.api_hostname, service = local.api },
        { hostname = var.web_hostname, service = local.web },
      ],
      [for h in var.extra_web_hostnames : { hostname = h, service = local.web }],
      [{ service = "http_status:404" }],
    )
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

resource "cloudflare_dns_record" "this" {
  for_each = toset(concat([var.web_hostname, var.api_hostname], var.extra_web_hostnames))
  zone_id  = var.zone_id
  name     = each.value
  type     = "CNAME"
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
  comment  = "Cloudflare Tunnel ${var.name} (terraform)"
}

output "tunnel_id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_token" {
  description = "Store in Bitwarden as CLOUDFLARE_TUNNEL_TOKEN in the environment's project."
  value       = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
  sensitive   = true
}
