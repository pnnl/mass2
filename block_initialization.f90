! ----------------------------------------------------------------
! file: block_initialization.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created December 31, 2010 by William A. Perkins
! Last Change: Sat Jan  1 08:08:07 2011 by William A. Perkins <d3g096@PE10588.pnl.gov>
! ----------------------------------------------------------------


! ----------------------------------------------------------------
! MODULE block_initialization
! ----------------------------------------------------------------
MODULE block_initialization

  USE config
  USE block_module

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE block_initialize
  ! ----------------------------------------------------------------
  SUBROUTINE block_initialize(blk)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(INOUT) :: blk

    CALL block_var_initialize(blk%uvel, uvel_initial)
    CALL block_var_initialize(blk%vvel, vvel_initial)

    IF (.NOT. read_initial_profile) THEN
       IF(given_initial_wsel)THEN
          blk%depth%current = wsel_or_depth_initial - blk%zbot%current
       ELSE
          blk%depth%current = wsel_or_depth_initial
       ENDIF
       IF (do_wetdry) THEN
          WHERE (blk%depth%current .LE. dry_zero_depth) 
             blk%depth%current = dry_zero_depth
          END WHERE
       END IF
       CALL block_var_iterate(blk%depth)
       CALL block_var_timestep(blk%depth)
       CALL block_var_timestep(blk%depth)

       blk%wsel%current = blk%depth%current + blk%zbot%current
       CALL block_var_iterate(blk%wsel)
       CALL block_var_timestep(blk%wsel)
       CALL block_var_timestep(blk%wsel)

    END IF


    ! FIXME
    IF (do_transport) THEN
       CALL error_message('transport initialization not implemented', fatal=.TRUE.)
    END IF

    CALL block_var_initialize(blk%eddy, eddy_default)
    CALL block_var_initialize(blk%kx_diff,  kx_diff_default)
    CALL block_var_initialize(blk%ky_diff, ky_diff_default)
    CALL block_var_initialize(blk%chezy, chezy_con_default)

  END SUBROUTINE block_initialize


  ! ----------------------------------------------------------------
  ! SUBROUTINE initialize
  ! ----------------------------------------------------------------
  SUBROUTINE initialize()

    IMPLICIT NONE

    INTEGER :: i, iblock, var

    ! assign initial conditions for each block
    ! using uniform values from cfg file or a restart file

    IF(read_hotstart_file)THEN
       ! FIXME: CALL read_hotstart()
       CALL error_message('hotstart not implemented', fatal=.TRUE.)
    ELSE
       CALL status_message('setting initial values for all blocks')
       DO iblock=1,max_blocks
          CALL block_initialize(block(iblock))
       END DO
       ! handle case if we are doing transport-only and not restarting
       IF((.NOT. do_flow).AND.(do_transport))THEN
          CALL error_message('transport-only initialization not implemented', fatal=.TRUE.)
       END IF
       CALL status_message('done setting initial values for all blocks')
    ENDIF

!     ! overwrite the default assignments
!     IF(do_spatial_eddy)THEN
!        filename = "eddy_coeff.dat"
!        CALL open_existing(filename, 50)
!        DO WHILE(.TRUE.)
!           READ(50,*,END=101)iblock, dum_val,i_start_cell, i_end_cell, j_start_cell , j_end_cell
!           block(iblock)%eddy(i_start_cell+1:i_end_cell+1,j_start_cell+1:j_end_cell+1) = dum_val
!        END DO
! 101    CLOSE(50)
!     ENDIF
!     IF(do_spatial_kx)THEN
!        filename = "kx_coeff.dat"
!        CALL open_existing(filename, 50)
!        DO WHILE(.TRUE.)
!           READ(50,*,END=102)iblock, dum_val,i_start_cell, i_end_cell, j_start_cell , j_end_cell
!           block(iblock)%kx_diff(i_start_cell+1:i_end_cell+1,j_start_cell+1:j_end_cell+1) = dum_val
!        END DO
! 102    CLOSE(50)
!     ENDIF
!     IF(do_spatial_ky)THEN
!        filename = "ky_coeff.dat"
!        CALL open_existing(filename, 50)
!        DO WHILE(.TRUE.)
!           READ(50,*,END=103)iblock, dum_val,i_start_cell, i_end_cell, j_start_cell , j_end_cell
!           block(iblock)%ky_diff(i_start_cell+1:i_end_cell+1,j_start_cell+1:j_end_cell+1) = dum_val
!        END DO
! 103    CLOSE(50)
!     ENDIF

!     IF(do_spatial_chezy)THEN
!        filename = "roughness_coeff.dat"
!        CALL open_existing(filename, 50)
!        DO WHILE(.TRUE.)
!           READ(50,*,END=100)iblock, dum_val,i_start_cell, i_end_cell, j_start_cell , j_end_cell
!           block(iblock)%chezy(i_start_cell+1:i_end_cell+1,j_start_cell+1:j_end_cell+1) = dum_val
!        END DO
! 100    CLOSE(50)
!     ENDIF

!     IF (read_initial_profile) THEN
!        CALL profile_init(given_initial_wsel, manning, SQRT(mann_con))
!     END IF

!     IF (do_wetdry) THEN
!        DO iblock=1,max_blocks
!           CALL check_wetdry(block(iblock))
!        END DO
!     END IF

!     IF (do_calc_eddy) THEN
!        DO iblock=1,max_blocks
!           CALL bedshear(block(iblock))
!           CALL calc_eddy_viscosity(block(iblock))
!        END DO
!     END IF

    DO iblock = 1, max_blocks
       CALL block_var_put(block(iblock)%uvel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%uvel, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%vvel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%vvel, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%depth, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%depth, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%wsel, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%wsel, BLK_VAR_STAR)
       CALL block_var_put(block(iblock)%eddy, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%kx_diff, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%ky_diff, BLK_VAR_CURRENT)
       CALL block_var_put(block(iblock)%chezy, BLK_VAR_CURRENT)
       CALL ga_sync()
       CALL block_var_get(block(iblock)%uvel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%uvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%vvel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%vvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%depth, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%depth, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%wsel, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%wsel, BLK_VAR_STAR)
       CALL block_var_get(block(iblock)%eddy, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%kx_diff, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%ky_diff, BLK_VAR_CURRENT)
       CALL block_var_get(block(iblock)%chezy, BLK_VAR_CURRENT)
    END DO

  END SUBROUTINE initialize




END MODULE block_initialization