# Nixfra main repo

## Goals

Trying to push the envelope a bit. Maybe not practical, but:

* What is the minimal set of components to get infra-as-code with stuff like full reproducibility built-in?
* Why are we slaving away in terrible templating languages if we have Elixir?
* Just how fast can you make a CI/CD pipeline?

## Design

A very minimal terraform setup with two main moving parts:

* An infra account that essentially launches a GitHub Action Runner running on NixOS. This runner attaches to the
  org and ensures that all jobs are executed on NixOS instead of some silly bloated container. A DIY runner also
  gets rid of all the caching complexity, the Nix store does a much better job.

* Staging/production/... accounts that deploy a standard VPC with NixOS EC2 instances. The EC2 instances run
  "Deployinator" which is a very simple Elixir service that will fetch new releases and run them. Deployinator
  clusters based on EC2 tags and uses Erlang clustering to ensure a rolling release.

## Principles

Simplicity. Every moving part is necessary, nothing is chosen because people on HackerNews say so. Less moving parts
is less chance for things to go wrong.

Speed. Five minutes between merge and finished deploy is the hard max. One minute is closer to the goal. Note that
this depends to a large extent on the codebase being deployed.

Self-contained. No external dependencies beyond NixOS. All scripts fully declare their needs, which means that this
can eventually run on a completely stripped down version of NixOS.

### Security

Zero trust. Everything runs in public subnets (for the purposes of this PoC).

Zero touch. There's no bootstrap manual copying of secrets.

## How it works.

We deploy standard AMIs using NixOS' "amazon-init" service. This interprets the userdata as a NixOS configuration
and proceeds by installing it and rebuilding NixOS with it. With this, we can bootstrap either a GitHub runner
or Deployinator. All the TF needed is just "whip up VPC and an EC2 instance".

Building (nixfra_phx is the demo project) is just a `nix-build` on an as-native-as-possible build setup. For
Elixir/Phoenix, we use Nixpkg's [BEAM Languages](https://ryantm.github.io/nixpkgs/languages-frameworks/beam/) support
using `mixRelease` with `mixNixDeps` generated by `mix2nix`. This is very fast by default as dependencies are
locked down and cached, the release building essentially becomes hardlinking .beam files into the store output.

The result is a store URL that can be shared. Here's options: we can push it to target machines, target machines
can pull it, etc. The important part is that we just need the store path.

Deployinator will "somehow" learn of the new store path and will copy in the closure. It expects two scripts in the
result: `bin/serve` and `bin/migrate`. Its userdata also drops a configuration file that tells it whethe this is a
"headful" service or not, for headful services it will talk to ALB. The process then becomes:

* Ensure the closure is on the local box
* Take the cluster migration lock. With the lock:
  * Run `bin/migrate`
* Take the cluster upgrade lock. With the lock:
  * Remove localhost from ALB
  * Take down service
  * Bring up new service
  * Wait a bit and then ping health endpoint
  * When healthy, add localhost to ALB

Thanks to the cluster upgrade locking, this happens in a rolling fashion over the cluster.

Deployinator supervises services directly. This is not some hack, projects like [Nerves](https://nerves-project.org/) have done this for years. [Erlexec](https://github.com/saleyn/erlexec) is a rock solid solution for this and makes managing
external processes as reliable as managing/supervising regular BEAM processes.

## Crazy ideas

* Make Deployinator the init process. Who needs systemd on a simple backend server?
* Remove GitHub. Any push on main with two authorized signatures straight to the builder gets the green light.
* Remove build machines. Building is probably so cheap that it can be done with spare capacity on backend servers, using
  peer-to-peer distribution of Nix closures.
