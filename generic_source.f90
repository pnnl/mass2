! ----------------------------------------------------------------
! file: generic_source.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created July 26, 2000 by William A. Perkins
! Last Change: Tue Jul 24 13:49:08 2001 by William A. Perkins <perk@dora.pnl.gov>
! ----------------------------------------------------------------

! RCS ID: $Id$ Battelle PNL

! ----------------------------------------------------------------
! MODULE generic_source

! This module encapsulates the source term for generic scalar species,
! which are conservative, or decay radioactively, and/or decay in some
! other manner e.g. chemical (future work) and/or sorb to sediment
! (future work)

! ----------------------------------------------------------------
MODULE generic_source

  USE bed_source

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  TYPE generic_source_rec

                                ! RADIOACTIVE DECAY: halflife is in
                                ! years, lambda is computed from
                                ! halflife with units of 1/sec

     DOUBLE PRECISION :: halflife, lamda 

                                ! BED (nonpoint) SOURCE

     LOGICAL :: hasbedsrc

                                ! BIOTA transport

     LOGICAL :: isbiotic
     INTEGER :: bioidx          ! index of "analyte" in biota module
     INTEGER :: biophase        ! scalar index for biota phase

                                ! Particulate transport

     LOGICAL :: issorbed

                                ! "Molecular" Diffusivity for exchange
                                ! with bed pore water, ft^2/s

     DOUBLE PRECISION :: diffusivity

     TYPE(bedsrc_rec), POINTER :: bedsrc
  END TYPE generic_source_rec

CONTAINS

  ! ----------------------------------------------------------------
  ! TYPE(generic_source_rec) FUNCTION generic_parse_options
  ! ----------------------------------------------------------------
  TYPE(generic_source_rec) FUNCTION generic_parse_options(options)

    USE misc_vars, ONLY: error_iounit
    
    IMPLICIT NONE

    POINTER generic_parse_options

    CHARACTER (LEN=*) :: options(:)
    INTEGER :: nopt
    INTEGER :: i

    i = 1

    nopt = UBOUND(options, 1)

    ALLOCATE(generic_parse_options)

    generic_parse_options%halflife = 0.0
    generic_parse_options%lamda = 0.0
    generic_parse_options%hasbedsrc = .FALSE.
    generic_parse_options%isbiotic = .FALSE.
    generic_parse_options%issorbed = .FALSE.
    generic_parse_options%bioidx = 0

    DO WHILE ((LEN_TRIM(options(i)) .GT. 0) .AND. (i .LE. nopt))
       SELECT CASE (options(i))
       CASE ('HALFLIFE')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'HALFLIFE'
             WRITE(error_iounit, 100) 'HALFLIFE'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) generic_parse_options%halflife
          i = i + 1
       CASE ('BEDSOURCE')
          IF ((i + 2 .GT. nopt) .OR. (LEN_TRIM(options(i+2)) .LE. 0) .OR. &
               &(LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'BEDSOURCE'
             WRITE(error_iounit, 100) 'BEDSOURCE'
             CALL EXIT(8)
          END IF
          generic_parse_options%hasbedsrc = .TRUE.
          generic_parse_options%bedsrc => &
               &bedsrc_read(options(i+1), options(i+2))
          i = i + 2
       CASE ('DIFFUS')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'DIFFUS'
             WRITE(error_iounit, 100) 'DIFFUS'
             CALL EXIT(8)
          END IF
           READ(options(i+1), *) generic_parse_options%diffusivity
       CASE DEFAULT
          WRITE(error_iounit, *) 'WARNING: GEN scalar option "', &
               &TRIM(options(i)), '" not understood and ignored'
       END SELECT
       i = i + 1
    END DO
    IF (generic_parse_options%halflife .GT. 0.0) THEN
       generic_parse_options%lamda = 0.693147/(generic_parse_options%halflife*86400.0*365.25)
    END IF
100 FORMAT('FATAL ERROR: additional argument missing for ', A10, ' keyword')
  END FUNCTION generic_parse_options

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION generic_bedpore_exch
  ! We need to make sure we are doing sediment before we call this function
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION generic_bedpore_exch(rec, iblk, i, j, conc, pore)

    USE misc_vars, ONLY: delta_t

    IMPLICIT NONE
    TYPE(generic_source_rec) :: rec
    INTEGER, INTENT(IN) :: iblk, i, j
    DOUBLE PRECISION , INTENT(IN) :: conc, pore

    DOUBLE PRECISION :: bdepth, porosity, diffc, maxexch
    INCLUDE 'bed_functions.inc'
  
    generic_bedpore_exch = 0.0

                                ! use some arbitrary minimum depth so
                                ! things don't blow up

    bdepth = bed_depth(iblk, i, j)
    IF (bdepth .GT. 1e-3) THEN
       porosity = bed_porosity(iblk, i, j)
       diffc = rec%diffusivity
       maxexch = pore*bdepth/porosity/delta_t
       generic_bedpore_exch = diffc*(pore - conc)/(bdepth/2.0)
       IF (generic_bedpore_exch .GT. maxexch) generic_bedpore_exch = maxexch
    END IF
  END FUNCTION generic_bedpore_exch


  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION generic_source_term
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION generic_source_term(rec, iblock, i, j, conc, depth, area)

    IMPLICIT NONE

    TYPE(generic_source_rec) :: rec
    INTEGER :: iblock, i, j
    DOUBLE PRECISION :: conc, depth, area
    
    generic_source_term = 0.0
    
    IF (rec%halflife .GT. 0.0) THEN
       generic_source_term = generic_source_term - &
            &rec%lamda*depth*conc
    END IF
    IF (rec%hasbedsrc) THEN
       generic_source_term = generic_source_term + &
            bedsrc_source_term(rec%bedsrc, iblock, i, j)/area
    END IF
  END FUNCTION generic_source_term

END MODULE generic_source