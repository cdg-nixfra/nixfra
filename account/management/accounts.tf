resource "aws_organizations_organization" "organization" {
  aws_service_access_principals = [
    "sso.amazonaws.com"
  ]
  feature_set = "ALL"
}

# Unused, slated to be deleted, we use SSO in the management account
# instead
resource "aws_organizations_account" "users" {
  name      = "nixfra-users"
  email     = "cg+users2@cdegroot.ca"
  role_name = "Admin"
}

# Central stuff - builders, logging.
resource "aws_organizations_account" "infra" {
  name      = "nixfra-infra"
  email     = "cg+infra@cdegroot.ca"
  role_name = "Admin"
}

# Pre-production
resource "aws_organizations_account" "staging" {
  name      = "nixfra-staging"
  email     = "cg+staging@cdegroot.ca"
  role_name = "Admin"
}

# Production
resource "aws_organizations_account" "production" {
  name      = "nixfra-production"
  email     = "cg+production@cdegroot.ca"
  role_name = "Admin"
}

provider "aws" {
  profile = "nixfra-production"
  alias   = "production"
  region  = var.region
}

provider "aws" {
  profile = "nixfra-staging"
  alias   = "staging"
  region  = var.region
}

provider "aws" {
  profile = "nixfra-infra"
  alias   = "infra"
  region  = var.region
}

data "aws_ssoadmin_instances" "sso" {}

resource "aws_identitystore_group" "admin" {
  display_name      = "Admin"
  description       = "AWS Infra Administrators"
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
}

resource "aws_identitystore_user" "cees" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]

  display_name = "Cees de Groot"
  user_name    = "cees"

  name {
    given_name  = "Cees"
    family_name = "de Groot"
  }

  emails {
    value = "cg+infraxadmin@cdegroot.ca"
  }
}

resource "aws_identitystore_group_membership" "cees_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = aws_identitystore_user.cees.user_id
}

module "sso" {
  source = "avlcloudtechnologies/sso/aws"
  depends_on = [
    aws_identitystore_group.admin
  ]

  permission_sets = {
    AdministratorAccess = {
      description      = "Provides full access to AWS services and resources.",
      session_duration = "PT12H",
      managed_policies = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
    }
  }
  account_assignments = [
    {
      principal_name = "admin"
      principal_type = "GROUP"
      permission_set = "AdministratorAccess"
      account_ids = [
        207298744613, # management account
        aws_organizations_account.infra.id,
        aws_organizations_account.staging.id,
        aws_organizations_account.production.id
      ]
    }
  ]
}

resource "local_file" "account_ids" {
  content  = <<EOF
output "infra_account_id" {
  value = "${aws_organizations_account.infra.id}"
}
output "staging_account_id" {
  value = "${aws_organizations_account.staging.id}"
}
output "production_account_id" {
  value = "${aws_organizations_account.production.id}"
}
EOF
  filename = "../management-state/account_ids.tf"
}
