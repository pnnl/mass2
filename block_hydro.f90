! ----------------------------------------------------------------
! file: block_hydro.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created January  3, 2011 by William A. Perkins
! Last Change: Tue Jan  4 08:20:45 2011 by William A. Perkins <d3g096@PE10900.pnl.gov>
! ----------------------------------------------------------------


! ----------------------------------------------------------------
! MODULE block_hydro
!
! Basically just a set of routines to operate on hydrodynamics
! variables
! ----------------------------------------------------------------
MODULE block_hydro

  USE config
  USE block_module
  USE differencing
  ! USE solver_module

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"


CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE velocity_shift
  ! This routine computes velocity components at the cell center
  ! ----------------------------------------------------------------
  SUBROUTINE velocity_shift()

    IMPLICIT NONE

    INTEGER :: iblk, i, j
    DOUBLE PRECISION :: flux1, flux2

    ! compute fluxes for all blocks first

    DO iblk = 1, max_blocks

       ! cell center velocity components 
       ! with fluxes !
       block(iblk)%uflux%current = 0.0
       block(iblk)%vflux%current = 0.0
       DO i = i_index_min+1, block(iblk)%xmax+i_index_extra
          DO j=2, block(iblk)%ymax 
             IF (block_owns(block(iblk), i, j)) THEN
                flux2 = uflux(block(iblk), i, j, j)
                block(iblk)%uflux%current(i,j) = flux2
             END IF
          END DO
          IF (block_owns(block(iblk), i, 1)) THEN
             block(iblk)%uflux%current(i,1) = block(iblk)%uflux%current(i,2)
          END IF
          IF (block_owns(block(iblk), i, block(iblk)%ymax+1)) THEN
             block(iblk)%uflux%current(i,block(iblk)%ymax+1) = &
                  &block(iblk)%uflux%current(i,block(iblk)%ymax)
          END IF
       END DO

       DO j= j_index_min+1, block(iblk)%ymax + j_index_extra
          DO i = 2, block(iblk)%xmax
             IF (block_owns(block(iblk), i, j)) THEN
                flux2 = vflux(block(iblk), i, i, j)
                block(iblk)%vflux%current(i,j) = flux2
             END IF
          END DO
          IF (block_owns(block(iblk), 1, j)) THEN
             block(iblk)%vflux%current(1,j) = block(iblk)%vflux%current(2,j)
          END IF
          IF (block_owns(block(iblk), block(iblk)%xmax+1, j)) THEN
             block(iblk)%vflux%current(block(iblk)%xmax+1, j) = &
                  &block(iblk)%vflux%current(block(iblk)%xmax, j)
          END IF
       END DO

       CALL block_var_put(block(iblk)%uflux)
       CALL block_var_put(block(iblk)%vflux)
       CALL ga_sync()
       CALL block_var_get(block(iblk)%uflux)
       CALL block_var_get(block(iblk)%vflux)

    END DO

    ! Next, compute the p-cell center velocity components from the fluxes

    DO iblk = 1, max_blocks

       DO i = i_index_min+1, block(iblk)%xmax+i_index_extra
          DO j=2, block(iblk)%ymax 
             IF (block_owns(block(iblk), i, j)) THEN
                flux1 = block(iblk)%uflux%current(i-1,j)
                flux2 = block(iblk)%uflux%current(i,j)
                block(iblk)%uvel_p%current(i,j) = &
                     &0.5*(flux1+flux2)/block(iblk)%hp2%current(i,j)/&
                     &block(iblk)%depth%current(i,j)
             END IF
          END DO
       END DO

       DO j= j_index_min+1, block(iblk)%ymax + j_index_extra
          DO i = 2, block(iblk)%xmax
             IF (block_owns(block(iblk), i, j)) THEN
                flux1 = block(iblk)%uflux%current(i,j-1)
                flux2 = block(iblk)%uflux%current(i,j)
                block(iblk)%vvel_p%current(i,j) = 0.5*(flux1+flux2)/&
                     &block(iblk)%hp1%current(i,j)/block(iblk)%depth%current(i,j)
             END IF
          END DO
          IF (block_owns(block(iblk), 1, j)) THEN
             block(iblk)%vflux%current(1,j) = block(iblk)%vflux%current(2,j)
          END IF
          IF (block_owns(block(iblk), block(iblk)%xmax+1, j)) THEN
             block(iblk)%vflux%current(block(iblk)%xmax+1, j) = &
                  &block(iblk)%vflux%current(block(iblk)%xmax, j)
          END IF
       END DO

       i = 1
       DO j = 2, block(iblk)%ymax
          IF (block_owns(block(iblk), i, j)) THEN
             block(iblk)%uvel_p%current(i,j) = block(iblk)%uvel%current(i+1,j)
          END IF
       END DO
       j = 1
       DO i = 2, block(iblk)%xmax
          IF (block_owns(block(iblk), i, j)) THEN
             block(iblk)%vvel_p%current(i,j) = block(iblk)%vvel%current(i,j+1)
          END IF
       END DO

       ! eastward & northward velocity @ cell center

       WHERE (block(iblk)%hp1%current .NE. 0.0 .AND. block(iblk)%hp2%current .NE. 0.0)
          block(iblk)%u_cart%current = &
               &(block(iblk)%uvel_p%current/block(iblk)%hp1%current)*block(iblk)%x_xsi%current + &
               &(block(iblk)%vvel_p%current/block(iblk)%hp2%current)*block(iblk)%x_eta%current
          block(iblk)%v_cart%current = &
               &(block(iblk)%uvel_p%current/block(iblk)%hp1%current)*block(iblk)%y_xsi%current + &
               &(block(iblk)%vvel_p%current/block(iblk)%hp2%current)*block(iblk)%y_eta%current
       ELSEWHERE
          block(iblk)%u_cart%current = 0.0
          block(iblk)%v_cart%current = 0.0
       END WHERE

       CALL block_var_put(block(iblk)%uvel_p)
       CALL block_var_put(block(iblk)%vvel_p)
       CALL block_var_put(block(iblk)%u_cart)
       CALL block_var_put(block(iblk)%v_cart)
       CALL ga_sync()
       CALL block_var_get(block(iblk)%uvel_p)
       CALL block_var_get(block(iblk)%vvel_p)
       CALL block_var_get(block(iblk)%u_cart)
       CALL block_var_get(block(iblk)%v_cart)
       
    END DO
  END SUBROUTINE velocity_shift

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION uarea
  ! computes the flow area for an arbitrary u location, i is a u
  ! location, jbeg and jend are cell locations
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION uarea(blk, i, jbeg, jend)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(IN) :: blk
    INTEGER, INTENT(IN) :: i, jbeg, jend

    INTEGER :: j
    DOUBLE PRECISION :: d, a

    uarea = 0.0

    DO j = jbeg, jend
       IF (i .GT. blk%xmax) THEN
          d = blk%depth%current(i-1, j)
       ELSE IF (i .LT. 2) THEN
          d = blk%depth%current(i, j)
       ELSE
          d = 0.5*(blk%depth%current(i+1, j) + blk%depth%current(i, j))
       END IF
       a = d*blk%hu2%current(i,j)
       uarea = uarea + a
    END DO

  END FUNCTION uarea

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION uflux
  ! computes the flux through an arbitrary u location, i is a u
  ! location, jbeg and jend are cell locations
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION uflux(blk, i, jbeg, jend)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(IN) :: blk
    INTEGER, INTENT(IN) :: i, jbeg, jend

    INTEGER :: j
    DOUBLE PRECISION :: a, q

    uflux = 0.0

    DO j = jbeg, jend
       a = uarea(blk, i, j, j)
       q = a*blk%uvel%current(i,j)
       uflux = uflux + q
    END DO
  END FUNCTION uflux

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION varea
  ! computes the flow area for an arbitrary v location, j is a v
  ! location, ibeg and iend are cell locations
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION varea(blk, ibeg, iend, j)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(IN) :: blk
    INTEGER, INTENT(IN) :: ibeg, iend, j

    INTEGER :: i
    DOUBLE PRECISION :: d, a

    varea = 0.0

    DO i = ibeg, iend
       IF (j .GT. blk%ymax) THEN
          d = blk%depth%current(i, j-1)
       ELSE IF (j .LT. 2) THEN
          d = blk%depth%current(i, j)
       ELSE
          d = 0.5*(blk%depth%current(i, j+1) + blk%depth%current(i, j))
       END IF
       a = d*blk%hv1%current(i,j)
       varea = varea + a
    END DO

  END FUNCTION varea

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION vflux
  ! computes the flux through an arbitrary v location, i is a u
  ! location, jbeg and jend are cell locations
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION vflux(blk, ibeg, iend, j)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(IN) :: blk
    INTEGER, INTENT(IN) :: ibeg, iend, j 

    INTEGER :: i
    DOUBLE PRECISION :: a, q

    vflux = 0.0

    DO i = ibeg, iend
       a = varea(blk, i, i, j)
       q = a*blk%vvel%current(i,j)
       vflux = vflux + q
    END DO
  END FUNCTION vflux

  ! ----------------------------------------------------------------
  ! SUBROUTINE depth_check
  ! 
  ! Collective
  ! ----------------------------------------------------------------
  SUBROUTINE depth_check(blk, date_str, time_str)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(INOUT) :: blk
    CHARACTER (LEN=*), INTENT(IN) :: date_str, time_str

