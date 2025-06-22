# Inventory

An inventory is a collection of [host](./host.md) it use the
[`lib.mkInventory`](./lib#mkInventory) to generate the set of
[NixosSystems](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L22) for
each system.

## Definition

It's compose of 5 arguments:

- `defaultModules`: List of [avalanche host modules](./docs/host.md#module) that
  will be apply to each hosts.
- `overlays`: List of [overlays](https://wiki.nixos.org/wiki/Overlays) to add to
  the [`nixpkgs.overlay`](https://search.nixos.org/options?show=nixpkgs.overlays)
  options of each hosts.
- `extraArgs`: Attribut set pass to [NixosSystems](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L22)
  to pass extra argument to the modules.
- `group`: Attribut set of [avalanche group modules](./docs/group.md#module)
  that will be apply to hosts that member of the group.
- `hosts`: The map of hosts name and they [avalanche host modules](./docs/host.md#module).

## Example

```nix
lib.mkInventory {
  extraArgs = {};
  overlays = [];
  defaultModules = [];
  groups = { };
  hosts = { };
}
```
