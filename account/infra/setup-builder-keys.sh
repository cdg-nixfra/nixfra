#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bash awscli2 jq

# Setup host keys

rm -f /etc/ssh/ssh_host_*_key*

aws secretsmanager get-secret-value \
    --secret-id "staging/builder/rsa_host_key"  |
    jq -r .SecretString >/etc/ssh/ssh_host_rsa_key
aws secretsmanager get-secret-value \
    --secret-id "staging/builder/ed25519_host_key"  |
    jq -r .SecretString >/etc/ssh/ssh_host_ed25519_key

chmod 400 /etc/ssh/ssh_host*

systemctl restart sshd

# Setup Nix keys

aws secretsmanager get-secret-value \
    --secret-id "staging/builder/nix_ssh_serve_key"     |
    jq -r .SecretString >/etc/nix/ssh_serve_key.conf
``
chmod 400 /etc/nix/ssh_server_key.conf
