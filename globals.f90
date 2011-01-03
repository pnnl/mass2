! ----------------------------------------------------------------
! file: globals.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created January  3, 2011 by William A. Perkins
! Last Change: Mon Jan  3 15:30:50 2011 by William A. Perkins <d3g096@PE10900.pnl.gov>
! ----------------------------------------------------------------

! ----------------------------------------------------------------
! MODULE globals
! ----------------------------------------------------------------
MODULE globals

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  CHARACTER (LEN=80), SAVE :: code_version = "MASS2 0.27 (Parallel)"
  CHARACTER (LEN=80), SAVE :: code_date = "Release: $Date$"

  ! ----------------------------------------------------------------
  ! Some physical, and other, constants that need to be known globally 
  ! ----------------------------------------------------------------
  
  DOUBLE PRECISION, PARAMETER :: grav = 32.2, tiny = 1.0D-100
  DOUBLE PRECISION, PARAMETER :: density = 1.94
  DOUBLE PRECISION, PARAMETER :: density_air = 0.00237  ! 60 degrees F
  DOUBLE PRECISION, PARAMETER :: bigfactor = 1.0d80
  DOUBLE PRECISION, PARAMETER :: vonkarmon = 0.4
  DOUBLE PRECISION, PARAMETER :: viscosity_water = 1.22e-05 ! ft^2/s @ 60F

  ! ----------------------------------------------------------------
  ! global parameters used to control cell overlap at block boundaries,
  ! and ghost cells
  ! ----------------------------------------------------------------

  INTEGER, PUBLIC, PARAMETER :: nghost = 2
  INTEGER, PUBLIC, PARAMETER :: i_ghost = nghost, j_ghost = nghost
  INTEGER, PUBLIC, PARAMETER :: i_index_min = 1-i_ghost, i_index_extra = 1+i_ghost
  INTEGER, PUBLIC, PARAMETER :: j_index_min = 1-j_ghost, j_index_extra = 1+j_ghost

  ! ----------------------------------------------------------------
  ! some simulation values that can change
  ! ----------------------------------------------------------------
  DOUBLE PRECISION, PUBLIC, SAVE :: salinity = 0.0
  DOUBLE PRECISION, PUBLIC, SAVE :: baro_press = 760.0

CONTAINS


END MODULE globals