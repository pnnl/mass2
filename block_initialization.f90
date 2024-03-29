! ----------------------------------------------------------------
! file: block_initialization.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created December 31, 2010 by William A. Perkins
! Last Change: 2015-02-20 10:46:38 d3g096
! ----------------------------------------------------------------


! ----------------------------------------------------------------
! MODULE block_initialization
! ----------------------------------------------------------------
MODULE block_initialization

  USE config
  USE block_hydro
  USE scalars
  USE hotstart

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  INTEGER, PARAMETER, PRIVATE :: coeff_file_count = 4
  CHARACTER (LEN=80), PARAMETER, PRIVATE :: coeff_file_name(coeff_file_count) = (/&
       &"eddy_coeff.dat     ", &
       &"kx_coeff.dat       ", &
       &"ky_coeff.dat       ", &
       &"roughness_coeff.dat"&
       &/)

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE block_initialize
  ! ----------------------------------------------------------------
  SUBROUTINE block_initialize(blk)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(INOUT) :: blk

    CALL block_var_initialize(blk%bv_uvel, uvel_initial)
    CALL block_var_initialize(blk%bv_vvel, vvel_initial)

    IF (.NOT. read_initial_profile) THEN
       IF(given_initial_wsel)THEN
          blk%depth = wsel_or_depth_initial - blk%zbot
       ELSE
          blk%depth = wsel_or_depth_initial
       ENDIF
       IF (do_wetdry) THEN
          WHERE (blk%depth .LE. dry_zero_depth) 
             blk%depth = dry_zero_depth
          END WHERE
       END IF
       CALL block_var_iterate(blk%bv_depth)
       CALL block_var_timestep(blk%bv_depth)
       CALL block_var_timestep(blk%bv_depth)

       blk%wsel = blk%depth + blk%zbot

    END IF

    CALL block_var_initialize(blk%bv_eddy, eddy_default)
    CALL block_var_initialize(blk%bv_kx_diff,  kx_diff_default)
    CALL block_var_initialize(blk%bv_ky_diff, ky_diff_default)
    CALL block_var_initialize(blk%bv_chezy, chezy_con_default)

  END SUBROUTINE block_initialize


  ! ----------------------------------------------------------------
  ! SUBROUTINE initialize
  ! ----------------------------------------------------------------
  SUBROUTINE initialize()

    USE profile_init

    IMPLICIT NONE

    INTEGER :: i, iblock, var

    ! assign initial conditions for each block
    ! using uniform values from cfg file or a restart file

    CALL status_message('setting initial values for all blocks')
    DO iblock=1,max_blocks
       CALL block_initialize(block(iblock))
    END DO
    IF (do_transport) THEN
       DO i = 1, max_species
          DO iblock =1, max_blocks
             CALL block_var_initialize(species(i)%scalar(iblock)%concvar, &
                  &scalar_source(i)%initial)
             CALL block_var_put(species(i)%scalar(iblock)%concvar, BLK_VAR_CURRENT)
             CALL block_var_put(species(i)%scalar(iblock)%concvar, BLK_VAR_OLD)
             CALL block_var_put(species(i)%scalar(iblock)%concvar, BLK_VAR_OLDOLD)
             CALL block_var_sync()
             CALL block_var_get(species(i)%scalar(iblock)%concvar, BLK_VAR_CURRENT)
             CALL block_var_get(species(i)%scalar(iblock)%concvar, BLK_VAR_OLD)
             CALL block_var_get(species(i)%scalar(iblock)%concvar, BLK_VAR_OLDOLD)
             CALL block_var_sync()
          END DO
       END DO
    END IF
    CALL status_message('done setting initial values for all blocks')

    ! overwrite the default assignments
    IF(do_spatial_eddy) CALL initialize_coeff("eddy_coeff.dat")
    IF(do_spatial_kx) CALL initialize_coeff("kx_coeff.dat")
    IF(do_spatial_ky) CALL initialize_coeff("ky_coeff.dat")
    IF(do_spatial_chezy) CALL initialize_coeff("roughness_coeff.dat")

    IF (read_initial_profile) THEN
       CALL profile_initialize(given_initial_wsel, manning, SQRT(mann_con))
    ELSE IF(read_hotstart_file)THEN
       CALL read_hotstart()
    END IF

    IF (do_wetdry) THEN
       DO iblock=1,max_blocks
          CALL check_wetdry(block(iblock))
       END DO
    END IF

    IF (do_calc_eddy) THEN
       DO iblock=1,max_blocks
          CALL bedshear(block(iblock))
          CALL calc_eddy_viscosity(block(iblock))
       END DO
    END IF

    DO iblock = 1, max_blocks
       CALL block_var_put(block(iblock)%bv_uvel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_uvel, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%bv_uvel, BLK_VAR_OLD)
       CALL block_var_put(block(iblock)%bv_uvel, BLK_VAR_OLDOLD)
       CALL block_var_put(block(iblock)%bv_vvel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_vvel, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%bv_vvel, BLK_VAR_OLD)
       CALL block_var_put(block(iblock)%bv_vvel, BLK_VAR_OLDOLD)
       CALL block_var_put(block(iblock)%bv_depth, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_depth, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%bv_depth, BLK_VAR_OLD)
       CALL block_var_put(block(iblock)%bv_depth, BLK_VAR_OLDOLD)
       CALL block_var_put(block(iblock)%bv_wsel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_eddy, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_kx_diff, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_ky_diff, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%bv_chezy, BLK_VAR_CURRENT)
       CALL block_var_sync()

       ! don't block_var_get old or oldolod because the ghosted values
       ! are not needed locally (except for depth)

       CALL block_var_get(block(iblock)%bv_uvel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_uvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%bv_vvel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_vvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%bv_depth, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_depth, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%bv_depth, BLK_VAR_OLD)
       CALL block_var_get(block(iblock)%bv_wsel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_eddy, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_kx_diff, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_ky_diff, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%bv_chezy, BLK_VAR_CURRENT)
       CALL block_var_sync()
    END DO


  END SUBROUTINE initialize

  ! ----------------------------------------------------------------
  ! SUBROUTINE initialize_coeff
  ! ----------------------------------------------------------------
  SUBROUTINE initialize_coeff(filename)

    IMPLICIT NONE

    INTEGER, PARAMETER :: iounit = 50
    CHARACTER (LEN=*), INTENT(IN) :: filename
    INTEGER :: ifile

    INTEGER :: iblock
    INTEGER :: i_start_cell, i_end_cell, j_start_cell, j_end_cell
    DOUBLE PRECISION :: dum_val
    INTEGER :: i, j
    INTEGER :: iostat

    DOUBLE PRECISION, POINTER :: tmp(:, :)

    DO ifile = 1, coeff_file_count
       IF (filename .EQ. coeff_file_name(ifile)) THEN

          CALL open_existing(filename, iounit)

          DO WHILE(.TRUE.)
             READ(iounit,*,IOSTAT=iostat) iblock, dum_val, &
                  &i_start_cell, i_end_cell, j_start_cell , j_end_cell

             ! FIXME: check iblock

             IF (iostat .EQ. 0) THEN
                SELECT CASE (ifile)
                CASE (1)
                   tmp => block(iblock)%eddy
                   
                CASE (2)
                   tmp => block(iblock)%kx_diff
                   
                CASE (3)
                   tmp => block(iblock)%ky_diff
                   
                CASE (4)
                   tmp => block(iblock)%chezy
                   
                CASE DEFAULT
                   CYCLE
                END SELECT

                DO i = i_start_cell+1, i_end_cell+1
                   DO j = j_start_cell+1, j_end_cell+1
                      IF (block_owns(block(iblock), i, j)) tmp(i, j) = dum_val
                   END DO
                END DO
             ELSE 
                EXIT
             END IF
          END DO
          CLOSE(iounit)
       END IF
    END DO
       
  END SUBROUTINE initialize_coeff





END MODULE block_initialization
