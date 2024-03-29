C23456789012345678901234567890123456789012345678901234567890123456789012
      PROGRAM VOLTSTORUNUP

C Written by Debbie Green 12/3/93
C This program reads in data collected with a runup gage that is in
C    volts and converts the data into runup values.

      PARAMETER(NPTSM=2000,NTSM=40)
C     MODIFIED PARAMETER STATEMENTS, 26 JAN 94, MJB
      PARAMETER(VEND=-4.891,N=32,NRODSPACE=31)
C      PARAMETER(V1=-2.485,VW=-2.485,IRODW=2) ! R3 Setup - large runup
C      PARAMETER(V1=-2.485,VW=-2.485,IRODW=1) ! R1 Setup - test phase
      PARAMETER(V1=-2.484,VW=-3.330,IRODW=13) ! R2 Setup - small runup
C
      PARAMETER(NSKIP=79)
      PARAMETER(SV=1,SH=4)
C********************************************************************
C V1     = Voltage for Rod 1 wet, volts
C VEND   = Voltage for end rod wet, volts
C VW     = Voltage for rod at waterline, volts
C N      = Total number of rods, i.e. 25 for test case
C DIST   = Spacing between rods parallel to slope, may be variable
C            (i.e. 1 cm for test case)
C IRODW  = Rod number at waterline, (a rod located at the waterline)
C            (i.e. 11 for test case)
C          Use actual rod from observation, regardless of whether registers
C HV     = Vertical height between rods, same units as DIST
C SH     = Horizontal island slope component, i.e. 4 for circular island
C SV     = Vertical island slope component, i.e. 1 for circular island
C VOUT   = Output voltage read in from data file
C RV     = Vertical runup height relative to waterline, should be
C            + or - from waterline, i.e. units of cm for test since
C            DIST is in cm
C OFFSET = A correction for waterline reading because of gap
C            between rod and bottom, add to all VOUT voltage
C            readings, i.e. -0.219 for test case
C NPTS   = Number of points in input file per gage, i.e. 2000
C            (multiply 25 hz time 80 sec)
C NTS    = Number of time series or number of gages
C NSKIP  = Number of header records to skip
C NRODSPACE = (N-1) Number of spaces between rods on runup gage
C*******************************************************************

      DATA TITLE1/' OUTPUT FROM PROGRAM VOLTSTORUNUP'/
      DATA TITLE2/' TSUNAMI CIRCULAR ISLAND STUDY'/
      DATA TITLE3/' INPUT PARAMETER SUMMARY'/
      DATA DIST/2.0,2.0,2.0,2.0,2.0,2.0,2.0,1.0,1.0,1.0,1.0,1.0,
     &  1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,2.0,2.0,2.0,
     &  2.0,2.0,2.0,2.0,2.0/

      DIMENSION TSDAT(NPTSM,NTSM)
      DIMENSION VOUT2(NPTSM,NTSM)
      DIMENSION ROD(NPTSM,NTSM)
      DIMENSION IROD(NPTSM,NTSM)
      DIMENSION HDR(NSKIP)
      DIMENSION DIST(NRODSPACE)

      CHARACTER*80 TITLE1,TITLE2,TITLE3
      CHARACTER*80 HDR
      CHARACTER*8 FILEIN
      CHARACTER*28 INFILE
      CHARACTER*28 FILEOUT
      CHARACTER*16  DIR
      CHARACTER*4 DAT
      CHARACTER*3 NEW
      CHARACTER*4 VTR
      DATA DIR/'[BRIGGS.TSUNAMI]'/
      DATA NEW/'NEW'/
      DATA VTR/'.VTR'/
      DATA DAT/'.DAT'/
C
      LUNI=12
      TYPE *, ' ENTER INPUT FILE NAME, FILEIN'
      READ(*,5) FILEIN
  5   FORMAT (A)
      TYPE *,' ENTER # OF GAGES (INCLUDING CMMD & FDBCK), NTS'
      READ(*,*) NTS
      TYPE *,' ENTER # OF POINTS PER GAGE, NPTS'
      READ(*,*) NPTS
      TYPE *,' ENTER THE CHANNEL # OF THE RUNUP GAGE, NRGAGE'
      READ(*,*) NRGAGE

      INFILE=DIR//FILEIN//DAT
      OPEN(LUNI,FILE=INFILE,STATUS='OLD',FORM='FORMATTED',RECL=80)

C****READ INPUT DATA FROM FILE****

      CALL INPUT(LUNI,NTS,NPTS,NSKIP,HDR,TSDAT)

C****APPLY OFFSET TO ALL VOLTAGE READINGS****
C     CALCULATE OFFSET
      OFFSET = V1 + ((VEND - V1)/(N-1)) * (IRODW-1) - VW
