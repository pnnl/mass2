! ----------------------------------------------------------------
! file: sediment_source.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created August 23, 2000 by William A. Perkins
! Last Change: Thu Jul 26 14:20:32 2001 by William A. Perkins <perk@dora.pnl.gov>
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! MODULE sediment_source
! ----------------------------------------------------------------
MODULE sediment_source

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  TYPE sediment_source_block_rec
                                ! these are rates, units: (mass)/ft^2/s

     DOUBLE PRECISION, POINTER :: deposition(:,:)
     DOUBLE PRECISION, POINTER :: erosion(:,:)
  END TYPE sediment_source_block_rec

  TYPE sediment_source_rec
     INTEGER :: ifract          ! sediment fraction index
     DOUBLE PRECISION :: erode, eshear
     DOUBLE PRECISION :: setvel, dshear
     DOUBLE PRECISION :: pdens, d50
     TYPE (sediment_source_block_rec), POINTER :: block(:)
  END TYPE sediment_source_rec

                                ! total number of sediment fractions
                                ! simulated (may be needed by bed more
                                ! than here)

  INTEGER, PUBLIC, SAVE :: sediment_fractions = 0

                                ! map sediment fraction index to
                                ! scalar index

  INTEGER, PUBLIC, ALLOCATABLE :: sediment_scalar_index(:)

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE sediment_source_initialize
  ! ----------------------------------------------------------------
  SUBROUTINE sediment_source_initialize()

    USE globals

    IMPLICIT NONE

    INTEGER :: iblk

    ALLOCATE(sediment_scalar_index(sediment_fractions))
  END SUBROUTINE sediment_source_initialize


  ! ----------------------------------------------------------------
  ! TYPE (SEDIMENT_SOURCE_REC) FUNCTION sediment_parse_options
  ! ----------------------------------------------------------------
  TYPE (SEDIMENT_SOURCE_REC) FUNCTION sediment_parse_options(options)

    USE misc_vars, ONLY: error_iounit
    USE globals

    IMPLICIT NONE
    POINTER sediment_parse_options
    CHARACTER (LEN=*) :: options(:)
    INTEGER :: nopt
    INTEGER :: i, iblk

    i = 1
    nopt = UBOUND(options, 1)

    ALLOCATE(sediment_parse_options) 
    sediment_parse_options%erode = 0.0
    sediment_parse_options%eshear = -1.0
    sediment_parse_options%setvel = 0.0
    sediment_parse_options%dshear = 0.0
    sediment_parse_options%pdens = 0.0
    sediment_parse_options%d50 = 0.0

                                ! allocate storage for erosion and
                                ! deposition rates

    ALLOCATE(sediment_parse_options%block(max_blocks))
    DO iblk = 1, max_blocks
       ALLOCATE(sediment_parse_options%block(iblk)%deposition(block(iblk)%xmax+1, block(iblk)%ymax+1))
       sediment_parse_options%block(iblk)%deposition = 0.0
       ALLOCATE(sediment_parse_options%block(iblk)%erosion(block(iblk)%xmax+1, block(iblk)%ymax+1))
       sediment_parse_options%block(iblk)%erosion = 0.0
    END DO
    
    DO WHILE ((LEN_TRIM(options(i)) .GT. 0) .AND. (i .LE. nopt))
       SELECT CASE (options(i))

                                ! median partical diameter, feet

       CASE ('D50')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'D50'
             WRITE(error_iounit, 100) 'D50'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%d50
          i = i + 1

                                ! erodibility coefficient, (mass)/ft^2/s

       CASE ('ERODIBILTY')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'ERODIBILTY'
             WRITE(error_iounit, 100) 'ERODIBILTY'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%erode
          i = i + 1

                                ! critical shear stress for erosion, lbf/ft^2

       CASE ('ESHEAR')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'ESHEAR'
             WRITE(error_iounit, 100) 'ESHEAR'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%eshear
          i = i + 1

                                ! critical shear stress for deposition, lbf/ft^2

       CASE ('DSHEAR')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'DSHEAR'
             WRITE(error_iounit, 100) 'DSHEAR'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%dshear
          i = i + 1

                                ! settling velocity for deposition, ft/s

       CASE ('SETVEL')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'SETVEL'
             WRITE(error_iounit, 100) 'SETVEL'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%setvel
          i = i + 1

                                ! solids density, mass/ft^3

       CASE ('DENSITY')
          IF ((i + 1 .GT. nopt) .OR. (LEN_TRIM(options(i+1)) .LE. 0)) THEN
             WRITE(*, 100) 'SETVEL'
             WRITE(error_iounit, 100) 'SETVEL'
             CALL EXIT(8)
          END IF
          READ(options(i+1), *) sediment_parse_options%pdens
          i = i + 1

       CASE DEFAULT
          WRITE(error_iounit, *) 'WARNING: GEN scalar option "', &
               &TRIM(options(i)), '" not understood and ignored'
       END SELECT
       i = i + 1
    END DO

                                ! in order for a sediment species to
                                ! be meaningful, all of the parameters
                                ! should be non zero

    IF (sediment_parse_options%setvel .LE. 0.0) THEN
       WRITE (*, *) 'FATAL ERROR: Invalid or unspecified value for SETVEL'
       WRITE (error_iounit, *) 'FATAL ERROR: Invalid or unspecified value for SETVEL'
       CALL EXIT(10)
    END IF
    IF (sediment_parse_options%eshear .LE. 0.0) THEN
       WRITE (*, *) 'FATAL ERROR: Invalid or unspecified value for ESHEAR'
       WRITE (error_iounit, *) 'FATAL ERROR: Invalid or unspecified value for ESHEAR'
       CALL EXIT(10)
    END IF
    IF (sediment_parse_options%dshear .LE. 0.0) THEN
       WRITE (*, *) 'FATAL ERROR: Invalid or unspecified value for DSHEAR'
       WRITE (error_iounit, *) 'FATAL ERROR: Invalid or unspecified value for DSHEAR'
       CALL EXIT(10)
    END IF
    IF (sediment_parse_options%erode .LT. 0.0) THEN
       WRITE (*, *) 'FATAL ERROR: Invalid or unspecified value for ERODIBILTY'
       WRITE (error_iounit, *) 'FATAL ERROR: Invalid or unspecified value for ERODIBILTY'
       CALL EXIT(10)
    END IF
    IF (sediment_parse_options%pdens .LE. 0.0) THEN
       WRITE (*, *) 'FATAL ERROR: Invalid or unspecified value for DENSITY'
       WRITE (error_iounit, *) 'FATAL ERROR: Invalid or unspecified value for DENSITY'
       CALL EXIT(10)
    END IF
    IF (sediment_parse_options%d50 .LE. 0.0) THEN 
       WRITE (*,*) 'FATAL ERROR: Bad D50 value for SED species: ', sediment_parse_options%d50
       WRITE (error_iounit,*) 'FATAL ERROR: Bad D50 value for SED species: ', sediment_parse_options%d50
       CALL EXIT(10)
    END IF
