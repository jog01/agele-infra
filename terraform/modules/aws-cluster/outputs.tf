output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ebs_kms_key_arn" {
  description = "Set as storageClass.kmsKeyId in environments/<env>/platform-config.yaml."
  value       = aws_kms_key.this["ebs"].arn
}

output "pg_backup_bucket" {
  value = aws_s3_bucket.pg_backups.bucket
}

output "pg_backup_destination" {
  description = "Set as postgres.backup.destinationPath in environments/<env>/agele-data.yaml."
  value       = "s3://${aws_s3_bucket.pg_backups.bucket}/${var.postgres_cluster_name}"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
