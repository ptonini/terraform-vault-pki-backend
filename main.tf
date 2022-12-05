module "backend" {
  source = "ptonini/mount/vault"
  version = "~> 1.0.0"
  path = var.path
  type = var.backend_type
}

resource "vault_pki_secret_backend_intermediate_cert_request" "this" {
  backend = module.backend.this.path
  type = var.type
  common_name = var.common_name
  organization = var.organization
}

resource "vault_pki_secret_backend_root_sign_intermediate" "this" {
  count = var.root_ca_pki_path != null ? 1 : 0
  backend = var.root_ca_pki_path
  csr = vault_pki_secret_backend_intermediate_cert_request.this.csr
  ttl = var.ttl
  common_name = var.common_name
  organization = var.organization
  revoke = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "this" {
  count = var.root_ca_pki_path != null || var.signed_certificate != null ? 1 : 0
  backend = module.backend.this.path
  certificate = coalesce(var.signed_certificate, try(vault_pki_secret_backend_root_sign_intermediate.this[0].certificate, null))
}

resource "null_resource" "update_default_issuer" {
  triggers = {
    certificate = vault_pki_secret_backend_intermediate_set_signed.this[0].certificate
  }
  provisioner "local-exec" {
    environment = {
      VAULT_TOKEN = var.vault_token
    }
    command = <<EOF
      if [ $(vault list -format=json ${module.backend.this.path}/issuers | jq -r '. | length') -ge 1 ]; then
        vault delete ${module.backend.this.path}/issuer/default
        vault write ${module.backend.this.path}/root/replace default=$(vault list -format=json ${module.backend.this.path}/issuers | jq -r '.[0]')
      fi
      vault write ${module.backend.this.path}/issuer/default leaf_not_after_behavior=truncate
    EOF
  }
  depends_on = [
    vault_pki_secret_backend_intermediate_set_signed.this[0]
  ]
}