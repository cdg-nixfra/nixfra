#!/usr/bin/env sh

umask 007

secret=`mktemp`
public=`mktemp`

trap "rm $secret $public" 0

nix-store --generate-binary-cache-key infrax-builder.1 $secret $public

aws secretsmanager create-secret --name "nixfra/infra/builder/nix_signing_key" >&/dev/null
aws secretsmanager put-secret-value \
  --secret-id "nixfra/infra/builder/nix_signing_key" \
  --secret-string "$(cat $secret)"

cp $public nix_binary_cache_key.pub
