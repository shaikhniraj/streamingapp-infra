# streamingapp-infra

AWS infrastructure for **streamingapp**, managed with Terraform + Terragrunt. This repo provisions the cloud resources a containerized streaming platform needs to run: container image registries, a Kubernetes (EKS) cluster, and an S3 bucket with a narrowly-scoped IAM user for application access.

Terraform state is stored remotely in **Terraform Cloud** (org: `shaikhniraj`) — one workspace per component, e.g. `streamingapp-dev-ecr`, `streamingapp-dev-eks`.

## What it provisions

| Component | Path | Creates |
|---|---|---|
| **ECR** | [`live/dev/ecr`](live/dev/ecr/terragrunt.hcl) | One ECR repository per microservice (`auth`, `streaming`, `admin`, `chat`, `frontend`) under `streamingapp/<service>`, with scan-on-push enabled |
| **EKS** | [`live/dev/eks`](live/dev/eks/terragrunt.hcl) | An EKS cluster (via the official `terraform-aws-modules/eks/aws` module) with a managed node group (`t3.medium`, 1–3 nodes) in an existing VPC, plus admin access entries for specified IAM roles/users |
| **S3** | [`live/dev/s3`](live/dev/s3/terragrunt.hcl) | A media/storage S3 bucket for the app |
| **IAM S3 access** | [`live/dev/iam-s3-access`](live/dev/iam-s3-access/terragrunt.hcl) | A dedicated IAM user + access key scoped to read/write/delete objects and list *only* the S3 bucket above (nothing else) |

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
│       └── iam-s3-access/terragrunt.hcl   # depends on s3's output (bucket_arn)
└── modules/
    ├── ecr/
    ├── eks/
    ├── s3/
    └── iam-s3-access/
```

Each `live/dev/<component>/terragrunt.hcl` includes the root config (backend + provider) and points at the matching module in `modules/`, passing in environment-specific inputs. `iam-s3-access` declares a Terragrunt `dependency` on `s3` so it automatically picks up the bucket ARN instead of it being hardcoded.

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

Repeat for `eks`, `s3`, and `iam-s3-access` as needed. **Apply `s3` before `iam-s3-access`**, since the latter reads the bucket ARN from the former's state.

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

## Notes

- `.terraform/` and `.terragrunt-cache/` directories are generated locally by Terragrunt and are gitignored — don't commit them.
- Only a `dev` environment exists today; add a sibling `live/<env>/` directory (e.g. `live/staging/`) with its own `terragrunt.hcl` files to introduce another environment.
