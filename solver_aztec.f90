! ----------------------------------------------------------------
! file: solver_aztec.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created November  4, 2002 by William A. Perkins
! Last Change: Mon Jan 13 07:40:44 2003 by William A. Perkins <perk@leechong.pnl.gov>
! ----------------------------------------------------------------

! ----------------------------------------------------------------
! MODULE solver_module
! ----------------------------------------------------------------
MODULE solver_module

  IMPLICIT NONE

  include "../aztec/lib/az_aztecf.h"

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"


  INTEGER, PRIVATE, DIMENSION(0:AZ_PROC_SIZE) :: &
       &proc_config, &          ! Processor information.
       &options                 ! Array used to select solver options.

  DOUBLE PRECISION, PRIVATE, DIMENSION(0:AZ_PARAMS_SIZE) :: &
       &params                  ! User selected solver paramters.

  double precision, PRIVATE, DIMENSION(0:AZ_STATUS_SIZE) :: &
       &status                  ! Information returned from AZ_solve()

  integer, PRIVATE, ALLOCATABLE, DIMENSION(:) :: &
       &update, &               ! vector elements updated on this node.
       &extern, &             ! vector elements needed by this node.
       &update_index, &         ! ordering of update[] and extern[] 
       &extern_index, &         ! locally on this processor
       &bindx, &                ! Sparse matrix indices
       &data_org                ! Array to specify data layout 

  DOUBLE PRECISION, PRIVATE, ALLOCATABLE, DIMENSION(:) :: &
       &val, &                  ! sparse matrix values
       &b, xsol                 ! rhs and approximate solution


  INTEGER, PRIVATE, PARAMETER :: MAX_NZ_ROW = 5
