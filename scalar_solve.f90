! ----------------------------------------------------------------
! file: scalar_solve.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created August 19, 2003 by William A. Perkins
! Last Change: Thu Apr 15 11:11:53 2004 by William A. Perkins <perk@leechong.pnl.gov>
! ----------------------------------------------------------------
! $Id$

! ----------------------------------------------------------------
! SUBROUTINE bedshear
! computes the shear used by biota/sediment scalars
! ----------------------------------------------------------------
SUBROUTINE bedshear(blk)

  USE globals, ONLY: block_struct, grav, density
  USE misc_vars, ONLY: manning, mann_con

  IMPLICIT NONE

  TYPE (block_struct) :: blk
  INTEGER :: i, j
  DOUBLE PRECISION :: roughness, u, v

  blk%shear = 0 
  DO i = 1, blk%xmax + 1
     DO j = 2, blk%ymax
        IF (i .EQ. 1) THEN
           u = blk%uvel(i,j)
           v = 0.0
        ELSE IF (i .EQ. blk%xmax + 1) THEN
           u = blk%uvel(i-1,j)
           v = 0.0
        ELSE 
           u = 0.5*(blk%uvel(i-1,j) + blk%uvel(i,j))
           v = 0.5*(blk%vvel(i-1,j) + blk%vvel(i,j))
        END IF
        IF(manning)THEN
           roughness = 0.0
           IF (blk%depth(i,j) .GT. 0.0) THEN
              roughness = (grav*blk%chezy(i,j)**2)/&
                   &(mann_con*blk%depth(i,j)**0.3333333)
           END IF
        ELSE
           roughness = blk%chezy(i,j)
        ENDIF
        blk%shear(i,j) = roughness*density*sqrt(u*u + v*v)
     END DO
  END DO

END SUBROUTINE bedshear

! ----------------------------------------------------------------
! SUBROUTINE transport_precalc
! This routine precalculates various hydrodynamic values needed
! ----------------------------------------------------------------
SUBROUTINE transport_precalc(blk)

  USE globals, ONLY: block_struct
  USE misc_vars, ONLY: delta_t

  IMPLICIT NONE

  TYPE (block_struct), INTENT(INOUT) :: blk
  DOUBLE PRECISION :: hp1,hp2,he1,he2,hw1,hw2,hn1,hn2,hs1,hs2	! metric coefficients at p,e,w,n,s
  DOUBLE PRECISION :: xdiffp, ydiffp
  INTEGER :: i, j, x_end, y_end

  x_end = blk%xmax
  y_end = blk%ymax

  i = 1
  ! blk%inlet_area(2:y_end) = blk%depth(i,2:y_end)*blk%hu2(i,2:y_end)

  blk%k_e = 0.0
  blk%k_w = 0.0
  blk%k_n = 0.0
  blk%k_s = 0.0
  DO i= 2,x_end
     DO j=2,y_end
        
        hp1 = blk%hp1(i,j)
        hp2 = blk%hp2(i,j)
        he1 = blk%hu1(i,j)
        he2 = blk%hu2(i,j)
        hw1 = blk%hu1(i-1,j)
        hw2 = blk%hu2(i-1,j)
        hs1 = blk%hv1(i,j-1)
        hs2 = blk%hv2(i,j-1)
        hn1 = blk%hv1(i,j)
        hn2 = blk%hv2(i,j)
        
                                ! do not allow diffusion in dead cells 
        
        IF (blk%isdead(i,j)%p) THEN
           xdiffp = 0.0
           ydiffp = 0.0
        ELSE 
           xdiffp = blk%kx_diff(i,j)
           ydiffp = blk%ky_diff(i,j)
        END IF
        
                                ! use the harmonic, rather than
                                ! arithmatic, mean of diffusivity

        IF (xdiffp .GT. 0.0) THEN
           IF (.NOT. blk%isdead(i,j)%u) THEN
              blk%k_e(i,j) = &
                   &2.0*xdiffp*blk%kx_diff(i+1,j)/&
                   &(xdiffp + blk%kx_diff(i+1,j))
           END IF
           IF (.NOT. blk%isdead(i-1,j)%u) THEN
              blk%k_w(i,j) = &
                   &2.0*xdiffp*blk%kx_diff(i-1,j)/&
                   &(xdiffp + blk%kx_diff(i-1,j))
           END IF
        END IF
        
        IF (ydiffp .GT. 0.0) THEN
           IF (.NOT. blk%isdead(i,j)%v) THEN
              blk%k_n(i,j) = &
                   &2.0*ydiffp*blk%ky_diff(i,j+1)/&
                   &(ydiffp + blk%ky_diff(i,j+1))
           END IF
           IF (.NOT. blk%isdead(i,j-1)%v) THEN
              blk%k_s(i,j) = &
                   &2.0*ydiffp*blk%ky_diff(i,j-1)/&
                   &(ydiffp + blk%ky_diff(i,j-1))
           END IF
        END IF
        
        ! blk%k_e(i,j) = 0.5*(blk%kx_diff(i,j)+blk%kx_diff(i+1,j))
        ! blk%k_w(i,j) = 0.5*(blk%kx_diff(i,j)+blk%kx_diff(i-1,j))
        ! blk%k_n(i,j) = 0.5*(blk%ky_diff(i,j)+blk%ky_diff(i,j+1))
        ! blk%k_s(i,j) = 0.5*(blk%ky_diff(i,j)+blk%ky_diff(i,j-1))
        
        blk%depth_e(i,j) = 0.5*(blk%depth(i,j)+blk%depth(i+1,j))
        blk%depth_w(i,j) = 0.5*(blk%depth(i,j)+blk%depth(i-1,j))
        blk%depth_n(i,j) = 0.5*(blk%depth(i,j)+blk%depth(i,j+1))
        blk%depth_s(i,j) = 0.5*(blk%depth(i,j)+blk%depth(i,j-1))

        ! IF(i == 2) blk%depth_w(i,j) = blk%depth(i-1,j)
        ! IF(i == x_end) blk%depth_e(i,j) = blk%depth(i+1,j)
        IF(j == 2) blk%depth_s(i,j) = blk%depth(i,j-1)
        IF(j == y_end) blk%depth_n(i,j) = blk%depth(i,j+1)
        
        blk%flux_e(i,j) = he2*blk%uvel(i,j)*blk%depth_e(i,j)
        blk%flux_w(i,j) = hw2*blk%uvel(i-1,j)*blk%depth_w(i,j)
        blk%flux_n(i,j) = hn1*blk%vvel(i,j)*blk%depth_n(i,j)
        blk%flux_s(i,j) = hs1*blk%vvel(i,j-1)*blk%depth_s(i,j)
        blk%diffu_e(i,j) = blk%k_e(i,j)*blk%depth_e(i,j)*he2/he1
        blk%diffu_w(i,j) = blk%k_w(i,j)*blk%depth_w(i,j)*hw2/hw1
        blk%diffu_n(i,j) = blk%k_n(i,j)*blk%depth_n(i,j)*hn1/hn2
        blk%diffu_s(i,j) = blk%k_s(i,j)*blk%depth_s(i,j)*hs1/hs2
        
                                ! only needed when the power law scheme is used
        ! blk%pec_e(i,j) = blk%flux_e(i,j)/blk%diffu_e(i,j)
        ! blk%pec_w(i,j) = blk%flux_w(i,j)/blk%diffu_w(i,j)
        ! blk%pec_n(i,j) = blk%flux_n(i,j)/blk%diffu_n(i,j)
        ! blk%pec_s(i,j) = blk%flux_s(i,j)/blk%diffu_s(i,j)
           
     END DO
  END DO

  blk%apo(2:x_end,2:y_end) = blk%hp1(2:x_end,2:y_end)*blk%hp2(2:x_end,2:y_end)*&
       &blk%depthold(2:x_end,2:y_end)/delta_t

