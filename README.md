# Avalanche

Avalanche is a [nix](https://nixos.org/) [flake](https://wiki.nixos.org/wiki/Flakes)
library to generate complex NixOS configuration.

## Inspiration

This project is inspire by [Ansible](https://www.ansible.com/) the defunct
[NixOps](https://github.com/NixOS/nixops) project.

## Getting started

### Instalation

You can use Avalanche by incuding it in your falke input and laoding it's
library.

```nix
{
  inputs = {
    avalanche.url = "git+https://gitlab.julesdecube.com/infra/avalanche.git";
    ...
  };

  output = { avalanche, ... }:
    let
      # Import the avalanche library.
      inherit (avalanche) lib;
    in {
      ...
    };
}
```

### Usage

The main library function is `mkInventory` it generate Nixos System like the
[`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
function but with the adition of groups:

```nix
lib.mkInventory {
  defaultModules = [];
  groups = { };
  hosts = { };
}
```

- `defaultModules`: List of [avalanche host modules](./docs/host.md#module) that
  will be apply to each hosts.
- `group`: attribut set of [avalanche group modules](./docs/group.md#module)
  that will be apply to hosts that are apparte of the group.
- `hosts`: the host specific [avalanche host modules](./docs/host.md#module).

### Example

following a `flake.nix` to deploy a loadbalanced dns server:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos";
    avalanche.url = "git+https://gitlab.julesdecube.com/infra/avalanche.git";
  };

  outputs = { nixpkgs, avalanche, ... }:
    let
      getIP = system: (builtins.elemAt system.config.networking.interfaces.eno1.ipv4.addresses 0).address;
    in
    {
      nixosConfigurations = avalanche.lib.mkInventory {
        defaultModules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
        ];

        groups = {
          dns = { pkgs, hosts, ... }: {
            services.bind = {
              enable = true;
              zones."example.com" = {
                master = true;
                file = pkgs.writeText "zone-example.com" ''
                  $ORIGIN example.com.
                  @            IN      SOA     ns1 hostmaster ( 1 3h 1h 1w 1h)
                               IN      NS      ns1
                  ns1          IN      A       ${getIP hosts.lb01}
                '';
              };
            };
          };
        };

        hosts = {
          ns01 = { groups, ... }: {
            groups = [ groups.dns ];
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.9"; prefixLength = 24; }];
          };
          ns02 = { groups, ... }: {
            groups = [ groups.dns ];
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.8"; prefixLength = 24; }];
          };

          lb01 = { groups, groupsMembers, ... }: {
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];
            services.dnsdist =
              let
                mkServer = name: system: ''
                  newServer({address=${getIP system}, name="${name}"})
                '';
                servers = builtins.attrValues (builtins.mapAttrs mkServer groupsMembers.dns);
              in
              {
                enable = true;
                listenPort = 53;
                extraConfig = ''
                  setServerPolicy(roundrobin)
                  ${nixpkgs.lib.concatStrings servers}
                '';
              };
          };
        };
      };
    };
}
```

You can found more example in the [`example` folder](./examples/).

## Documentation

You can found the project documentation inside the [`docs` folder](./docs/index.md)
