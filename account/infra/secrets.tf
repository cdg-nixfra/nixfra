# Private key goes into secrets manager so we can use it
# to pull closures.
resource "aws_secretsmanager_secret" "nix_ssh_serve" {
  name = "staging/builder/nix_ssh_serve_key"
}

# No secret version, key creation with Terraform is not recommended. See make-nix-key.sh

data "aws_iam_policy_document" "allow_secret_access" {
    statement {
    sid    = "EnableAnotherAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
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
