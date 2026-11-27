variable "domain" {
  type    = string
  default = "agele.xyz"
}

variable "tailnet" {
  description = "Tailnet name, e.g. jog01.github or example.com."
  type        = string
}

variable "admins" {
  description = "Tailscale logins with admin access to clusters, databases and dashboards."
  type        = list(string)
}

variable "api_rate_limit_per_minute" {
  description = "Requests per minute per IP and Cloudflare colo on the API hostname."
  type        = number
  default     = 600
}

variable "environments" {
  type    = list(string)
  default = ["staging", "production"]
}