END SUBROUTINE transport_precalc


! ----------------------------------------------------------------
! SUBROUTINE scalar_solve
! ----------------------------------------------------------------
SUBROUTINE scalar_solve(blkidx, blk, scalar, xstart, ystart)

  USE globals, ONLY: block_struct
  USE scalars, ONLY: scalar_struct, SCALAR_BOUNDARY_TYPE, SCALBC_CONC, SCALBC_ZG
  USE solver_module

  IMPLICIT NONE
  
  TYPE (block_struct), INTENT(IN) :: blk
  TYPE (scalar_struct), INTENT(INOUT) :: scalar
  INTEGER, INTENT(IN) :: blkidx, xstart, ystart

  INTEGER :: xend, yend

  DOUBLE PRECISION :: &
       & ap(xstart:blk%xmax, ystart:blk%ymax),&
       & ae(xstart:blk%xmax, ystart:blk%ymax), &
       & aw(xstart:blk%xmax, ystart:blk%ymax), &
       & an(xstart:blk%xmax, ystart:blk%ymax), &
       & as(xstart:blk%xmax, ystart:blk%ymax), &
       & bp(xstart:blk%xmax, ystart:blk%ymax)

  INTEGER :: i, j, junk

  xend = blk%xmax
  yend = blk%ymax


  ae(xstart:xend,ystart:yend) = &
       &max(0d+00, -blk%flux_e(xstart:xend,ystart:yend), &
       &blk%diffu_e(xstart:xend,ystart:yend) - &
       &blk%flux_e(xstart:xend,ystart:yend)/2.0)
  aw(xstart:xend,ystart:yend) = &
       &max(0d+00, blk%flux_w(xstart:xend,ystart:yend), &
       &blk%diffu_w(xstart:xend,ystart:yend) + &
       &blk%flux_w(xstart:xend,ystart:yend)/2.0)
  an(xstart:xend,ystart:yend) = &
       &max(0d+00, -blk%flux_n(xstart:xend,ystart:yend), &
       &blk%diffu_n(xstart:xend,ystart:yend) - &
       &blk%flux_n(xstart:xend,ystart:yend)/2.0)
  as(xstart:xend,ystart:yend) = &
       &max(0d+00, blk%flux_s(xstart:xend,ystart:yend), &
       &blk%diffu_s(xstart:xend,ystart:yend) + &
       &blk%flux_s(xstart:xend,ystart:yend)/2.0)
  bp = 0.0

  DO i= xstart,xend
     DO j=ystart,yend

        ap(i,j) = ae(i,j) + aw(i,j) + an(i,j) + as(i,j) + blk%apo(i,j) 
        bp(i,j) = scalar%srcterm(i,j) + blk%apo(i,j)* scalar%concold(i,j)

        SELECT CASE (scalar%cell(i,j)%xtype)
        CASE (SCALAR_BOUNDARY_TYPE)
           SELECT CASE (scalar%cell(i,j)%xbctype)
           CASE (SCALBC_CONC)
              IF (i .EQ. xstart) THEN
                 bp(i,j) = bp(i,j) + 2.0*aw(i,j)* scalar%conc(i-1,j)
                 ap(i,j) = ap(i,j) + aw(i,j)
                 aw(i,j) = 0.0
              END IF
           CASE DEFAULT
              IF (i .EQ. xstart) THEN
                 ap(i,j) = ap(i,j) - aw(i,j)
                 aw(i,j) = 0.0
              ELSE IF (i .EQ. xend) THEN
                 ap(i,j) = ap(i,j) - ae(i,j)
                 ae(i,j) = 0.0
              END IF
           END SELECT
        CASE DEFAULT
           IF (i .EQ. xstart) THEN
              bp(i,j) = bp(i,j) + aw(i,j)*scalar%conc(i-1,j)
              aw(i,j) = 0.0
           ELSE IF (i .EQ. xend) THEN
              bp(i,j) = bp(i,j) + ae(i,j)*scalar%conc(i+1,j)
              ae(i,j) = 0.0
           END IF
        END SELECT

        SELECT CASE (scalar%cell(i,j)%ytype)
        CASE (SCALAR_BOUNDARY_TYPE)
           SELECT CASE (scalar%cell(i,j)%ybctype)
           CASE (SCALBC_CONC)
              IF (j .EQ. ystart) THEN
                 bp(i,j) = bp(i,j) + 2.0*as(i,j)*scalar%conc(i,j-1)
                 ap(i,j) = ap(i,j) + as(i,j)
                 as(i,j) = 0.0
              END IF
           CASE DEFAULT
              IF (j .EQ. ystart) THEN
                 ap(i,j) = ap(i,j) - as(i,j)
                 as(i,j) = 0.0
              ELSE IF (j .EQ. yend) THEN
                 ap(i,j) = ap(i,j) - an(i,j)
                 an(i,j) = 0.0
              END IF
           END SELECT
        CASE DEFAULT
           IF (j .EQ. ystart) THEN
              bp(i,j) = bp(i,j) + as(i,j)*scalar%conc(i,j-1)
              as(i,j) = 0.0
           ELSE IF (j .EQ. yend) THEN
              bp(i,j) = bp(i,j) + an(i,j)*scalar%conc(i,j+1)
              an(i,j) = 0.0
           END IF
        END SELECT

     END DO
  END DO

  junk = solver(blkidx, SOLVE_SCALAR, xstart, xend, ystart, yend, scalar_sweep, &
       &ap(xstart:xend,ystart:yend), aw(xstart:xend,ystart:yend), &
       &ae(xstart:xend,ystart:yend), as(xstart:xend,ystart:yend), &
       &an(xstart:xend,ystart:yend), bp(xstart:xend,ystart:yend), &
       &scalar%conc(xstart:xend,ystart:yend))

