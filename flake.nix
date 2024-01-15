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
        if pkg ? type && pkg.type == "derivation" && pkg ? outputs then (
          pkgs.stdenv.mkDerivation (( builtins.listToAttrs (builtins.map (x: { name = "pkg_${x}"; value = pkg."${x}"; }) pkg.outputs )) // {
            inherit (pkg) name outputs meta passthru;
            coreutils = pkgs.coreutils;
            findutils = pkgs.findutils;
            builder = "${pkgs.bash}/bin/bash";
            args = [
              ./wrap.sh
              pkgs.mesa.drivers
              pkg.outputs
            ];
          })
        ) else pkg
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
