#!/usr/bin/env sh

ed25519=`mktemp`
rsa=`mktemp`

trap "rm $ed25519 $rsa" 0

rm $ed25519 $rsa
ssh-keygen -t rsa -N '' -f $rsa -C infrax-staging-builder
ssh-keygen -t ed25519 -N '' -f $ed25519 -C infrax-staging-builder

aws secretsmanager put-secret-value \
  --secret-id "staging/builder/rsa_host_key" \
  --secret-string "$(cat $rsa)"
aws secretsmanager put-secret-value \
  --secret-id "staging/builder/ed25519_host_key" \
  --secret-string "$(cat $ed25519)"

cp $ed25519.pub ed25519_host_key.pub
cp $rsa.pub rsa_host_key.pub
