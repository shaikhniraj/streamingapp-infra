Result of ECR - terragrunt apply 

PS C:\Users\Tanishq\Documents\Assignment\ContainerizationandContainerOrchestration\streamingapp-infra\live\dev\ecr> terragrunt apply
12:04:21.212 WARN   Using `terragrunt.hcl` as the root of Terragrunt configurations is an anti-pattern, and no longer recommended. In a future version of Terragrunt, this willresult in an error. You are advised to use a differently named file like `root.hcl` instead. For more information, see https://docs.terragrunt.com/migrate/migrating-from-root-terragrunt-hcl
12:04:35.385 STDOUT terraform: Terraform used the selected providers to generate the following execution
12:04:35.386 STDOUT terraform: plan. Resource actions are indicated with the following symbols:
12:04:35.386 STDOUT terraform:   + create
12:04:35.386 STDOUT terraform: Terraform will perform the following actions:
12:04:35.386 STDOUT terraform:   # aws_ecr_repository.this["admin"] will be created
12:04:35.386 STDOUT terraform:   + resource "aws_ecr_repository" "this" {
12:04:35.386 STDOUT terraform:       + arn                  = (known after apply)
12:04:35.386 STDOUT terraform:       + id                   = (known after apply)
12:04:35.386 STDOUT terraform:       + image_tag_mutability = "MUTABLE"
12:04:35.386 STDOUT terraform:       + name                 = "streamingapp/admin"
12:04:35.387 STDOUT terraform:       + region               = "us-east-1"
12:04:35.387 STDOUT terraform:       + registry_id          = (known after apply)
12:04:35.387 STDOUT terraform:       + repository_url       = (known after apply)
12:04:35.387 STDOUT terraform:       + tags_all             = (known after apply)
12:04:35.387 STDOUT terraform:       + image_scanning_configuration {
12:04:35.387 STDOUT terraform:           + scan_on_push = true
12:04:35.387 STDOUT terraform:         }
12:04:35.387 STDOUT terraform:     }
12:04:35.387 STDOUT terraform:   # aws_ecr_repository.this["auth"] will be created
12:04:35.387 STDOUT terraform:   + resource "aws_ecr_repository" "this" {
12:04:35.387 STDOUT terraform:       + arn                  = (known after apply)
12:04:35.387 STDOUT terraform:       + id                   = (known after apply)
12:04:35.387 STDOUT terraform:       + image_tag_mutability = "MUTABLE"
12:04:35.388 STDOUT terraform:       + name                 = "streamingapp/auth"
12:04:35.388 STDOUT terraform:       + region               = "us-east-1"
12:04:35.388 STDOUT terraform:       + registry_id          = (known after apply)
12:04:35.388 STDOUT terraform:       + repository_url       = (known after apply)
12:04:35.388 STDOUT terraform:       + tags_all             = (known after apply)
12:04:35.388 STDOUT terraform:       + image_scanning_configuration {
12:04:35.388 STDOUT terraform:           + scan_on_push = true
12:04:35.388 STDOUT terraform:         }
12:04:35.388 STDOUT terraform:     }
12:04:35.388 STDOUT terraform:   # aws_ecr_repository.this["chat"] will be created
12:04:35.388 STDOUT terraform:   + resource "aws_ecr_repository" "this" {
12:04:35.388 STDOUT terraform:       + arn                  = (known after apply)
12:04:35.388 STDOUT terraform:       + id                   = (known after apply)
12:04:35.389 STDOUT terraform:       + image_tag_mutability = "MUTABLE"
12:04:35.389 STDOUT terraform:       + name                 = "streamingapp/chat"
12:04:35.389 STDOUT terraform:       + region               = "us-east-1"
12:04:35.389 STDOUT terraform:       + registry_id          = (known after apply)
12:04:35.389 STDOUT terraform:       + repository_url       = (known after apply)
12:04:35.389 STDOUT terraform:       + tags_all             = (known after apply)
12:04:35.389 STDOUT terraform:       + image_scanning_configuration {
12:04:35.389 STDOUT terraform:           + scan_on_push = true
12:04:35.389 STDOUT terraform:         }
12:04:35.389 STDOUT terraform:     }
12:04:35.389 STDOUT terraform:   # aws_ecr_repository.this["frontend"] will be created
12:04:35.389 STDOUT terraform:   + resource "aws_ecr_repository" "this" {
12:04:35.390 STDOUT terraform:       + arn                  = (known after apply)
12:04:35.390 STDOUT terraform:       + id                   = (known after apply)
12:04:35.390 STDOUT terraform:       + image_tag_mutability = "MUTABLE"
12:04:35.390 STDOUT terraform:       + name                 = "streamingapp/frontend"
12:04:35.390 STDOUT terraform:       + region               = "us-east-1"
12:04:35.390 STDOUT terraform:       + registry_id          = (known after apply)
12:04:35.390 STDOUT terraform:       + repository_url       = (known after apply)
12:04:35.390 STDOUT terraform:       + tags_all             = (known after apply)
12:04:35.391 STDOUT terraform:       + image_scanning_configuration {
12:04:35.391 STDOUT terraform:           + scan_on_push = true
12:04:35.391 STDOUT terraform:         }
12:04:35.391 STDOUT terraform:     }
12:04:35.391 STDOUT terraform:   # aws_ecr_repository.this["streaming"] will be created
12:04:35.391 STDOUT terraform:   + resource "aws_ecr_repository" "this" {
12:04:35.391 STDOUT terraform:       + arn                  = (known after apply)
12:04:35.391 STDOUT terraform:       + id                   = (known after apply)
12:04:35.391 STDOUT terraform:       + image_tag_mutability = "MUTABLE"
12:04:35.391 STDOUT terraform:       + name                 = "streamingapp/streaming"
12:04:35.391 STDOUT terraform:       + region               = "us-east-1"
12:04:35.391 STDOUT terraform:       + registry_id          = (known after apply)
12:04:35.391 STDOUT terraform:       + repository_url       = (known after apply)
12:04:35.392 STDOUT terraform:       + tags_all             = (known after apply)
12:04:35.392 STDOUT terraform:       + image_scanning_configuration {
12:04:35.392 STDOUT terraform:           + scan_on_push = true
12:04:35.392 STDOUT terraform:         }
12:04:35.392 STDOUT terraform:     }
12:04:35.392 STDOUT terraform: Plan: 5 to add, 0 to change, 0 to destroy.
12:04:35.392 STDOUT terraform: Changes to Outputs:
12:04:35.392 STDOUT terraform:   + repository_urls = {
12:04:35.392 STDOUT terraform:       + admin     = (known after apply)
12:04:35.392 STDOUT terraform:       + auth      = (known after apply)
12:04:35.392 STDOUT terraform:       + chat      = (known after apply)
12:04:35.393 STDOUT terraform:       + frontend  = (known after apply)
12:04:35.393 STDOUT terraform:       + streaming = (known after apply)
12:04:35.393 STDOUT terraform:     }
12:04:35.393 STDOUT terraform: 
12:04:35.393 STDOUT terraform: Do you want to perform these actions in workspace "streamingapp-dev-ecr"?
12:04:35.393 STDOUT terraform:   Terraform will perform the actions described above.
12:04:35.393 STDOUT terraform:   Only 'yes' will be accepted to approve.
12:04:35.393 STDOUT terraform:   Enter a value: 
yes
12:05:33.261 STDOUT terraform: aws_ecr_repository.this["admin"]: Creating...
12:05:33.262 STDOUT terraform: aws_ecr_repository.this["auth"]: Creating...
12:05:33.262 STDOUT terraform: aws_ecr_repository.this["frontend"]: Creating...
12:05:33.262 STDOUT terraform: aws_ecr_repository.this["streaming"]: Creating...
12:05:33.262 STDOUT terraform: aws_ecr_repository.this["chat"]: Creating...
12:05:35.016 STDOUT terraform: aws_ecr_repository.this["frontend"]: Creation complete after 2s [id=streamingapp/frontend]
12:05:35.073 STDOUT terraform: aws_ecr_repository.this["admin"]: Creation complete after 2s [id=streamingapp/admin]
12:05:35.116 STDOUT terraform: aws_ecr_repository.this["auth"]: Creation complete after 2s [id=streamingapp/auth]
12:05:35.146 STDOUT terraform: aws_ecr_repository.this["streaming"]: Creation complete after 2s [id=streamingapp/streaming]
12:05:35.503 STDOUT terraform: aws_ecr_repository.this["chat"]: Creation complete after 3s [id=streamingapp/chat]
12:05:37.988 STDOUT terraform: 
12:05:37.990 STDOUT terraform: Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
12:05:37.990 STDOUT terraform: 
12:05:37.990 STDOUT terraform: Outputs:
12:05:37.991 STDOUT terraform: repository_urls = {
12:05:37.991 STDOUT terraform:   "admin" = "586917955726.dkr.ecr.us-east-1.amazonaws.com/streamingapp/admin"
12:05:37.992 STDOUT terraform:   "auth" = "586917955726.dkr.ecr.us-east-1.amazonaws.com/streamingapp/auth"
12:05:37.992 STDOUT terraform:   "chat" = "586917955726.dkr.ecr.us-east-1.amazonaws.com/streamingapp/chat"
12:05:37.993 STDOUT terraform:   "frontend" = "586917955726.dkr.ecr.us-east-1.amazonaws.com/streamingapp/frontend"
12:05:37.993 STDOUT terraform:   "streaming" = "586917955726.dkr.ecr.us-east-1.amazonaws.com/streamingapp/streaming"
12:05:37.993 STDOUT terraform: }
PS C:\Users\Tanishq\Documents\Assignment\ContainerizationandContainerOrchestration\streamingapp-infra\live\dev\ecr> 