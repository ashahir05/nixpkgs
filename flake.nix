{
  description = "Nix GL Fixes";

  inputs = {  
    nixpkgs.url = "github:NixOS/nixpkgs/ef754f93dd25862be5a03fd9a3c0e651d64219cc";
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
        if pkg ? overrideAttrs then pkg.overrideAttrs (old: {
          name = "${pkg.name}-gled";
          nativeBuildInputs= [];
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
      legacyPackages = forAllSystems (system:
        let pkgs = import nixpkgs { config.allowUnfree = true; inherit system; };
        in recurse pkgs pkgs
      );
    };
}
