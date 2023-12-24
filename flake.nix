{
  description = "Nix GL Fixes";

  inputs = {  
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib nixosModules htmlDocs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64"
      ];
      recurse = val: pkgs: if builtins.typeOf(val) == "set" then (nixpkgs.lib.mapAttrs (k: v: if v ? type && v.type == "derivation" then (wrapPackage v pkgs) else (recurse v pkgs)) val) else val;
      wrapPackage = pkg: pkgs: (
        if pkg ? type && pkg.type == "derivation" then pkgs.stdenv.mkDerivation (rec {
          inherit (pkg) name outputs passthru meta;
          src = pkg;
          buildInputs= [ pkg pkgs.mesa.drivers ];
          nativeBuildInputs= [ pkg pkgs.mesa.drivers ];
          installPhase = builtins.concatStringsSep ''''\n'' (builtins.map (output: let oldOut = pkg."${output}"; out = output; in ''
            mkdir -p ''$${out}/bin
            for node in ${oldOut}/*; do
              if [ $(basename $node) != "nix-support" ]; then
                cp -rs $node ''$${out}/
              fi
            done
            mkdir -p ''$${out}/bin_org
            for orgBin in ''$${out}/bin/*; do
              bin_name=$(basename $orgBin)
              mv ''$${out}/bin/* ''$${out}/bin_org/
              echo "#!/bin/sh" > ''$${out}/bin/$bin_name
              echo "export LD_LIBRARY_PATH=${pkgs.mesa.drivers}/lib" >> ''$${out}/bin/$bin_name
              echo "export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri" >> ''$${out}/bin/$bin_name
              echo "exec ''$${out}/bin_org/$bin_name "''$\@"" >> ''$${out}/bin/$bin_name
              chmod +x ''$${out}/bin/$bin_name
            done
          '') outputs);
        }) else pkg
      );
    in
    {
      inherit (nixpkgs) lib;
      legacyPackages = forAllSystems (system:
        let pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
        in recurse pkgs pkgs
      );
    };
}
