! ----------------------------------------------------------------
! file: scalar_bc.f90
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Battelle Memorial Institute
! Pacific Northwest Laboratory
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! Created January 20, 2011 by William A. Perkins
! Last Change: 2014-04-24 12:53:31 d3g096
! ----------------------------------------------------------------
! ----------------------------------------------------------------
! MODULE scalar_bc_module
! ----------------------------------------------------------------
MODULE scalar_bc_module

  USE utility
  USE config
  USE table_boundary_conditions

  IMPLICIT NONE

  CHARACTER (LEN=80), PRIVATE, SAVE :: rcsid = "$Id$"

  ! ----------------------------------------------------------------
  ! TYPE scalar_bc_spec_struct
  ! ----------------------------------------------------------------
  TYPE  scalar_bc_spec_struct

     CHARACTER (LEN=10) :: bc_loc
     CHARACTER (LEN=10) :: bc_type, bc_kind, bc_extent
     INTEGER :: block, species, x_start, table_num != 0
     INTEGER :: con_block, con_start_cell(max_cell_values), con_end_cell(max_cell_values), con_row
     INTEGER :: start_cell(max_cell_values), end_cell(max_cell_values)
     INTEGER :: num_cell_pairs != 0

  END TYPE scalar_bc_spec_struct

  ! ----------------------------------------------------------------
  ! TYPE scalar_bc_struct
  ! ----------------------------------------------------------------
  TYPE scalar_bc_struct
     
     INTEGER  :: num_bc != 0
     TYPE(scalar_bc_spec_struct) :: bc_spec(200)

  END TYPE scalar_bc_struct
  
  TYPE(scalar_bc_struct), ALLOCATABLE :: scalar_bc(:)

  CHARACTER (LEN=80), PRIVATE :: scalar_bcspecs_name = "scalar_bcspecs.dat"
  INTEGER, PARAMETER, PRIVATE :: bcspec_iounit = 18

CONTAINS

  ! ----------------------------------------------------------------
  ! allocate_scalar_block_bc
  ! ----------------------------------------------------------------
  SUBROUTINE allocate_scalar_block_bc(max_blocks)
    IMPLICIT NONE
    INTEGER :: max_blocks, alloc_stat, i

    ALLOCATE(scalar_bc(max_blocks), STAT = alloc_stat)
    IF(alloc_stat /= 0)THEN
       CALL error_message('allocation failed for the array of scalar bc ', fatal=.TRUE.)
    ENDIF
    CALL status_message('allocation successful for array of scalar bc')
    scalar_bc%num_bc = 0
    DO i=1,max_blocks
       scalar_bc(i)%bc_spec%table_num = 0
       scalar_bc(i)%bc_spec%num_cell_pairs = 0
    END DO

  END SUBROUTINE allocate_scalar_block_bc

  ! ----------------------------------------------------------------
  ! read_scalar_bcspecs
  ! ----------------------------------------------------------------
  SUBROUTINE read_scalar_bcspecs(max_blocks, max_species, xmax, ymax)


    ! reads the bc spec file
    ! format: block#	bc_loc	bc_type	bc_kind	bc_extent	'connect_block OR filename' 'cell pairs'			

    IMPLICIT NONE
    INTEGER, INTENT(IN) :: max_blocks, max_species
    INTEGER, INTENT(IN) :: xmax(:), ymax(:)

    INTEGER :: junk1, block, species, cells(2*max_cell_values) = -999 , num_bc, con_block, i
    INTEGER :: table_count = 0, num_cells, num_cell_pairs, x_start
    INTEGER :: maxidx, lerr, ierr, line
    CHARACTER (LEN=10) :: junk_char1, junk_char2
    CHARACTER (LEN=10) :: bc_loc, bc_type, bc_kind, bc_extent
    CHARACTER (LEN=80) :: file_name
    CHARACTER (LEN=1024) :: msg

    CALL open_existing(scalar_bcspecs_name, bcspec_iounit)

    ! first we need to count how many SCALAR TABLE bc types 

    DO WHILE(.TRUE.)
       READ(bcspec_iounit,*,END=100)junk1,junk_char1,junk_char2
       SELECT CASE (junk_char2) 
       CASE ("TABLE", "SOURCE")
          max_scalar_tables = max_scalar_tables + 1
       END SELECT
    END DO

    ! now allocate the number of table bc structs that we need
