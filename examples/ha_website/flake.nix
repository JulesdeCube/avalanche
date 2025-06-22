{
  # Description of the nix flake.
  description = "Avalanche library example: website in high availability.";

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
  outputs =
    { nixpkgs, avalanche, ... }:
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
          # Group that define backends.
          backend =
            { members, ... }:
            {
              # Nginx service.
              services.nginx = {
                # Enable Nginx.
                enable = true;
                # Make the default host to point to the /var/www folder.
                virtualHosts._.root = "/var/www/";
              };
            };
          # Group for the reverse proxy
          reverseProxy =
            { groupsMembers, ... }:
            {
              # We use nginx as the reverse proxy.
              services.nginx = {
                # Enable nginx.
                enable = true;
                # Backend generated from backend group.
                upstreams.backend = {
                  # Generate server attribut set from memeber of the backend
                  # groups.
                  servers = lib.mapAttrs' (_: system: lib.nameValuePair (getIP system) { }) groupsMembers.backend;
                  # Add extra configuration to check avaiblility.
                  extraConfig = ''
                    least_conn;
                    keepalive 16;
                  '';
                };
                # Simple proxy to the backend.
                virtualHosts._.locations."/".proxyPass = "http://backend";
              };

              # We se Keepalive to have a "share" virtual IP.
              services.keepalived = {
                # enable keepalived
                enable = true;
                # Create a virtual ip
                vrrpInstances.frontend = {
                  # Hard coded to be easier.
                  interface = "eno1";
                  # Both reverse proxy are master
                  state = "MASTER";
                  priority = 50;
                  # IP address of the VIP
                  virtualIps = [ { addr = "10.0.0.254"; } ];
                  # id of the group
                  virtualRouterId = 1;
                };
              };
            };
        };

        # List of hosts.
        hosts = {
          # Backend hosts.
          backend01 =
            { groups, ... }:
            {
              # Add the host to the backend group.
              groups = [ groups.backend ];

              # Define the ip address.
              networking.interfaces.eno1.ipv4.addresses = [
                {
                  address = "10.0.0.9";
                  prefixLength = 24;
                }
              ];
            };
          backend02 =
            { groups, ... }:
            {
              # Add the host to the backend group.
              groups = [ groups.backend ];

              # Define the ip address.
              networking.interfaces.eno1.ipv4.addresses = [
                {
                  address = "10.0.0.8";
                  prefixLength = 24;
                }
              ];
            };

          # reverse proxy hosts.
          reverse-proxy01 =
            { groups, ... }:
            {
              # Add the host to the reverse proxy group.
              groups = [ groups.reverseProxy ];

              # Define the ip address.
              networking.interfaces.eno1.ipv4.addresses = [
                {
                  address = "10.0.0.1";
                  prefixLength = 24;
                }
              ];
            };

          reverse-proxy02 =
            { groups, ... }:
            {
              # Add the host to the reverse proxy group.
              groups = [ groups.reverseProxy ];

              # Define the ip address.
              networking.interfaces.eno1.ipv4.addresses = [
                {
                  address = "10.0.0.2";
                  prefixLength = 24;
                }
              ];
            };
        };
      };
    };
}
