# Security

## Postgres compared with RDS

The ask was "similar to RDS security-wise". This is how each RDS control maps here.

| RDS control | Here |
|---|---|
| Encryption at rest with KMS | gp3 volumes encrypted with a customer-managed KMS key (`storageClass.kmsKeyId`), rotated yearly |
| Encrypted backups and snapshots | S3 SSE-KMS with its own key, versioning on, public access blocked, TLS-only bucket policy |
| Point-in-time recovery | Continuous WAL archive + daily base backups, 30 days in production |
| Multi-AZ | Three instances in three zones, synchronous commit to one standby, automatic failover |
| `rds.force_ssl` | `pg_hba` rejects every non-TLS connection; TLS 1.3 minimum |
| Not publicly accessible, security groups | No public endpoint. NetworkPolicy admits only pods labelled `agele.xyz/postgres-client`, the operator, monitoring and the Tailscale proxy |
| IAM-controlled backup access | EKS Pod Identity role for the `agele-pg` ServiceAccount; no static keys |
| Master user | Superuser disabled; the app owns its database with a generated password |
| Automatic minor upgrades | Image bump PR; the operator upgrades standbys, then switches over |
| Enhanced monitoring | CloudNativePG metrics in Prometheus and its Grafana dashboard |
| Deletion protection | `reclaimPolicy: Retain` on the StorageClass, Argo CD finalizers, S3 versioning |

What RDS has that this does not: AWS runs it for you. Here the operator handles failover and backups, and a person handles major upgrades and restores ([operations](operations.md)).

## Boundaries

```mermaid
flowchart TB
  internet([Internet]) -->|443 only| cf[Cloudflare: TLS, WAF, rate limits]
  cf -->|tunnel| cfd[cloudflared]
  cfd --> app[web, api, ws]
  app --> data[(Postgres, Redis)]
  tailnet([Tailnet admins]) -->|ACL: 4 ports| admin[k8s API, Argo CD, Grafana, Postgres]
  internet -.x|no inbound path| cluster[(nodes, pods)]
```

| Layer | Enforced by |
|---|---|
| Edge | Cloudflare strict TLS, HTTPS only, managed and OWASP rulesets, 600 req/min per IP on the API, POST-only Helius webhook |
| Network | Private subnets only; no public load balancer or node port; VPC flow logs on |
| Cluster API | Private endpoint; public endpoint only during bootstrap from listed IPs; access through Tailscale and EKS access entries |
| Namespace | Default-deny ingress; explicit allow per workload |
| Pod | Non-root, read-only root, no capabilities, seccomp, no service account token |
| Node | Bottlerocket, IMDSv2 with hop limit 1 (pods cannot reach node credentials), encrypted root volume |
| Secrets | Bitwarden per environment; etcd envelope encryption with KMS; nothing in git |
| Change | Git + Argo CD self-heal; Argo CD local admin off, SSO before launch, read-only by default |
| Audit | EKS API and audit logs to CloudWatch; Argo CD history; Bitwarden event logs |

## Not covered yet

- Image signing and admission policy (cosign + Kyverno) for GHCR images.
- Egress restrictions: pods can reach the internet (needed for Solana RPC, Helius, Jupiter, Privy). An egress allowlist through a proxy is a later step.
- Runtime detection (GuardDuty EKS Runtime Monitoring is one switch in AWS).
