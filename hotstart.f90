! ----------------------------------------------------------------
! MODULE hotstart
! ----------------------------------------------------------------
MODULE hotstart

  USE config
  USE block_module

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  CHARACTER (LEN=80), PRIVATE, PARAMETER :: hotstart_file_name = 'hotstart.bin'
  INTEGER, PRIVATE, PARAMETER :: hotstart_iounit = 16, restart_iounit = 17

CONTAINS

  ! ----------------------------------------------------------------
  ! SUBROUTINE hotstart_read_var
  ! ----------------------------------------------------------------
  SUBROUTINE hotstart_read_var(iunit, var, buffer, index)
    
    IMPLICIT NONE

    INTEGER, INTENT(IN) :: iunit
    TYPE (block_var), INTENT(INOUT) :: var
    DOUBLE PRECISION, INTENT(INOUT) :: &
         &buffer(var%base%imin_global:var%base%imax_global, &
         &var%base%jmin_global:var%base%jmax_global)
    INTEGER, INTENT(IN), OPTIONAL :: index

    INTEGER :: myindex

    myindex = BLK_VAR_CURRENT

    IF (PRESENT(index)) myindex = index

    READ (iunit, *) buffer(var%base%imin_global:var%base%imax_global, &
         &var%base%jmin_global:var%base%jmax_global)
    CALL block_var_put_all(var, buffer, myindex)

  END SUBROUTINE hotstart_read_var


  ! ----------------------------------------------------------------
  ! SUBROUTINE read_hotstart
  ! ----------------------------------------------------------------
  SUBROUTINE read_hotstart()

    IMPLICIT NONE

#include "global.fh"

    INTEGER :: iblk, i
    CHARACTER (LEN=1024) :: msg
    LOGICAL :: do_transport_restart
    INTEGER :: max_species_in_restart

    IF (ga_nodeid() .EQ. 0) THEN

       CALL open_existing(hotstart_file_name, hotstart_iounit)
       CALL status_message('reading hotstart file "' // TRIM(hotstart_file_name) // '"')
       READ(hotstart_iounit,*) do_transport_restart, max_species_in_restart
       DO iblk=1,max_blocks
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_STAR)
          
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_STAR)
          
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_STAR)
          
          CALL hotstart_read_var(hotstart_iounit, block(iblk)%bv_eddy, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
       END DO
       
       IF( (do_transport).AND.(do_transport_restart) )THEN

!!$       ! if a bed is expected in the
!!$       ! hotstart, the number of scalars must
!!$       ! be the same in the hotstart as was
!!$       ! specified for the simulation
!!$
!!$       IF (source_doing_sed .AND. (max_species_in_restart .NE. max_species)) THEN
!!$          WRITE (msg,*) 'specified number of scalar species, ', &
!!$               &max_species, ', does not match that in hotstart file (',&
!!$               &max_species_in_restart, ')'
!!$          CALL error_message(msg, fatal=.TRUE.)
!!$       END IF
!!$
!!$       ! if we don't expect a bed, don't
!!$       ! worry about the number of scalar
!!$       ! species
!!$
!!$       IF(max_species_in_restart > max_species) max_species_in_restart = max_species
!!$       DO i=1,max_species_in_restart
!!$          DO iblock = 1, max_blocks
!!$             READ(hotstart_iounit,*) species(i)%scalar(iblock)%conc
!!$             WRITE(msg,*)'done with conc read for species -',i,'and block -',iblock
!!$             CALL status_message(msg)
!!$             READ(hotstart_iounit,*) species(i)%scalar(iblock)%concold
!!$             WRITE(msg,*)'done with concold read for species -',i,'and block -',iblock
!!$             CALL status_message(msg)
!!$             READ(hotstart_iounit,*) species(i)%scalar(iblock)%concoldold
!!$             WRITE(msg,*)'done with concoldold read for species -',i,'and block -',iblock
!!$             CALL status_message(msg)
!!$          END DO
!!$       END DO
!!$
!!$       ! if any sediment species were
!!$       ! specified, we expect to find a bed
!!$       ! in the hotstart file
!!$
!!$       IF (source_doing_sed) CALL bed_read_hotstart(hotstart_iounit)
!!$
!!$    ELSE IF (do_transport) THEN
!!$       DO i = 1, max_species
!!$          DO iblk =1, max_blocks
!!$             species(i)%scalar(iblk)%conc = conc_initial
!!$             species(i)%scalar(iblk)%concold = conc_initial
!!$          END DO
!!$       END DO
       END IF

       CLOSE(hotstart_iounit)

       CALL status_message('done reading hotstart file')
    END IF

    CALL ga_sync()

    DO iblk=1,max_blocks
       CALL block_var_get(block(iblk)%bv_uvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblk)%bv_uvel, BLK_VAR_OLDOLD)
       CALL block_var_get(block(iblk)%bv_uvel, BLK_VAR_OLD)
       CALL block_var_get(block(iblk)%bv_uvel, BLK_VAR_CURRENT)

       CALL block_var_get(block(iblk)%bv_vvel, BLK_VAR_STAR)
       CALL block_var_get(block(iblk)%bv_vvel, BLK_VAR_OLDOLD)
       CALL block_var_get(block(iblk)%bv_vvel, BLK_VAR_OLD)
       CALL block_var_get(block(iblk)%bv_vvel, BLK_VAR_CURRENT)
    
       CALL block_var_get(block(iblk)%bv_depth, BLK_VAR_STAR)
       CALL block_var_get(block(iblk)%bv_depth, BLK_VAR_OLDOLD)
       CALL block_var_get(block(iblk)%bv_depth, BLK_VAR_OLD)
       CALL block_var_get(block(iblk)%bv_depth, BLK_VAR_CURRENT)

       CALL block_var_get(block(iblk)%bv_eddy, BLK_VAR_CURRENT)

       block(iblk)%wsel = block(iblk)%depth + block(iblk)%zbot
       CALL block_var_put(block(iblk)%bv_wsel, BLK_VAR_CURRENT)
       CALL ga_sync()
       CALL block_var_get(block(iblk)%bv_wsel, BLK_VAR_CURRENT)
    END DO

  END SUBROUTINE read_hotstart

  ! ----------------------------------------------------------------
  !  FUNCTION hotstart_name
  ! ----------------------------------------------------------------
  FUNCTION hotstart_name(ds, ts)

    IMPLICIT NONE

    CHARACTER (LEN=80) :: hotstart_name
    CHARACTER (LEN=*), INTENT(IN) :: ds, ts

    CHARACTER (LEN=80) :: buffer
    INTEGER :: i

    buffer = "hotstart_" // TRIM(ds) // "_" // TRIM(ts) // ".bin"

    ! take the colons out 

    i = SCAN(buffer, ':')
    DO WHILE (i .GT. 0)
       buffer(i:) = buffer(i+1:)
       i = SCAN(buffer, ':')
    END DO
    hotstart_name = buffer
  END FUNCTION hotstart_name

  ! ----------------------------------------------------------------
  ! SUBROUTINE restart_write_var
  ! ----------------------------------------------------------------
  SUBROUTINE restart_write_var(iunit, var, buffer, index)

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: iunit
    TYPE (block_var), INTENT(IN) :: var
    DOUBLE PRECISION, INTENT(OUT) :: buffer(:, :)
    INTEGER, INTENT(IN), OPTIONAL :: index

    INTEGER :: myindex

    myindex = BLK_VAR_CURRENT

    IF (PRESENT(index)) myindex = index

    CALL block_var_get_all(var, buffer, myindex)
    WHERE(abs(buffer) < tiny) &
         &buffer = sign(tiny, buffer)
    WRITE(iunit,*) buffer

  END SUBROUTINE restart_write_var


  !##########################################################################
  !---------------------------------------------------------------------------
  ! write a  restart file
  !---------------------------------------------------------------------------

  SUBROUTINE write_restart()
    IMPLICIT NONE

