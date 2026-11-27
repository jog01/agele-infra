data "cloudflare_zone" "this" {
  filter = { name = var.domain }
}

locals {
  zone_id   = data.cloudflare_zone.this.zone_id
  api_hosts = ["api.${var.domain}", "staging-api.${var.domain}"]
}

# Edge TLS: full strict, TLS 1.2+, HTTPS only.
resource "cloudflare_zone_setting" "this" {
  for_each = {
    ssl                      = "strict"
    min_tls_version          = "1.2"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    tls_1_3                  = "on"
    websockets               = "on"
    security_level           = "medium"
    browser_check            = "on"
  }
  zone_id    = local.zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_ruleset" "waf_managed" {
  zone_id     = local.zone_id
  name        = "agele managed WAF"
  description = "Cloudflare Managed Ruleset and OWASP Core Ruleset"
  kind        = "zone"
  phase       = "http_request_firewall_managed"
  rules = [
    {
      description       = "Cloudflare Managed Ruleset"
      expression        = "true"
      action            = "execute"
      action_parameters = { id = "efb7b8c949ac4650a09736fc376e9aee" }
    },
    {
      description       = "Cloudflare OWASP Core Ruleset"
      expression        = "true"
      action            = "execute"
      action_parameters = { id = "4814384a9e5d4991b9815dcfc25d2f1f" }
    },
  ]
}

resource "cloudflare_ruleset" "custom" {
  zone_id     = local.zone_id
  name        = "agele custom rules"
  description = "Request rules ahead of the managed WAF"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  rules = [
    {
      description = "Helius webhooks: POST only"
      expression  = "(http.request.uri.path eq \"/v1/webhooks/helius\" and http.request.method ne \"POST\")"
      action      = "block"
    },
  ]
}

resource "cloudflare_ruleset" "rate_limit" {
  zone_id     = local.zone_id
  name        = "agele rate limits"
  description = "Per-IP limits on the API hostnames"
  kind        = "zone"
  phase       = "http_ratelimit"
  rules = [
    {
      description = "API requests per IP"
      expression  = "(http.host in {${join(" ", [for h in local.api_hosts : "\"${h}\""])}} and not http.request.uri.path eq \"/ws\")"
      action      = "block"
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = 60
        requests_per_period = var.api_rate_limit_per_minute
        mitigation_timeout  = 60
      }
    },
  ]
}

# One web origin: www redirects to the apex, which is the only origin the API allows (CORS) and Privy lists.
resource "cloudflare_ruleset" "redirects" {
  zone_id     = local.zone_id
  name        = "agele redirects"
  description = "www to apex"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"
  rules = [
    {
      description = "www.${var.domain} to ${var.domain}"
      expression  = "(http.host eq \"www.${var.domain}\")"
      action      = "redirect"
      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = true
          target_url = {
            expression = "concat(\"https://${var.domain}\", http.request.uri.path)"
          }
        }
      }
    },
  ]
}
