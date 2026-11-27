# Tailnet policy. Only admins reach clusters, databases and dashboards; nothing else is granted.
resource "tailscale_acl" "this" {
  acl = jsonencode({
    groups = {
      "group:agele-admins" = var.admins
    }
    tagOwners = {
      "tag:k8s-operator" = ["group:agele-admins"]
      "tag:k8s"          = ["tag:k8s-operator"]
      "tag:k8s-admin"    = ["tag:k8s-operator"]
      "tag:k8s-db"       = ["tag:k8s-operator"]
    }
    grants = [
      # kubectl through the operator's API server proxy, as cluster-admin impersonation.
      {
        src = ["group:agele-admins"]
        dst = ["tag:k8s-operator"]
        ip  = ["443"]
        app = {
          "tailscale.com/cap/kubernetes" = [{ impersonate = { groups = ["system:masters"] } }]
        }
      },
      # Argo CD and Grafana.
      { src = ["group:agele-admins"], dst = ["tag:k8s-admin"], ip = ["443"] },
      # psql to the CloudNativePG primary (TLS-only, see charts/agele-data).
      { src = ["group:agele-admins"], dst = ["tag:k8s-db"], ip = ["5432"] },
    ]
    ssh = []
    tests = [
      { src = var.admins[0], accept = ["tag:k8s-db:5432", "tag:k8s-admin:443"] },
    ]
  })
}

# One operator OAuth client per cluster. Store id and secret in that environment's Bitwarden project.
resource "tailscale_oauth_client" "operator" {
  for_each    = toset(var.environments)
  description = "agele ${each.key} k8s operator"
  scopes      = ["devices:core", "auth_keys", "services"]
  tags        = ["tag:k8s-operator"]
}

output "operator_oauth_client_ids" {
  value = { for k, v in tailscale_oauth_client.operator : k => v.id }
}

output "operator_oauth_client_secrets" {
  value     = { for k, v in tailscale_oauth_client.operator : k => v.key }
  sensitive = true
}
