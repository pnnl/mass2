! ----------------------------------------------------------------
! file: solver_test.f90
!
! This program tests the solver module by setting up the cell
! coefficients for a simple steady-state heat transfer problem.  The
! problem and (inaccurate) solution are described in Example 7.2 of
! "An Introduction to Computational Fluid Dynamics" by H.K. Versteeg
! and W. Malalasekera.  Successful output should look like (this does
! not precisely match the answer in the book):
! 
!     1     1     1    10.0     0.0     0.0    10.0    20.0   500.0  260.04
!     1     2     2    10.0    10.0     0.0    10.0    30.0   500.0  242.27
!     1     3     3    10.0    10.0     0.0    10.0    30.0   500.0  205.59
!     1     4     4     0.0    10.0     0.0    10.0    40.0  2500.0  146.32
!     2     1     5    10.0     0.0    10.0    10.0    30.0     0.0  227.80
!     2     2     6    10.0    10.0    10.0    10.0    40.0     0.0  211.20
!     2     3     7    10.0    10.0    10.0    10.0    40.0     0.0  178.18
!     2     4     8     0.0    10.0    10.0    10.0    50.0  2000.0  129.70
!     3     1     9    10.0     0.0    10.0     0.0    20.0     0.0  212.16
!     3     2    10    10.0    10.0    10.0     0.0    30.0     0.0  196.53
!     3     3    11    10.0    10.0    10.0     0.0    30.0     0.0  166.23
!     3     4    12     0.0    10.0    10.0     0.0    40.0  2000.0  123.98

! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created November  4, 2002 by William A. Perkins
! Last Change: Wed Jan 12 12:54:26 2011 by William A. Perkins <d3g096@PE10900.pnl.gov>
! ----------------------------------------------------------------

PROGRAM solver_test
  
  USE solver_module

  IMPLICIT NONE

  CHARACTER (LEN=80), SAVE :: rcsid = "$Id$"

  INTEGER, PARAMETER :: imax = 3, jmax = 4
  DOUBLE PRECISION :: k, t, w, h
  DOUBLE PRECISION :: dx,dy
  DOUBLE PRECISION, DIMENSION(1:imax,1:jmax) :: ap, aw, ae, as, an, bp, tsol
  CHARACTER (LEN=1024) :: buf

  INTEGER :: i, j, junk, limin, limax, ljmin, ljmax
  INTEGER :: iP, iN, iS, iE, iW
  INTEGER :: ierr, me, nproc, p

  DATA k, t, w, h / 1000, 0.01, 0.3, 0.4 /

  dx = w/REAL(imax)
  dy = h/REAL(jmax)

  scalar_sweep = 500

  CALL mpi_init( ierr )
  CALL mpi_comm_rank(MPI_COMM_WORLD, me, ierr)
  CALL mpi_comm_size(MPI_COMM_WORLD, nproc, ierr)

  CALL solver_initialize(1)

  SELECT CASE (nproc) 
  CASE (1)
     limin = 1
     limax = imax
     ljmin = 1
     ljmax = jmax
  CASE (2)
     limin = 1
     limax = imax
     ljmin = me*jmax/2 + 1
     ljmax = (me+1)*jmax/2
  CASE DEFAULT
     STOP
  END SELECT
     
  WRITE (*, *) me, limin, limax, ljmin, ljmax

  junk = solver_initialize_block(1, 1, imax, 1, jmax, &
       &limin, limax, ljmin, ljmax, .FALSE., .TRUE.)

  OPEN(file="junk", unit=1)
  WRITE(1,*) "Writing after Solver Initialization"
  CLOSE(1)

  OPEN(file="junk", unit=1)
  READ(1,'(A1024)') buf
  WRITE(*,*) TRIM(buf)
  CLOSE(1)

  DO i = limin, limax
     DO j = ljmin, ljmax
        bp(i,j) = 0.0
        ap(i,j) = 0.0
            
        IF (j .EQ. 1) THEN
           as(i,j) = 0.0
           bp(i,j) = bp(i,j) + 0.0
           ap(i,j) = ap(i,j) - 0.0
        ELSE
           as(i,j) = (k/dx)*(dx*t)
        END IF
        
        IF (j .EQ. jmax) THEN
           an(i,j) = 0.0
           bp(i,j) = bp(i,j) + 2*k/dy*(dy*t)*100.0
           ap(i,j) = ap(i,j) + 2*k/dy*(dy*t)
        ELSE
           an(i,j) = (k/dx)*(dx*t)
        END IF
        
        IF (i .EQ. 1) THEN
           aw(i,j) = 0.0
           bp(i,j) = bp(i,j) + 500000.0*dy*t
           ap(i,j) = ap(i,j) - 0.0
        ELSE
           aw(i,j) = (k/dx)*(dx*t)
        END IF
        
        IF (i .EQ. imax) THEN
           ae(i,j) = 0.0
           bp(i,j) = bp(i,j) + 0.0
           ap(i,j) = ap(i,j) - 0.0
        ELSE
           ae(i,j) = (k/dx)*(dx*t)
        END IF
        
        ap(i,j) = ap(i,j) + aw(i,j) + ae(i,j) + an(i,j) + as(i,j)
        
     END DO
  END DO

  tsol = 0.0

!!$  DO i = 1, imax
!!$     DO j = 1, jmax
!!$        ip = (i-1)*jmax + j
!!$        WRITE (*,100) i, j, ip, &
!!$             &an(i,j), as(i,j), aw(i,j), ae(i,j), &
!!$             &ap(i,j), bp(i,j),  tsol(i, j)
!!$     END DO
!!$  END DO


  junk = solver(1, SOLVE_SCALAR, limin, limax, ljmin, ljmax, 500, &
       &ap(limin:limax,ljmin:ljmax), aw(limin:limax,ljmin:ljmax), ae(limin:limax,ljmin:ljmax), &
       &as(limin:limax,ljmin:ljmax), an(limin:limax,ljmin:ljmax), bp(limin:limax,ljmin:ljmax), &
       &tsol(limin:limax,ljmin:ljmax))

  DO i = 1, imax
     DO j = ljmin, ljmax
        IF (.NOT.(limin .LE. i .AND. i .LE. limax)) CYCLE
        IF (.NOT.(ljmin .LE. j .AND. j .LE. ljmax)) CYCLE
        ip = (i-1)*jmax + j
        WRITE (*,100) me, i, j, ip, &
             &an(i,j), as(i,j), aw(i,j), ae(i,j), &
             &ap(i,j), bp(i,j),  tsol(i, j)
        CALL mpi_barrier(MPI_COMM_WORLD, ierr)
     END DO
  END DO

!!$  ! tsol = 0.9*tsol
!!$  junk = solver(1, SOLVE_SCALAR, 1, imax, 1, jmax, 500, &
!!$       &ap, aw, ae, &
!!$       &as, an, bp, &
!!$       &tsol)
!!$
!!$  WRITE(*,*)
!!$  DO p = 0, nproc - 1
!!$     IF (me .EQ. p) THEN
!!$        DO i = limin, limax
!!$           DO j = ljmin, ljmax
!!$              ip = (i-1)*jmax + j
!!$              WRITE (*,100) p, i, j, ip, &
!!$                   &an(i,j), as(i,j), aw(i,j), ae(i,j), &
!!$                   &ap(i,j), bp(i,j),  tsol(i, j)
!!$           END DO
!!$        END DO
!!$     END IF
!!$  END DO

  junk = solver_finalize()

  CALL mpi_finalize(junk)   
  
100 FORMAT(I2, 3I6,6F8.1, F8.2)

END PROGRAM solver_test
