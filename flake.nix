{
  description = "Nix GL Fixes";

  inputs = {  
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ];
    in
    rec {
      legacyPackages = forAllSystems (system:
        import nixpkgs { config.allowUnfree = true; overlays = [ overlays.${system} ]; inherit system;}
      );
      lib = nixpkgs.lib;
    };
}
