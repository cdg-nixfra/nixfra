#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash awscli2 jq

# TODO Setup trusted host keys
# TODO Setup our private key

#aws secretsmanager get-secret-value \
    #--secret-id "nixfra/infra/builder/rsa_host_key"  |
    #jq -r .SecretString >ssh_host_rsa_key

true
