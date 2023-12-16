resource "vault_mount" "this" {
  path = var.path
  type = var.backend_type
}

resource "vault_pki_secret_backend_intermediate_cert_request" "this" {
  backend      = vault_mount.this.path
  type         = var.type
  common_name  = var.common_name
  organization = var.organization
}

resource "vault_pki_secret_backend_root_sign_intermediate" "this" {
  count        = var.root_ca_pki_path != null ? 1 : 0
  backend      = var.root_ca_pki_path
  csr          = vault_pki_secret_backend_intermediate_cert_request.this.csr
  ttl          = var.ttl
  common_name  = var.common_name
  organization = var.organization
  revoke       = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "this" {
  count       = var.root_ca_pki_path != null || var.signed_certificate != null ? 1 : 0
  backend     = vault_mount.this.path
  certificate = coalesce(var.signed_certificate, try(vault_pki_secret_backend_root_sign_intermediate.this[0].certificate, null))
}

resource "vault_pki_secret_backend_config_issuers" "config" {
  count                         = one(vault_pki_secret_backend_intermediate_set_signed.this[*]) == null ? 0 : 1
  backend                       = vault_mount.this.path
  default                       = one(vault_pki_secret_backend_intermediate_set_signed.this[*].imported_issuers)
  default_follows_latest_issuer = true
}