100 CALL allocate_scalar_table_bc(max_scalar_tables)

    scalar_bc(:)%num_bc = 0

    ! now start over to fill and parse
    REWIND(bcspec_iounit)

    ierr = 0
    line = 0

    DO WHILE(.TRUE.)
       READ(bcspec_iounit,*,END=200)block, bc_loc, bc_type, species, bc_kind, bc_extent
       line = line + 1
       lerr = 0

       scalar_bc(block)%num_bc = scalar_bc(block)%num_bc + 1
       num_bc = scalar_bc(block)%num_bc

       scalar_bc(block)%bc_spec(num_bc)%bc_loc = bc_loc
       scalar_bc(block)%bc_spec(num_bc)%bc_type =	bc_type
       scalar_bc(block)%bc_spec(num_bc)%bc_kind =	bc_kind
       scalar_bc(block)%bc_spec(num_bc)%bc_extent = bc_extent
       scalar_bc(block)%bc_spec(num_bc)%species = species

       ! check block number

       IF (block .GT. max_blocks .OR. block .LT. 1) THEN
          lerr = lerr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": block number out of range: ", block
          CALL error_message(msg, fatal=.FALSE.)
          ierr = ierr + lerr
          CYCLE
       END IF

       ! check species number

       IF (species .GT. max_species .OR. species .LT. 1) THEN
          lerr = lerr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": species number out of range: ", species
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       ! make sure we understand the BC
       ! location

       SELECT CASE(bc_loc)
       CASE ("US", "DS")
          maxidx = ymax(block) - 1
       CASE ("RB", "LB")
          maxidx = xmax(block) - 1
       CASE ("IN")
          ! decide maxidx below
       CASE DEFAULT
          lerr = lerr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": ", TRIM(bc_loc), "?"
          CALL error_message(msg, fatal=.FALSE.)
       END SELECT

       IF (lerr .EQ. 0) THEN

          ! reread BC specific information from the line

          BACKSPACE(bcspec_iounit)

          SELECT CASE(bc_type)

          CASE("SOURCE")
             cells = -999
             READ(bcspec_iounit,*)block,bc_loc,bc_type,species,bc_kind,bc_extent,file_name,cells
             table_count = table_count + 1
             scalar_bc(block)%bc_spec(num_bc)%table_num = table_count
             scalar_table_bc(table_count)%file_name = file_name

             SELECT CASE(bc_extent)
             CASE("PART")
                CALL set_scalar_area(scalar_bc(block)%bc_spec(num_bc),&
                     &cells, xmax(block) - 1, ymax(block) - 1, line, lerr)
             CASE("ALL")
                scalar_bc(block)%bc_spec(num_bc)%num_cell_pairs = 1
                scalar_bc(block)%bc_spec(num_bc)%start_cell(1) = 1
                scalar_bc(block)%bc_spec(num_bc)%end_cell(1) = xmax(block) - 1
                scalar_bc(block)%bc_spec(num_bc)%start_cell(2) = 1
                scalar_bc(block)%bc_spec(num_bc)%end_cell(2) = ymax(block) - 1
             CASE DEFAULT
                lerr = lerr + 1
                WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
                     &": ", TRIM(bc_extent), "?"
                CALL error_message(msg, fatal=.FALSE.)
             END SELECT

          CASE("ZEROG")
             SELECT CASE(bc_extent)
             CASE("ALL")
                READ(bcspec_iounit,*)block,bc_loc,bc_type,species,bc_kind,bc_extent
                scalar_bc(block)%bc_spec(num_bc)%num_cell_pairs = 1
                scalar_bc(block)%bc_spec(num_bc)%start_cell(1) = 1
                scalar_bc(block)%bc_spec(num_bc)%end_cell(1) = maxidx
             CASE("PART")
                cells = -999
                READ(bcspec_iounit,*)block,bc_loc,bc_type,species,bc_kind,bc_extent,cells(:)
                CALL set_scalar_part(scalar_bc(block)%bc_spec(num_bc), &
                     &cells, maxidx, line, lerr)
             CASE DEFAULT
                lerr = lerr + 1
                WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
                     &": ", TRIM(bc_extent), "?"
                CALL error_message(msg, fatal=.FALSE.)
             END SELECT

          CASE("BLOCK")
             READ(bcspec_iounit,*)block, bc_loc, bc_type, species, bc_kind, bc_extent, con_block

             scalar_bc(block)%num_bc = scalar_bc(block)%num_bc - 1
             num_bc = scalar_bc(block)%num_bc

             WRITE (msg, *) TRIM(scalar_bcspecs_name), ": warning: line ", line, &
                  &': block connection ignored'
             CALL error_message(msg, fatal=.FALSE.)

          CASE("TABLE")
             x_start = 1
             SELECT CASE(bc_extent)
             CASE("ALL")
                READ(bcspec_iounit,*)block,bc_loc,bc_type,species,bc_kind,bc_extent,file_name,x_start
                table_count = table_count + 1 ! keep a running count of the number of tables
                scalar_bc(block)%bc_spec(num_bc)%table_num = table_count
                scalar_table_bc(table_count)%file_name = file_name ! associate file and table number
                scalar_bc(block)%bc_spec(num_bc)%x_start = x_start ! starting x grid line for BC
                scalar_bc(block)%bc_spec(num_bc)%num_cell_pairs = 1
                scalar_bc(block)%bc_spec(num_bc)%start_cell(1) = 1
                scalar_bc(block)%bc_spec(num_bc)%end_cell(1) = maxidx
             CASE("PART")
                cells = -999
                READ(bcspec_iounit,*)block,bc_loc,bc_type,species,bc_kind,bc_extent,file_name,x_start,cells(:)
                table_count = table_count + 1 ! keep a running count of the number of tables
                scalar_bc(block)%bc_spec(num_bc)%table_num = table_count
                scalar_table_bc(table_count)%file_name = file_name ! associate file and table number
                scalar_bc(block)%bc_spec(num_bc)%x_start = x_start ! starting x grid line for BC
                CALL set_scalar_part(scalar_bc(block)%bc_spec(num_bc), &
                     &cells, maxidx, line, lerr)
             CASE DEFAULT
                lerr = lerr + 1
                WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
                     &": ", TRIM(bc_extent), "?"
                CALL error_message(msg, fatal=.FALSE.)
             END SELECT
          CASE DEFAULT
             lerr = lerr + 1
             WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
                  &": ", TRIM(bc_type), "?"
             CALL error_message(msg, fatal=.FALSE.)
             READ(bcspec_iounit, *) junk1
          END SELECT
       END IF
       ierr = ierr + lerr
    END DO