#include "mafdecls.fh"
#include "global.fh"

    INTEGER :: x_beg, x_end, y_beg, y_end, i, j
    INTEGER :: crash(1)

    crash(1) = 0

    x_beg = 2
    x_end = blk%xmax
    y_beg = 2
    y_end = blk%ymax

    DO i = x_beg, x_end
       DO j = y_beg, y_end
          IF (.NOT. block_owns(blk, i, j)) CYCLE
          IF (blk%depth%current(i,j) <= 0.0) THEN
             IF (do_wetdry) THEN
                WRITE(utility_error_iounit,*)" ERROR: Negative Depth = ",blk%depth%current(i,j)
                WRITE(utility_error_iounit,*)"     Simulation Time: ", date_str, " ", time_str
                WRITE(utility_error_iounit,*)"     Block Number = ",blk%index
                WRITE(utility_error_iounit,*)"     I,J Location of negative depth = (", i, ", ", j, ")"

                WRITE(*,*)" ERROR: Negative Depth = ",blk%depth%current(i,j)
                WRITE(*,*)"     Simulation Time: ", date_str, " ", time_str
                WRITE(*,*)"     Block Number = ",blk%index
                WRITE(*,*)"     I,J Location of negative depth = (", i, ", ", j, ")"

                blk%depth%current(i,j) = dry_zero_depth
             ELSE

                WRITE(utility_error_iounit,*)" FATAL ERROR: Negative Depth = ",MINVAL(blk%depth%current)
                WRITE(utility_error_iounit,*)"     Block Number = ",blk%index
                WRITE(utility_error_iounit,*)"     I,J Location of negative depth = ",MINLOC(blk%depth%current)

                WRITE(*,*)" FATAL ERROR: Negative Depth = ",MINVAL(blk%depth%current)
                WRITE(*,*)"     Block Number = ",blk%index
                WRITE(*,*)"     I,J Location of negative depth = ",MINLOC(blk%depth%current)

                crash(1) = 1

             END IF
          ELSE IF (.NOT. do_wetdry .AND. blk%depth%current(i,j) <= 0.20) THEN
             WRITE(utility_error_iounit,*)" WARNING: Small Depth = ", blk%depth%current(i,j)
             WRITE(utility_error_iounit,*)"     Simulation Time: ", date_str, " ", time_str
             WRITE(utility_error_iounit,*)"     Block Number = ",blk%index
             WRITE(utility_error_iounit,*)"     I,J Location of small depth = ",i, j
          END IF
       END DO
    END DO

    CALL ga_igop(MT_INT, crash, 1, '+');

  END SUBROUTINE depth_check

  ! ----------------------------------------------------------------
  ! SUBROUTINE bedshear
  ! computes the shear used by biota/sediment scalars
  ! ----------------------------------------------------------------
  SUBROUTINE bedshear(blk)

    IMPLICIT NONE

    TYPE (block_struct) :: blk
    INTEGER :: i, j
    DOUBLE PRECISION :: roughness, u, v

    blk%shear = 0 
    DO i = 1, blk%xmax + 1
       DO j = 2, blk%ymax
          IF (.NOT. block_owns(blk, i, j)) CYCLE
          IF (i .EQ. 1) THEN
             u = blk%uvel%current(i,j)
             v = 0.0
          ELSE IF (i .EQ. blk%xmax + 1) THEN
             u = blk%uvel%current(i-1,j)
             v = 0.0
          ELSE 
             u = 0.5*(blk%uvel%current(i-1,j) + blk%uvel%current(i,j))
             v = 0.5*(blk%vvel%current(i-1,j) + blk%vvel%current(i,j))
          END IF
          IF(manning)THEN
             roughness = 0.0
             IF (blk%depth%current(i,j) .GT. 0.0) THEN
                roughness = (grav*blk%chezy%current(i,j)**2)/&
                     &(mann_con*blk%depth%current(i,j)**0.3333333)
             END IF
          ELSE
             roughness = blk%chezy%current(i,j)
          ENDIF
          blk%shear(i,j) = roughness*density*(u*u + v*v)
       END DO
    END DO

  END SUBROUTINE bedshear

  ! ----------------------------------------------------------------
  ! SUBROUTINE calc_eddy_viscosity
  ! ----------------------------------------------------------------
  SUBROUTINE calc_eddy_viscosity(blk)

    IMPLICIT NONE

    TYPE (block_struct), INTENT(INOUT) :: blk

    INTEGER :: i, j
    DOUBLE PRECISION :: eddystar

    DO i = 2, blk%xmax
       DO j = 2, blk%ymax
          IF (block_owns(blk, i, j)) THEN
             eddystar = viscosity_water + &
                  &vonkarmon/6.0*sqrt(blk%shear(i,j)/density)*blk%depth%current(i,j)
             blk%eddy%current(i,j) = relax_eddy*eddystar +&
                  &(1.0 - relax_eddy)*blk%eddy%current(i,j)
          END IF
       END DO
    END DO

  END SUBROUTINE calc_eddy_viscosity

END MODULE block_hydro
