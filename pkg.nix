{ pkg, pkgs, ... } @ args:
  let 
    finalPkg = pkg.override (builtins.removeAttrs args [ "pkg" "pkgs" ]);
    build = orgPkg: ({
      name = if orgPkg ? name then orgPkg.name else null;
      pname = if orgPkg ? pname then orgPkg.pname else null;
      outputs = orgPkg.outputs;
      passthru = if orgPkg ? passthru then orgPkg.passthru else null;
      meta = if orgPkg ? meta then orgPkg.meta else null;
      targetDrv = orgPkg;
      builder = "${pkgs.bash}/bin/bash";
      args = [
        "-c"
        (pkgs.lib.concatStringsSep "\n" (builtins.concatMap (x: [''
          export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin"
          outname="${x}"
          out=''${!outname}
          mkdir -p $out
          
          cd ${orgPkg."${x}"}
          find -L * -type d -exec mkdir -p $out/{} \;
          find -L * -type f -exec ln -s ${orgPkg."${x}"}/{} $out/{} \;

          for orgBin in $out/bin/*; do
            [ -e "$orgBin" ] || continue
            bin_name=$(basename $orgBin)
            rm $out/bin/$bin_name
            echo "#!/bin/sh" > $out/bin/$bin_name
            echo "export LD_LIBRARY_PATH=${pkgs.mesa.drivers}/lib" >> $out/bin/$bin_name
            echo "export LIBGL_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri" >> $out/bin/$bin_name
            echo "export VK_DRIVER_FILES=${pkgs.mesa.drivers}/share/vulkan/icd.d" >> $out/bin/$bin_name
            echo "exec ${orgPkg."${x}"}/bin/$bin_name \"\$@\"" >> $out/bin/$bin_name
            chmod +x $out/bin/$bin_name
          done
        '']) orgPkg.outputs))
      ];
    });
  in
    (pkgs.stdenv.mkDerivation (build finalPkg)) // { overrideAttrs = x: pkgs.stdenv.mkDerivation (build (finalPkg.overrideAttrs x));  }
