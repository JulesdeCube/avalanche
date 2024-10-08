# Inventory

An inventory is a collection of [host](./host.md) it use the
[`lib.mkInventory`](./lib#mkInventory) to generate the set of
[NixosSystems](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L22) for
each system.

## Definition

It's compose of 3 arguements:

- `defaultModules`: List of [avalanche host modules](./docs/host.md#module) that
  will be apply to each hosts.
- `extraArgs`: attribut set pass to [NixosSystems](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L22)
  to pass extra argument to the modules.
- `group`: attribut set of [avalanche group modules](./docs/group.md#module)
  that will be apply to hosts that are apparte of the group.
- `hosts`: the host specific [avalanche host modules](./docs/host.md#module).

## Example

```nix
lib.mkInventory {
  extraArgs = {};
  defaultModules = [];
  groups = { };
  hosts = { };
}
```
