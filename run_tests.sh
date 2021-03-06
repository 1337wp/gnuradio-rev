#!/bin/sh

# First argument is absolute path to top of component source directory
# Second argument is absolute path to top of component build directory
# Third argument is component source directory for qa tests

# Absolute path to the top of the source directory
abs_top_srcdir=/home/me/gnuradio-3.4.0

# Absolute path to the top of the build directory
abs_top_builddir=/home/me/gnuradio-3.4.0

# current QA srcdir
export srcdir=$3

# Where to find my C++ and swig generated shared libraries
mylibdir=$2/src:$2/src/.libs:$2/src/lib:$2/src/lib/.libs:$2/lib:$2/lib/.libs:$2/swig:$2/swig/.libs

# Where to find my swig generated python module
mysrcdir=$1/src:$1/src/lib

# Where to find my hand written python modules
mypydir=$1/src:$1/src/python:$1/python

# Where to find core's swig generated shared libraries,
# and hand generated swig glue
grswigdir=${abs_top_builddir}/gnuradio-core/src/lib/swig:${abs_top_builddir}/gnuradio-core/src/lib/swig/.libs:${abs_top_srcdir}/gnuradio-core/src/lib/swig

# Where to find core's python modules
grpydir=${abs_top_srcdir}/gnuradio-core/src/python

# Construct search path for python modules, if each exists
for dir in $grswigdir $grpydir
do
    if [ "$dir" != "" ]
    then
	if [ "$PYTHONPATH" = "" ]
	then
	    PYTHONPATH="$dir"
	else
	    PYTHONPATH="$dir:$PYTHONPATH"
	fi
    fi
done

# Where to find pre-installed python modules
withpydirs=

# Add the 'with' dirs to the end of the python search path, if it exists
if [ "$withpydirs" != "" ]
then
    PYTHONPATH="$PYTHONPATH:$withpydirs"
fi

# Add the "my" dirs to the absolute front of the python search path
PYTHONPATH="$mylibdir:$mysrcdir:$mypydir:$PYTHONPATH"
export PYTHONPATH

# Where to find gruel library files
grueldir=${abs_top_builddir}/gruel/src/lib:${abs_top_builddir}/gruel/src/lib/.libs

# Where to find gnuradio core's library files
grcoredir=${abs_top_builddir}/gnuradio-core/src/lib:${abs_top_builddir}/gnuradio-core/src/lib/.libs

# Construct search path for python modules
# Check each one to make sure it's not "" before adding
grlibdir=""
for dir in $grcoredir $grueldir
do
    if [ "$dir" != "" ]
    then
	if [ "$grlibdir" = "" ]
	then
	    grlibdir="$dir"
	else
	    grlibdir="$dir:$grlibdir"
	fi
    fi
done

# Add 'mylibdir' to the start of the library load path, to get local
# (to this component) created libraries

# Where to find pre-installed libraries
withlibdirs=

case "linux-gnu" in
  darwin*)
    # Special Code for executing on Darwin / Mac OS X only
    if [ "$DYLD_LIBRARY_PATH" = "" ]
    then
	DYLD_LIBRARY_PATH=$mylibdir
    else
	DYLD_LIBRARY_PATH=$mylibdir:$DYLD_LIBRARY_PATH
    fi
    # DYLD_LIBRARY_PATH will not be empty now
    # Add the grlibdir paths to the front of any library load variable
    if [ "$grlibdir" != "" ]
    then
	DYLD_LIBRARY_PATH=$grlibdir:$DYLD_LIBRARY_PATH
    fi
    # Add the withdirs paths to the end of any library load variable
    if [ "$withlibdirs" != "" ]
    then
	DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$withlibdirs
    fi
    export DYLD_LIBRARY_PATH
    ;;
  cygwin*|win*|mingw*)
    # Special Code for executing on Win32 variants only
    if [ "$PATH" = "" ]
    then
	PATH=$mylibdir
    else
	PATH=$mylibdir:$PATH
    fi
    # PATH will not be empty now
    # Add the grlibdir paths to the front of any library load variable
    if [ "$grlibdir" != "" ]
    then
	PATH=$grlibdir:$PATH
    fi
    # Add the withdirs paths to the end of any library load variable
    if [ "$withlibdirs" != "" ]
    then
	PATH=$PATH:$withlibdirs
    fi
    export PATH
    ;;
esac

# Don't load user or system prefs
GR_DONT_LOAD_PREFS=1
export GR_DONT_LOAD_PREFS

# Run everything that matches qa_*.py and return the final result.

ok=yes
for file in $3/qa_*.py
do
  # echo $file
  /usr/bin/python $file
  r=$?
  if [ $r -ne 0 ]
  then
    if [ $r -ge 128 ]		# killed by a signal
    then
      exit $r
    fi
    ok=no
  fi  
done

if [ $ok = yes ]
then
  exit 0
else
  exit 1
fi
