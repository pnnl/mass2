# -*- Autoconf -*-
# -----------------------------------------------------------
# file: acx_petsc.m4
# check for the PETSc 3.x library
#
# The PETSc library thinks that is the only library on the system.  If
# there in another useful library, PETSc should have an interface to
# it it.
#
# This only works with PETSc 3.x.  It tries to find extra packages
# (like Hypre) installed.  This expects PETSc to be compiled in place
# and not installed in some system directory (i.e. configuration info
# must all be there).
# -----------------------------------------------------------
# -----------------------------------------------------------
# Battelle Memorial Institute
# Pacific Northwest Laboratory
# -----------------------------------------------------------
# -----------------------------------------------------------
# Created December 12, 2003 by William A. Perkins
# Last Change: Thu Dec 15 08:04:09 2011 by William A. Perkins <d3g096@PE10900.pnl.gov>
# -----------------------------------------------------------

# -----------------------------------------------------------
# ACX_PETSC
# -----------------------------------------------------------
AC_DEFUN([ACX_PETSC], [

acx_petsc_ok=yes
acx_petsc_finclude=unknown

AC_PREREQ(2.60)
AC_REQUIRE([AC_CANONICAL_HOST])
AC_REQUIRE([AC_PROG_SED])
AC_REQUIRE([AC_PROG_GREP])

# 
# Extract PETSc variables from the environment variables
#
AC_ARG_VAR(PETSC_DIR, [location of PETSc installation])
AC_ARG_VAR(PETSC_ARCH, [PETSc configuration])
AC_MSG_CHECKING([for PETSc dir])
if test -z "$PETSC_DIR"; then
    AC_MSG_RESULT(no)
    AC_MSG_ERROR([PETSc not found; set PETSC_DIR])
    acx_petsc_ok=no
elif test ! -d "$PETSC_DIR"; then
    AC_MSG_ERROR([PETSc not found; PETSC_DIR=$PETSC_DIR is invalid])
    acx_petsc_ok=no
elif test ! -d "$PETSC_DIR/include"; then
    AC_MSG_ERROR([PETSc include dir $PETSC_DIR/include not found; check PETSC_DIR])
    acx_petsc_ok=broken
fi

if test x"$acx_petsc_ok" = xyes; then
    # find the fortran include directory
    if test -d "$PETSC_DIR/include/finclude"; then # 3.0 < PETSc < 3.6
        acx_petsc_finclude="$PETSC_DIR/include"
    elif test -d  "$PETSC_DIR/include/petsc/finclude"; then #  PETSc >= 3.6
        acx_petsc_finclude="$PETSC_DIR/include/petsc"
    else
       AC_MSG_ERROR([PETSc Fortran include directory not found; check installation])
       acx_petsc_ok=broken
    fi
fi

AC_MSG_RESULT([$PETSC_DIR])

# 
# Check to make sure we can understand the PETSc installation and it
# is reasonable
# 
# The PETSc installation is describe by a configuration file, which is
# just included in the Makefiles.  These files are:
# 
#  V. 3.x: $PETSC_DIR/$PETSC_ARCH/conf/petscvariables
#  V. 3.7: $PETSC_DIR/$PETSC_ARCH/lib/petsc/conf/petscvariables
#          $PETSC_DIR/lib/petsc/conf/petscvariables (in MacPorts)

acx_petsc_pkg_file=unknown


acx_petsc_pkg_file=" \
    $PETSC_DIR/$PETSC_ARCH/lib/petsc/conf/petscvariables \
    $PETSC_DIR/$PETSC_ARCH/lib/petsc/conf/petscvariables \
    $PETSC_DIR/lib/petsc/conf/petscvariables
"
PETSC_PKG=""
for i in $acx_petsc_pkg_file; do
    if test -r "$i"; then
        PETSC_PKG="$i"
    fi
done  


if test -z "$PETSC_PKG"; then
    acx_petsc_ok=disable
fi

acx_petsc_base_libs="-lpetsc"
# Make sure we can read the PETSC package file
if test x"$acx_petsc_ok" == x"yes"; then
    PETSC_LIBS_PATH="$PETSC/$PETSC_ARCH/lib"
fi

# and the header file
if test $acx_petsc_ok = yes; then
    AC_CHECK_FILE(${acx_petsc_finclude}/finclude/petsc.h, , [acx_petsc_ok=disable])
    AC_CHECK_FILE(${acx_petsc_finclude}/finclude/petscsys.h, , [acx_petsc_ok=disable])
fi

if test $acx_petsc_ok = yes; then
#
# Extract MPI, BLAS, and LAPACK flags from the PETSC configuration.
# This assumes that Make variables are not used in the specific
# entries.  We need some error checking here, and handling make
# variables link $(VAR).
#
# 3.1: PACKAGE_LIBS 
# 3.2: PETSC_EXTERNAL_LIB_BASIC
# 

list="PACKAGES_LIBS PETSC_EXTERNAL_LIB_BASIC"
for i in $list; do
    AC_MSG_CHECKING([Looking for $i in $PETSC_PKG])
    eval `$GREP "^$i  *=" $PETSC_PKG | $SED -e 's/  *=  */=\"/' -e 's/$/\"/' `
    eval v=\$$i
    AC_MSG_RESULT([$v])
done  

fi  

AC_SUBST([PETSC_FCFLAGS])
AC_SUBST([PETSC_FLIBS])
PETSC_FCFLAGS="-I$acx_petsc_finclude -I$PETSC_DIR/$PETSC_ARCH/include -I$PETSC_DIR/include"
PETSC_FLIBS="-L$PETSC_DIR/$PETSC_ARCH/lib -L$PETSC_DIR/lib -lpetsc $PACKAGES_LIBS $PETSC_EXTERNAL_LIB_BASIC"

# Ensure the comiler finds the library...
tmpLIBS=$LIBS
tmpCPPFLAGS=$CPPFLAGS

AC_LANG_PUSH(Fortran)

LIBS="$PETSC_FLIBS -lm $LIBS"
CPPFLAGS="$PETSC_FCFLAGS $CPPFLAGS"

if test $acx_petsc_ok = yes; then
AC_CHECK_LIB(
	[petsc],
	[petscerror],
	[],
	[acx_petsc_ok=disable] )
fi

# Save variables...
AC_LANG_POP
LIBS=$tmpLIBS
CPPFLAGS=$tmpCPPFLAGS

if test $acx_petsc_ok != yes; then
AC_MSG_ERROR( [Could not link in the PETSC library... ] )
fi


# Finally, execute ACTION-IF-FOUND/ACTION-IF-NOT-FOUND:
if test x"$acx_petsc_ok" = xyes; then
        ifelse([$1],,AC_DEFINE(HAVE_PETSC,1,[Define if you have a PETSC library.]),[$1])
        :
else
        acx_petsc_ok=no
        $2
fi

])# ACX_PETSC

