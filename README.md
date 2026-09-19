# streamingapp-infra

AWS infrastructure for **streamingapp**, managed with Terraform + Terragrunt. This repo provisions the cloud resources a containerized streaming platform needs to run: container image registries, a Kubernetes (EKS) cluster, and an S3 bucket with a narrowly-scoped IAM user for application access.

Terraform state is stored remotely in **Terraform Cloud** (org: `shaikhniraj`) — one workspace per component, e.g. `streamingapp-dev-ecr`, `streamingapp-dev-eks`.

## What it provisions

| Component | Path | Creates |
|---|---|---|
| **ECR** | [`live/dev/ecr`](live/dev/ecr/terragrunt.hcl) | One ECR repository per microservice (`auth`, `streaming`, `admin`, `chat`, `frontend`) under `streamingapp/<service>`, with scan-on-push enabled |
| **EKS** | [`live/dev/eks`](live/dev/eks/terragrunt.hcl) | An EKS cluster (via the official `terraform-aws-modules/eks/aws` module) with a managed node group (`t3.medium`, 1–3 nodes) in an existing VPC, admin access entries for specified IAM roles/users, IRSA (OIDC provider) enabled, the **EBS CSI driver** and **metrics-server** installed as EKS add-ons (the former backs Mongo's PVC via a default `gp3` StorageClass, the latter is what `HorizontalPodAutoscaler`s in the app's Helm chart read CPU% from), and a security group rule opening cross-node pod-to-pod traffic |
| **S3** | [`live/dev/s3`](live/dev/s3/terragrunt.hcl) | A media/storage S3 bucket for the app |
| **IAM S3 access** | [`live/dev/iam-s3-access`](live/dev/iam-s3-access/terragrunt.hcl) | A dedicated IAM user + access key scoped to read/write/delete objects and list *only* the S3 bucket above (nothing else) |
| **ingress-nginx** | [`live/dev/ingress-nginx`](live/dev/ingress-nginx/terragrunt.hcl) | The `ingress-nginx` controller (via Terraform's `helm` provider, not a manual `helm install`), exposed as a `LoadBalancer` Service — AWS provisions a Classic ELB for it, which is the app's single public entry point |
| **monitoring** | [`live/dev/monitoring`](live/dev/monitoring/terragrunt.hcl) | The `amazon-cloudwatch-observability` EKS add-on (CloudWatch Agent + Fluent Bit, via IRSA) for Container Insights metrics and centralized logs, an SNS topic, and 5 CloudWatch alarms — see [Monitoring & Alarms](#monitoring--alarms) below |

Reusable Terraform modules for each component live under [`modules/`](modules/).

### Repo layout

```
streamingapp-infra/
├── live/
│   ├── terragrunt.hcl          # root config: Terraform Cloud backend + AWS provider (generated for every child)
│   └── dev/
│       ├── ecr/terragrunt.hcl
│       ├── eks/terragrunt.hcl
│       ├── s3/terragrunt.hcl
│       ├── iam-s3-access/terragrunt.hcl   # depends on s3's output (bucket_arn)
│       ├── ingress-nginx/terragrunt.hcl   # depends on eks's outputs (cluster endpoint/CA/name)
│       └── monitoring/terragrunt.hcl      # depends on eks (oidc outputs) + ingress-nginx (ELB hostname)
└── modules/
    ├── ecr/
    ├── eks/
    ├── s3/
    ├── iam-s3-access/
    ├── ingress-nginx/
    └── monitoring/
```

Each `live/dev/<component>/terragrunt.hcl` includes the root config (backend + provider) and points at the matching module in `modules/`, passing in environment-specific inputs. Components with a Terragrunt `dependency` block (`iam-s3-access` on `s3`; `ingress-nginx` on `eks`; `monitoring` on both `eks` and `ingress-nginx`) automatically read the values they need from that component's state instead of them being hardcoded — apply in that order, or just use `run-all` (see [Usage](#usage)), which resolves the order for you.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) `>= 1.9.0`
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- AWS credentials configured locally (e.g. via `aws configure`, SSO, or environment variables) with permission to manage ECR, EKS, VPC/EC2, IAM, and S3
- A [Terraform Cloud](https://app.terraform.io/) account with access to the `shaikhniraj` organization (state backend), and `terraform login` run locally
- An existing VPC and subnets in `us-east-1` for the EKS cluster (see [Configuration](#configuration) below)

## Usage

All commands are run with `terragrunt` from inside a specific component directory under `live/dev/`.

### Provision a single component

```bash
cd live/dev/ecr
terragrunt plan
terragrunt apply
```

Repeat for the other components as needed, respecting dependency order: **`s3` before `iam-s3-access`**, **`eks` before `ingress-nginx`**, and **both `eks` and `ingress-nginx` before `monitoring`**.

### Provision everything at once

From `live/dev`, Terragrunt can run a command across all components in dependency order:

```bash
cd live/dev
terragrunt run-all plan
terragrunt run-all apply
```

### Destroy

```bash
cd live/dev/<component>
terragrunt destroy
```

Or `terragrunt run-all destroy` from `live/dev` to tear everything down (destroys in reverse dependency order).

### After applying EKS

Update your local kubeconfig to talk to the new cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name streamingapp-dev-cluster
```

`enable_irsa = true` on the cluster also creates an IAM OIDC provider, and its ARN/issuer are exposed as the `oidc_provider_arn`/`oidc_provider` outputs — any later module that needs to grant a Kubernetes ServiceAccount its own IAM role (the EBS CSI driver and the monitoring module's `cloudwatch-agent` role both already do this) reads them from here instead of re-deriving them.

### After applying ingress-nginx

Get the public entry point for the whole app — an AWS Classic ELB hostname:

```bash
cd live/dev/ingress-nginx
terragrunt output load_balancer_hostname
```

Point the streaming app's Helm chart `clientUrl` value (and CORS/`CLIENT_URLS`) at `http://<that-hostname>`, and use it to reach the app in a browser.

### After applying ECR

Authenticate Docker to the new registries and push images, e.g.:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/streamingapp/<service>:<tag>
```

### After applying `iam-s3-access`

Read the generated credentials out of Terraform Cloud/Terragrunt outputs (the secret key is marked sensitive and won't print in plain plan/apply logs):

```bash
cd live/dev/iam-s3-access
terragrunt output access_key_id
terragrunt output -raw secret_access_key
```

Use these as the app's S3 credentials — they only allow read/write/delete/list on the one bucket created by the `s3` component.

## Configuration

Environment-specific values are set as `inputs` in each `live/dev/<component>/terragrunt.hcl`. Notably, `eks/terragrunt.hcl` currently hardcodes:

- `vpc_id` and `subnet_ids` — replace these with your actual AWS VPC/subnet IDs before applying
- `cluster_admin_role_arns` — IAM roles/users granted cluster-admin access via EKS Access Entries; update these to match who should have `kubectl` admin access

The AWS region (`us-east-1`) and Terraform Cloud organization (`shaikhniraj`) are set once in [`live/terragrunt.hcl`](live/terragrunt.hcl) and inherited by every component.

## Monitoring & Alarms

The `monitoring` component installs the `amazon-cloudwatch-observability` EKS add-on, which runs two DaemonSets in the `amazon-cloudwatch` namespace:

- **CloudWatch Agent** — publishes Container Insights metrics (`ContainerInsights` namespace): per-node and per-pod CPU/memory utilization, container restart counts, etc. — viewable under CloudWatch → Container Insights, no extra setup.
- **Fluent Bit** — ships every pod's stdout/stderr to CloudWatch Logs under `/aws/containerinsights/streamingapp-dev-cluster/{application,dataplane,host}` — the app's services need no logging code changes; they already log via `morgan`/`console.log`.

Both authenticate via IRSA (a dedicated `cloudwatch-agent` IAM role, not the node role), scoped to just the `cloudwatch-agent` ServiceAccount via `CloudWatchAgentServerPolicy`.

5 CloudWatch alarms are created, all publishing to one SNS topic (`streamingapp-dev-alerts`, output as `sns_topic_arn`):

| Alarm | Source | Threshold |
|---|---|---|
| `streamingapp-dev-node-cpu-high` | Container Insights | Node CPU > 80% for 15 min |
| `streamingapp-dev-node-memory-high` | Container Insights | Node memory > 80% for 15 min |
| `streamingapp-dev-pod-restarts-high` | Container Insights | > 3 container restarts cluster-wide in 5 min |
| `streamingapp-dev-ingress-elb-unhealthy-hosts` | `AWS/ELB` (no agent needed — the Classic ELB publishes this itself) | Any unhealthy backend for 3 min |
| `streamingapp-dev-ingress-elb-backend-5xx` | `AWS/ELB` | > 10 backend 5xx responses in 5 min |

Subscribe an email to the topic by setting `alarm_email` in `live/dev/monitoring/terragrunt.hcl`, or subscribe something else (Slack/Teams/Telegram via SNS) directly — this is the topic the optional ChatOps step would reuse.

## Notes

- `.terraform/` and `.terragrunt-cache/` directories are generated locally by Terragrunt and are gitignored — don't commit them.
- Only a `dev` environment exists today; add a sibling `live/<env>/` directory (e.g. `live/staging/`) with its own `terragrunt.hcl` files to introduce another environment.
