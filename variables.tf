variable "backend_type" {
  default = "pki"
}

variable "path" {}

variable "type" {
  default = "internal"
}

variable "common_name" {}

variable "organization" {
  default = ""
}

variable "ttl" {
  default = null
}

variable "root_ca_pki_path" {
  default = null
}

variable "signed_certificate" {
  default = null
}

variable "vault_token" {}