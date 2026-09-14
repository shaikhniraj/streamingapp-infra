include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/ecr"
}

inputs = {
  services = ["auth", "streaming", "admin", "chat", "frontend"]
  project  = "streamingapp"
}