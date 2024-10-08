# Host

A host is the base element of an [inventory](./inventory.md). It's a NixOS
system configuration with some extra module and arguements.

## Module

An avalanche host module is a [NixOS module](https://wiki.nixos.org/wiki/NixOS_modules)
with some extra aguments:

- `groups`: attribut set of each groups and it's name.
- `groupsMembers`: attribut set of group members by group name.
- `hosts`: final system configuration of every hosts

It's also used in the [`defaultModules`](./inventory.md#definition) attirbute of
an [inventory](./inventory.md).

### Example

```nix
{ groups
, groupsMembers
, hosts
  # nixos module arguments
, pkgs
, lib
, ...
}: {
    # NixOS configuration
}
```