#include "global.fh"

    INTEGER :: i, iblk
    INTEGER :: me
    LOGICAL :: do_transport_restart
    CHARACTER (LEN=1024) :: restart_filename

    me = ga_nodeid()

    IF( me .EQ. 0 .AND. (current_time%time >= end_time%time) .OR. &
         &(MOD(time_step_count,restart_print_freq) == 0))THEN

       restart_filename = hotstart_name(current_time%date_string, current_time%time_string)

       CALL open_new(restart_filename, restart_iounit)

       IF (do_transport) THEN
          do_transport_restart = .TRUE.
          WRITE(restart_iounit,*) do_transport_restart, max_species
       ELSE
          do_transport_restart = .FALSE.
          WRITE(restart_iounit,*) do_transport_restart, 0
       END IF

       DO iblk=1,max_blocks

          CALL restart_write_var(restart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_uvel, &
               &block(iblk)%buffer, BLK_VAR_STAR)

          CALL restart_write_var(restart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_vvel, &
               &block(iblk)%buffer, BLK_VAR_STAR)

          CALL restart_write_var(restart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_OLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_OLDOLD)
          CALL restart_write_var(restart_iounit, block(iblk)%bv_depth, &
               &block(iblk)%buffer, BLK_VAR_STAR)

          CALL restart_write_var(restart_iounit, block(iblk)%bv_eddy, &
               &block(iblk)%buffer, BLK_VAR_CURRENT)

       END DO

       IF(do_transport)THEN
!!$          DO i=1,max_species
!!$             DO iblock = 1, max_blocks
!!$                block(iblock)%work = species(i)%scalar(iblock)%conc
!!$                WHERE(abs(block(iblock)%work) < tiny) &
!!$                     &block(iblock)%work = sign(tiny, block(iblock)%work)
!!$                WRITE(restart_iounit,*)block(iblock)%work
!!$
!!$                block(iblock)%work = species(i)%scalar(iblock)%concold
!!$                WHERE(abs(block(iblock)%work) < tiny) &
!!$                     &block(iblock)%work = sign(tiny, block(iblock)%work) 
!!$                WRITE(restart_iounit,*)block(iblock)%work
!!$
!!$                block(iblock)%work = species(i)%scalar(iblock)%concoldold
!!$                WHERE(abs(block(iblock)%work) < tiny) &
!!$                     &block(iblock)%work = sign(tiny, block(iblock)%work) 
!!$                WRITE(restart_iounit,*)block(iblock)%work
!!$
!!$                ! WRITE(restart_iounit,*) species(i)%scalar(iblock)%conc
!!$                ! WRITE(restart_iounit,*) species(i)%scalar(iblock)%concold
!!$             END DO
!!$          END DO
!!$
!!$          IF (source_doing_sed) CALL bed_write_hotstart(restart_iounit)
       END IF

       CLOSE(restart_iounit)

    ENDIF

  END SUBROUTINE write_restart




END MODULE hotstart
