provider "vault" {
  address = "http://localhost:8200/"
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_policy" "all_kv" {
  name = "all_kv"

  policy = <<EOT
path "kv/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_approle_auth_backend_role" "allkv" {
  backend        = vault_auth_backend.approle.path
  role_name      = "allkv"
  token_policies = ["default", "all_kv"]
}

resource "vault_approle_auth_backend_role_secret_id" "allkv" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.allkv.role_name
}

resource "local_file" "role_id_txt" {
  content  = "${vault_approle_auth_backend_role.allkv.role_id}"
  filename = "../vault-agent/role_id.txt"
}

resource "local_file" "secret_id_txt" {
  content  = "${vault_approle_auth_backend_role_secret_id.allkv.secret_id}"
  filename = "../vault-agent/secret_id.txt"
}