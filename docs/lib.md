# Avalanche library {#sec-functions-library-inventory}


## `lib.inventory.mkHostNameModule` {#function-library-lib.inventory.mkHostNameModule}

Function to generate a nixos module that set the hostName and the domain
base on the `fqdn` parameter.

### Inputs

`fqdn`

: Full qualiter domain name of the host.

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

## `lib.inventory.labelsToDomain` {#function-library-lib.inventory.labelsToDomain}

Function that convert a list of dns labels to a full qualifer domain name.

### Inputs

`lables`

: List of labels to concat.

### Type

```
labelsToDomain :: [String] -> String
```

### Examples
:::{.example}
#### `lib.labelsToDomain` usage example

```nix
labelsToDomain [ "node01", "sub-domain", "domain", "tld" ]
=> "node01.sub-domain.domain.tld"
labelsToDomain [ "node01" ]
=> "node01"
```

:::

## `lib.inventory.getFqdnInfo` {#function-library-lib.inventory.getFqdnInfo}

Parse a Full Qualifer Domain Name and retrive it's labels, hostname and
domain.

### Inputs

`fqdn`

: Full qualifer domain name to parse.

### Type

```
getFqdnInfo :: String -> {
  labels = [String];
  hostname = String;
  domain = String;
}
```

### Examples
:::{.example}
#### `lib.getFqdnInfo` usage example

```nix
getFqdnInfo "node01.sub-domain.domain.tld"
=> {
  labels = [ "node01", "sub-domain", "domain", "tld" ];
  hostname = "node01";
  domain = "sub-domain.domain.tld";
}
labelsToDomain "node01"
=> {
  labels = [ "node01" ];
  hostname = "node01";
  domain = null;
}
```

:::

## `lib.inventory.appendDomain` {#function-library-lib.inventory.appendDomain}

Append 2 domains together.

### Inputs

`domain1`

: First domain that will be append at the front.

`domain2`

: Second domain that will be append at the back.

### Type

```
appendDomain :: String -> String -> String
```

### Examples
:::{.example}
#### `lib.appendDomain` usage example

```nix
appendDomain "node01.sub-domain" "domain.tld"
=> "node01.sub-domain.domain.tld"
appendDomain "node01" ""
=> "node01"
```

:::

## `lib.inventory.setDomain` {#function-library-lib.inventory.setDomain}

Set the domain part of a FQDN.

### Inputs

`fqdn`

: The Full Qualifer Domain Name that must be modify.

`domain`

: the domain that will replace the `fqdn` domain.

### Type

```
setDomain :: String -> String -> String
```

### Examples
:::{.example}
#### `lib.setDomain` usage example

```nix
setDomain "node01.sub-domain.domain.tld" "other-domain.other-tld"
=> "node01.sub-domain.domain.tld"
setDomain "node01.sub-domain.domain.tld" ""
=> "node01"
```

:::

## `lib.inventory.mapHostsFqdn` {#function-library-lib.inventory.mapHostsFqdn}

Function to map/modify Full Qualifer Domain Name of an hosts attributs set
base on a given function.

### Inputs

`f`

: The mapping function that take the fqdn and the configuration as
  parameter.

`hosts`

: The attribut ser of hosts by the Full Qualifer Domain Name.

### Type

```
mapHostsFqdn :: (String -> (AttrSet | AttrSet -> AttrSet ) -> String) -> AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.mapHostsFqdn` usage example

```nix
mapHostsFqdn (fqdn: _: "private-${fqdn}") { runner01 = {}; runner02 = {}; }
=> { private-runner01 = {}; private-runner02 = {}; }
mapHostsFqdn (fqdn: _: nixpkgs.lib.toUpper fqdn) { ad01 = {...}: { };  dns01 = {...}: { }; }
=> { AD01 = {...}: { };  DNS01 = {...}: { }; }
```

:::

## `lib.inventory.setHostsDomain` {#function-library-lib.inventory.setHostsDomain}

Set the domain of each hosts Full Qualifer Domain Name.

### Inputs

`domain`

: The domain that must replace the current one.

`hosts`

: The attribut ser of hosts by the Full Qualifer Domain Name.

### Type

```
setHostDomain :: String -> AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.setHostsDomain` usage example

