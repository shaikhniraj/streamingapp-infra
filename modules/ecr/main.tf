resource "aws_ecr_repository" "this" {
    for_each = toset(var.services)
    name = "${var.project}/${each.value}"
    image_tag_mutability = "MUTABLE"

# Add this line to allow Terragrunt to wipe the images and delete the repo
  force_delete         = true 
  
    image_scanning_configuration{
        scan_on_push = true
    }
}