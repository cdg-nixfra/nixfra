resource "aws_s3_bucket" "state" {
  bucket = "nixfra-infra-tfstate"
}

import {
  to = aws_s3_bucket.state
  id = "nixfra-infra-tfstate"
}

# Public keys goes in S3 so we can have services use it for verification

locals {
  keys = [
    "ed25519_host_key",
    "rsa_host_key",
    "nix_binary_cache_key"
  ]
}

resource "aws_s3_object" "public_key" {
  for_each     = toset(local.keys)
  bucket       = aws_s3_bucket.state.id
  key          = "infra/builder/${each.key}.pub"
  content      = file("${each.key}.pub")
  content_type = "text/plain"
}

# Not needed by clients, we stash it in S3 in case we need it
# somewhere else.
resource "aws_s3_object" "client_key" {
  bucket       = aws_s3_bucket.state.id
  key          = "infra/builder_client_key.pub"
  content      = file("builder_client_key.pub")
  content_type = "text/plain"
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
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionAttributes"
    ]

    resources = [
      "${aws_s3_bucket.state.arn}/infra/builder/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_state_access" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.allow_state_access.json
}