CONTAINS

  ! ----------------------------------------------------------------
  ! INTEGER FUNCTION solver_initialize
  ! Returns 0 if all is well
  ! ----------------------------------------------------------------
  INTEGER FUNCTION solver_initialize(blocks, xmax, ymax)

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: blocks, xmax(blocks), ymax(blocks)

    INTEGER :: imax, jmax

                                ! do serial only -- for now

    call AZ_set_proc_config(proc_config, AZ_NOT_MPI)

                                ! allocate matrix storage space based
                                ! on the largest block dimensions
    
    imax = MAXVAL(xmax) + 1
    jmax = MAXVAL(ymax) + 1

    ALLOCATE(&
         &b(0:imax*jmax), & 
         &xsol(0:imax*jmax), &
         &data_org(0:imax*jmax), &
         &update(0:imax*jmax), &
         &extern(0:imax*jmax), &
         &update_index(0:imax*jmax), &
         &extern_index(0:imax*jmax), &
         &bindx(0:imax*jmax*MAX_NZ_ROW+1), &
         &val(0:imax*jmax*MAX_NZ_ROW+1))

    call AZ_set_proc_config(proc_config, AZ_NOT_MPI)

    solver_initialize = 0

  END FUNCTION solver_initialize

  ! ----------------------------------------------------------------
  ! SUBROUTINE solver_read_config
  ! ----------------------------------------------------------------
  SUBROUTINE solver_read_config()

    IMPLICIT NONE

  END SUBROUTINE solver_read_config


  ! ----------------------------------------------------------------
  ! INTEGER FUNCTION solver
  ! ----------------------------------------------------------------
  INTEGER FUNCTION solver(blk, x_start, x_end, y_start, y_end, its, &
       &ap, aw, ae, as, an, bp, x)

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: blk, x_start, x_end, y_start, y_end, its
    DOUBLE PRECISION, INTENT(IN), &
         &DIMENSION(x_start:x_end,y_start:y_end) :: &
         &ap, aw, ae, as, an, bp
    DOUBLE PRECISION, INTENT(INOUT), &
         &DIMENSION(x_start:x_end,y_start:y_end) :: x

    INTEGER :: N_update
    INTEGER :: imax, jmax, i, j, idx, location
    INTEGER :: iP, iW, iE, iS, iN

                                ! this was used in development to
                                ! quickly change the signs of the
                                ! neighbor cell coefficients.  The
                                ! test case was formulated such that
                                ! the neighbor cell coefficients had
                                ! to be negated.

    DOUBLE PRECISION, PARAMETER :: sign = -1.0

                                ! x_start, y_start and x_end, y_end
                                ! define the region to solve: imax x
                                ! jmax cells

    imax = x_end - x_start + 1
    jmax = y_end - y_start + 1

    CALL AZ_read_update(N_update,update,proc_config,imax*jmax,1,AZ_linear)

                                ! fill the sparse matrix

    bindx(0) = N_update + 1
    DO location = 0, N_update - 1

                                ! this is the current matrix row 

       iP = update(location)

                                ! current cell indices 
       i = iP/jmax
       j = iP - i*jmax

                                ! neigbor cell indicies

       iE = (i+1)*jmax + j
       iW = (i-1)*jmax + j
       iN = i*jmax + (j+1)
       iS = i*jmax + (j-1)

                                ! put assign appropriate indices and
                                ! values to the sparse matrix

       idx = bindx(location)
       IF (i .GT. 0) THEN 
          bindx(idx) = iW
          val(idx) = sign*aw(i+x_start, j+y_start)
          idx = idx + 1
       END IF
       IF (j .GT. 0) THEN 
          bindx(idx) = iS
          val(idx) = sign*as(i+x_start, j+y_start)
          idx = idx + 1
       END IF
       IF (i .LT. imax - 1) THEN 
          bindx(idx) = iE
          val(idx) = sign*ae(i+x_start, j+y_start)
          idx = idx + 1
       END IF
       IF (j .LT. jmax - 1) THEN 
          bindx(idx) = iN
          val(idx) = sign*an(i+x_start, j+y_start)
          idx = idx + 1
       END IF
       val(location) = ap(i+x_start, j+y_start)
       bindx(location+1) = idx

    END DO

                                ! distribute the matrix

    CALL AZ_transform(proc_config, extern, bindx, val, update, update_index,&
         &extern_index, data_org, N_update, 0, 0, 0, 0, AZ_MSR_MATRIX)

                                ! set the solver options

    CALL AZ_defaults(options, params)
    options(AZ_output) = AZ_none
    options(AZ_solver) = AZ_bicgstab
    options(AZ_precond) = AZ_sym_GS
    options(AZ_max_iter) = its
    options(AZ_poly_ord) = 2
    options(AZ_conv) = AZ_r0
    params(AZ_tol) = 1e-1

                                ! fill the initial value and rhs
                                ! vectors according to the re-ordering
                                ! done by AZ_transform
    
    DO location = 0, N_update - 1
       iP = update_index(location)
       i = iP/jmax
       j = iP - i*jmax
       b(iP) = bp(i+x_start, j+y_start)
       xsol(iP) = x(i+x_start, j+y_start)
    END DO

                                ! solve the system

    CALL AZ_solve(xsol,b, options, params, 0,bindx,0,0, 0,val, &
         &data_org, status, proc_config)

                                ! copy the (approximate) solution back
                                ! into the initial value

    DO location = 0, N_update - 1
       iP = update_index(location)
       i = iP/jmax
       j = iP - i*jmax
       x(i+x_start, j+y_start) = xsol(iP)
    END DO

    IF (status(AZ_why) .EQ. AZ_normal) THEN
       ! WRITE (*,*) 'Successful solution after ', INT(status(AZ_its)), ' iterations'
       solver = 0
    ELSE
       ! WRITE (*,*) 'Solution failed after ', INT(status(AZ_its)), ' iterations, reason: ', INT(status(AZ_why))
       solver = status(AZ_why)
    END IF

100 FORMAT(2(I5, 1X), 7G11.4)


  END FUNCTION solver

  ! ----------------------------------------------------------------
  ! INTEGER FUNCTION solver_finalize
  ! ----------------------------------------------------------------
  INTEGER FUNCTION solver_finalize()

    IMPLICIT NONE

    DEALLOCATE(&
         &b, &
         &xsol, &
         &data_org, &
         &update, &
         &extern, &
         &update_index, &
         &extern_index, &
         &bindx, &
         &val)

    solver_finalize = 0

  END FUNCTION solver_finalize

END MODULE solver_module