200 CONTINUE

    CLOSE(bcspec_iounit)

    IF (ierr .GT. 0) THEN
       WRITE(msg, *) TRIM(scalar_bcspecs_name), ": ", ierr, " errors"
       CALL error_message(msg, fatal=.TRUE.)
    END IF
    CALL status_message("done reading scalar bc specifications file")

  END SUBROUTINE read_scalar_bcspecs

  ! ----------------------------------------------------------------
  ! SUBROUTINE set_scalar_part
  ! ----------------------------------------------------------------
  SUBROUTINE set_scalar_part(spec, cells, maxidx, line, ierr)

    IMPLICIT NONE
    INTEGER, INTENT(IN) :: cells(:), maxidx, line
    TYPE (scalar_bc_spec_struct), INTENT(INOUT) :: spec
    INTEGER, INTENT(INOUT) :: ierr

    INTEGER :: num_cells, num_cell_pairs, i
    CHARACTER (LEN=1024) :: msg

    num_cells = COUNT(cells .NE. -999)
    num_cell_pairs = num_cells/2
    spec%num_cell_pairs = num_cell_pairs
    spec%start_cell(1:num_cell_pairs) = cells(1:num_cells:2)
    spec%end_cell(1:num_cell_pairs) = cells(2:num_cells:2)

    ! check the cell numbers

    DO i = 1, spec%num_cell_pairs
       IF (spec%start_cell(i) .LT. 1 .OR. spec%start_cell(i) .GT. maxidx) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": start index ", spec%start_cell(i), ' out of range'
          CALL error_message(msg, fatal=.FALSE.)
       END IF
       IF (spec%end_cell(i) .LT. 1 .OR. spec%end_cell(i) .GT. maxidx) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": end index ", spec%end_cell(i), ' out of range'
          CALL error_message(msg, fatal=.FALSE.)
       END IF
    END DO


  END SUBROUTINE set_scalar_part

  ! ----------------------------------------------------------------
  ! SUBROUTINE set_scalar_area
  ! ----------------------------------------------------------------
  SUBROUTINE set_scalar_area(spec, cells, xmax, ymax, line, ierr)

    IMPLICIT NONE

    INTEGER, INTENT(IN) :: cells(:), xmax, ymax, line
    TYPE (scalar_bc_spec_struct), INTENT(INOUT) :: spec
    INTEGER, INTENT(INOUT) :: ierr

    INTEGER :: num_cells, num_cell_pairs, i
    CHARACTER (LEN=1024) :: msg

    num_cells = COUNT(cells /= -999)

    IF (num_cells .NE. 4) THEN
       ierr = ierr + 1
       WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
            &": four indices expected, got ", num_cells
       CALL error_message(msg, fatal=.FALSE.)
    ELSE
       num_cell_pairs = num_cells/2
       spec%num_cell_pairs = num_cells/2
       spec%start_cell(1:num_cell_pairs) = cells(1:num_cells:2)
       spec%end_cell(1:num_cell_pairs) = cells(2:num_cells:2)

       IF (spec%start_cell(1) .LT. 1 .OR. &
            &spec%start_cell(1) .GT. xmax) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": minimum x index out of range: ", spec%start_cell(1)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       IF (spec%end_cell(1) .LT. 1 .OR. &
            &spec%end_cell(1) .GT. xmax) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": maximum x index out of range: ", spec%end_cell(1)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       IF (spec%end_cell(1) .LT. spec%start_cell(1)) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": invalid x index range: ", spec%start_cell(1), " to ", &
               &spec%end_cell(1)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       IF (spec%start_cell(2) .LT. 1 .OR. &
            &spec%start_cell(2) .GT. ymax) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": minimum y index out of range: ", spec%start_cell(2)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       IF (spec%end_cell(2) .LT. 1 .OR. &
            &spec%end_cell(2) .GT. ymax) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": maximum y index out of range: ", spec%end_cell(2)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

       IF (spec%end_cell(2) .LT. spec%start_cell(2)) THEN
          ierr = ierr + 1
          WRITE(msg, *) TRIM(scalar_bcspecs_name), ": error: line ", line, &
               &": invalid y index range: ", spec%start_cell(2), " to ", &
               &spec%end_cell(2)
          CALL error_message(msg, fatal=.FALSE.)
       END IF

    END IF

  END SUBROUTINE set_scalar_area

  ! ----------------------------------------------------------------
  ! SUBROUTINE set_scalar_block_connections
  ! ----------------------------------------------------------------
  SUBROUTINE set_scalar_block_connections()

    IMPLICIT NONE

    INTEGER :: error_iounit, status_iounit
    INTEGER :: block,num_bc,con_block, i, start_cell, end_cell
    INTEGER :: species_con_block, species_num_bc, species_block, ispecies

    ! for each hydro block-to-block connection, build a scalar BC for
    ! each species that copies the hydro connection

