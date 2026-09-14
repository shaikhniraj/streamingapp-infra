variable "project"{
    type = string
    default = "streamingapp"
    description = "The name of the project"
}

variable "services" { 

    type = list(string)
    description = "The list of services"
}

