{ nixpkgs, system }: (pkg: pkg.overrideAttrs (prev: {
  buildCommand = ''
    set -euo pipefail
    ${
      nixpkgs.lib.concatStringsSep "\n"
        (map
          (outputName:
            ''
              echo "Building output ${outputName}"
              set -x
              for file in ${pkg.${outputName}}/bin/* ; do
                if [ -f "$file" ]; then
                  cat <<-EOF > "''$${outputName}/bin/$(basename $file)"
                  export LD_LIBRARY_PATH="${nixpkgs.legacyPackages.${system}.mesa.drivers}/lib:$LD_LIBRARY_PATH"
                  export LIBGL_DRIVERS_PATH="${nixpkgs.legacyPackages.${system}.mesa.drivers}/lib/dri:$LIBGL_DRIVERS_PATH"
                  export VK_DRIVER_FILES="${nixpkgs.legacyPackages.${system}.mesa.drivers}/share/vulkan/icd.d:$VK_DRIVER_FILES"
                  exec $file "$@"
                  EOF
                fi 
              done
              set +x
            ''
          )
          (prev.outputs or ["out"])
        )
    }
  '';
}))
