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
resource "aws_iam_role" "client_key_access" {
  name               = "client_key_access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = module.management_state.staging_account_id
        }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = module.management_state.production_account_id
        }
      }
    ]
  })

  inline_policy {
    name = "client_key_access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["secretsmanager:GetSecretValue"]
          Effect   = "Allow"
          Resource = data.aws_secretsmanager_secret.builder_client_key.arn
        }
      ]
    })
  }
}