END SUBROUTINE scalar_solve


! ----------------------------------------------------------------
! SUBROUTINE default_scalar_bc
! ----------------------------------------------------------------
SUBROUTINE default_scalar_bc(blk, sclr)

  USE globals, ONLY: block_struct
  USE scalars, ONLY: scalar_struct, SCALAR_BOUNDARY_TYPE, SCALBC_NONE

  IMPLICIT NONE

  TYPE (block_struct), INTENT(INOUT) :: blk
  TYPE (scalar_struct), INTENT(INOUT) :: sclr

  INTEGER :: x_end, y_end, i, j

  x_end = blk%xmax
  y_end = blk%ymax

  sclr%conc(1,:) = sclr%conc(2,:)
  sclr%cell(2,:)%xtype = SCALAR_BOUNDARY_TYPE
  sclr%cell(2,:)%xbctype = SCALBC_NONE

  sclr%conc(x_end+1,:) = sclr%conc(x_end,:)
  sclr%cell(x_end,:)%xtype = SCALAR_BOUNDARY_TYPE
  sclr%cell(x_end,:)%xbctype = SCALBC_NONE

  sclr%conc(:,1) = sclr%conc(:,2)
  sclr%cell(:,2)%ytype = SCALAR_BOUNDARY_TYPE
  sclr%cell(:,2)%ybctype = SCALBC_NONE

  sclr%conc(:,y_end+1) = sclr%conc(:,y_end)
  sclr%cell(:,y_end)%ytype = SCALAR_BOUNDARY_TYPE
  sclr%cell(:,y_end)%ybctype = SCALBC_NONE

END SUBROUTINE default_scalar_bc


