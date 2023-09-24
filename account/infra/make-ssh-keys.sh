#!/usr/bin/env sh

ed25519=`mktemp`
rsa=`mktemp`
client=`mktemp`

umask 007

trap "rm $ed25519 $rsa $client" 0

rm $ed25519 $rsa $client
ssh-keygen -t rsa -N '' -f $rsa -C infrax-staging-builder
ssh-keygen -t ed25519 -N '' -f $ed25519 -C infrax-staging-builder
ssh-keygen -t rsa -N '' -f $client -C infrax-builder-client

aws secretsmanager create-secret --name "nixfra/infra/builder/rsa_host_key" >&/dev/null
aws secretsmanager create-secret --name "nixfra/infra/builder/ed25519_host_key" >&/dev/null
aws secretsmanager create-secret --name "nixfra/infra/builder_client_key" >&/dev/null
aws secretsmanager put-secret-value \
  --secret-id "nixfra/infra/builder/rsa_host_key" \
  --secret-string "$(cat $rsa)"
aws secretsmanager put-secret-value \
  --secret-id "nixfra/infra/builder/ed25519_host_key" \
  --secret-string "$(cat $ed25519)"
aws secretsmanager put-secret-value \
  --secret-id "nixfra/infra/builder_client_key" \
  --secret-string "$(cat $client)"

cp $ed25519.pub ed25519_host_key.pub
cp $rsa.pub rsa_host_key.pub
cp $client.pub builder_client_key.pub