C
      DO I = 1, NPTS
         VOUT2(I,NRGAGE) = TSDAT(I,NRGAGE) + OFFSET
      END DO

      THETAR=ATAN2(SV,SH)
      THETAD=THETAR*57.2958
      ICOUNT=0
      DO J=1,NPTS
         ROD(J,NRGAGE) = 1 + (((VOUT2(J,NRGAGE) - V1)*(N-1))/(VEND-V1))
         IROD(J,NRGAGE) = NINT(ROD(J,NRGAGE))
C         IF (ABS(ROD(J,NRGAGE)-IROD(J,NRGAGE)).GE.0.3) THEN
C            ICOUNT=ICOUNT +1
C            TYPE *,IROD(J,NRGAGE),ROD(J,NRGAGE)
C         END IF
         IF (IROD(J,NRGAGE).GT.IRODW) THEN
            INC=1
         ELSE
            INC=-1
         ENDIF
         HV=0.0
C        CORRECTION, 9 DEC 93, MJB
         IF (IROD(J,NRGAGE) .EQ. IRODW) HV=0.0
         IF (IROD(J,NRGAGE) .GT. IRODW) THEN
           DO I=IRODW,(IROD(J,NRGAGE)-1),INC
              HV = INC * DIST(I) * SIN(THETAR) + HV
           END DO
         END IF
         IF (IROD(J,NRGAGE) .LT. IRODW) THEN
           DO I=(IRODW-1),IROD(J,NRGAGE),INC
              HV = INC * DIST(I) * SIN(THETAR) + HV
           END DO
         END IF
C
         TSDAT(J,NRGAGE) = HV
      END DO

      FILEOUT=DIR//FILEIN//VTR
      LUNO=14
      OPEN(LUNO,FILE=FILEOUT,STATUS='UNKNOWN',FORM='FORMATTED',RECL=80)

      CALL MAXRUNUP(RUMAX,NTS,NPTS,NRGAGE,TSDAT)

C      CALL OUTPUT(LUNO,NTS,NPTS,NSKIP,HDR,TSDAT)

      CALL OUTPUT_GAGE28_ONLY(LUNO,NTS,NPTS,NRGAGE,TSDAT)

C     OUTPUT RESULTS
C      IF (LUN .NE. 6) THEN
        LUN=15
        OPEN (UNIT=LUN,FILE='VOLTSTORUNUP.OUT',STATUS='UNKNOWN')
C      END IF
      WRITE (LUN,20) TITLE1,TITLE2
 20   FORMAT (2(/,A80))
      WRITE (LUN,30) TITLE3
 30   FORMAT (/,A80)
      WRITE (LUN,40) INFILE,FILEOUT,NTS,NPTS,NRGAGE,V1,VEND,VW,OFFSET,N,
     &               IRODW,SV,SH,THETAD,RUMAX
 40   FORMAT (/,T10,'INPUT FILENAME, INFILE = ',T60,A,
     & /,T10,'OUTPUT FILENAME, FILEOUT = ',T60,A,/,
     & /,T10,'NUMBER OF GAGES (INCLUDE CMMD & FDBK), NTS = ',T60,I6,
     & /,T10,'NUMBER OF POINTS PER GAGE, NPTS = ',T60,I6,
     & /,T10,'CHANNEL NUMBER FOR RUNUP GAGE, NRGAGE = ',T60,I6,/,
     & /,T10,'VOLTAGE FOR ROD 1 WET, V1 = ',T60,F9.4,' VOLTS',
     & /,T10,'VOLTAGE FOR END ROD WET, VEND = ',T60,F9.4,' VOLTS',
     & /,T10,'VOLTAGE FOR ROD AT WATERLINE, VW = ',T60,F9.4,' VOLTS',
     & /,T10,'CORRECTION FOR WATERLINE READING, OFFSET = ',T60,F9.4,
     &       ' VOLTS',/,
     & /,T10,'TOTAL NUMBER OF RODS, N = ',T60,I3,
     & /,T10,'ROD NUMBER AT WATERLINE, IRODW = ',T60,I3,/,
     & /,T10,'VERTICAL ISLAND SLOPE COMPONENT, SV = ',T60,F7.2,
     & /,T10,'HORIZONTAL ISLAND SLOPE COMPONENT, SH = ',T60,F7.2,
     & /,T10,'CIRCULAR ISLAND SLOPE ANGLE, THETAD = ',T60,F7.2,' DEG',
     & /,/,T10,'MAXIMUM RUNUP VALUE, RUMAX = ',T60,F9.4,/)

      WRITE (LUN,*)' RUNUP GAGE SPACING BETWEEN RODS'
      WRITE (LUN,*)' *******************************'
      DO I=1,NRODSPACE
         WRITE (LUN,41) I,I+1,DIST(I)
  41     FORMAT(' SPACING BETWEEN ROD ',I3,' AND ROD ',I3,' IS ',F5.1,
     &   ' CM')
      END DO

      CLOSE(LUN)
      CLOSE(LUNI)
      CLOSE(LUNO)
      END


