{
  # Description of the nix flake.
  description = "Avalanche library";

  # Flake used as inputs for the all flake
  inputs = {
    # Snowball is a flake that i use to sync all my project inputs
    # it allow to make batched update without desync version garanty that
    # flake version are compatible.
    snowball.url = "git+https://gitlab.julesdecube.com/infra/snowball.git";

    # Nixpkgs, main nix packages collection ussing follow to get snowball
    # verison
    nixpkgs.follows = "snowball/nixpkgs";
    # Utils used to generate per system (architecture) packages.
    flake-utils.follows = "snowball/flake-utils";
    # Git-hooks library use for code checking.
    git-hooks.follows = "snowball/git-hooks";
  };

  # This is the main output of everything that can be generated by the flake.
  outputs = { nixpkgs, flake-utils, git-hooks, ... }:
    let
      # Import function from flake-utils library
      inherit (flake-utils.lib) eachDefaultSystem;

      # Small function to import pkgs for the given system ussing the given
      # nixpkgs flake.
      pkgImport = pkgs: system:
        import pkgs {
          inherit system;
        };

      # Output that are not system specific (lib, host configuration, overlay).
      globalOutput = { };

      # Output system specific (pkgs, check, devShell). `system` is a arguement
      # to geneate the system configuration for the system `system`.
      systemOutput = system:
        let
          # Import packages for the given system.
          pkgs = pkgImport nixpkgs system;
          # Retrive pre-commit-hooks library for the given system.
          hook = git-hooks.lib.${system};
        in
        rec {
          # Every check on the repository.
          checks = {
            # Check done by pre-commit-hook (linting and formatting).
            pre-commit = hook.run {
              # Check all the files.
              src = ./.;

              # List of hooks runs
              hooks = {
                # Eanble nixpkgs-fmt
                nixpkgs-fmt.enable = true;
                # Enable markdown lint
                markdownlint.enable = true;
              };
            };
          };

          # List of developement shells.
          devShells = {
            # Default developement shell.
            default = pkgs.mkShell {
              # Name of the developement shell.
              name = "Avalanche";

              # Install the pre-commit hook inside the git.
              inherit (checks.pre-commit) shellHook;

              # Retrive the pre-commit hooks packages
              buildInputs = checks.pre-commit.enabledPackages;

              # list of extra packages use to develop.
              packages = with pkgs; [
                git

                nil
              ];
            };
          };
        };

    in
    # Merging the global configuration and the system specfic configuration.
    globalOutput //
    # Generating all systems specific output
    eachDefaultSystem systemOutput;
}
