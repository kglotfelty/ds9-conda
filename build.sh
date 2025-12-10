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

mkdir -p $PREFIX/imager
cp ds9/unix/ds9 $PREFIX/imager/ds9
if test -f ds9/unix/ds9.zip
then
  cp ds9/unix/ds9.zip $PREFIX/imager/ds9.zip
fi

cat << EOM > $PREFIX/bin/ds9
#!/bin/sh

"\${CONDA_PREFIX}/imager/ds9" "\$@"
EOM

# ------- obsolete -------------------------
#~ mkdir -p $PREFIX/lib/ds9
#~ cp -r ds9/unix/mntpt/* $PREFIX/lib/ds9

#~ cp ds9/unix/ds9.script $PREFIX/bin/ds9
#~ chmod +x $PREFIX/bin/ds9

