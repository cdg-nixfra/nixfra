#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash awscli2 jq

# Setup host keys

cd /etc/ssh

rm -f ssh_host_*_key*

aws secretsmanager get-secret-value \
    --secret-id "nixfra/infra/builder/rsa_host_key"  |
    jq -r .SecretString >ssh_host_rsa_key
aws secretsmanager get-secret-value \
    --secret-id "nixfra/infra/builder/ed25519_host_key"  |
    jq -r .SecretString >ssh_host_ed25519_key

chmod 400 ssh_host*
ssh-keygen -y -f ssh_host_rsa_key >ssh_host_rsa_key.pub
ssh-keygen -y -f ssh_host_ed25519_key >ssh_host_ed25519_key.pub

systemctl restart sshd

# Setup Nix signing key

aws secretsmanager get-secret-value \
    --secret-id "nixfra/infra/builder/nix_signing_key"     |
    jq -r .SecretString >/etc/nix/signing_key
``
chmod 400 /etc/nix/signing_key
