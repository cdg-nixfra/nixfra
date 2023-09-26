#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash awscli2 jq

# TODO Template this

cd /etc
umask 077

credentials=$(aws sts assume-role --role-arn arn:aws:iam::796253384641:role/client_key_access --role-session-name client_key_access)
export AWS_ACCESS_KEY_ID=$(echo $credentials | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $credentials | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $credentials | jq -r .Credentials.SessionToken)

aws secretsmanager get-secret-value \
    --secret-id arn:aws:secretsmanager:ca-central-1:796253384641:secret:nixfra/infra/builder_client_key |
    jq -r .SecretString >/etc/builder_client_key
