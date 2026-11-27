variable "name" {
  description = "Cluster and resource name prefix, e.g. agele-production."
  type        = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  description = "Three zones: Postgres keeps one instance per zone."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "One NAT gateway instead of one per zone. Fine for staging, not for production."
  type        = bool
  default     = false
}

variable "node_instance_types" {
  type    = list(string)
  default = ["m7i.xlarge"]
}

variable "node_min_size" {
  type    = number
  default = 3
}

variable "node_max_size" {
  type    = number
  default = 9
}

variable "endpoint_public_access" {
  description = "Public API endpoint. Needed only until the Tailscale API proxy works (docs/go-live.md); then set false."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Operator IPs allowed on the public endpoint while it is on."
  type        = list(string)
  default     = []
}

variable "admin_principal_arns" {
  description = "IAM roles or users granted cluster admin through EKS access entries."
  type        = list(string)
  default     = []
}

variable "pg_backup_retention_days" {
  description = "S3 keeps objects this many days after barman deletes them; barman's own retention lives in Helm values."
  type        = number
  default     = 35
}

variable "postgres_namespace" {
  type    = string
  default = "agele"
}

variable "postgres_cluster_name" {
  description = "CloudNativePG cluster name; its pods run as a ServiceAccount of the same name."
  type        = string
  default     = "agele-pg"
}

variable "tags" {
  type    = map(string)
  default = {}
}
