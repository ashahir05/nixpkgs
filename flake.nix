{
  description = "nixpkgs+unfree+gl";

  inputs = {  
    nixpkgs.url = "github:ashahir05/nixpkgs/unfree";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = lib.systems.flakeExposed;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs systems;
      local = eachSystem (system: rec {
        pkgs = nixpkgs.legacyPackages."${system}";
        recurse = lib.mapAttrs (key: val: if (val ? type && val.type == "derivation") then (wrap val) else (if (val ? type && val.type == "set") then (recurse val) else val));
        wrap = import ./wrap.nix { nixpkgs = pkgs; };
      });
    in
    {
      inherit (nixpkgs) lib nixosModules htmlDocs;
      legacyPackages = eachSystem (system:
        local."${system}".recurse local."${system}".pkgs
      );
    };
}
