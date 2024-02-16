export PATH="$coreutils/bin:$findutils/bin"

for output_name in $2; do
  out=${!output_name}
  pkg_output_name="pkg_${output_name}"
  pkg=${!pkg_output_name}
  mkdir -p $out/bin

  cd $pkg
  find -L * -type d -exec mkdir -p $out/{} \;
  find -L * -type f -exec ln -s $pkg/{} $out/{} \;

  mkdir -p $out/bin_org
  for orgBin in $out/bin/*; do
    [ -e "$orgBin" ] || continue
    bin_name=$(basename $orgBin)
    mv $orgBin $out/bin_org/$bin_name
    echo "#!/bin/sh" > $out/bin/$bin_name
    echo "export LD_LIBRARY_PATH=$1/lib" >> $out/bin/$bin_name
    echo "export LIBGL_DRIVERS_PATH=$1/lib/dri" >> $out/bin/$bin_name
    echo "export VK_DRIVER_FILES=$1/share/vulkan/icd.d" >> $out/bin/$bin_name
    echo "exec $out/bin_org/$bin_name \"\$@\"" >> $out/bin/$bin_name
    chmod +x $out/bin/$bin_name
  done
done
