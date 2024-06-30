{
  description = "nixpkgs+unfree+gl";

  inputs = {  
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = lib.systems.flakeExposed;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs systems;
      recurse = val: pkgs: if builtins.typeOf(val) == "set" then (nixpkgs.lib.mapAttrs (k: v: if v ? type && v.type == "derivation" then (wrapPackage v pkgs) else (recurse v pkgs)) val) else val;
      wrapPackage = pkg: pkgs: (pkgs.callPackage ./pkg.nix { inherit pkg pkgs; });
    in
    {
      inherit (nixpkgs) lib nixosModules htmlDocs;
      legacyPackages = eachSystem (system:
        let pkgs = import nixpkgs { config.allowUnfree = true; config.allowUnsupportedSystem = true; inherit system; };
        in recurse pkgs pkgs
      );
    };
}