!!$    DO block = 1, max_blocks
!!$
!!$       DO num_bc = 1, block_bc(block)%num_bc
!!$
!!$          IF (block_bc(block)%bc_spec(num_bc)%bc_type .EQ. 'BLOCK') THEN
!!$
!!$             DO ispecies = 1, max_species
!!$
!!$                scalar_bc(block)%num_bc = scalar_bc(block)%num_bc + 1
!!$                species_num_bc = scalar_bc(block)%num_bc
!!$
!!$                scalar_bc(block)%bc_spec(species_num_bc)%bc_type =	'BLOCK'
!!$                scalar_bc(block)%bc_spec(species_num_bc)%bc_kind =	'CONC'
!!$                scalar_bc(block)%bc_spec(species_num_bc)%bc_loc = &
!!$                     &block_bc(block)%bc_spec(num_bc)%bc_loc
!!$                scalar_bc(block)%bc_spec(species_num_bc)%bc_extent = &
!!$                     &block_bc(block)%bc_spec(num_bc)%bc_extent
!!$                scalar_bc(block)%bc_spec(species_num_bc)%block = block
!!$                scalar_bc(block)%bc_spec(species_num_bc)%species = ispecies
!!$                scalar_bc(block)%bc_spec(species_num_bc)%con_block = &
!!$                     &block_bc(block)%bc_spec(num_bc)%con_block
!!$                scalar_bc(block)%bc_spec(species_num_bc)%num_cell_pairs = &
!!$                     &block_bc(block)%bc_spec(num_bc)%num_cell_pairs
!!$                scalar_bc(block)%bc_spec(species_num_bc)%start_cell = &
!!$                     &block_bc(block)%bc_spec(num_bc)%start_cell
!!$                scalar_bc(block)%bc_spec(species_num_bc)%end_cell = &
!!$                     &block_bc(block)%bc_spec(num_bc)%end_cell
!!$                scalar_bc(block)%bc_spec(species_num_bc)%con_start_cell = &
!!$                     &block_bc(block)%bc_spec(num_bc)%con_start_cell
!!$                scalar_bc(block)%bc_spec(species_num_bc)%con_end_cell = &
!!$                     &block_bc(block)%bc_spec(num_bc)%con_end_cell
!!$             END DO
!!$          END IF
!!$       END DO
!!$    END DO
!!$
!!$    CALL status_message("done setting scalar block connections")

    IF (max_blocks .GT. 1) CALL error_message("multiple blocks not supported", fatal=.TRUE.)

  END SUBROUTINE set_scalar_block_connections

END MODULE scalar_bc_module
  
