{ pkg, pkgs, ... }: {
  stdenv.mkDerivation {
    installPhase = ''
      mkdir $out
    '';
  }
}
