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
        if pkg ? type && pkg.type == "derivation" then pkgs.stdenv.mkDerivation ({
          inherit (pkg) name pname outputs passthru;
          nativeBuildInputs= [ pkg ];
          buildCommand = ''
            set -euo pipefail
            ${
              nixpkgs.lib.concatStringsSep "\n"
                (map
                  (outputName:
                    ''
                      set -x
                      cp -rs --no-preserve=mode "${pkg.${outputName}}" "''$${outputName}"
                      set +x
                    ''
                  )
                  (pkg.outputs or ["out"])
                )
            }
            for bin in $out/bin/*; do
              mkdir -p $out/bin/org
              mv $bin $out/bin/org
              echo "#!/bin/sh" > $bin
              echo "export LD_LIBRARY_PATH=${pkgs.mesa.drivers}/lib" >> $bin
              echo "export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri" >> $bin
              echo "exec $out/bin/org/$(basename $bin) \"\$@\"" >> $bin
              chmod +x $bin
            done
          '';
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
