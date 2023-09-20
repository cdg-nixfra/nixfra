resource "aws_s3_bucket" "state" {
  bucket = "nixfra-infra-tfstate"
}

import {
  to = aws_s3_bucket.state
  id = "nixfra-infra-tfstate"
}

# Host key goes in S3 so we can have services verify
# the host.
resource "aws_s3_object" "host_key" {
  bucket  = aws_s3_bucket.state.id
  key     = "staging/builder/host_key"
  content = tls_private_key.host_key.public_key_openssh
}

# Public Nix key goes in S3 so we can have services import
# from its store.
resource "aws_s3_object" "nix_key" {
  bucket   = aws_s3_bucket.state.id
  key      = "staging/builder/nix_key"
  content  = file("nix-binary-cache-key.pub")
}

data "aws_iam_policy_document" "allow_state_access" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        module.management_state.staging_account_id,
        module.management_state.production_account_id
      ]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.state.arn}/${aws_s3_object.host_key.key}",
      "${aws_s3_bucket.state.arn}/${aws_s3_object.nix_key.key}"
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_state_access" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.allow_state_access.json
}
