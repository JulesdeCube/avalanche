# This script allow to update the docs/lib.md docuemntation from the source code
nix run nixpkgs#nixdoc -- --file lib/default.nix --category inventory --description 'Avalanche library' > docs/lib.md
