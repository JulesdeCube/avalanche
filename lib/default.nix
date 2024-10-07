{ lib }:
rec {
  /**
    Function to generate a nixos module that set the hostName and the domain
    base on the `fqdn` parameter.

    # Inputs

    `fqdn`

    : Full qualiter domaine name of the host.

    # Type

    ```
    mkMostNameModule :: String -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.mkHostNameModule` usage example

    ```nix
    hostNameModule "host1.example.com"
    => { networking = { hostName = "host1"; domain = "example.com"; }; }
    hostNameModule "host1"
    => { networking = { hostName = "host1"; domain = null; }; }
    ```

    :::
  */
  mkHostNameModule = fqdn:
    let
      # Get each label that compose the fqdn (label1.label2.lable3).
      labels = lib.splitString "." fqdn;
    in
    {
      networking = {
        # The hostname of the first label of the fqdn.
        hostName = builtins.elemAt labels 0;
        domain =
          # The domain is null if there is only one (it's the hostname).
          if (builtins.length labels) == 1 then
          # Null if the default non value.
            null
          else
          # Otherwith rebuild the domain without the first label.
            lib.intersperse "." (lib.drop 1 labels);
      };
    };

  /**
    Modules use to define group in an Inventory.

    This module is useless without the use of [`mkInventory`](#mkInventory).

    # Inputs

    # Type

    ```
    groupModule :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.groupModule` usage example

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
  */
  groupModule = { lib, ... }:
    # Get lib to get typoes and mkOption
    with lib; {
      # Generate the groups option.
      options.groups = mkOption {
        # The groups option is the the names of the groups to bypass any
        # possible multi instantionation of the same groupe.
        type = types.listOf types.string;
        # By default incude no group (make the option optional).
        default = [ ];
        # Descrition of the module (use mdDoc to use markdown).
        description = lib.mdDoc ''
          List of group of the host.
        '';
      };
      # Don't incude a `config` block because it will we used externaly durring
      # inventory generation.
    };

  /**
    Generate the attributs set of group and group name.

    # Inputs

    `groups`

    : Attribute set of all the group and their configurations.


    # Type

    ```
    genGroupsNames :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.genGroupsNames` usage example

    ```nix
    lib.genGroupsNames { group1 = {...}: {}; group2 = {...}: {}}
    => { group1 = "group1"; group2 = "group2"; }
    ```

    :::
  */
  genGroupsNames =
    # The group input parmeter is not explicite as mapAttrs take 2 parameter by
    # default (partial application).
    builtins.mapAttrs (name: _: name);

  /**
    Check if a system configuration define that it is in the given group.

    # Inputs

    `system`

    : System configuration generated from [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
      with the [`groupModule`](#groupModule).

    `groupName`

    : Name of the group that must be check.


    # Type

    ```
    isInGroup :: AttrSet -> String -> Bool
    ```

    # Examples
    :::{.example}
    ## `lib.isInGroup` usage example

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
  */
  isInGroup = system: groupName:
    # Check that the group name is in the group option of the system
    # configuration.
    builtins.elem groupName system.config.groups;

  /**
    Filter a attribute set of system configuration base on the membership of a
    group.

    # Inputs

    `system`

    : System configuration generated from [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
      with the [`groupModule`](#groupModule).

    `groupName`

    : Name of the group that the system must be member.


    # Type

    ```
    getGroupMembers :: AttrSet -> String -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.getGroupMembers` usage example

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
  */
  getGroupMembers = systems: groupName:
    lib.filterAttrs (_: system: isInGroup system groupName) systems;

  /**
    Generate each system configuration base on the input configuration and the
    groups.

    # Inputs

    `groups`

    : Attribut set of group name and there respective configuration.

    `hosts`

    : Attribut set of host configuration like in [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)].

    # Type

    ```
    mkInventory :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.mkInventory` usage example

    ```nix
    lib.mkInventory {
      groups =
        let
          getIP = value: (builtins.elemAt value.config.networking.interfaces.eno1.ipv4.addresses 0).address;
        in {
        group1 = {members, ...}: {
          services.nginx = {
            enable = true;

            upstreams.backend.servers = lib.mapAttrs' ( _: value: lib.nameValuePair (getIP value) { }) members;
            virtualHosts._.locations."/".proxyPass = "http://backend";
          };

          nixpkgs.hostPlatform = "x86_64-linux";
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
  */
  mkInventory =
    { groups ? { }
    , hosts ? { }
    }:
    let
      # Partialy apply the function with the hosts.
      getGroupMembers' = getGroupMembers finalSystems;

      # Generate all the group name with the group configuration.
      groupsNames = genGroupsNames groups;
      # Get the attribut set for each group of memeber system configuration.
      groupsMembers = builtins.mapAttrs (_: getGroupMembers') groupsNames;

      # Function to generate base system from the given configuration and fqdn.
      mkBaseSystem = fqdn: config:
        # Use nixpkgs nixosSystem function generate the base configuration.
        lib.nixosSystem {
          # Add extra agrument (depricated) to get list of groups the members of
          # each group and the list of every systems.
          extraArgs = {
            # Attribute set of every group (and they name).
            groups = groupsNames;
            # Attribute set of every group memebers.
            groupsMembers = groupsMembers;
            # Attribute set of every hosts.
            hosts = finalSystems;
          };
          modules = [
            # Generate the hostname module base on the fqdn given via the
            # attribut set.
            (mkHostNameModule fqdn)
            # Add group module to be able to define the `groups` option.
            groupModule
            # The input configuration from the user.
            config
          ];
        };
      # Function to apply a group to a base system (by it's base name).
      applyGroup = system: groupName:
        # Use the nixosSystem.extendModules fonction to apply the group.
        system.extendModules {
          # Apply special agument base on the group.
          specialArgs = {
            # Get the name of the apply group.
            groupName = groupName;
            # Get the members of the apply group.
            members = groupsMembers.${groupName};
            # Attribut set of every groups.
            groups = groupsNames;
            # Attribut set of every groups members.
            groupsMembers = groupsMembers;
            # Attribut set of every hosts.
            hosts = finalSystems;
          };
          # Apply the given group.
          modules = [ groups.${groupName} ];
        };
      # Function that apply every groups define in Groups to the base configuration.
      applyGroups = _: baseSystem:
        let
          # Get the list of system group for this host.
          systemGroups = baseSystem.config.groups;
        in
        # Begin with the base system and apply group by group.
        builtins.foldl' applyGroup baseSystem systemGroups;

      # Generate all the base system configuration by applying the input
      # configuration with some base module.
      baseSystems = builtins.mapAttrs mkBaseSystem hosts;
      # Apply the groups configuration base of the groups option of each system.
      finalSystems = builtins.mapAttrs applyGroups baseSystems;
    in
    # Return the result after applying the host configuration and the group
      # configuration.
    finalSystems;
}
