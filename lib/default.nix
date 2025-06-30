{
  lib ? (import <nixpkgs>).lib,
}:
rec {
  /**
    Function to generate a nixos module that set the hostName and the domain
    base on the `fqdn` parameter.

    # Inputs

    `fqdn`

    : Full qualiter domain name of the host.

    # Type

    ```nix
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
  mkHostNameModule =
    fqdn:
    let
      # Parse fqdn to extract domain and hostname.
      info = getFqdnInfo fqdn;
    in
    {
      networking = {
        # Rename capitalise of hostname from info.
        hostName = info.hostname;
        # Retrive domain from info.
        inherit (info) domain;
      };
    };

  /**
    Function that convert a list of dns labels to a full qualifer domain name.

    # Inputs

    `lables`

    : List of labels to concat.

    # Type

    ```nix
    labelsToDomain :: [String] -> String
    ```

    # Examples
    :::{.example}
    ## `lib.labelsToDomain` usage example

    ```nix
    labelsToDomain [ "node01", "sub-domain", "domain", "tld" ]
    => "node01.sub-domain.domain.tld"
    labelsToDomain [ "node01" ]
    => "node01"
    ```

    :::
  */
  # There is no parameter because the concatStringSep is a partial apply
  # function.
  labelsToDomain =
    # Just concat string with ".""
    builtins.concatStringsSep ".";

  /**
    Parse a Full Qualifer Domain Name and retrive it's labels, hostname and
    domain.

    # Inputs

    `fqdn`

    : Full qualifer domain name to parse.

    # Type

    ```nix
    getFqdnInfo :: String -> {
      labels = [String];
      hostname = String;
      domain = String;
    }
    ```

    # Examples
    :::{.example}
    ## `lib.getFqdnInfo` usage example

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
  */
  getFqdnInfo =
    fqdn:
    let
      # Get each label that compose the fqdn (label1.label2.lable3).
      rawLabels = lib.splitString "." fqdn;
    in
    rec {
      # Filter empty labels.
      labels = builtins.filter (label: label != "") rawLabels;

      # The hostname of the first label of the fqdn.
      hostname = builtins.elemAt labels 0;

      # The domain is null if there is only one (it's the hostname).
      domain =
        if (builtins.length labels) == 1 then
          # Null if the default non value.
          null
        else
          # Otherwith rebuild the domain without the first label.
          labelsToDomain (lib.drop 1 labels);
    };

  /**
    Append 2 domains together.

    # Inputs

    `domain1`

    : First domain that will be append at the front.

    `domain2`

    : Second domain that will be append at the back.

    # Type

    ```nix
    appendDomain :: String -> String -> String
    ```

    # Examples
    :::{.example}
    ## `lib.appendDomain` usage example

    ```nix
    appendDomain "node01.sub-domain" "domain.tld"
    => "node01.sub-domain.domain.tld"
    appendDomain "node01" ""
    => "node01"
    ```

    :::
  */
  appendDomain =
    domain1: domain2:
    let
      # Parse first domain.
      info1 = getFqdnInfo domain1;
      # Parse second domain.
      info2 = getFqdnInfo domain2;
    in
    # Generate the combine domain by merging both labels and combined it back to
    # a string.
    labelsToDomain (info1.labels ++ info2.labels);

  /**
    Set the domain part of a FQDN.

    # Inputs

    `fqdn`

    : The Full Qualifer Domain Name that must be modify.

    `domain`

    : the domain that will replace the `fqdn` domain.

    # Type

    ```nix
    setDomain :: String -> String -> String
    ```

    # Examples
    :::{.example}
    ## `lib.setDomain` usage example

    ```nix
    setDomain "node01.sub-domain.domain.tld" "other-domain.other-tld"
    => "node01.sub-domain.domain.tld"
    setDomain "node01.sub-domain.domain.tld" ""
    => "node01"
    ```

    :::
  */
  # Don't put the domain parameter because the appendDomain method is partialy
  # apply.
  setDomain =
    fqdn:
    let
      # Parse the FQDN to be able to extract the hostname.
      info = getFqdnInfo fqdn;
    in
    # Use the appendDomain method to merge the hostname and the domain.
    appendDomain info.hostname;

  /**
    Function to map/modify Full Qualifer Domain Name of an hosts attributs set
    base on a given function.

    # Inputs

    `f`

    : The mapping function that take the fqdn and the configuration as
      parameter.

    `hosts`

    : The attribut ser of hosts by the Full Qualifer Domain Name.

    # Type

    ```nix
    mapHostsFqdn :: (String -> (AttrSet | AttrSet -> AttrSet ) -> String) -> AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.mapHostsFqdn` usage example

    ```nix
    mapHostsFqdn (fqdn: _: "private-${fqdn}") { runner01 = {}; runner02 = {}; }
    => { private-runner01 = {}; private-runner02 = {}; }
    mapHostsFqdn (fqdn: _: nixpkgs.lib.toUpper fqdn) { ad01 = {...}: { };  dns01 = {...}: { }; }
    => { AD01 = {...}: { };  DNS01 = {...}: { }; }
    ```

    :::
  */
  # Don't put hosts argument as it's a partialy apply function and the argument
  # is directly pass to the mapAttrs' function.
  mapHostsFqdn =
    f:
    # Use  mapAttrs' to be able to modify the name (value/config is pass
    # directly).
    lib.mapAttrs' (
      fqdn: config: {
        # The name is mapped from the input function and the previous fqdn and
        # config.
        name = f fqdn config;
        # Config is juste rename as value.
        value = config;
      }
    );

  /**
    Set the domain of each hosts Full Qualifer Domain Name.

    # Inputs

    `domain`

    : The domain that must replace the current one.

    `hosts`

    : The attribut ser of hosts by the Full Qualifer Domain Name.

    # Type

    ```nix
    setHostDomain :: String -> AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.setHostsDomain` usage example

    ```nix
    setHostsDomain "domain.tld" { runner01 = {}; runner02 = {}; }
    => { "runner01.domain.tld" = {}; "runner02.domain.tld" = {}; }
    setHostsDomain "" { "ad01.example.com" = {...}: { };  }
    => { ad01 = {...}: { }; }
    setHostsDomain "domain.tld" { "ad01.example.com" = {...}: { };  }
    => { "ad01.domain.tld" = {...}: { }; }
    ```

    :::
  */
  # No hosts parameter as mapHostsFqdn is partialy apply.
  setHostsDomain =
    domain:
    # Use the setDomain to set the domain on every fqdn
    mapHostsFqdn (fqdn: _: setDomain fqdn domain);

  /**
    Append the given domain at the front of the Full Qualifer Domain Name.

    # Inputs

    `domain`

    : The domain that must be append at the beggining of the fqdn.

    `hosts`

    : The attribut ser of hosts by the Full Qualifer Domain Name.

    # Type

    ```nix
    appendHostDomain :: String -> AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.appendHostsDomain` usage example

    ```nix
    setHostsDomain "domain.tld" { runner01 = {}; runner02 = {}; }
    => { "runner01.domain.tld" = {}; "runner02.domain.tld" = {}; }
    setHostsDomain "" { "ad01.example.com" = {...}: { };  }
    => { ad01.example.com = {...}: { }; }
    setHostsDomain "domain.tld" { "ad01.private" = {...}: { };  }
    => { "ad01.private.domain.tld" = {...}: { }; }
    ```

    :::
  */
  # No hosts parameter as appendHostsDomain is partialy apply.
  appendHostsDomain =
    domain:
    # Use the appendDomain to append the domain on every fqdn.
    mapHostsFqdn (fqdn: _: appendDomain fqdn domain);

  /**
    Import sub group by passing it's inputs and append the key as domain.

    # Inputs

    `inputs`

    :  The inputs to pass to the imported module.

    `domaines`

    :  The attribut set of domain and they hosts or import path.

    # Type

    ```nix
    importDomains :: Any -> AttrSet -> AttrSet
    ```

    # Example
    :::{.example}
    ## `lib.importDomains` usage example

    ```nix
     importDomains {inherit lib;} { "tld1" = ./tld1; "tld2" = {"host1" = {...}: { };}; }
    => { "host1.tld1" = {...}: { }; "host2.tld1" = {...}: { };, "host1.tld2" = {...}: { }; }
    ```

    :::
  */
  importDomains =
    inputs:
    let
      mapping =
        domain: content:
        let
          hosts = if builtins.isAttrs content then content else (import content) inputs;
        in
        appendHostsDomain domain hosts;
    in
    lib.concatMapAttrs mapping;
  /**
    Modules use to define group in an Inventory.

    <!-- markdownlint-disable-next-line link-fragments -->
    This module is useless without the use of [`mkInventory`](#lib.mkInventory).

    # Inputs

    # Type

    ```nix
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
  groupModule =
    { lib, ... }:
    # Get lib to get typoes and mkOption
    with lib;
    {
      # Generate the groups option.
      options.groups = mkOption {
        # The groups option is the the names of the groups to bypass any
        # possible multi instantionation of the same groupe.
        type = types.listOf types.str;
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

    ```nix
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
      <!-- markdownlint-disable-next-line link-fragments -->
      with the [`groupModule`](#lib.groupModule).

    `groupName`

    : Name of the group that must be check.

    # Type

    ```nix
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
  isInGroup =
    system: groupName:
    # Check that the group name is in the group option of the system
    # configuration.
    builtins.elem groupName system.config.groups;

  /**
    Filter a attribute set of system configuration base on the membership of a
    group.

    # Inputs

    `system`

    : System configuration generated from [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)
      <!-- markdownlint-disable-next-line link-fragments -->
      with the [`groupModule`](#lib.groupModule).

    `groupName`

    : Name of the group that the system must be member.

    # Type

    ```nix
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
  getGroupMembers =
    systems: groupName:
    # Filter attribut and check if the group name is in the system group list
    # options.
    lib.filterAttrs (_: system: isInGroup system groupName) systems;

  /**
    Function to pad a string with a padding patern to the given length by adding
    padding to the left.

    # Inputs

    `padding`

    : String that represent the patten used for padding.

    `length`

    : Final string length.

    `str`

    : String that must be pad.

    # Type

    ```nix
    padStringLeft :: String -> Int -> String -> String
    ```

    # Examples
    :::{.example}
    ## `lib.padStringLeft` usage example

    ```nix
    PadStringLeft " " 10 "toto"
    => "      toto"
    PadStringLeft "_" 2 "toto"
    => "toto"
    ```

    :::
  */
  padStringLeft =
    padding: length: str:
    # Check if the string is at list the right size.
    if (builtins.stringLength str) < length then
      # Call recusivly by adding  padding to the string
      padStringLeft padding length (padding + str)
    else
      # When the string size math the desire length juste return the string.
      str;

  /**
    Function to pad a number with zero to achive the given length.

    # Inputs

    `length`

    : Final length of the string.

    `n`

    : Number to pad

    # Type

    ```nix
    padNumber :: Int -> Int -> String
    ```

    # Examples
    :::{.example}
    ## `lib.padNumber` usage example

    ```nix
    PadStringLeft 5 303
    => "  303"
    PadStringLeft 2 303
    => "303"
    ```

    :::
  */
  padNumber =
    length: n:
    # Pad with 0 for the given lenth also convert the interger to string.
    padStringLeft "0" length (builtins.toString n);

  /**
    Function to genearate a name id.

    # Inputs

    `id`

    : index of the server

    # Type

    ```nix
    genId :: Int -> String
    ```

    # Examples
    :::{.example}
    ## `lib.genId` usage example

    ```nix
    genId 1
    => "01"
    genId 101
    => "101"
    ```

    :::
  */
  genId =
    # Hostname index is a 2 digit number.
    padNumber 2;

  /**
    Function to generate a hostname base on a name and id and id max length.

    # Inputs

    `length`

    : Max lenght of the id

    `name`

    : Base name of the server

    `id`

    : Index of the server

    # Type

    ```nix
    genHostname :: Int -> String -> Int -> String
    ```

    # Examples
    :::{.example}
    ## `lib.genHostname` usage example

    ```nix
    genHostname "2 lb" 1
    => "lb01"
    genHostname "5 node" 20
    => "node00020"
    ```

    :::
  */
  genHostname' =
    length: name: id:
    # Hostname is the chousen name follow by a 2 digit index.
    "${name}${genId length id}";

  /**
    Function to generate a hostname base on a name and id.

    # Inputs

    `name`

    : Base name of the server

    `id`

    : index of the server

    # Type

    ```nix
    genHostname :: String -> Int -> String
    ```

    # Examples
    :::{.example}
    ## `lib.genHostname` usage example

    ```nix
    genHostname "lb" 1
    => "lb01"
    genHostname "node" 20
    => "node20"
    ```

    :::
  */
  genHostname =
    # partial apply with lenght of 2.
    genHostname' 2;

  /**
    Function to wrap module and add extra speical argument to the call of a
    function or attribut set.

    # Inputs

    `speicalArgs`

    : attibut set of exta aguments.

    `module`

    : NixOS module

    # Type

    ```nix
    addSpecialArgs :: AttrSet -> (AttrSet | AttrSet -> AttrSet) -> String
    ```

    # Examples
    :::{.example}
    ## `lib.addSpecialArgs` usage example

    ```nix
    addSpecialArgs { a = 1; } ({ a, ... }: { b = a; })
    => { b = 1; }
    addSpecialArgs { a = 1; } { b = 2; }
    => { b = 2; }
    ```

    :::
  */
  addSpecialArgs =
    specialArgs: module:
    # Check if the module is a function
    if builtins.isFunction module then
      # If it's a function wrap the module function and append special argument
      # to the inputs.
      inputs: module (inputs // specialArgs)
    else
      # If it's a attribut set juste return it.
      module;

  /**
    Function to generate an set of host with incremental hostname base on a
    system configuration and the id lenght.

    # Inputs

    `length`

    : Max lenght of the id

    `config`

    : the configuration that will be used for every host.

    `prefix`

    : prefix use before the incremental index

    `number`

    : number of host to generate

    # Type

    ```nix
    genHosts :: (AttrSet | AttrSet -> AttrSet) -> String -> Int ->  (AttrSet | AttrSet -> AttrSet)
    ```

    # Examples
    :::{.example}
    ## `lib.genHosts` usage example

    ```nix
    genHosts' 2 ({ ... }: { }) "lb" 2
    => { lb01 = {...}: { };  lb02 = {...}: { }; }
    genHosts' 10 { } "empty" 0
    => {  }
    ```

    :::
  */
  genHosts' =
    length: config: prefix: number:
    let
      # Partialy apply genHostname with the prefix.
      genHostname'' = genHostname length prefix;
      # Function that take the id and generate the hostname and identifiver
      genHostEntry = id: {
        # The name is the hostname (add 1 because it's start at 0).
        name = genHostname'' (id + 1);
        # Value is the system configuration with the id parameter append to it.
        value = addSpecialArgs { inherit id; } config;
      };
      # Generate the list of all host parameter (hostanme and id).
      hostsEntries = builtins.genList genHostEntry number;
    in
    # Convert the list of entry (name/value) into a attribut set.
    builtins.listToAttrs hostsEntries;

  /**
    Function to generate an set of host with incremental hostname base on a
    system configuration.

    # Inputs

    `config`

    : the configuration that will be used for every host.

    `prefix`

    : prefix use before the incremental index

    `number`

    : number of host to generate

    # Type

    ```nix
    genHosts :: (AttrSet | AttrSet -> AttrSet) -> String -> Int ->  (AttrSet | AttrSet -> AttrSet)
    ```

    # Examples
    :::{.example}
    ## `lib.genHosts` usage example

    ```nix
    genHosts ({ ... }: { }) "lb" 2
    => { lb01 = {...}: { };  lb02 = {...}: { }; }
    genHosts { } "empty" 0
    => {  }
    ```

    :::
  */
  genHosts = genHosts' 2;

  /**
    Generate each system configuration base on the input configuration and the
    groups.

    # Inputs

    `overlays`

    : List of [overlays](https://wiki.nixos.org/wiki/Overlays) to add to
      [`nixpkgs.overlay`](https://search.nixos.org/options?show=nixpkgs.overlays).

    `extraArgs`

    : Attribut set to append to [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)]
      `extraArgs` arguements.

    `defaultModules`

    : List of avalanche host modules that will be apply to every hosts.

    `groups`

    : Attribut set of group name and there respective configuration.

    `hosts`

    : Attribut set of host configuration like in [`nixpkgs.lib.nixosSystem`](https://github.com/NixOS/nixpkgs/blob/master/flake.nix#L57)].

    # Type

    ```nix
    mkInventory :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.mkInventory` usage example

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
  */
  mkInventory =
    {
      extraArgs ? { },
      overlays ? [ ],
      defaultModules ? [ ],
      groups ? { },
      hosts ? { },
    }:
    let
      # Partialy apply the function with the hosts.
      getGroupMembers' = getGroupMembers finalSystems;

      # Generate all the group name with the group configuration.
      groupsNames = genGroupsNames groups;
      # Get the attribut set for each group of memeber system configuration.
      groupsMembers = builtins.mapAttrs (_: getGroupMembers') groupsNames;

      # Function to generate base system from the given configuration and fqdn.
      mkBaseSystem =
        fqdn: config:
        # Use nixpkgs nixosSystem function generate the base configuration.
        lib.nixosSystem {
          # Add extra agrument (depricated) to get list of groups the members of
          # each group and the list of every systems.
          specialArgs = {
            # Attribute set of every group (and they name).
            groups = groupsNames;
            # Attribute set of every group memebers.
            groupsMembers = groupsMembers;
            # Attribute set of every hosts.
            hosts = finalSystems;
            # Add extra arguments from user inputs.
          } // extraArgs;
          modules = [
            # Generate the hostname module base on the fqdn given via the
            # attribut set.
            (mkHostNameModule fqdn)
            # Add overlays to overide Nixpkgs packages.
            { nixpkgs.overlays = overlays; }
            # Add group module to be able to define the `groups` option.
            groupModule
            # The input configuration from the user.
            config
          ] ++ defaultModules;
        };
      # Function to apply a group to a base system (by it's base name).
      applyGroup =
        system: groupName:
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
            # Add extra arguments from user inputs.
          } // extraArgs;
          # Apply the given group.
          modules = [ groups.${groupName} ];
        };
      # Function that apply every groups define in Groups to the base configuration.
      applyGroups =
        _: baseSystem:
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
