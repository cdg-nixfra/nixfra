# Declare and import keys created with the make-*key.sh scripts.
# We don't want secrets to touch Terraform state so we generate things
# outside of it. These resources normally get terraform-imported by
# the shellscripts.
data "aws_secretsmanager_secret" "nix_signing_key" {
  name = "nixfra/infra/builder/nix_signing_key"
}

data "aws_secretsmanager_secret" "rsa_host_key" {
  name = "nixfra/infra/builder/rsa_host_key"
}

data "aws_secretsmanager_secret" "ed25519_host_key" {
  name = "nixfra/infra/builder/ed25519_host_key"
}

data "aws_secretsmanager_secret" "builder_client_key" {
  name = "nixfra/infra/builder_client_key"
}

# Allow staging account to get secrets they need.
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

    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      data.aws_secretsmanager_secret.builder_client_key.arn
    ]
  }
}

resource "aws_secretsmanager_secret_policy" "allow_secret_access" {
  secret_arn = data.aws_secretsmanager_secret.nix_signing_key.arn
  policy     = data.aws_iam_policy_document.allow_secret_access.json
}
