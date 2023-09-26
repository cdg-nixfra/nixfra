# TODO

## Must

* [x] Standard NixOS image.
* [x] Setup an EC2 Github builder in infra
* [x] Cloud-init to start Github thingy.
* [x] Give builder instance role to allow image builds
* [ ] Networking access between VPCs
* [x] SSH Key management.
* [ ] Nix Key management.

      nix.conf secret-key-files: space-sep'd secret key _files_
      nix.conf trusted-public-keys: space-sep'd public key _values_
* [ ] Add cross-account bucket access to admin permission set in SSO
* [ ] Terraform provisioning role?

* [x] Test phoenix application
* [ ] Github thingy to build that thing on EC2 builder
* [ ] nix-copy-closure. Push? Pull? How do we release?
* [ ] There is a service.nix now included in the store  but do we want that? Our own
      supervisor? Existing supervisor? It's almost too simple to write an Elixir version.

## Should

* [ ] create AMI script to Terraform so we can use the output
* [ ] Write AMI somewhere and share it with accounts
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ami_launch_permission

## Could

* [ ] Purge old AMIs

## Would

* [ ] Allow EC2 Github builder to kick off new AMIs
