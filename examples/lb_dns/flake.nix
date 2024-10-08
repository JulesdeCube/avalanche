{
  # Description of the nix flake.
  description = "Avalanche library example: loadbalancer dns.";

  # Flake used as inputs for example.
  inputs = {
    # Nixpkgs, main nix packages collection ussing follow to get snowball
    # verison
    nixpkgs.url = "github:NixOS/nixpkgs/nixos";
    # Import the library.
    avalanche.url = "git+https://gitlab.julesdecube.com/infra/avalanche.git";
  };

  # Output of all the NixOS configurations. take nixpkgs and the avalanche
  # library.
  outputs = { nixpkgs, avalanche, ... }:
    let
      # import nixpkgs lib.
      inherit (nixpkgs) lib;
      # import mkInventory from Avalanche lib.
      inherit (avalanche.lib) mkInventory;

      # Dumb function to get system ip.
      getIP = system: (builtins.elemAt system.config.networking.interfaces.eno1.ipv4.addresses 0).address;
    in
    {
      # All hosts configurations.
      nixosConfigurations = mkInventory {

        # List of module apply to each hosts.
        defaultModules = [
          # Only define the host platform.
          { nixpkgs.hostPlatform = "x86_64-linux"; }
        ];

        # Attribut set of all the groups.
        groups = {
          # Group that define dns servers.
          dns = { pkgs, hosts, ... }: {
            # Bind dns server service.
            services.bind = {
              # Enable Bind.
              enable = true;
              # Define the main zone.
              zones."example.com" = {
                # Maker both server as master (there are behind a load balancer).
                master = true;
                # The configuration
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

        # List of hosts.
        hosts = {
          # dns server hosts.
          ns01 = { groups, ... }: {
            # Add the host to the dns group.
            groups = [ groups.dns ];

            # Define the ip address.
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.9"; prefixLength = 24; }];
          };
          ns02 = { groups, ... }: {
            # Add the host to the dns group.
            groups = [ groups.dns ];

            # Define the ip address.
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.8"; prefixLength = 24; }];
          };

          # Load balancer host.
          lb01 = { groups, groupsMembers, ... }: {
            # Define the ip address.
            networking.interfaces.eno1.ipv4.addresses = [{ address = "10.0.0.1"; prefixLength = 24; }];

            # add dnsdisct as dns load balancer
            services.dnsdist =
              let
                # Generate one dns server line.
                mkServer = name: system: ''
                  newServer({address=${getIP system}, name="${name}"})
                '';
                # Apply to every servers.
                servers = builtins.attrValues (builtins.mapAttrs mkServer groupsMembers.dns);
              in
              {
                # Enable dnsdist.
                enable = true;
                # Listen on the default port.
                listenPort = 53;
                # Add every dns server and set the policy to roudrobin
                extraConfig = ''
                  setServerPolicy(roundrobin)
                  ${lib.concatStrings servers}
                '';
              };
          };
        };
      };
    };
}
