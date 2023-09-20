{ pkgs ? import <nixpkgs> {} }:

with pkgs;

mkShell {
  buildInputs = [
    bash
    direnv
    jq
    mustache-go
    nixos-generators
    terraform
    awscli2
    github-cli
  ];

  shellHook = ''
    eval "$(direnv hook bash)"
    export TF_VAR_region=ca-central-1
    alias instances="aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'"
  '';
}
