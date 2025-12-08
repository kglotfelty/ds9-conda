#!/bin/sh


#PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${PREFIX}/share/pkgconfig"

./unix/configure
make

mkdir -p $CONDA_PREFIX/imager
cp ds9/unix/ds9base $CONDA_PREFIX/imager/ds9

mkdir -p $CONDA_PREFIX/lib/ds9
cp -r ds9/unix/mntpt/* $CONDA_PREFIX/lib/ds9

cp ds9/unix/ds9.script $CONDA_PREFIX/bin/ds9
chmod +x $CONDA_PREFIX/bin/ds9
