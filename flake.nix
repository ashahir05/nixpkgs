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
        import nixpkgs { config.allowUnfree = true; config.allowUnsupportedSystem = true; inherit system; }
      );
    };
}
