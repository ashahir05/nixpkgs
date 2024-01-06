mkdir -p $out/bin
cd $1
find -L * -type d -exec mkdir -p $out/{} \;
find -L * -type f -exec ln -s $1/{} $out/{} \;
mkdir -p $out/bin_org
for orgBin in $out/bin/*; do
  bin_name=$(basename $orgBin)
  mv $orgBin $out/bin_org/$bin_name
  echo "#!/bin/sh" > $out/bin/$bin_name
  echo "export LD_LIBRARY_PATH=$2/lib" >> $out/bin/$bin_name
  echo "export LIBGL_DRIVERS_PATH=$2/lib/dri" >> $out/bin/$bin_name
  echo "exec $out/bin_org/$bin_name \"$@\"" >> $out/bin/$bin_name
  chmod +x $out/bin/$bin_name
done

