# Group

A group is a configuration that will be apply to a set of the
[inventory](./inventory.md) [hosts](./host.md), base on the custom
[groups](./host.md#options) option.

A group is define by a name and it's avalanche group module.

## Module

An avalanche group module is a [NixOS module](https://wiki.nixos.org/wiki/NixOS_modules)
with some extra aguments:

- `groupName`: name of the applied group.
- `members`: attribut set of system configuration of each member of the group.
- `groups`: attribut set of each groups and it's name.
- `groupsMembers`: attribut set of group members by group name.
- `hosts`: final system configuration of every hosts

### Example

```nix
{ groupName
, members
, groups
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
