{
  description = "nixpkgs+unfree";

  inputs = {  
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = lib.systems.flakeExposed;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs systems;
    in
    {
      inherit (nixpkgs) lib nixosModules htmlDocs;
      legacyPackages = eachSystem (system:
        let 
          patchedPkgs = import nixpkgs { config.allowUnfree = true; config.allowUnsupportedSystem = true; inherit system; };
          wrap = import ./wrap.nix { nixpkgs = patchedPkgs; system = system; };
          recurse = lib.mapAttrs (key: val: if (val ? type && val.type == "derivation") then (wrap val) else (recurse val));
        in
          recurse patchedPkgs
      );  
    };
}
