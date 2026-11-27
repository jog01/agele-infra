# Running on GKE

The Helm charts, Argo CD apps, Cloudflare and Tailscale setup do not change. Only the Terraform for the cluster and a few values do.

| Piece | EKS (this repo) | GKE |
|---|---|---|
| Cluster | `terraform/modules/aws-cluster` (VPC, EKS) | `terraform-google-modules/kubernetes-engine` private regional cluster across 3 zones, Dataplane V2 |
| NetworkPolicy | VPC CNI with `enableNetworkPolicy` | Dataplane V2 enforces it |
| Encrypted disks | EBS gp3 + KMS (`cloud: aws`) | PD balanced + CMEK (`cloud: gcp`, `storageClass.kmsKeyId` = Cloud KMS key) |
| etcd secret encryption | KMS key on the cluster | Application-layer secrets encryption with Cloud KMS |
| Backup bucket | S3 + SSE-KMS, versioned | GCS with CMEK and object versioning |
| Backup credentials | EKS Pod Identity on `agele-pg` | Workload Identity: annotate `postgres.serviceAccountAnnotations` with `iam.gke.io/gcp-service-account` |
| Backup values | `destinationPath: s3://...`, `inheritFromIAMRole: true` | `destinationPath: gs://...`; change the `ObjectStore` to `googleCredentials: { gkeEnvironment: true }` |
| Nodes | Bottlerocket, IMDSv2 hop limit 1 | Container-Optimized OS, Shielded nodes, metadata concealment via Workload Identity |
| Admin access | Tailscale operator API proxy; public endpoint off after bootstrap | Same; set `master_authorized_networks` empty after bootstrap |

Steps in [go-live.md](go-live.md) are the same; replace step 3 with the GKE module and `gcloud container clusters get-credentials`.
