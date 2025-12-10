#!/bin/sh


#PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${PREFIX}/share/pkgconfig"

(unset host_alias; unset build_alias; ./unix/configure; make)

mkdir -p $PREFIX/imager
cp ds9/unix/ds9base $PREFIX/imager/ds9

mkdir -p $PREFIX/lib/ds9
cp -r ds9/unix/mntpt/* $PREFIX/lib/ds9

cp ds9/unix/ds9.script $PREFIX/bin/ds9
chmod +x $PREFIX/bin/ds9
