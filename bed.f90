! ----------------------------------------------------------------
! file: bed.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created August 29, 2000 by William A. Perkins
! Last Change: Tue Mar 19 09:16:01 2002 by William A. Perkins <perk@leechong.pnl.gov>
! ----------------------------------------------------------------

! ----------------------------------------------------------------
! MODULE bed
! ----------------------------------------------------------------
MODULE bed_module

  USE scalars_source
  USE scalars
  USE globals

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  DOUBLE PRECISION, PRIVATE, PARAMETER :: bed_min_depth = 1d-10
  CHARACTER (LEN=*), PRIVATE, PARAMETER :: bed_init_file = "initial_bed.dat"

  LOGICAL, PUBLIC :: read_bed_init = .FALSE.

  TYPE bed_block_rec
                                ! mass of any generic species in the
                                ! bed pore space (mass/ft^2 - or
                                ! converted as with the dissolved
                                ! concentrations)

     DOUBLE PRECISION, POINTER :: pore(:,:,:)

                                ! mass of each particulate species per
                                ! unit bed area (e.g. Ci/ft^2)

     DOUBLE PRECISION, POINTER :: particulate(:,:,:) 

                                ! mass of each sediment fraction per
                                ! unit bed area

     DOUBLE PRECISION, POINTER :: sediment(:,:,:)
     DOUBLE PRECISION, POINTER :: porosity(:,:)
     DOUBLE PRECISION, POINTER :: depth(:,:)  ! feet
  END TYPE bed_block_rec

  TYPE (bed_block_rec), ALLOCATABLE :: bed(:)

  DOUBLE PRECISION, PUBLIC :: bed_default_porosity = 0.0
  DOUBLE PRECISION, PUBLIC :: bed_initial_depth = 0.0
CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_initialize
  ! ----------------------------------------------------------------
  SUBROUTINE bed_initialize()

    USE misc_vars, ONLY: i_index_min, i_index_extra, j_index_min, j_index_extra

    IMPLICIT NONE

    INTEGER :: iblk, i, j, ifract
    INTEGER :: imin, imax, jmin, jmax
    DOUBLE PRECISION :: bdens

    ALLOCATE(bed(max_blocks))
    DO iblk = 1, max_blocks

       imin = i_index_min
       imax = block(iblk)%xmax + i_index_extra
       jmin = j_index_min
       jmax = block(iblk)%ymax + j_index_extra

       ALLOCATE(bed(iblk)%pore(max_species, imin:imax, jmin:jmax))
       ALLOCATE(bed(iblk)%particulate(max_species, imin:imax, jmin:jmax))
       ALLOCATE(bed(iblk)%sediment(sediment_fractions, imin:imax, jmin:jmax))
       ALLOCATE(bed(iblk)%depth(imin:imax, jmin:jmax))
       ALLOCATE(bed(iblk)%porosity(imin:imax, jmin:jmax))

                                ! initialize with default values (from
                                ! the configuration file?)

       bed(iblk)%pore = 0.0
       bed(iblk)%particulate = 0.0
       bed(iblk)%sediment = 0.0
       bed(iblk)%porosity = bed_default_porosity
       bed(iblk)%depth = bed_initial_depth
    END DO

    IF (read_bed_init) THEN
       CALL bed_read_init()
    ELSE

                                ! assume even portions of each
                                ! sediment fraction initially (if no
                                ! other info provided)
    
       bdens = 0.0
       DO ifract = 1, sediment_fractions
          bdens = bdens + 1.0/sediment_fractions/ &
               &scalar_source(sediment_scalar_index(ifract))%sediment_param%pdens
       END DO
       
       DO iblk = 1, max_blocks
          bed(iblk)%sediment = 0.0
          DO i = 2, block(iblk)%xmax
             DO j = 2, block(iblk)%ymax
                DO ifract = 1, sediment_fractions
                   bed(iblk)%sediment(ifract, i, j) = (1.0/sediment_fractions)* &
                        &bed(iblk)%depth(i,j)/(bdens/(1 - bed(iblk)%porosity(i,j)))
                END DO
             END DO
          END DO
       END DO

    END IF

  END SUBROUTINE bed_initialize

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_sediment_exchange
  ! This is called after the completion of a time step's transport
  ! calculations.  This does the necessary erosion and deposition
  ! accounting for the bed.
  ! ----------------------------------------------------------------
  SUBROUTINE bed_sediment_exchange(deltat)

    USE misc_vars, ONLY: error_iounit

    IMPLICIT NONE
    DOUBLE PRECISION, INTENT(IN) :: deltat
    INTEGER :: iblk, ifract, i, j, sedidx
    DOUBLE PRECISION :: sconc, e, d

    DO iblk = 1, max_blocks
       DO i = 2, block(iblk)%xmax
          DO j = 2, block(iblk)%ymax
             DO ifract = 1, sediment_fractions
                sedidx = sediment_scalar_index(ifract)
                sconc = species(sedidx)%scalar(iblk)%conc(i,j)
                e = sediment_erosion(scalar_source(sedidx)%sediment_param,&
                     &iblk, i, j)
                d = sediment_deposition(scalar_source(sedidx)%sediment_param,&
                     &iblk, i, j, sconc)
                IF (d .GT. 0.0) THEN
                   bed(iblk)%sediment(ifract,i,j) = &
                        &bed(iblk)%sediment(ifract,i,j) + d*deltat
                END IF
                IF (e .GT. 0.0) THEN
                   bed(iblk)%sediment(ifract,i,j) = &
                        &bed(iblk)%sediment(ifract,i,j) - e*deltat
                   IF (bed(iblk)%sediment(ifract,i,j) .LT. 0.0) THEN
                      WRITE(*,*) 'WARNING: negative bed sediment mass ',&
                           &bed(iblk)%sediment(ifract,i,j), ' set to zero: fract=',&
                           &ifract, ', block=', iblk, ', i=', i, ', j=', j
                      WRITE(error_iounit,*) 'WARNING: negative bed sediment mass ',&
                           &bed(iblk)%sediment(ifract,i,j), ' set to zero: fract=',&
                           &ifract, ', block=', iblk, ', i=', i, ', j=', j
                      bed(iblk)%sediment(ifract,i,j) = 0.0
                   END IF
                END IF
                scalar_source(sedidx)%sediment_param%block(iblk)%deposition(i, j) = d
                scalar_source(sedidx)%sediment_param%block(iblk)%erosion(i, j) = e
             END DO
          END DO
       END DO

                                ! for output, do the edges of per unit
                                ! area values only

       scalar_source(sedidx)%sediment_param%block(iblk)%deposition(:, 1) = &
            &scalar_source(sedidx)%sediment_param%block(iblk)%deposition(:, 2)
       scalar_source(sedidx)%sediment_param%block(iblk)%deposition(:, block(iblk)%ymax + 1) =&
            &scalar_source(sedidx)%sediment_param%block(iblk)%deposition(:, block(iblk)%ymax)
       scalar_source(sedidx)%sediment_param%block(iblk)%deposition(1, :) = &
            &scalar_source(sedidx)%sediment_param%block(iblk)%deposition(2, :)
       scalar_source(sedidx)%sediment_param%block(iblk)%deposition(block(iblk)%xmax + 1, :) =&
            &scalar_source(sedidx)%sediment_param%block(iblk)%deposition(block(iblk)%xmax, :)

       scalar_source(sedidx)%sediment_param%block(iblk)%erosion(:, 1) = &
            &scalar_source(sedidx)%sediment_param%block(iblk)%erosion(:, 2)
       scalar_source(sedidx)%sediment_param%block(iblk)%erosion(:, block(iblk)%ymax + 1) =&
            &scalar_source(sedidx)%sediment_param%block(iblk)%erosion(:, block(iblk)%ymax)
       scalar_source(sedidx)%sediment_param%block(iblk)%erosion(1, :) = &
            &scalar_source(sedidx)%sediment_param%block(iblk)%erosion(2, :)
       scalar_source(sedidx)%sediment_param%block(iblk)%erosion(block(iblk)%xmax + 1, :) =&
            &scalar_source(sedidx)%sediment_param%block(iblk)%erosion(block(iblk)%xmax, :)

       bed(iblk)%sediment(ifract,:,1) = bed(iblk)%sediment(ifract,:,2)
       bed(iblk)%sediment(ifract,:,block(iblk)%ymax+1) = &
            &bed(iblk)%sediment(ifract,:,block(iblk)%ymax)
       bed(iblk)%sediment(ifract,1,:) = bed(iblk)%sediment(ifract,2,:)
       bed(iblk)%sediment(ifract,block(iblk)%xmax+1,:) = &
            &bed(iblk)%sediment(ifract,block(iblk)%xmax,:)
    END DO

    CALL bed_compute_depth()

  END SUBROUTINE bed_sediment_exchange

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_particulate_exchange
  ! ----------------------------------------------------------------
  SUBROUTINE bed_particulate_exchange(deltat)

    USE misc_vars, ONLY: error_iounit

    IMPLICIT NONE

    DOUBLE PRECISION, INTENT(IN) :: deltat
    INTEGER :: ispecies, ifract, iblk, i, j, sphase, dphase
    DOUBLE PRECISION :: dconc, bconc, pconc, sconc

    INCLUDE 'bed_functions.inc'

    DO ispecies = 1, max_species
       SELECT CASE (scalar_source(ispecies)%srctype)
       CASE (PART)
          dphase = scalar_source(ispecies)%part_param%disidx
          sphase = scalar_source(ispecies)%part_param%sedidx
          ifract = scalar_source(sphase)%sediment_param%ifract
          DO iblk = 1, max_blocks
             DO i = 2, block(iblk)%xmax 
                DO j = 2, block(iblk)%ymax
                   bconc = bed_part_conc(ispecies, &
                        &scalar_source(sphase)%sediment_param%ifract, iblk, i, j)
                   dconc = species(dphase)%scalar(iblk)%conc(i,j)
                   sconc = species(sphase)%scalar(iblk)%conc(i,j)
                   pconc = species(ispecies)%scalar(iblk)%conc(i,j)

                                ! save the particulate interaction w/
                                ! bed for output later

                   scalar_source(ispecies)%part_param%block(iblk)%bedexch(i, j) = &
                        &part_bed_exch(scalar_source(ispecies)%part_param, ispecies, &
                        &   scalar_source(sphase)%sediment_param, iblk, i, j, &
                        &   pconc, sconc, bconc)

                                ! adjust the parctulate mass according
                                ! to exchange rates

                   bed(iblk)%particulate(ispecies, i, j) = &
                        &bed(iblk)%particulate(ispecies, i, j) - &
                        &deltat*scalar_source(ispecies)%part_param%block(iblk)%bedexch(i, j) + &
                        &deltat*part_dissolve_bed_exch(scalar_source(ispecies)%part_param, &
                        &    scalar_source(sphase)%sediment_param, iblk, i, j, dconc, bconc)

                                ! check to make sure masses do not go negative

                   IF (bed(iblk)%sediment(ifract, i, j) .LE. 0.0) THEN
                      bed(iblk)%particulate(ispecies, i, j) = 0.0
                   END IF
                   IF (bed(iblk)%particulate(ispecies, i, j) .LT. 0.0) THEN
                      WRITE(*,*) 'WARNING: negative particulate mass ',&
                           &bed(iblk)%particulate(ispecies, i, j), ' set to zero: species=',&
                           &ispecies, ', block=', iblk, ', i=', i, ', j=', j
                      WRITE(error_iounit,*) 'WARNING: negative particulate mass ',&
                           &bed(iblk)%particulate(ispecies, i, j), ' set to zero: species=',&
                           &ispecies, ', block=', iblk, ', i=', i, ', j=', j
                      bed(iblk)%particulate(ispecies, i, j) = 0.0
                   END IF
                END DO
             END DO

                                ! for output, do the edges of per unit
                                ! area values only

             bed(iblk)%particulate(ispecies,:,1) = bed(iblk)%particulate(ispecies,:,2)
             bed(iblk)%particulate(ispecies,:,block(iblk)%ymax+1) = &
                  &bed(iblk)%particulate(ispecies,:,block(iblk)%ymax)
             bed(iblk)%particulate(ispecies,1,:) = bed(iblk)%particulate(ispecies,2,:)
             bed(iblk)%particulate(ispecies,block(iblk)%xmax+1,:) = &
                  &bed(iblk)%particulate(ispecies,block(iblk)%xmax,:)

             scalar_source(ispecies)%part_param%block(iblk)%bedexch(:, 1) = &
                  &scalar_source(ispecies)%part_param%block(iblk)%bedexch(:, 2)
             scalar_source(ispecies)%part_param%block(iblk)%bedexch(:, block(iblk)%ymax+1) = &
                  &scalar_source(ispecies)%part_param%block(iblk)%bedexch(:, block(iblk)%ymax)
             
             scalar_source(ispecies)%part_param%block(iblk)%bedexch(1, :) = &
                  &scalar_source(ispecies)%part_param%block(iblk)%bedexch(2, :)
             scalar_source(ispecies)%part_param%block(iblk)%bedexch(block(iblk)%xmax+1, :) = &
                  &scalar_source(ispecies)%part_param%block(iblk)%bedexch(block(iblk)%xmax, :)
          END DO
       END SELECT
    END DO
  END SUBROUTINE bed_particulate_exchange


  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_pore_exchange
  ! ----------------------------------------------------------------
  SUBROUTINE bed_pore_exchange(deltat)

    USE misc_vars, ONLY: error_iounit

    IMPLICIT NONE

    DOUBLE PRECISION, INTENT(IN) :: deltat
    INTEGER :: ispecies, iblk, i, j
    DOUBLE PRECISION :: dconc, pconc, bdepth

    INCLUDE 'bed_functions.inc'

    DO ispecies = 1, max_species
       SELECT CASE (scalar_source(ispecies)%srctype)
       CASE (GEN)
          DO iblk = 1, max_blocks
             DO i = 2, block(iblk)%xmax 
                DO j = 2, block(iblk)%ymax
                   bdepth = bed(iblk)%depth(i, j)
                   pconc = bed_pore_conc(ispecies, iblk, i, j)
                   dconc = species(ispecies)%scalar(iblk)%conc(i,j)
                   bed(iblk)%pore(ispecies, i, j) = &
                        &bed(iblk)%pore(ispecies, i, j) - &
                        &generic_bedpore_exch(scalar_source(ispecies)%generic_param, &
                        &iblk, i, j, dconc, pconc)*deltat
                END DO
             END DO
          END DO
       END SELECT

    END DO

  END SUBROUTINE bed_pore_exchange

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_compute_depth
  ! ----------------------------------------------------------------
  SUBROUTINE bed_compute_depth()
    
    IMPLICIT NONE
    
    INTEGER :: iblk, i, j, ifract, ispec
    DOUBLE PRECISION :: vs

    DO iblk = 1, max_blocks
       DO i = 2, block(iblk)%xmax
          DO j = 2, block(iblk)%ymax
             vs = 0.0
             DO ifract = 1, sediment_fractions
                ispec = sediment_scalar_index(ifract)
                vs = vs + bed(iblk)%sediment(ifract,i,j)/&
                     &scalar_source(ispec)%sediment_param%pdens
             END DO
             bed(iblk)%depth(i,j) = vs/(1 - bed(iblk)%porosity(i,j))
          END DO
       END DO

                                ! do the edges for output

       bed(iblk)%depth(:,1) = bed(iblk)%depth(:,2)
       bed(iblk)%depth(:,block(iblk)%ymax+1) = bed(iblk)%depth(:,block(iblk)%ymax)
       bed(iblk)%depth(1,:) = bed(iblk)%depth(2,:)
       bed(iblk)%depth(block(iblk)%xmax+1,:) = bed(iblk)%depth(block(iblk)%xmax,:)
    END DO
  
  END SUBROUTINE bed_compute_depth

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_equilibrate

  ! This routine rearranges (and decays) contaminant between sediment
  ! fractions and pore water in the bed

  ! ----------------------------------------------------------------
  SUBROUTINE bed_equilibrate(deltat)

    IMPLICIT NONE

    DOUBLE PRECISION, INTENT(IN) :: deltat
    INTEGER :: iblk, i, j
    INTEGER :: ifract, ispecies, disidx, sedidx

                                ! cmass is the total contaminant mass
                                ! in the bed (per unit area) indexed
                                ! by the index of the *dissolved*
                                ! scalar species

    DOUBLE PRECISION :: cmass(max_species), kdsum(max_species)
    DOUBLE PRECISION :: fract(sediment_fractions)
    DOUBLE PRECISION :: sum, bdens


    DO iblk = 1, max_blocks
       DO i = 2, block(iblk)%xmax 
          DO j = 2, block(iblk)%ymax 

                                ! precompute bed sediment mass and
                                ! bulk density
    
             bdens = 0.0
             sum = 0.0
             DO ifract = 1, sediment_fractions
                sum = sum + bed(iblk)%sediment(ifract, i, j)
                bdens = bdens + bed(iblk)%sediment(ifract, i, j)/&
                     &scalar_source(sediment_scalar_index(ifract))%sediment_param%pdens
             END DO

             IF (bdens .GT. 0.0) THEN
                bdens = sum/bdens*(1.0 - bed(iblk)%porosity(i, j))
             END IF

             IF (sum .GT. 0.0) THEN

                                ! compute total mass of each
                                ! contaminant in bed

                kdsum = 0.0
                cmass = 0.0
                DO ispecies = 1, max_species
                   SELECT CASE (scalar_source(ispecies)%srctype)
                   CASE (GEN)
                      cmass(ispecies) = cmass(ispecies) + &
                           &bed(iblk)%pore(ispecies, i, j)
                   CASE (PART)
                      disidx = scalar_source(ispecies)%part_param%disidx
                      sedidx = scalar_source(ispecies)%part_param%sedidx
                      ifract =  scalar_source(sedidx)%sediment_param%ifract
                      cmass(disidx) = cmass(disidx) + &
                           &bed(iblk)%particulate(ispecies, i, j)
                      kdsum(disidx) = kdsum(disidx) +  &
                           &scalar_source(ispecies)%part_param%bedkd*&
                           &bed(iblk)%sediment(ifract, i, j)/sum
                   END SELECT
                END DO
                
                                ! decay the total contaminant mass if
                                ! appropriate

                DO ispecies = 1, max_species
                   SELECT CASE (scalar_source(ispecies)%srctype)
                   CASE (GEN)
                      IF (cmass(ispecies) .LE. 0.0) cmass(ispecies) = 0.0
                      IF (scalar_source(ispecies)%generic_param%halflife .GT. 0.0) THEN
                         cmass(ispecies) = cmass(ispecies)*&
                              &EXP(-scalar_source(ispecies)%generic_param%lamda*deltat)
                      END IF
                   END SELECT
                END DO

                                ! compute the pore water concentrations first

                DO ispecies = 1, max_species
                   SELECT CASE (scalar_source(ispecies)%srctype)
                   CASE (GEN)
                      IF (scalar_source(ispecies)%generic_param%issorbed .AND. &
                           &kdsum(ispecies) .GT. 0.0) THEN
                         bed(iblk)%pore(ispecies, i, j) = cmass(ispecies)/&
                              &(1 + bdens/bed(iblk)%porosity(i,j)*kdsum(ispecies))
                      END IF
                   END SELECT
                END DO
                
                                ! then compute the redistributed
                                ! particulate concentrations

                DO ispecies = 1, max_species
                   SELECT CASE (scalar_source(ispecies)%srctype)
                   CASE (PART)
                      disidx = scalar_source(ispecies)%part_param%disidx
                      sedidx = scalar_source(ispecies)%part_param%sedidx
                      ifract =  scalar_source(sedidx)%sediment_param%ifract
                      bed(iblk)%particulate(ispecies, i, j) = bdens*&
                           &bed(iblk)%pore(disidx, i, j)/&
                           &bed(iblk)%porosity(i,j)*&
                           &scalar_source(ispecies)%part_param%bedkd*&
                           &(bed(iblk)%sediment(ifract, i, j)/sum)
                   END SELECT
                END DO
             
             ELSE

                                ! if there is no sediment in the bed,
                                ! there is no contaminant in the bed

                bed(iblk)%particulate(:, i, j) = 0.0
                bed(iblk)%pore(:, i, j) = 0.0
             END IF
          END DO
       END DO

                                ! do the edges for output

       bed(iblk)%pore(:, :, 1) = bed(iblk)%pore(:, :, 2)
       bed(iblk)%pore(:, :, block(iblk)%ymax + 1) =&
            &bed(iblk)%pore(:, :, block(iblk)%ymax)
       bed(iblk)%pore(:, 1, :) = bed(iblk)%pore(:, 2, :)
       bed(iblk)%pore(:, block(iblk)%xmax + 1, :) = &
            &bed(iblk)%pore(:, block(iblk)%xmax, :)

       bed(iblk)%particulate(:, :, 1) = bed(iblk)%particulate(:, :, 2)
       bed(iblk)%particulate(:, :, block(iblk)%ymax + 1) =&
            &bed(iblk)%particulate(:, :, block(iblk)%ymax)
       bed(iblk)%particulate(:, 1, :) = bed(iblk)%particulate(:, 2, :)
       bed(iblk)%particulate(:, block(iblk)%xmax + 1, :) = &
            &bed(iblk)%particulate(:, block(iblk)%xmax, :)
    END DO

  END SUBROUTINE bed_equilibrate

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_accounting
  ! ----------------------------------------------------------------
  SUBROUTINE bed_accounting(delta_t)

    IMPLICIT NONE
    DOUBLE PRECISION, INTENT(IN) :: delta_t

                                ! order is important here

    CALL bed_pore_exchange(delta_t)
    CALL bed_particulate_exchange(delta_t)
    CALL bed_sediment_exchange(delta_t)
    CALL bed_equilibrate(delta_t)
  

  END SUBROUTINE bed_accounting



  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_write_hotstart
  ! ----------------------------------------------------------------
  SUBROUTINE bed_write_hotstart(hiounit)

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: hiounit
    INTEGER :: ispecies, ifract, iblock

                                ! write the number of sediment
                                ! fractions and particulates that will
                                ! be written to the hotstart file

    WRITE(hiounit,*) sediment_fractions, particulates

                                ! as with other info, write bed info
                                ! by block

    DO iblock = 1, max_blocks
       DO ifract = 1, sediment_fractions
          WRITE(hiounit,*) bed(iblock)%sediment(ifract, :, :)
       END DO
       DO ispecies = 1, max_species
          SELECT CASE (scalar_source(ispecies)%srctype)
          CASE (GEN)
             WRITE(hiounit,*) bed(iblock)%pore(ispecies, :, :)
          CASE (PART)
             WRITE(hiounit,*) bed(iblock)%particulate(ispecies, :, :)
          END SELECT
       END DO
    END DO
  END SUBROUTINE bed_write_hotstart

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_read_hotstart
  ! ----------------------------------------------------------------
  SUBROUTINE bed_read_hotstart(hiounit)

    USE misc_vars, ONLY: error_iounit

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: hiounit
    INTEGER :: hotstart_fractions, hotstart_parts
    INTEGER :: ifract, iblock, ispecies

                                ! read the number of sediment
                                ! fractions and particulates from the
                                ! hotstart

    READ(hiounit,*) hotstart_fractions, hotstart_parts

                                ! let's be hard-nosed and quit with a
                                ! fatal error if the hotstart does not
                                ! match the current configuration
                                ! (this may have to change)

    IF (hotstart_fractions .NE. sediment_fractions) THEN
       WRITE(*,*) 'FATAL ERROR: specified number of sediment scalars, ',&
            &sediment_fractions, ', does not match those in hotstart, ',&
            &hotstart_fractions
       WRITE(error_iounit,*) 'FATAL ERROR: specified number of sediment scalars, ',&
            &sediment_fractions, ', does not match those in hotstart, ',&
            &hotstart_fractions
    END IF

    IF (hotstart_parts .NE. particulates) THEN
       WRITE(*,*) 'FATAL ERROR: specified number of particulate scalars, ',&
            &particulates, ', does not match those in hotstart, ',&
            &hotstart_parts
       WRITE(error_iounit,*) 'FATAL ERROR: specified number of particulate scalars, ',&
            &particulates, ', does not match those in hotstart, ',&
            &hotstart_parts
    END IF

                                ! if we're OK, read the bed part of
                                ! the hotstart file

    DO iblock = 1, max_blocks
       DO ifract = 1, sediment_fractions
          READ(hiounit,*) bed(iblock)%sediment(ifract, :, :)
       END DO
       DO ispecies = 1, max_species
          SELECT CASE (scalar_source(ispecies)%srctype)
          CASE (GEN)
             READ(hiounit,*) bed(iblock)%pore(ispecies, :, :)
          CASE (PART)
             READ(hiounit,*) bed(iblock)%particulate(ispecies, :, :)
          END SELECT
       END DO
    END DO


  END SUBROUTINE bed_read_hotstart

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_read_init
  ! ----------------------------------------------------------------
  SUBROUTINE bed_read_init()

    USE globals, ONLY: max_blocks, block
    USE misc_vars, ONLY: grid_iounit, restart_iounit, error_iounit, status_iounit

    IMPLICIT NONE

    DOUBLE PRECISION, ALLOCATABLE :: fract(:)
    DOUBLE PRECISION :: depth, bdens, sum
    INTEGER :: istat, ijunk, jjunk
    INTEGER :: iblk, i, j, ifract

    CHARACTER (LEN=1024) :: filename

    ALLOCATE(fract(sediment_fractions))

 	OPEN(restart_iounit,FILE=bed_init_file, STATUS='old', IOSTAT=istat, FORM='formatted')
    IF (ISTAT .NE. 0) THEN
       WRITE(*, *) 'FATAL ERROR: unable to initial bed file ', TRIM(bed_init_file)
       WRITE(error_iounit, *) 'FATAL ERROR: unable to initial bed file ', TRIM(bed_init_file)
       CALL EXIT(8)
    END IF

    WRITE(status_iounit, *) 'reading initial bed data from ', TRIM(bed_init_file)

    DO iblk = 1, max_blocks
       READ(restart_iounit, *) filename
       
       OPEN(grid_iounit,FILE=filename, STATUS='old', IOSTAT=istat, FORM='formatted')
       IF (istat .NE. 0) THEN
          WRITE(*, *) 'FATAL ERROR: unable to open block ', i,  &
               &' initial bed map file ', TRIM(filename)
          WRITE(error_iounit, *) 'FATAL ERROR: unable to open block ', i,  &
               &' initial bed map file ', TRIM(filename)
          CALL EXIT(8)
       END IF

       READ(grid_iounit, *)  ijunk, jjunk ! skip first line
       IF (ijunk .NE. block(iblk)%xmax - 1 .OR. jjunk .NE. block(iblk)%ymax - 1) THEN
          WRITE(*,*) 'WARNING: x and y max values on first line of ', &
               &TRIM(filename), ' do not match that for block ', iblk
       END IF

       WRITE(status_iounit, *) 'reading initial bed data for block ', iblk, &
            &' from ', TRIM(bed_init_file)

       DO i = 2, block(iblk)%xmax
          DO j = 2, block(iblk)%ymax
             fract = 0.0
             READ(grid_iounit, *) ijunk, jjunk, depth, fract
             
             IF (depth .LT. 0.0) THEN
                bed(iblk)%depth = 0.0
                DO ifract = 1, sediment_fractions
                   bed(iblk)%sediment(ifract, i, j) = 0.0
                END DO
             ELSE

                bed(iblk)%depth(i, j) = depth

                                ! in the fraction do not sum to 1.0,
                                ! we're going to have trouble, so
                                ! let's make sure they do

                sum = 0.0
                DO ifract = 1, sediment_fractions
                   sum = sum + fract(ifract)
                END DO

                bdens = 0.0
                DO ifract = 1, sediment_fractions
                   fract(ifract) = fract(ifract)/sum
                   bdens = bdens + fract(ifract)/&
                        &scalar_source(sediment_scalar_index(ifract))%sediment_param%pdens
                END DO
                bdens = bdens/(1.0 - bed(iblk)%porosity(i, j))

                                ! compute sediment masses

                DO ifract = 1, sediment_fractions
                   bed(iblk)%sediment(ifract, i, j) = fract(ifract)*depth/bdens
                END DO
             END IF             
          END DO
       END DO
       CLOSE(grid_iounit)
    END DO
    CLOSE(restart_iounit)

    DEALLOCATE(fract)

                                ! recompute bed depths to check

    CALL bed_compute_depth()

  END SUBROUTINE bed_read_init

  ! ----------------------------------------------------------------
  ! SUBROUTINE bed_dist_bedsrc

  ! This subroutine takes the bed source for sorbed contaminants and
  ! runs it through it the bed, if any.  This must be called before
  ! any transport calculations, but after the bed source rates have
  ! been updated for this timestep (bedsrc_time_step).

  ! ----------------------------------------------------------------
  SUBROUTINE bed_dist_bedsrc(deltat)

    IMPLICIT NONE

    DOUBLE PRECISION, INTENT(IN) :: deltat

    INTEGER :: ispecies, iblock, i, j
    TYPE (bedsrc_rec), POINTER :: src
    LOGICAL :: doeq = .FALSE.

    DO ispecies = 1, max_species
       SELECT CASE (scalar_source(ispecies)%srctype)
       CASE (GEN)
          IF (scalar_source(ispecies)%generic_param%hasbedsrc .AND. &
               &(scalar_source(ispecies)%generic_param%issorbed .OR. &
               & scalar_source(ispecies)%generic_param%diffusivity .GT. 0.0)) THEN
             src => scalar_source(ispecies)%generic_param%bedsrc
             DO iblock = 1, max_blocks
                DO i = 2, block(iblock)%xmax
                   DO j = 2, block(iblock)%ymax
                      IF (bed(iblock)%depth(i,j) .GT. bed_min_depth .AND. &
                           &src%map(iblock)%cellrate(i, j) .GT. 0.0) THEN
                         bed(iblock)%pore(ispecies, i, j) = &
                              &bed(iblock)%pore(ispecies, i, j) + &
                              &src%map(iblock)%cellrate(i, j)*deltat/&
                              &block(iblock)%hp1(i,j)/block(iblock)%hp2(i,j)
                         src%map(iblock)%cellrate(i, j) = 0.0
                         doeq = .TRUE.
                      END IF
                   END DO
                END DO
             END DO
          END IF
       END SELECT
    END DO

    IF (doeq) CALL bed_equilibrate(deltat)

  END SUBROUTINE bed_dist_bedsrc



END MODULE bed_module

