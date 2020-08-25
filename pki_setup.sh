# Create namespace "acmeco"
vault namespace create acmeco

# Create namespace "acmeco/dev"
vault namespace create -namespace="acmeco" dev

# Create namespace "acmeco/dev/robocop"
vault namespace create -namespace="acmeco/dev" robocop

# Create policy for issuing certificates 
vault policy write -namespace=acmeco/dev/robocop issue_cert - << EOF
path "pki/issue/rsa_client_only" {
    capabilities = ["update"]
}
EOF

# Enable approle
vault auth enable -namespace=acmeco/dev/robocop approle

# Create role1 in approle
vault write -namespace=acmeco/dev/robocop auth/approle/role/role1 token_policies="issue_cert" secret_id_ttl=10m

# Get role id
role_id=$(vault read -format=json -namespace=acmeco/dev/robocop auth/approle/role/role1/role-id  | jq -r .data.role_id)

echo "role ID is: $role_id"

# Get secret id
secret_id=$(vault write -namespace=acmeco/dev/robocop -format json -f auth/approle/role/role1/secret-id | jq -r '.data.secret_id')

echo "Secret ID is: $secret_id"

# Get token from approle with policy to issue certs
VAULT_TOKEN_LIMITED=$(vault write -format=json -namespace=acmeco/dev/robocop auth/approle/login role_id=$role_id secret_id=$secret_id | jq -r .auth.client_token )

echo "Limited Token is: $VAULT_TOKEN_LIMITED"

# Enable PKI
vault secrets enable -namespace=acmeco/dev/robocop pki

# Configure PKI
vault write -namespace=acmeco/dev/robocop pki/root/generate/internal \
    common_name=my-ca.com \
    ttl=8760h

# Create PKI role
vault write -namespace=acmeco/dev/robocop pki/roles/rsa_client_only \
    allowed_domains=testing-cert.com \
    allow_subdomains=true \
    max_ttl=72h