C***********************************************************************
      SUBROUTINE INPUT(LUNI,NTS,NPTS,NSKIP,HDR,TSDAT)
C     READS MEASURED DATA IN CERC FORMAT, DATA IS DEMULTIPLEXED 
C     READS ALL DATA FROM FIRST POINT IN TSDAT
C
      PARAMETER (NPTSM=2000,NTSM=40)
      CHARACTER*8 FORFOR
      CHARACTER*80 HDR
      DIMENSION TSDAT(NPTSM,NTSM)
      DIMENSION HDR(NSKIP)

C  THE DATA FILE IS CALLED UNIT LUNI AND MUST BE OPENED UPSTREAM OF      *
C  THIS CODE AS:   OPEN(LUNI,FILE='datafile',STATUS='OLD',FORM=          *
C  'FORMATTED',RECL=80)                                               *
C**********************************************************************
C READ IN ALL HEADER INFORMATION INTO CHARACTER ARRAY HDR
C**********************************************************************

      DO I=1,NSKIP
        READ(LUNI,10) HDR(I)
 10     FORMAT(A80)
      END DO
C
C**********************************************************************
C     LOAD DATA INTO ARRAY 'TSDAT' 
      FORFOR='(8F10.5)'
      DO  NC=1,NTS
        READ (LUNI,FORFOR) (TSDAT(I,NC),I=1,NPTS)
      END DO
C
      RETURN
      END

C************************************************************
      SUBROUTINE MAXRUNUP(RUMAX,NTS,NPTS,NRGAGE,TSDAT)
C************************************************************
      PARAMETER (NPTSM=2000,NTSM=40)
      DIMENSION TSDAT(NPTSM,NTSM)

C LOCATE THE MAXIMUM RUNUP VALUE AND SAVE IN VARIABLE RUMAX

      RUMAX=TSDAT(1,NRGAGE)
      DO I=1,NPTS
         IF (TSDAT(I,NRGAGE).GT.RUMAX) THEN
            RUMAX=TSDAT(I,NRGAGE)
         ENDIF
      ENDDO
      RETURN
      END                       ! Subroutine MAXRUNUP


C************************************************************
      SUBROUTINE OUTPUT(LUNO,NTS,NPTS,NSKIP,HDR,TSDAT)
C************************************************************
C
      CHARACTER*80 HDR
      CHARACTER*8 FORFOR
      PARAMETER (NPTSM=2000,NTSM=40)
      DIMENSION HDR(NSKIP),TSDAT(NPTSM,NTSM)
C
C**********************************************************************
C WRITE OUT ALL HEADER INFORMATION INTO CHARACTER ARRAY HDR
C**********************************************************************
      DO I=1,NSKIP
        WRITE(LUNO,10) HDR(I)
 10     FORMAT(A80)
      END DO
C**********************************************************************
C WRITE DATA FROM TSDAT ARRAY BACK OUT TO FILE      
C**********************************************************************
      FORFOR='(8F10.5)'
      DO I=1,NTS
        WRITE(LUNO,FORFOR) (TSDAT(J,I),J=1,NPTS)
      END DO
C
      RETURN
      END

C*****************************************************************
      SUBROUTINE OUTPUT_GAGE28_ONLY(LUNO,NTS,NPTS,NRGAGE,TSDAT)
C*****************************************************************
C
      CHARACTER*80 HDR3
      CHARACTER*8 FORFOR
      PARAMETER (NPTSM=2000,NTSM=40)
      DIMENSION TSDAT(NPTSM,NTSM)
C
C**********************************************************************
C WRITE NEW RUNUP VALUES FOR RUNUP GAGES NUMBER 28 INTO FILE WITH
C ORIGINAL FILENAME, BUT A .VTR EXTENSION, IN ONE-COLUMN FORMAT SO
C THAT THE FILE CAN EASILY BE IMPORTED INTO AXUM FOR PLOTTING
C          D.R.G.   7/20/94
C**********************************************************************
      WRITE(LUNO,600) NRGAGE
  600 FORMAT(' RUNUP GAGE ',I2)
      FORFOR='(F10.5)'
      DO I=1,NPTS
        WRITE(LUNO,FORFOR) TSDAT(I,NRGAGE)
      END DO
C
      RETURN
      END
