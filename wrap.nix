{ nixpkgs, system }: (pkg:
  nixpkgs.stdenv.mkDerivation {
    inherit (pkg) name version meta outputs passthru;
    buildInputs = [ pkg ];
    nativeBuildInputs = [ pkg ];
    buildCommand = ''
      set -o pipefail
      ${
        nixpkgs.lib.concatStringsSep "\n"
          (map
            (outputName:
              ''
                echo "Building output ${outputName}"
                set -x
                mkdir -p "''$${outputName}/"
                cp -rs ${pkg.${outputName}}/* "''$${outputName}/"
                chmod -R 777 "''$${outputName}/bin/"
                rm -rf "''$${outputName}/bin/"
                mkdir -p "''$${outputName}/bin/"
                for file in ${pkg.${outputName}}/bin/* ; do
                  if [ -f "$file" ]; then
                    echo "#!${nixpkgs.bash}/bin/bash" > "''$${outputName}/bin/$(basename $file)"
                    echo "export LD_LIBRARY_PATH="${nixpkgs.mesa.drivers}/lib:$LD_LIBRARY_PATH"" >> "''$${outputName}/bin/$(basename $file)"
                    echo "export LIBGL_DRIVERS_PATH="${nixpkgs.mesa.drivers}/lib/dri:$LIBGL_DRIVERS_PATH"" >> "''$${outputName}/bin/$(basename $file)"
                    echo "export VK_DRIVER_FILES="${nixpkgs.mesa.drivers}/share/vulkan/icd.d:$VK_DRIVER_FILES"" >> "''$${outputName}/bin/$(basename $file)"
                    echo "exec $file "\"\$@\""" >> "''$${outputName}/bin/$(basename $file)"
                    chmod +x "''$${outputName}/bin/$(basename $file)"
                    cp -s $file "''$${outputName}/bin/$(basename $file).raw"
                  fi
                done
                set +x
              ''
            )
            (pkg.outputs)
          )
      }
    '';
  }
)
