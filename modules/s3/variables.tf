variable "project" {
    type = string
    description = "The project name for the S3 module"
}

variable "environment" {
    type = string
    description = "The environment for the S3 module (e.g., dev, staging, prod)"
}