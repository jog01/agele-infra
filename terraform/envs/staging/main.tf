terraform {
  required_version = ">= 1.10"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.0" }
    cloudflare = { source = "cloudflare/cloudflare", version = "~> 5.0" }
  }
  # terraform init -backend-config=../../backend.hcl -backend-config="key=staging/terraform.tfstate"
  backend "s3" {}
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { environment = "staging", project = "agele" }
  }
}

provider "cloudflare" {}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cloudflare_account_id" {
  type = string
}

variable "admin_principal_arns" {
  type    = list(string)
  default = []
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access_cidrs" {
  type    = list(string)
  default = []
}

data "cloudflare_zone" "this" {
  filter = { name = "agele.xyz" }
}

module "cluster" {
  source = "../../modules/aws-cluster"

  name               = "agele-staging"
  vpc_cidr           = "10.1.0.0/16"
  azs                = ["${var.region}a", "${var.region}b", "${var.region}c"]
  single_nat_gateway = true
  node_min_size      = 3

  admin_principal_arns         = var.admin_principal_arns
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
}

module "tunnel" {
  source = "../../modules/cloudflare-tunnel"

  account_id          = var.cloudflare_account_id
  zone_id             = data.cloudflare_zone.this.zone_id
  name                = "agele-staging"
  web_hostname        = "staging.agele.xyz"
  api_hostname        = "api.staging.agele.xyz"
  extra_web_hostnames = []
}

output "cluster_name" {
  value = module.cluster.cluster_name
}

output "ebs_kms_key_arn" {
  value = module.cluster.ebs_kms_key_arn
}

output "pg_backup_destination" {
  value = module.cluster.pg_backup_destination
}

output "tunnel_token" {
  value     = module.tunnel.tunnel_token
  sensitive = true
}
