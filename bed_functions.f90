! ----------------------------------------------------------------
! file: bed_erosion.f90

! Some functions to allow the suspended sediment and particulate
! species to find out about the bed We have to put these functions in
! their own object file to avoid a circular module dependancy (Fortran
! can't handle it)

! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created September  6, 2000 by William A. Perkins
! Last Change: Mon Jul 23 09:45:20 2001 by William A. Perkins <perk@dora.pnl.gov>
! ----------------------------------------------------------------

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_max_erosion
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_max_erosion(ifract, iblk, i, j, deltat)

  USE bed_module
  
  IMPLICIT NONE
  INTEGER :: ifract, iblk, i, j
  DOUBLE PRECISION :: deltat

  DOUBLE PRECISION :: mass

  mass = bed(iblk)%sediment(ifract, i, j)

  bed_max_erosion = mass/deltat

END FUNCTION bed_max_erosion

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_max_part_erosion
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_max_part_erosion(ispecies, iblk, i, j, deltat)

  USE bed_module
  
  IMPLICIT NONE
  INTEGER :: ispecies, iblk, i, j
  DOUBLE PRECISION :: deltat

  DOUBLE PRECISION :: mass

  mass = bed(iblk)%particulate(ispecies, i, j)

  bed_max_part_erosion = mass/deltat

END FUNCTION bed_max_part_erosion

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_part_conc
! returns the current concentration of a particulate per unit sediment
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_part_conc(ispecies, ifract, iblk, i, j)

  USE bed_module

  IMPLICIT NONE

  INTEGER, INTENT(IN) ::ispecies, ifract,  iblk, i, j

  IF (bed(iblk)%sediment(ifract, i, j) .GT. 0.0d0) THEN
     bed_part_conc = bed(iblk)%particulate(ispecies, i, j) / &
          &bed(iblk)%sediment(ifract, i, j)
  ELSE
     bed_part_conc = 0.0
  END IF

END FUNCTION bed_part_conc

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_part_vconc
! returns the current concentration of a particulate per unit bed
! volume, ispecies is the index of the dissolved phase scalar.  This
! function is used by the biota.
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_part_vconc(ispecies, iblk, i, j)

  USE scalars_source !, ONLY: source_doing_sed
  USE bed_module

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: ispecies, iblk, i, j
  INTEGER :: ipart, idiss

  bed_part_vconc = 0.0

  if (.NOT. source_doing_sed) RETURN
  
  IF (bed(iblk)%depth(i, j) .LE. 0.0) RETURN
  
  DO ipart = 1, max_species
     SELECT CASE (scalar_source(ipart)%srctype)
     CASE (PART)
        idiss = scalar_source(ipart)%part_param%disidx
        IF (idiss .EQ. ispecies) &
             &bed_part_vconc = bed_part_vconc + &
             &bed(iblk)%particulate(ipart, i, j)
     END SELECT
  END DO
  
  bed_part_vconc = bed_part_vconc/bed(iblk)%depth(i, j)

  RETURN
END FUNCTION bed_part_vconc

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_pore_conc
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_pore_conc(ispecies, iblk, i, j)

  USE scalars_source ! , ONLY: source_doing_sed
  USE bed_module

  IMPLICIT NONE

  INTEGER, INTENT(IN) ::ispecies, iblk, i, j

  bed_pore_conc = 0.0
  if (.NOT. source_doing_sed) RETURN
  IF (bed(iblk)%depth(i, j) .LE. 0.0) RETURN

  bed_pore_conc = bed(iblk)%pore(ispecies, i, j)/bed(iblk)%depth(i, j)/bed(iblk)%porosity(i, j)

  RETURN
END FUNCTION bed_pore_conc


! ----------------------------------------------------------------
! SUBROUTINE bed_porosity
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_porosity(iblk, i, j)

  USE bed_module

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: iblk, i, j

  bed_porosity = bed(iblk)%porosity(i, j)

END FUNCTION bed_porosity

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_depth
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_depth(iblk, i, j)

  USE bed_module

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: iblk, i, j

  bed_depth = bed(iblk)%depth(i, j)

END FUNCTION bed_depth

! ----------------------------------------------------------------
! DOUBLE PRECISION FUNCTION bed_sediment_mass
! ----------------------------------------------------------------
DOUBLE PRECISION FUNCTION bed_sediment_mass(ifract, iblk, i, j)

  USE bed_module
  
  IMPLICIT NONE
  INTEGER :: ifract, iblk, i, j

  bed_sediment_mass = bed(iblk)%sediment(ifract, i, j)
END FUNCTION bed_sediment_mass