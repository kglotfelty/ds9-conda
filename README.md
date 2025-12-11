# `conda` build recipe for SAOImageDS9

This repro provides a [`conda-build`](https://docs.conda.io/projects/conda-build/en/stable/)
recipe for [`SAOImageDS9`](https://ds9.si.edu) (DS9).

## Motivation

Chandra's [CIAO](https://cxc.cfa.harvard.edu/ciao) software is distributed
as a set of _conda_ packages. For DS9, the CIAO recipe simply copies the existing
binary from certain OS specific builds into the conda install tree.
This means the ds9 binaries still have system specific dependencies.
This broke with Ubuntu 25.10 when they released with a binary incompatible
version of `libxml2` (which broke lots of packages, not just DS9).

Since building against a static version of `libxml2` is not feasible, we
created this recipe to build a conda native version of ds9 that is linked
against the conda libraries.


## Versions

This recipe was developed using DS9 v8.7.b3, with some initial
investigations using v8.6.

There are no code patches required. (See _rabbit holes_ below.)

## Platforms

This recipe has been tested on

- Linux-x86_64
- macOS-arm64
- macOS-x86_64

It has not been tested on Windows.

## Build

To build DS9 for conda, just clone this repo and then

```bash
conda build recipe --output-folder=/some/Path
```

The conda install files will be located in the `output-folder` location.

## Prior work

It is important to note that this is not the first (nor surely the last)
venture into creating a conda build for DS9.

There is currently a build of ds9 on _conda-forge_

```bash
$ conda search -c conda-forge ds9
Loading channels: done
# Name                       Version           Build  Channel
ds9                              8.6      hf18e563_0  conda-forge
```

The conda recipe can be found in the [ds9-feedstack repository](https://github.com/conda-forge/ds9-feedstock).

As of commit `81b7e41`, there are a couple of issues with this build.
First, it is only available for Linux-x86_64; it is not available for macOS.
Second, the recipe does not contain all the libraries needed to build
`Tk` with True Type Font support. This means that the fonts in the GUI are, well,
ugly, and not scalable.

There are [forks](https://github.com/jehturner/ds9-feedstock) of this repro under
active development which includes support for macOS.


## Notes on `meta.yaml`

I am not a `conda-build` expert so the `meta.yaml` is very basic.

The problem with the prior work is the lack of True Type font (TTF) support
in the version of Tk that DS9 builds. TTF support is include when Tk
is able to use the `xft` library.  Unfortunately, Tk is not especially helpful
in telling you why it does not use xft, you simply get this message during the build:

    checking whether to use xft... no

After sufficient hacking into the configure files we were able to identify
all the missing libraries and package-config files. The packages listed
in the `requirements:` `host:` section then are all the packages required
on Linux and macOS to enable xft support in Tk.  There may be some that could
be included just on Linux or just on macOS but having the extra packages
during the build here does not hurt, so good enough.


## Notes on `build.sh`

The normal `./unix/configure && make` command used to build the X11 version of
DS9 on all platforms unfortunately fails on macOS-arm64 systems.
The version of the configure scripts in the `xpa`, `funtools`, and `ast`
sub-packages are out of date and do not recognize `amd64-apple` when they are being
configured. For more details see the _rabbit hole_ section below.
To work around the issue, we need to unset the `host_alias` and
`build_alias` environment variables that are set by `conda build`

CIAO has a unique requirement on DS9.  CIAO provides it's own
shell script wrapper around DS9 that adds extra flags to the command line.
These commands source additional tcl/tk scripts and add tasks to the DS9
Analysis menu.

Because of this, CIAO needs to have the ds9 executable **not** be installed
in `$PREFIX/bin`.  Traditionally, CIAO has used `$PREFIX/imager`, which
is what this build script does.

This build script does create a wrapper script in `$PREFIX/bin/ds9`
that will call the executable in the `imager` directory unless there
is a `ds9.overrride` executable in the user's path.  For CIAO, the
current `ds9` script will need to be renamed to `ds9.overrride`
for this setup to work.

We also made the choice to install the set of [XPA tools](https://github.com/ericmandel/xpa)
that DS9 builds. These tools can be built and installed separately;
however, since DS9 is about the only tool left that still uses them
we made the choice to install them since they are already built (and
guaranteed to be the same (and therefore compatible) version as DS9 uses.


## Rabbit Holes

Developing this recipe lead down several ultimately unproductive paths.
The stories are captured here for future reference.

### `zipfs` file system

When starting this project, we understood that other attempts had been
made to create a conda build of DS9 and that those attempts failed
because of how DS9 is packaged.  Specifically how it uses the `zipfs` file
system to package all the Tcl/Tk modules into a single self contained
file that gets mounted by the application.  The issue we believed was
related to how conda uses `patchelf` / `install_name_tool` to modify the
path to shared libraries somehow messing up the hybrid zip file.

This lead down a _rabbit hole_ of working out how to separate the
application into a stand alone binary and keep the tcl/tk modules separate
and installed into a new `$PREFIX/lib/ds9` directory.

This was indeed completed and available on a forked branch on Github.

**HOWEVER** when looking at the current _conda-forge_ recipe we see
that they do not make any accommodations for the `zipfs` file system stuff.
So it turns out that this whole effort was a diversion.  It's nice to know
that we can separate out the parts but ultimately not necessary.

So no code changes needed.


### configuring `xpa`, `funtools`, and `ast`

After getting things initially working on Linux we moved on to macOS-arm64.
Again there was a lot of _whack-a-mole_ trial and error to get the set of
X11 libraries and package-config files needed to build Tk with TTF support.
However, getting past that the build failed when configuring the `xpa`
directory.

The error was an unknown configuration for `arm64-apple`; this was really
confusing since when it is configured outside of conda it configured for `arm-apple`
 (no `64`) which did not have any problems.

The preferred solution was to regenerate the configuration files with
newer version of `autotools`. Both `xpa` and `funtools`' `configure.ac` files
were sufficiently old that they required some modifications to work with
the current set of `autotools`. The config files for these were updated
and conda build was able to proceed. These changes are also available on
a forked branch on GitHub.

 However, `ast`'s `configure.ac` file **requires** a custom version of `automake`

```
dnl   Require Starlink automake
AM_INIT_AUTOMAKE([1.8.2-starlink subdir-objects])
```

and since that version of `automake` isn't readily available -- re-configuring
was not an (easy) option.

Subsequent searches lead to the `host_alias` and `build_alias` environment
variables that are set by `conda build`.  It's not pretty, but really the
only option was to `unset` these environment variables in the `build.sh` script.
Without them, it still builds for `arm-apple`, and since all `arm-apple` are
64-bit there is no difference.

Ultimately, since we decided to go the `unset foo_alias` route, there was
no immediate need for the regenerated `xpa` and `funtools` config files.

So, again, no code changes needed.