```nix
setHostsDomain "domain.tld" { runner01 = {}; runner02 = {}; }
=> { "runner01.domain.tld" = {}; "runner02.domain.tld" = {}; }
setHostsDomain "" { "ad01.example.com" = {...}: { };  }
=> { ad01 = {...}: { }; }
setHostsDomain "domain.tld" { "ad01.example.com" = {...}: { };  }
=> { "ad01.domain.tld" = {...}: { }; }
```

:::

## `lib.inventory.appendHostsDomain` {#function-library-lib.inventory.appendHostsDomain}

Append the given domain at the front of the Full Qualifer Domain Name.

### Inputs

`domain`

: The domain that must be append at the beggining of the fqdn.

`hosts`

: The attribut ser of hosts by the Full Qualifer Domain Name.

### Type

```
appendHostDomain :: String -> AttrSet -> AttrSet
```

### Examples
:::{.example}
#### `lib.appendHostsDomain` usage example

```nix
setHostsDomain "domain.tld" { runner01 = {}; runner02 = {}; }
=> { "runner01.domain.tld" = {}; "runner02.domain.tld" = {}; }
setHostsDomain "" { "ad01.example.com" = {...}: { };  }
=> { ad01.example.com = {...}: { }; }
setHostsDomain "domain.tld" { "ad01.private" = {...}: { };  }
=> { "ad01.private.domain.tld" = {...}: { }; }
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

## `lib.inventory.padStringLeft` {#function-library-lib.inventory.padStringLeft}

Function to pad a string with a padding patern to the given length by adding
padding to the left.

### Inputs

`padding`

: String that represent the patten used for padding.

`length`

: Final string length.

`str`

: String that must be pad.

### Type

```
padStringLeft :: String -> Int -> String -> String
```

### Examples
:::{.example}
#### `lib.padStringLeft` usage example

```nix
PadStringLeft " " 10 "toto"
=> "      toto"
PadStringLeft "_" 2 "toto"
=> "toto"
```

:::

## `lib.inventory.padNumber` {#function-library-lib.inventory.padNumber}

Function to pad a number with zero to achive the given length.

### Inputs

`length`

: Final length of the string.

`n`

: Number to pad

### Type

```
padNumber :: Int -> Int -> String
```

### Examples
:::{.example}
#### `lib.padNumber` usage example

```nix
PadStringLeft 5 303
=> "  303"
PadStringLeft 2 303
=> "303"
```

:::

## `lib.inventory.genId` {#function-library-lib.inventory.genId}

Function to genearate a name id.

### Inputs

`id`

: index of the server

### Type

```
genId :: Int -> String
```

### Examples
:::{.example}
#### `lib.genId` usage example

```nix
genId 1
=> "01"
genId 101
=> "101"
```

:::

## `lib.inventory.genHostname` {#function-library-lib.inventory.genHostname}

Function to generate a hostname base on a name and id.

### Inputs

`name`

: name of the

`id`

: index of the server

### Type

```
genHostname :: String -> Int -> String
```

### Examples
:::{.example}
#### `lib.genHostname` usage example

```nix
genHostname "lb" 1
=> "lb01"
genHostname "node" 20
=> "node20"
```

:::

## `lib.inventory.addSpecialArgs` {#function-library-lib.inventory.addSpecialArgs}

Function to wrap module and add extra speical argument to the call of a
function or attribut set.

### Inputs

`speicalArgs`

: attibut set of exta aguments.

`module`

: NixOS module

### Type

```
addSpecialArgs :: AttrSet -> (AttrSet | AttrSet -> AttrSet) -> String
```

### Examples
:::{.example}
#### `lib.addSpecialArgs` usage example

```nix
addSpecialArgs { a = 1; } ({ a, ... }: { b = a; })
=> { b = 1; }
addSpecialArgs { a = 1; } { b = 2; }
=> { b = 2; }
```

:::

## `lib.inventory.genHosts` {#function-library-lib.inventory.genHosts}

Function to generate an set of host with incremental hostname base on a
system configuration.

### Inputs

`config`

: the configuration that will be used for every host.

`prefix`

: prefix use before the incremental index

`number`

: number of host to generate

### Type

```
genHosts :: (AttrSet | AttrSet -> AttrSet) -> String -> Int ->  (AttrSet | AttrSet -> AttrSet)
```

### Examples
:::{.example}
#### `lib.genHosts` usage example

```nix
genHosts ({ ... }: { }) "lb" 2
=> { lb01 = {...}: { };  lb02 = {...}: { }; }
genHosts { } "empty" 0
=> {  }
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

