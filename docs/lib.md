# Avalanche library {#sec-functions-library-inventory}


## `lib.inventory.mkHostNameModule` {#function-library-lib.inventory.mkHostNameModule}

Function to generate a nixos module that set the hostName and the domain
base on the `fqdn` parameter.

### Inputs

`fqdn`

: Full qualiter domaine name of the host.

### Type

```
mkMostNameModule :: String -> AttrSet
```

### Examples
:::{.example}
#### `lib.mkHostNameModule` usage example

```nix
hostNameModule "host1.example.com"
=> { networking = { hostName = "host1"; domain = "example.com"; }; }
hostNameModule "host1"
=> { networking = { hostName = "host1"; domain = null; }; }
```

:::

## `lib.inventory.groupModule` {#function-library-lib.inventory.groupModule}

Modules use to define group in an Inventory.

This module is useless without the use of [`mkInventory`](#mkInventory).

### Inputs

### Type

```
groupModule :: AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.groupModule` usage example

```nix
nixpkgs.lib.nixosSystem {
  imports = [
    lib.groupModule
    {
      groups = [ "group1" ];
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
=> {
  _module = { ... };
  _type = "configuration";
  class = "nixos";
  config = { ... };
  extendModules = «lambda @ ...»;
  extraArgs = { ... };
  lib = { ... };
  options = { ... };
  pkgs = { ... };
  type = { ... };
}
```

:::

## `lib.inventory.genGroupsNames` {#function-library-lib.inventory.genGroupsNames}

Generate the attributs set of group and group name.

### Inputs

`groups`

: Attribute set of all the group and their configurations.


### Type

```
genGroupsNames :: AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.genGroupsNames` usage example

```nix
lib.genGroupsNames { group1 = {...}: {}; group2 = {...}: {}}
=> { group1 = "group1"; group2 = "group2"; }
```

:::

## `lib.inventory.isInGroup` {#function-library-lib.inventory.isInGroup}

Check if a system configuration define that it is in the given group.

### Inputs

`system`

: System configuration generated from [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
  with the [`groupModule`](#groupModule).

`groupName`

: Name of the group that must be check.


### Type

```
isInGroup :: AttrSet -> String -> Bool
```

### Examples
:::{.example}
#### `lib.isInGroup` usage example

```nix
lib.isInGroup (nixpkgs.lib.nixosSystem {
  imports = [
    lib.groupModule
    {
      groups = [ "group1" ];
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ]) "group1";
=> true
lib.isInGroup (nixpkgs.lib.nixosSystem {
  imports = [
    lib.groupModule
    {
      groups = [ "group1" ];
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ]
}) "group2";
=> false
```

:::

## `lib.inventory.getGroupMembers` {#function-library-lib.inventory.getGroupMembers}

Filter a attribute set of system configuration base on the membership of a
group.

### Inputs

`system`

: System configuration generated from [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
  with the [`groupModule`](#groupModule).

`groupName`

: Name of the group that the system must be member.


### Type

```
getGroupMembers :: AttrSet -> String -> AttrSet
```

### Examples
:::{.example}
#### `lib.getGroupMembers` usage example

```nix
lib.getGroupMembers {
  host1 = nixpkgs.lib.nixosSystem {
    imports = [ lib.groupModule { groups = [ "group1" ]; nixpkgs.hostPlatform = "x86_64-linux"; }];
  };
  host2 = nixpkgs.lib.nixosSystem {
    imports = [ lib.groupModule { groups = [ "group2" ]; nixpkgs.hostPlatform = "x86_64-linux"; }];
  };
  host3 = nixpkgs.lib.nixosSystem {
    imports = [ lib.groupModule { groups = [ "group3" ]; nixpkgs.hostPlatform = "x86_64-linux"; }];
  };
}) "group1";
=> { host1 = {...}; host3 = {...}; }
```

:::

## `lib.inventory.mkInventory` {#function-library-lib.inventory.mkInventory}

Generate each system configuration base on the input configuration and the
groups.

### Inputs

`extraArgs`

: Attribut set to append to [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)]
  `extraArgs` arguements.

`defaultModules`

: List of avalanche host modules that will be apply to every hosts.

`groups`

: Attribut set of group name and there respective configuration.

`hosts`

: Attribut set of host configuration like in [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)].

### Type

```
mkInventory :: AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.mkInventory` usage example

```nix
lib.mkInventory {
  extraArgs = {
    backendName = "backend";
  };

  defaultModules = [ {
    nixpkgs.hostPlatform = "x86_64-linux";
  } ];

  groups =
    let
      getIP = value: (builtins.elemAt value.config.networking.interfaces.eno1.ipv4.addresses 0).address;
    in {
    group1 = {members, backendName, ...}: {
      services.nginx = {
        enable = true;

        upstreams.${backendName}.servers = lib.mapAttrs' ( _: value: lib.nameValuePair (getIP value) { }) members;
        virtualHosts._.locations."/".proxyPass = "http://${backendName}";
      };
    };
  };

  hosts = {
    host1 = { groups, ... }: {
      groups = [ groups.group1 ];

      networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];
    };

    host2 = { groups, ... }: {
      groups = [ groups.group1 ];

      networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.2"; prefixLength = 24; }];
    };
  };
};
=> { host1 = {...}; host2 = {...}; }
```

:::

