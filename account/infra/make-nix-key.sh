#!/usr/bin/env sh

umask 007

secret=`mktemp`
public=`mktemp`

trap "rm $secret $public" 0

nix-store --generate-binary-cache-key infrax-builder.1 $secret $public

aws secretsmanager put-secret-value \
  --secret-id "staging/builder/nix_ssh_serve_key" \
  --secret-string "$(cat $secret)"

cp $public nix-binary-cache-key.pub
