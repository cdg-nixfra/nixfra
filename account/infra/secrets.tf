# Private key goes into secrets manager so we can use it
# to pull closures.
resource "aws_secretsmanager_secret" "nix_ssh_serve" {
  name = "staging/builder/nix_ssh_serve_key"
}

resource "aws_secretsmanager_secret" "rsa_host_key" {
  name = "staging/builder/rsa_host_key"
}

resource "aws_secretsmanager_secret" "ed25519_host_key" {
  name = "staging/builder/ed25519_host_key"
}

# No secret versions, key creation with Terraform is not recommended. See make-nix-key.sh
# and make-ssh-keys.sh

# TODO this is not correct yet.
data "aws_iam_policy_document" "allow_secret_access" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        module.management_state.staging_account_id,
        module.management_state.production_account_id
      ]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "allow_secret_access" {
  secret_arn = aws_secretsmanager_secret.nix_ssh_serve.arn
  policy     = data.aws_iam_policy_document.allow_secret_access.json
}
