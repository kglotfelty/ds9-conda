#!/bin/sh

# The config files in funtools, xpa, and ast do not recognize
# arm64-apple. It's possible to autoreconf -if the funtools and xpa
# config files, but the ast ones require a special automake.
# So we unset these so that configure will work.
(unset host_alias; unset build_alias; ./unix/configure; make)

#
# Instead of installing in $PREFIX/bin, we install in
# $PREFIX/imager. This is where CIAO puts it. Then we drop a simple
# shell script in $PREFIX/bin; this script can be modified/customized
# to run ds9 w/ custom flags/etc. eg CIAO's ds9 which sources a
# TK script.
#

mkdir -p "${PREFIX}"/imager
cp bin/ds9 "${PREFIX}"/imager/ds9

#~ cp bin/xpa* $PREFIX/bin/

if test -f bin/ds9.zip
then
    cp bin/ds9.zip "${PREFIX}"/imager/ds9.zip
fi

mkdir -p "${PREFIX}"/bin
cp "${RECIPE_DIR}"/ds9.wrapper "${PREFIX}"/bin/ds9
chmod +x "${PREFIX}"/bin/ds9

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
    cp "${RECIPE_DIR}/${CHANGE}.csh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.csh"
done