100 FORMAT('FATAL ERROR: additional argument missing for ', A10, ' keyword')
  END FUNCTION sediment_parse_options

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION sediment_erosion
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION sediment_erosion(rec, iblk, i, j)

    USE globals
    USE misc_vars, ONLY: delta_t

    IMPLICIT NONE
    INCLUDE 'bed_functions.inc'
    TYPE (sediment_source_rec) :: rec
    INTEGER, INTENT(IN) :: iblk, i, j
    DOUBLE PRECISION :: shear
    
    sediment_erosion = 0.0
    shear = block(iblk)%shear(i,j)

    IF (shear > rec%eshear) THEN
       sediment_erosion = &
            &MIN((shear/rec%eshear - 1.0)*rec%erode,&
            &bed_max_erosion(rec%ifract, iblk, i, j, delta_t))
    END IF
  END FUNCTION sediment_erosion


  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION sediment_deposition
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION sediment_deposition(rec, iblk, i, j, sconc)

    USE globals
    USE misc_vars, ONLY: delta_t

    IMPLICIT NONE
    TYPE (sediment_source_rec) :: rec
    INTEGER, INTENT(IN) :: iblk, i, j
    DOUBLE PRECISION, INTENT(IN) :: sconc
    DOUBLE PRECISION :: shear
    
    sediment_deposition = 0.0
    shear = block(iblk)%shear(i,j)
  
    IF (shear < rec%dshear) THEN
       sediment_deposition = (1.0 - shear/rec%dshear)*rec%setvel*sconc
       sediment_deposition = MAX(sediment_deposition, 0.0d0)
    END IF
  END FUNCTION sediment_deposition

  ! ----------------------------------------------------------------
  ! DOUBLE PRECISION FUNCTION sediment_source_term
  ! ----------------------------------------------------------------
  DOUBLE PRECISION FUNCTION sediment_source_term(rec, iblk, i, j, sconc)

    IMPLICIT NONE

    TYPE(sediment_source_rec), INTENT(IN) :: rec
    INTEGER, INTENT(IN) :: iblk, i, j
    DOUBLE PRECISION :: sconc

    sediment_source_term = &
         &sediment_erosion(rec, iblk, i, j) - &
         &sediment_deposition(rec, iblk, i, j, sconc)
  END FUNCTION sediment_source_term


END MODULE sediment_source

