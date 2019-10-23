C  USCTOMED.FOR                                            4/6/15
 
C  THIS IS A STAND-A-LONE PROGRAM TO DO THE SAME TASK AS WAS DONE BY
C  MODULE CONVRTLO.FOR IN THE OLD ITLIT8X.FOR PROGRAM: IT INPUTS A FILE
C  IN THE OLD USC*PACK FORMAT, AND CONVERTS IT TO WORKING COPY FORMAT
C  ... THE MEDIUM OLD FORMAT, BEFORE MULTIPLE DRUGS WERE ALLOWED.

C-----------------------------------------------------------------------

C  CONVRTLO.FOR							10-26-99

C  CONVRTL0 IS THE SAME AS CONVRTLN, EXCEPT FOR A SUBTLE BUG FIX.

C  PREVIOUSLY, A VALUE OF 0 WAS WRITTEN AT THE END OF EACH DOSAGE
C  LINE WHENEVER THERE WAS NO BOLUS INPUT COLUMN. AS LONG AS THIS
C  VALUE DIDN'T SHOW UP AS THE ONLY ENTRY ON A SEPARATE LINE, IT
C  WOULD BE IGNORED BY SUBROUTINE FILRED IN THE POPULATION PROGRAMS.
C  BUT, IF IT DID SHOW UP AS THE ONLY ENTRY, FILRED READS IT AND
C  MISINTERPRETS IT AS THE FIRST TIME OF THE NEXT DOSE (SINCE IT IS
C  NOT EXPECTING A BOLUS VALUE IN THIS CASE).

C  NOW, VALAST (THE BOLUS VALUE) IS NOT WRITTEN TO FILE 21 IF NUMBLS
C  = 0. 

C ... SEE OTHER COMMENTS IN THE MODULES CONVRTLN.FOR ... CONVRT.FOR.
C-----------------------------------------------------------------------

C     Define SOME variables:

C     DOSEVT -- Number of dose events.
C     NUMRAT -- Number of rate inputs.
C     NUMBLS -- Number of bolus inputs.
C     NUMEQT -- Number of Output equations.
C     FILFLG -- FIRST LINE FLAG TO INDICATE VERSION OF INPUT FILE.
C     IVER = 1 IF THIS FILE WAS CREATED BY THE OLD PASTRX.
C          = 2 IF THIS FILE WAS CREATED BY THE NEW PASTRXII.

C  FOR USCTOMED.FOR, ADD A IMPLICIT REAL*8(A-H,O-Z) STATEMENT TO ALL 
C  ROUTINES.
      IMPLICIT REAL*8(A-H,O-Z)

	DIMENSION DOSWGT(200),WEIGHT(200),GENMIN(1),GENMAX(1),
     1  AMOUNT(200),RATE(200),GENVAL(200),SERUMC(200),COV(200,30),
     2  COVDOS(200,30),TIMDOS(200),COVMEAN(30),TIMOBS(11*200),
     3  TOTLEV(11*200,11),XLEVEL(11,200),C0(11),C1(11),C2(11),C3(11)

	INTEGER DDAY(200),DMINS(200),WDAY(200),LASTL(11),
     1  WMINS(200),TMONTH,TDAY,TYEAR,LDAY(11,200),LMINS(11,200),
     2  SDAY(200),SMINS(200),ICOVTYP(30),LASTCOV(30),ICOVDAY(200,30),
     3  ICOVMINS(200,30)

      REAL MPERTU,LASTDI,IT(200)

	CHARACTER FILFLG*20,READLINE*72,ETHDES*20
	CHARACTER*20 LSTNAM,FSTNAM
	CHARACTER*73 FILOUT,FILEIN
	CHARACTER*10 CHTNUM,WARD
      	CHARACTER*1 PATSEX
      	CHARACTER*8 TIMEU,AMTU,RATEU,LEVELU,WGTU,SCU,GENU(1)
      	CHARACTER*4 ROUTE(200),GENNAM(1)
        CHARACTER*20 COVNAM(30)

C-----------------------------------------------------------------------

 1010 WRITE(*,1011)
 1011 FORMAT(/' THIS PROGRAM CONVERTS A PATIENT FILE IN THE OLD'/
     1' USC*PACK FORMAT INTO WORKING COPY FORMAT ... THE MEDIUM OLD'/
     2' FORMAT, BEFORE MULTIPLE DRUGS WERE ALLOWED.'//
     3' ENTER THE NAME OF A PATIENT DATA FILE IN THE OLD USC*PACK'/
     4' FORMAT: ')
      READ(*,1012) FILEIN
 1012 FORMAT(A73)

C  CHECK THAT THIS IS AN EXISTING FILE.

      OPEN(21,FILE=FILEIN,ERR=1020,STATUS='OLD')
      GO TO 1030
 1020 WRITE(*,1021) FILEIN
 1021 FORMAT(/' THE FOLLOWING FILE DOES NOT EXIST ... '/
     1'    ',A73)
      GO TO 1010
 1030 CLOSE(21)

 1040 WRITE(*,1031)
 1031 FORMAT(/' ENTER THE NAME OF THE NEW FILE WHICH WILL CONTAIN'/
     1' THE PATIENT INFORMATION IN THE "MEDIUM OLD" WORKING COPY '/
     2' FORMAT (I.E., BEFORE MULTIPLE DRUGS WERE ALLOWED): ')
      READ(*,1012) FILOUT

C  IF THIS FILE ALREADY EXISTS, GIVE THE USER THE CHANCE TO CHANGE
C  THE NAME SO THE OLD FILE WILL NOT BE OVERWRITTEN.

      OPEN(25,FILE=FILOUT,ERR=1050,STATUS='NEW')
      GO TO 1060
 1050 WRITE(*,1051) FILOUT
 1051 FORMAT(/' THE FOLLOWING FILE ALREADY EXISTS ...'/
     1'    ',A73)
      WRITE(*,1052)
 1052 FORMAT(/' ENTER 1 TO ENTER A NEW FILE NAME;'/
     1' ENTER 0 TO OVERWRITE THIS FILE: ')
      READ(*,*) IWRITE
      IF(IWRITE .NE. 0 .AND. IWRITE .NE. 1) GO TO 1050
      IF(IWRITE .EQ. 1) GO TO 1040

 1060 CLOSE(25)



C     OPEN THE USC*PACK FORMATTED FILE (FILE), AND THE ADAPT-LIKE FILE
C     (FILOUT)


        OPEN (1,FILE=FILEIN,Status='OLD')
        OPEN (21,FILE=FILOUT)


C     Set Initial value for dose events.
      IDOSEVT = 0

C     READ FILFLG to check the version of the file.

      READ(1,55) FILFLG
55      FORMAT (A20)

      IF (FILFLG(1:1).NE.'-') THEN
         WRITE(*,56)
56       FORMAT (/,' Your data file is an old one. New things have',
     *             ' been added.',
     *           /,' Please use Pastrx and remake the file.')
         
         GOTO 1220         
      ENDIF


C  IN CONVRTI.FOR, ELIMINATE THE CODE FOR ICS WHICH WAS PUT IN FOR 
C  CONVRTH.FOR. THIS CODE WAS JUST A TEMPORARY TEST DEVICE, SINCE 
C  NEITHER THE OLD PASTRX PROGRAM, NOR XAVIER'S NEW PASTRXII PROGRAM, 
C  ACTUALLY INCLUDES A '2' ANYWHERE IN THE FLAG ON LINE 1.

C  IT LOOKS LIKE (FROM XAVIER'S FIGURE 1 OF HIS WRITEUP REGARDING
C  PASTRXII) THE ALLOWABLE FIRST LINE FLAG FOR A NEW PASTRXII FILE
C  WILL BE THE FOLLOWING:

C  -11x1y ... WHERE
C	 x = 1 (STEADY STATE OPTION) ... N/A FOR THIS ROUTINE;
C	     SPACE (NO STEADY STATE OPTION);
C	 y = 1 IF THERE IS AN ASSAY ERROR PATTERN;
C	     0 OTHERWISE.

C  CHANGE BELOW FOR CONVRTJ.FOR. THE DIFFERENTIATION BETWEEN PASTRX
C  FILES (PREVIOUS VERSION) AND THE NEW PASTRXII FILES (CREATED BY
C  XPAST.EXE) IS IN FILFLG(5:5), WHICH = 1 IF IT'S A PASTRXII FILE,
C  AND IS BLANK IF IT'S A PASTRX FILE.

C  SET IVER = 1 IF THIS FILE WAS CREATED BY THE OLD PASTRX.
C           = 2 IF THIS FILE WAS CREATED BY THE NEW PASTRXII.

	IVER=1
	IF (FILFLG(5:5).EQ.'1') IVER=2

C  NOTE THAT FILES WITH IVER=2 WILL HAVE, POTENTIALLY, ASSAY NOISE 
C  COEFFICIENTS, AND EXTRA DESCRIPTORS (COVARIATES) AT THE END OF THE
C  FILE.

C     READ AND THEN WRITE Patient Data.

      READ(1,50) LSTNAM,FSTNAM,CHTNUM
50      FORMAT (2A20,A10)

	WRITE(21,49) LSTNAM,FSTNAM
   49   FORMAT(' ',' LAST AND FIRST NAMES ARE: ',A20,2X,A20)
	WRITE(21,51) CHTNUM
   51   FORMAT(' CHART NUMBER IS: ',A10)

C  NOTE BELOW THAT IF THIS FILE IS NOT IVER=2 (I.E., NOT MADE BY 
C  THE NEW PASTRXII), THE ETHNICITY FLAG IS SET = 1 (UNKNOWN), AND
C  THE ETHNICITY DESCRIPTION IS SET = ALL SPACES.

      IF (FILFLG(2:2).NE.'1') THEN     
       READ(1,75) WARD,PATAGE,PATSEX,PATHGT,DPATHT,IHUHT
75     FORMAT (A10,F5.1,A1,2F5.1,I1)
       IETHFLG=1
       ETHDES='                    '
      ENDIF

      IF(FILFLG(2:2) .EQ. '1' .AND. IVER .EQ. 1) THEN
       READ(1,80) WARD,PATAGE,PATSEX,PATHGT,DPATHT,IHUHT
80     FORMAT (A10,F10.6,A1,2F6.2,i1)
       IETHFLG=1
       ETHDES='                    '
      ENDIF

      IF(FILFLG(2:2) .EQ. '1' .AND. IVER .EQ. 2) THEN
       READ(1,85) WARD,PATAGE,PATSEX,PATHGT,DPATHT,IHUHT,IETHFLG,ETHDES
85     FORMAT (A10,F10.6,A1,2F6.2,i1,I1,A20)
      ENDIF
	
       	WRITE(21,76) 
   76  	FORMAT(/' WARD NO, PATIENT AGE (YEARS), SEX, HEIGHT (INCHES),'/
     1' ETHNICITY FLAG, AND ETHNICITY DESCRIPTION (IF ANY) FOLLOW ON'/
     2' THE NEXT 6 LINES:')
	WRITE(21,77) WARD
   77   FORMAT(A10)
	WRITE(21,78) PATAGE
   78   FORMAT(F10.6)
	WRITE(21,79) PATSEX
   79   FORMAT(A1)
	WRITE(21,81) PATHGT
   81   FORMAT(F6.2)
	WRITE(21,82) IETHFLG
   82   FORMAT(I1)
	WRITE(21,55) ETHDES

C     READ/WRITE Month, DAY, and Year of Therapy DAY 1.
      READ(1,100) TMONTH,TDAY,TYEAR
100      FORMAT (3I4)
	WRITE(21,83) TMONTH,TDAY,TYEAR
   83   FORMAT(/' DATE OF FIRST THERAPY IS ',3I4)

C     READ/WRITE the general data.
      READ(1,200) GENNAM(1),GENU(1),GENMIN(1),GENMAX(1)
200      FORMAT (A4,A8,2F7.2)
	WRITE(21,200) GENNAM(1),GENU(1),GENMIN(1),GENMAX(1)
 
C     READ/WRITE the unit values.
      READ(1,300) TIMEU,AMTU,RATEU,LEVELU,WGTU,SCU,MPERTU
300      FORMAT (6A8,F7.2)
      WRITE(21,300) TIMEU,AMTU,RATEU,LEVELU,WGTU,SCU,MPERTU

C  MUST READ THE REST OF THE FILE BEFORE WRITING ANYTHING ELSE, SINCE
C  THE COVARIATE VALUES (READ BELOW) ARE PUT INTO THE 'DOSAGE' COLUMNS.

 

C     READ the dose data.
      READ(1,400) LASTD
400      FORMAT (I4)
      IF (LASTD.GT.0) THEN
         DO 600 I = 1,LASTD
            IF (FILFLG(2:2).NE.'1') THEN
               READ(1,550) ROUTE(I),DDAY(I),DMINS(I),RATE(I),IT(I),
     1                      AMOUNT(I),GENVAL(I)
550	         FORMAT (A4,2I4,4F13.8)

C  NOTE THAT GENVAL IS THE CCR READING. 

            ELSE
               READ(1,500) ROUTE(I),DDAY(I),DMINS(I),RATE(I),IT(I),
     1                   AMOUNT(I),GENVAL(I)
500		FORMAT (A4,2I4,4F15.8)
            ENDIF
600      CONTINUE

C        READ LAST dose interval.
         IF (FILFLG(2:2).NE.'1') THEN
            READ(1,700) LASTDI
         ELSE
            READ(1,750) LASTDI
         ENDIF
700         FORMAT (F7.2)
750         FORMAT (F15.8)
      ENDIF


C??? CONVRTL.FOR HARDCODES NUMEQT = 1 UNTIL NEW XPAST PROGRAM READY ??? 
C    WHEN THE NEW XPAST IS READY, A FILFLG CODE WILL TELL THIS PROGRAM
C    THAT NUMEQT IS TO BE READ IN.

C  READ the level data. FIRST READ NUMEQT = NO. OF OUTPUT EQUATIONS.
C  THEN, FOR EACH OUTPUT, READ THE TIME AND THE OBSERVED VALUES IN
C  3 COLUMNS JUST AS IN CONVRTJ.FOR. SO THERE WILL BE NUMEQT ARRAYS,
C  ONE AFTER THE OTHER BELOW.

C	READ(1,*) NUMEQT

	NUMEQT = 1


	DO IOUT=1,NUMEQT

      READ(1,*) LASTL(IOUT)

C  NOTE BELOW THAT, IN CONVRTI.FOR, FILFLG(3:3) DETERMINES THE FORMAT 
C  FOR THE LEVELS, WEIGHT, AND SERUM CREATININE VALUES.

	DO I = 1,LASTL(IOUT)
	 IF(FILFLG(3:3) .EQ. ' ') READ(1,900) 
     1   LDAY(IOUT,I),LMINS(IOUT,I),XLEVEL(IOUT,I)
	 IF(FILFLG(3:3) .EQ. '1') READ(1,910) 
     1   LDAY(IOUT,I),LMINS(IOUT,I),XLEVEL(IOUT,I)
	END DO

900      FORMAT (2I4,F7.2)
910      FORMAT (2I4,F9.4)

	END DO

C  THE ABOVE END DO IS FOR THE  DO IOUT=1,NUMEQT  LOOP.

C  CALL SUBROUTINE COMBINE TO COMBINE ALL TIMES AND ALL NUMEQT SETS OF
C  OBSERVATIONS INTO ONE BIG MATRIX ... FOR OUTPUT BELOW TO THE 
C  ADAPT-LIKE FILE. NOTE THAT -99 IS PUT INTO EACH LEVEL ENTRY WHICH
C  DOESN'T HAVE AN OBSERVATION AT THE ASSOCIATED TIME. NOTE THAT NOBTIM
C  RETURNS AS THE TOTAL NO. OF UNIQUE OBSERVATION TIMES.

	CALL COMBINE(NUMEQT,LASTL,LDAY,LMINS,XLEVEL,LASTD,DDAY,DMINS,
     1  MPERTU,NOBTIM,TIMOBS,TOTLEV)


C     READ the weight data.
      READ(1,400) LASTW
      IF (LASTW.GT.0) THEN
         DO 1100 I = 1,LASTW
	IF(FILFLG(3:3) .EQ. ' ') READ(1,900) WDAY(I),WMINS(I),WEIGHT(I)
	IF(FILFLG(3:3) .EQ. '1') READ(1,910) WDAY(I),WMINS(I),WEIGHT(I)
1100     CONTINUE
      ENDIF


C  NEW FOR CONVRTI.FOR: READ SERUM CREATINE VALUES; ALSO, IF THIS FILE
C  IS MADE BY PASTRXII (NEW PASTRX), READ IN ASSAY ERROR PATTERN (IF
C  AVAILABLE), AND WHATEVER USER COVARIATE INFO IS IN THE FILE).

C     READ the SERUM CREATININE VALUES.
      READ(1,400) LASTS
      IF (LASTS.GT.0) THEN
         DO 1200 I = 1,LASTS
	IF(FILFLG(3:3) .EQ. ' ') READ(1,900) SDAY(I),SMINS(I),SERUMC(I)
	IF(FILFLG(3:3) .EQ. '1') READ(1,910) SDAY(I),SMINS(I),SERUMC(I)
1200     CONTINUE
      ENDIF

C  INITIALIZE NCOVAR = 0; IF IT CHANGES BELOW, INFO FOR NCOVAR 
C  COVARIATES WILL BE READ IN.

	NCOVAR = 0

C  IF IVER = 2 (WHICH MEANS THIS IS A PASTRXII TYPE FILE), READ REST OF
C  FILE; OTHERWISE, THE READING IS DONE.

	IF(IVER .EQ. 2) THEN


   60	 READ(1,57) READLINE
   57    FORMAT(A72)
	 IF(READLINE(1:1) .NE. '[') GO TO 60

C  READ IN ASSAY COEFFICIENTS IF NEXT LINE = [ASSAY ERROR PATTERN]. 
C  OTHERWISE, GO ON TO COVARIATE INFO READING (IF COV. INFO IS PRESENT).
C  NOTE: I DON'T THINK THE ASSAY COEFFICIENTS WILL EVER BE PRESENT, BUT
C        I'LL INCLUDE THE LOGIC FOR IT ANYWAY.

	 IF(READLINE(2:6) .EQ. 'ASSAY') THEN
	  DO IEQ=1,NUMEQT
	   READ(1,*) C0(IEQ),C1(IEQ),C2(IEQ),C3(IEQ)
	  END DO
	 ENDIF

C  READ IN COVARIATE INFO IF NEXT LINE = [USER COVARIATES]. OTHERWISE,
C  THE READING IS FINISHED.

	 READ(1,57) READLINE
	 IF(READLINE(2:5) .EQ. 'USER') THEN

	 READ(1,*) NCOVAR

C  AS OF CONVRTLM.FOR, TEST NCOVAR TO MAKE SURE IT IS .LE. 30 SINCE
C  SEVERAL ARRAYS WHICH ARE FILLED WITH NCOVAR VALUES HAVE DIMENSION
C  EQUAL TO 30.

	 IF(NCOVAR .GT. 30) THEN
	  WRITE(*,123) FILEIN, NCOVAR
  123     FORMAT(//' PATIENT FILE '/
     1' ',A73/
     2' HAS ',I3,' USER-SUPPLIED COVARIATES. THE MAXIMUM ALLOWABLE '/
     3' NUMBER OF SUCH COVARIATES IS 30.'//
     3' PLEASE RERUN THE PROGRAM AFTER EDITING YOUR PATIENT FILES TO '/
     4' INSURE EACH HAS A MAXIMUM OF 30 USER-SUPPLIED COVARIATES. '/)
	  STOP
	 ENDIF


	 DO 1300 ICOVAR=1,NCOVAR


C  READ IN INFO FOR COVARIATE NO. ICOVAR.

	 READ(1,58) COVNAM(ICOVAR),ICOVTYP(ICOVAR)
   58    FORMAT(A20,I1)

C  IF ICOVTYP(ICOVAR) = 2 OR 3, SKIP THE NEXT THREE LINES (WHICH GIVE
C  THE UNITS, THE MIN, AND THE MAX OF THE COVARIATE.

	   IF(ICOVTYP(ICOVAR) .NE. 1) THEN
	    DO I=1,3
	     READ(1,*)
	    END DO
	   ENDIF

C     READ THIS COVARIATE'S VALUES.

         READ(1,400) LASTCOV(ICOVAR)

         IF (LASTCOV(ICOVAR) .GT. 0) THEN
          DO I = 1,LASTCOV(ICOVAR)
	   IF(ICOVTYP(ICOVAR) .NE. 1) READ(1,920) ICOVDAY(I,ICOVAR),
     1      ICOVMINS(I,ICOVAR),COV(I,ICOVAR)
	   IF(ICOVTYP(ICOVAR) .EQ. 1) READ(1,930) ICOVDAY(I,ICOVAR),
     1      ICOVMINS(I,ICOVAR),COV(I,ICOVAR)
	  END DO
         ENDIF
  920     FORMAT(2I4,F16.8)
  930     FORMAT(2I4,F2.0)

 1300    CONTINUE


	ENDIF

C  THE ABOVE ENDIF IS FOR THE  IF(READLINE(2:5) .EQ. 'USER')  CONDITION.

	ENDIF

C  THE ABOVE ENDIF IS FOR THE  IF(IVER .EQ. 2)  CONDITION.


C     CLOSE the file.
      CLOSE (1)

C     Set the number of rate inputs: R(2) = WGT, R(3) = CCR,
C     FOLLOWED BY NCOVAR COVARIATES, R(4), ..., R(3+NCOVAR)

      NUMRAT = 3 + NCOVAR
 
C     Set the number of bolus inputs

      NUMBLS = 0

C  NUMBLS IS SET = 1 BELOW IF ANY DOSE IS A BOLUS (I.E., 'IM' = BOLUS
C  INJECTION INTO HIP; 'PO' = BOLUS ORAL DOSE INTO GUT). 

	IEXT=0
	DO I=1,LASTD
	IF((ROUTE(I) .EQ. 'IM') .OR. (ROUTE(I) .EQ. 'PO') .OR.
     1  (ROUTE(I) .EQ. 'im') .OR. (ROUTE(I) .EQ. 'po')) IEXT=1
	END DO
	NUMBLS=NUMBLS+IEXT


	IF(NCOVAR .EQ. 0) WRITE(21,18)
   18   FORMAT(/' THERE ARE NO COVARIATES IN THIS DATA SET.')
	IF(NCOVAR .GE. 1) WRITE(21,22) NCOVAR
   22   FORMAT(/' THERE ARE ',I2,' COVARIATES. THEIR NAMES ARE: ')

	DO I=1,NCOVAR
	 WRITE(21,55) COVNAM(I)
	END DO


      WRITE(21,23) NUMRAT
   23 FORMAT(' ',I5,' ... NO. OF "RATES", INCLUDING WT,CCR,COVARIATES.')

      WRITE(21,24) NUMBLS
   24 FORMAT(' ',I5,' ... NO. OF BOLUS INPUT COLUMNS.')

C     FIND THE TOTAL NO. OF DOSE EVENTS (IDOSEVT). 
C     IF ROUTE = IV or B --> INCREASE IDOSEVT BY 2. Otherwise, INCREASE
C     IDOSEVT BY  1.

      IF (LASTD.GT.0) THEN

         DO 2300 I = 1,LASTD
            IF ((ROUTE(I) .EQ. 'IV') .OR. (ROUTE(I) .EQ. 'iv')
     *         .OR. (ROUTE(I) .EQ. 'B') .OR. (ROUTE(I) .EQ. 'b')      
     *         .OR. (ROUTE(I) .EQ. 'I') .OR. (ROUTE(I) .EQ. 'i')) THEN
                IDOSEVT = IDOSEVT + 2
            ELSE
                IDOSEVT = IDOSEVT + 1
            ENDIF
2300      CONTINUE

      ENDIF

C     WRITE the number of dose events.
      WRITE(21,26) IDOSEVT
   26 FORMAT(' ',I5,' ... NO. OF DOSE EVENTS. EACH DOSE EVENT HAS, IN OR
     1DER:'/
     2'           TIME, IV RATE, WT, CCR, COV VALUES (IF ANY), BOLUS VAL
     3UE.'/)


C  CALL SETWGT JUST ONCE (AS OF CONVRTI.FOR), INSTEAD OF INSIDE THE 
C  2400 LOOP, SINCE JUST ONE CALL RETURNS ALL THE WEIGHTS AT ALL THE 
C  DOSE TIMES, DOSWGT(I),I=1,LASTD. 

C  SIMILARLY, CALL SETCOV BEFORE THE 2400 LOOP

C  IF NCOVAR .GT. 0.

         CALL SETWGT(LASTW,LASTD,DDAY,DMINS,MPERTU,
     1  WDAY,WMINS,WEIGHT,DOSWGT)

C  CALL SETCOV TO DETERMINE THE VALUES OF EACH COVARIATE AT THIS DOSE
C  TIME ... IF NCOVAR .GT. 0.

	IF(NCOVAR .GT. 0) CALL SETCOV(NCOVAR,LASTCOV,ICOVTYP,LASTD,DDAY,
     1			  DMINS,MPERTU,ICOVDAY,ICOVMINS,COV,COVDOS)

C     Translate DATA to the new format for each dose.

      DO 2400 I = 1,LASTD

C     Compute time into regimen. STORE IT INTO TIMDOS(I), WHICH WILL
C     BE NEEDED BELOW LOOP 2400 TO CALCULATE THE MEAN OF EACH COVARIATE.

         TIMREG = REGTIM(DDAY(I),DMINS(I),LASTD,MPERTU,DDAY(1),DMINS(1))
	 TIMDOS(I) = TIMREG

C  SET THE LAST ENTRY FOR EACH LINE TO BE THE BOLUS INPUT FOR THAT DOSE
C  (IF THE LINE IS FOR AN IV RATE (IV,B, OR I), SET THIS VALUE = 0).

	VALAST=AMOUNT(I)

        IF ((ROUTE(I) .EQ. 'IV') .OR. (ROUTE(I) .EQ. 'iv')
     1  .OR. (ROUTE(I) .EQ. 'B') .OR. (ROUTE(I) .EQ. 'b')      
     2  .OR. (ROUTE(I) .EQ. 'I') .OR. (ROUTE(I) .EQ. 'i')) VALAST=0.0

C  AS OF CONVRTLO.FOR, VALAST IS NOT WRITTEN TO FILE 21 IF NUMBLS
C  = 0. NOTE THAT IF NUMBLS = 0, THE BOLUS VALUE, VALAST=0 IS IGNORED 
C  BY SUBROUTINE FILRED IN THE POPULATION PROGRAMS IF IT SHOWS UP AS
C  THE LAST VALUE ON A DOSAGE LINE, BUT, IF IT IS THE ONLY VALUE ON
C  A SEPARATE LINE (WHICH CAN HAPPEN IF THERE ARE USER-DEFINED 
C  COVARIATES), IT WILL BE READ AND MISINTERPRETED BY FILRED. 

	IF(NCOVAR .EQ. 0 .AND. NUMBLS .GT. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),VALAST

	IF(NCOVAR .EQ. 0 .AND. NUMBLS .EQ. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I) 

	IF(NCOVAR .GT. 0 .AND. NUMBLS .GT. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),(COVDOS(I,J),J=1,NCOVAR),VALAST

	IF(NCOVAR .GT. 0 .AND. NUMBLS .EQ. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),(COVDOS(I,J),J=1,NCOVAR)


C  WRITE THE ENDING LINE FOR ANY IV-TYPE RATE.

         IF ((ROUTE(I) .EQ. 'IV') .OR. (ROUTE(I) .EQ. 'iv')
     1      .OR. (ROUTE(I) .EQ. 'B') .OR. (ROUTE(I) .EQ. 'b')  
     2      .OR. (ROUTE(I) .EQ. 'I') .OR. (ROUTE(I) .EQ. 'i')) THEN

            TIMREG = TIMREG + IT(I)
            RATE(I) = 0.0

C  NOTE THAT WEIGHTS, CCR'S, AND COVARIATE VALUES ARE ASSUMED TO BE
C  CONSTANT OVER AN IV DOSE PERIOD.

C  AS OF CONVRTL0.FOR, THE FOLLOWING IF STATEMENTS WILL BE BASED
C  ON BOTH NCOVAR AND NUMBLS (SEE REASONING ABOVE).

	IF(NCOVAR .EQ. 0 .AND. NUMBLS .GT. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),VALAST

	IF(NCOVAR .EQ. 0 .AND. NUMBLS .EQ. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I) 

	IF(NCOVAR .GT. 0 .AND. NUMBLS .GT. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),(COVDOS(I,J),J=1,NCOVAR),VALAST

	IF(NCOVAR .GT. 0 .AND. NUMBLS .EQ. 0) WRITE(21,*) TIMREG, 
     1  RATE(I), DOSWGT(I), GENVAL(I),(COVDOS(I,J),J=1,NCOVAR)


         ENDIF            

2400   CONTINUE

C      WRITE the number of model output equations.
       WRITE(21,*) NUMEQT

C  WRITE the total number of observations times, followed by the 
C  observation times and associated observations for all output eqs.

       WRITE(21,*) NOBTIM

        DO I = 1,NOBTIM
	 WRITE(21,*) TIMOBS(I), (TOTLEV(I,J),J=1,NUMEQT)
	END DO


C  CALCULATE THE "INTEGRATED MEAN" FOR WEIGHT, CCR, AND EACH 
C  ADDITIONAL COVARIATE. THIS "MEAN" = SUM OF EACH COVARIATE
C  MULTIPLIED BY THE ASSOCIATED TIME (UNTIL IT CHANGES), AND THEN
C  THIS SUM DIVIDED BY THE TOTAL TIME (LAST TIME - 1ST DOSE TIME).

C  NOTE: THE LAST TIME = MAX(LAST DOSE TIME, LAST OBSERVATION TIME).
C	 THE LAST DOSE TIME = TIMREG FROM  LOOP 2400.

C	 THIS LAST TIME WILL BE CALLED TIMMAX.

C        OBSERVE THAT THE THE LAST COVARIATE VALUE IS ASSUMED TO BE
C 	 EFFECTIVE FROM THE LAST DOSE TIME UNTIL TIMMAX (WHICH MEANS
C	 IF TIMMAX = LAST DOSE TIME, THERE WILL BE 0 CONTRIBUTION
C	 FROM THIS LAST COVARIATE VALUE).

C  ESTABLISH THE LAST TIME OF THE REGIMEN (DOSE OR CONCENTRATION TIME)
C  = TIMMAX.

	TIMMAX = TIMREG
        IF(TIMOBS(NOBTIM) .GT. TIMMAX) TIMMAX = TIMOBS(NOBTIM)

	WTMEAN = 0.0
	CCRMEAN = 0.0

	IF(NCOVAR .GT. 0) THEN
	 DO J=1,NCOVAR
	  COVMEAN(J)=0.0
	 END DO
	ENDIF


	DO IDOS = 1, LASTD-1

	 WTMEAN = WTMEAN + DOSWGT(IDOS)*(TIMDOS(IDOS+1) - TIMDOS(IDOS))
	 CCRMEAN = CCRMEAN + GENVAL(IDOS)*(TIMDOS(IDOS+1)-TIMDOS(IDOS))

	 IF(NCOVAR .GT. 0) THEN
	  DO J=1,NCOVAR
	   COVMEAN(J) = COVMEAN(J) + COVDOS(IDOS,J)*
     1                              (TIMDOS(IDOS+1)-TIMDOS(IDOS))
	  END DO
	 ENDIF

	END DO

C  NOTE THAT TIMMAX IS THE MAXIMUM TIME OF THE REGIMEN (DOSE OR
C  CONCENTRATION TIME), AND TIMDOS(1) IS THE 1ST DOSE TIME. IF THESE
C  TWO VALUES ARE EQUAL, IT MEANS THAT THERE IS ONLY 1 DOSE TIME, AND
C  IF THERE IS A CONCENTRATION TIME, IT OCCURS AT THIS DOSE TIME. THIS
C  WOULD OF COURSE GIVE MEANINGLESS INFORMATION (JUST ONE OBSERVATION
C  AT TIME 0 WOULD GIVE NO INFO ON ANY MODEL PARAMETERS), BUT 
C  NEVERTHELESS CHECK FOR THIS POSSIBILITY TO PREVENT A POTENTIAL
C  DIVIDE BY 0 ERROR. IN SUCH A CASE, TELL THE USER AND STOP.

	IF(TIMMAX .EQ. TIMDOS(1)) THEN
	 WRITE(*,17) FILEIN
   17    FORMAT(//' ************* BAD PATIENT DATA FILE *************'//
     1'  PATIENT, '/
     2' ',A73/
     3' HAS NO USEFUL INFORMATION. THE ONLY OBSERVATION TIME, IF THERE'/
     4' IS ONE, OCCURS AT THE ONLY DOSE TIME. PLEASE REMOVE THIS '/
     5' PATIENT AND RERUN THE PROGRAM. '//
     4' ************* BAD PATIENT DATA FILE *************'//)
	 STOP
	ENDIF

	WTMEAN = WTMEAN + DOSWGT(LASTD)*(TIMMAX - TIMDOS(LASTD))
	WTMEAN = WTMEAN/(TIMMAX - TIMDOS(1))

	CCRMEAN = CCRMEAN + GENVAL(LASTD)*(TIMMAX - TIMDOS(LASTD))
	CCRMEAN = CCRMEAN/(TIMMAX - TIMDOS(1))

	IF(NCOVAR .GT. 0) THEN
	  DO J=1,NCOVAR
	   COVMEAN(J) = COVMEAN(J) + COVDOS(LASTD,J)*
     1                              (TIMMAX - TIMDOS(LASTD))
	   COVMEAN(J) = COVMEAN(J)/(TIMMAX - TIMDOS(1))
	  END DO
	ENDIF

	WRITE(21,27)
   27   FORMAT(/' COVARIATE NAMES AND VALUES (1ST, LAST, AND MEAN) FOLLO
     1W:'/)

	WRITE(21,28) 'WT                  ',DOSWGT(1),DOSWGT(LASTD),
     1                WTMEAN
	WRITE(21,28) 'CCR                 ',GENVAL(1),GENVAL(LASTD),
     1                CCRMEAN

	IF(NCOVAR .GT. 0) THEN
	 DO J=1,NCOVAR
	  WRITE(21,28) COVNAM(J),COVDOS(1,J),COVDOS(LASTD,J),COVMEAN(J)
	 END DO
	ENDIF

   28   FORMAT(A20,3F15.5)


C  NOTE THAT IF FILFLG(6:6) = 1, THE ASSAY COEFFICIENTS WERE READ IN
C  ABOVE (FILFLG(6:6)=1 <--> [ASSAY ERROR PATTERN] IS IN USC*PACK FILE,
C  FOLLOWED BY THE C'S (SEE CODE ABOVE TO READ C'S IN IN THIS CASE).
C  ... I DON'T THINK FILFLG(6:6) WILL = 1 IN XAVIER'S CURRENT PASTRXII
C  PROGRAM, BUT I'LL INCLUDE THE LOGIC FOR IT BELOW, ANYWAY.

C  IN THIS CASE, WRITE THEM OUT ON THE LAST LINES OF THE FILE, WITH A 
C  COMMENT ON THE LINE PRECEEDING THEM.

	IF(FILFLG(6:6) .EQ. '1') THEN
	 WRITE(21,*) 'ASSAY COEFFICIENTS FOLLOW:'
	  DO IEQ=1,NUMEQT
	   WRITE(21,*) C0(IEQ),C1(IEQ),C2(IEQ),C3(IEQ)
	  END DO
	ENDIF

	IF(FILFLG(6:6) .NE. '1') THEN
	 WRITE(21,*) 'ASSAY COEFFICIENTS ARE NOT INCLUDED'
	ENDIF

       CLOSE (21)

1220   STOP
       END

C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
C     FUNCTION to determine the time INTO THE REGIMEN (IN HOURS IF
C     MPERTU=60) FROM THE 1ST DOSE ... AT DAY AND MINS.

C  FOR USCTOMED.FOR, REGTIM IS REAL*8, RATHER THAN REAL.
      	REAL*8 FUNCTION REGTIM(DAY,MINS,LASTD,MPERTU,DDAY,DMINS)

	REAL MPERTU
	INTEGER DDAY,DMINS,DAY,TOTDAY,TOTMIN
 
C     The time into the regimen is computed based on the
C     time of the first dose, hence, if there are no past
C     doses, the time into the regimen is given as an invalid
C     value.

      IF (LASTD.EQ.0) THEN
 
C        No past doses.
         REGTIM = -1.0
 
      ELSE
 
C        Compute days since midnight of the day the regimen
C        started to midnight of the current day.

         TOTDAY = DAY-DDAY

C        Convert days to minutes (1440 minutes per day).
         TOTMIN = TOTDAY*1440

C        Correct for minutes since midnight of first day.
         TOTMIN = TOTMIN-DMINS
 
C        Add in offset for minutes into current day.
         TOTMIN = TOTMIN+MINS

C        Convert for proper time units.
         REGTIM = TOTMIN/MPERTU
 
      ENDIF

      RETURN
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
	SUBROUTINE SETCOV(NCOVAR,LASTCOV,ICOVTYP,LASTD,DDAY,DMINS,
     1  MPERTU,ICOVDAY,ICOVMINS,COV,COVDOS)

C  THIS SUBROUTINE, CALLED BY SUBROUTINE CONVRT, DETERMINES THE VALUES 
C  OF EACH COVARIATE AT ALL THE DOSE TIMES.

C  FOR USCTOMED.FOR, ADD A IMPLICIT REAL*8(A-H,O-Z) STATEMENT TO ALL 
C  ROUTINES.
      IMPLICIT REAL*8(A-H,O-Z)


	DIMENSION COVDOS(200,30),COV(200,30),TIMCOV(200,30)
      REAL MPERTU 
	INTEGER DDAY(200),DMINS(200),ICOVDAY(200,30),ICOVMINS(200,30),
     1  LASTCOV(30),ICOVTYP(30)

C  INPUT ARE:

C  NCOVAR = NO. OF COVARIATES SELECTED BY USER.
C  LASTCOV(I) = NO. OF COVARIATE VALUES FOR COVARIATE I, I=1,NCOVAR.
C  ICOVTYP(I) = "TYPE" OF COVARIATE I, I=1,NCOVAR;
C		"TYPE" = 1  IF  COVARIATE IS BINARY (YES/1 OR NO/0);
C		"TYPE" = 2  IF  COVARIATE IS NUMERIC, WITH PIECEWISE
C			CONSTANT VALUES BETWEEN DOSES.
C		"TYPE" = 3  IF  COVARIATE IS NUMERIC, WITH INTERPOLATED
C			VALUES BETWEEN DOSES (ALTHOUGH VALUES WILL BE
C			CONSTANT WITHIN AN IV RATE DOSE PERIOD).
C  LASTD = NO. OF DOSES.
C  DDAY(I) = DAY FOR DOSE NO. I, I=1,LASTD.
C  DMINS(I) = MINS INTO THE DAY FOR DOSE NO. I, I=1,LASTD.
C  MPERTU = MINUTES PER TIME UNIT.
C  ICOVDAY(I,J) = DAY FOR COVARIATE J'S ITH VALUE; I=1,LASTCOV(J),
C		  J=1,NCOVAR.
C  ICOVMINS(I,J) = MINUTES INTO THE DAY FOR COVARIATE J'S ITH VALUE; 
C                 I=1,LASTCOV(J), J=1,NCOVAR.
C  COV(I,J) = COVARIATE J'S ITH VALUE; I=1,LASTCOV(J), J=1,NCOVAR.


C  OUTPUT IS:

C  COVDOS(I,J) = COVARIATE J'S VALUE AT THE ITH DOSE TIME; I=1,LASTD,
C 		 J=1,NCOVAR.


C  FIRST, ESTABLISH ALL THE TIMES INTO THE REGIMEN FOR EACH OF THE
C  COVARIATES. PUT THEM INTO TIMCOV(I,ICOV), I=1,LASTCOV(ICOV); 
C  ICOV=1,NCOVAR.

	DO ICOV = 1,NCOVAR
	 DO I=1,LASTCOV(ICOV)
          TIMCOV(I,ICOV) = REGTIM(ICOVDAY(I,ICOV),ICOVMINS(I,ICOV),
     1			  LASTD,MPERTU,DDAY(1),DMINS(1))
	 END DO
	END DO	  


	DO 200 IDOS = 1,LASTD

C  DETERMINE EACH COVARIATE'S VALUE AT DOSE NO. IDOS. FIRST, FIND THIS
C  DOSE TIME IN TERMS OF HOURS FROM THE BEGINNING DOSE.

         TIMREG = REGTIM(DDAY(IDOS),DMINS(IDOS),LASTD,MPERTU,
     1            DDAY(1),DMINS(1))


	 DO 100 ICOV=1,NCOVAR

C  FOR COVARIATE ICOV, IF ICOVTYP(I) = 1 OR 2, THE VALUE OF THE 
C  COVARIATE WILL BE CONSTANT FOR ALL DOSES BETWEEN ANY TWO CONSECUTIVE
C  COVARIATE VALUES. IF ICOVTYP(I) = 3, THE VALUE OF THE COVARIATE
C  WILL CHANGE (BY INTERPOLATION) FOR ALL DOSES BETWEEN ANY TWO
C  CONSECUTIVE COVARIATE VALUES.
  
C  FIND THE VALUE OF COVARIATE NO. ICOV FOR DOSE TIME, TIMREG.
C  THERE ARE 4 CASES: 
C   1. IF THIS COVARIATE HAS A COVARIATE TIME = TIMREG, THIS VALUE WILL
C      OF COURSE BE THE VALUE FOR COVDOS(IDOS,ICOV);
C   2. IF THIS COVARIATE'S FIRST COVARIATE TIME IS > TIMREG, SET 
C      COVDOS(IDOS,ICOV) = COV(1,ICOV) <-- THE 1ST COVARIATE VALUE.
C   3. IF THIS COVARIATE'S LAST COVARIATE TIME IS < TIMREG, SET 
C      COVDOS(IDOS,ICOV) = COV(LASTCOV(ICOV),ICOV) <-- THE LAST 
C      COVARIATE VALUE.
C   4. IF NONE OF 1., 2., AND 3. APPLIES, FIND THE TWO COVARIATE TIMES 
C      IN TIMCOV(I,ICOV) WHICH SURROUND TIMREG. THEN
C        A. IF ICOVTYP(ICOV) = 1 OR 2, SET COVDOS(IDOS,ICOV) = 
C           COV(IBEF,ICOV), WHERE IBEF IS THE HIGHEST INDEX FOR THIS 
C	    COVARIATE WITH A TIME WHICH IS < TIMREG.
C        B. IF ICOVTYP(ICOV) = 3, SET COVDOS(IDOS,ICOV) = INTERPOLATED 
C	    VALUE BETWEEN COV(IBEF,ICOV) AND COV(IBEF+1,ICOV), BASED ON 
C	    THE TIMES FOR THESE VALUES, AND THE TIME FOR THIS DOSE, 
C	    TIMREG.


C  CASE 2:	

	  IF(TIMCOV(1,ICOV) .GT. TIMREG) THEN
	   COVDOS(IDOS,ICOV) = COV(1,ICOV)
	   GO TO 100
	  ENDIF

C  CASE 3:

	  IF(TIMCOV(LASTCOV(ICOV),ICOV) .LT. TIMREG) THEN
	   COVDOS(IDOS,ICOV) = COV(LASTCOV(ICOV),ICOV)
	   GO TO 100
	  ENDIF

C  CASE 1:

	  DO ITIM=1,LASTCOV(ICOV)
	   IF(TIMCOV(ITIM,ICOV) .EQ. TIMREG) THEN
	    COVDOS(IDOS,ICOV) = COV(ITIM,ICOV)
	    GO TO 100
	   ENDIF
	  END DO

C  TO GET TO THIS POINT --> CASE 4:

	  DO 50 ITIM=1,LASTCOV(ICOV)

	   IF(TIMCOV(ITIM,ICOV) .GT. TIMREG) THEN

C  IF THIS COVARIATE IS A TYPE 1 OR 2, USE THE COV VALUE FROM THE
C  PREVIOUS TIME, ITIM-1. 

	    IF(ICOVTYP(ICOV) .LE. 2) THEN
	     COVDOS(IDOS,ICOV)=COV(ITIM-1,ICOV)
	     GO TO 100
	    ENDIF

C  THIS COVARIATE IS TYPE 3, SO USE THE INTERPOLATED VALUE
C  BETWEEN THE COV VALUE FROM THE PREVIOUS TIME AND THIS TIME.


	    TDEL = TIMREG - TIMCOV(ITIM-1,ICOV)
	    TTOT = TIMCOV(ITIM,ICOV) - TIMCOV(ITIM-1,ICOV)
	    DELCOV = TDEL/TTOT * (COV(ITIM,ICOV) - COV(ITIM-1,ICOV))
	    COVDOS(IDOS,ICOV) = COV(ITIM-1,ICOV) + DELCOV
	    GO TO 100

	   ENDIF

C  THE ABOVE ENDIF IS FOR THE  IF(TIMCOV(ITIM,ICOV) .GT. TIMREG) 
C  CONDITION.

   50     CONTINUE


  100    CONTINUE

  200	CONTINUE


	RETURN
	END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
        SUBROUTINE SETWGT(LASTW,LASTD,DDAY,DMINS,MPERTU,
     1  WDAY,WMINS,WEIGHT,DOSWGT)

C  FOR USCTOMED.FOR, ADD A IMPLICIT REAL*8(A-H,O-Z) STATEMENT TO ALL 
C  ROUTINES.
      IMPLICIT REAL*8(A-H,O-Z)

	DIMENSION DOSWGT(200),WEIGHT(200),TIMWGT(200)
      REAL MPERTU 
	INTEGER DDAY(200),DMINS(200),WDAY(200),WMINS(200)

C  THIS SUBROUTINE, CALLED BY SUBROUTINE CONVRT, DETERMINES THE VALUES 
C  OF WEIGHT AT ALL THE DOSE TIMES.

C  INPUT ARE:

C  LASTW = NO. OF VALUES FOR WEIGTH.
C  LASTD = NO. OF DOSES.
C  DDAY(I) = DAY FOR DOSE NO. I, I=1,LASTD.
C  DMINS(I) = MINS INTO THE DAY FOR DOSE NO. I, I=1,LASTD.
C  MPERTU = MINUTES PER TIME UNIT.
C  WDAY(I) = DAY FOR ITH WEIGHT VALUE.
C  WMINS(I) = MINUTES INTO THE DAY FOR ITH WEIGHT VALUE.
C  WEIGHT(I) = ITH WEIGHT VALUE.


C  OUTPUT IS:

C  DOSWGT(I) = WEIGHT AT THE ITH DOSE TIME; I=1,LASTD.


C  FIRST, ESTABLISH ALL THE TIMES INTO THE REGIMEN FOR THE WEIGHTS.
C  PUT THEM INTO TIMWGT(I), I=1,LASTW.

	 DO I=1,LASTW
          TIMWGT(I) = REGTIM(WDAY(I),WMINS(I),LASTD,MPERTU,DDAY(1),
     1		      DMINS(1))
	 END DO


	DO 200 IDOS = 1,LASTD

C  DETERMINE THE WEIGHT AT DOSE NO. IDOS. FIRST, FIND THIS
C  DOSE TIME IN TERMS OF HOURS FROM THE BEGINNING DOSE.

         TIMREG = REGTIM(DDAY(IDOS),DMINS(IDOS),LASTD,MPERTU,
     1            DDAY(1),DMINS(1))

C  THE VALUE OF THE WEIGHT WILL CHANGE (BY INTERPOLATION) FOR ALL 
C  DOSES BETWEEN ANY TWO CONSECUTIVE WEIGHT VALUES.
  
C  FIND THE VALUE OF THE WEIGHT FOR DOSE TIME, TIMREG.
C  THERE ARE 4 CASES: 
C   1. IF THE WEIGHT HAS A TIME = TIMREG, THE ASSOCIATED WEIGHT WILL
C      OF COURSE BE THE VALUE FOR DOSWGT(IDOS);
C   2. IF THE FIRST WEIGHT TIME IS > TIMREG, SET
C      DOSWGT(IDOS) = WEIGHT(1) <-- THE 1ST WEIGHT.
C   3. IF THE LAST WEIGHT TIME IS < TIMREG, SET 
C      DOSWGT(IDOS) = WEIGHT(LASTW) <-- THE LAST WEIGHT.
C   4. IF NONE OF 1., 2., AND 3. APPLIES, FIND THE TWO WEIGHT TIMES IN
C      TIMWGT(I) WHICH SURROUND TIMREG. THEN SET
C      DOSWGT(IDOS) = INTERPOLATED VALUE BETWEEN WEIGHT(IBEF) AND 
C      WEIGHT(IBEF+1), BASED ON THE TIMES FOR THESE VALUES, AND THE TIME
C      FOR THIS DOSE, TIMREG.


C  CASE 2:	

	  IF(TIMWGT(1) .GT. TIMREG) THEN
	   DOSWGT(IDOS) = WEIGHT(1)
	   GO TO 100
	  ENDIF

C  CASE 3:

	  IF(TIMWGT(LASTW) .LT. TIMREG) THEN
	   DOSWGT(IDOS) = WEIGHT(LASTW)
	   GO TO 100
	  ENDIF

C  CASE 1:

	  DO ITIM=1,LASTW
	   IF(TIMWGT(ITIM) .EQ. TIMREG) THEN
	    DOSWGT(IDOS) = WEIGHT(ITIM)
	    GO TO 100
	   ENDIF
	  END DO

C  TO GET TO THIS POINT --> CASE 4:

	  DO ITIM=1,LASTW
	   IF(TIMWGT(ITIM) .GT. TIMREG) THEN
	    TDEL = TIMREG - TIMWGT(ITIM-1)
	    TTOT = TIMWGT(ITIM) - TIMWGT(ITIM-1)
	    DELWGT = TDEL/TTOT * (WEIGHT(ITIM) - WEIGHT(ITIM-1))
	    DOSWGT(IDOS) = WEIGHT(ITIM-1) + DELWGT
	    GO TO 100
	   ENDIF
	  END DO


  100    CONTINUE

  200	CONTINUE


	RETURN
	END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
	SUBROUTINE COMBINE(NUMEQT,LASTL,LDAY,LMINS,XLEVEL,LASTD,DDAY,
     1  DMINS,MPERTU,NOBTIM,TIMOBS,TOTLEV)

C  FOR USCTOMED.FOR, ADD A IMPLICIT REAL*8(A-H,O-Z) STATEMENT TO ALL 
C  ROUTINES.
      IMPLICIT REAL*8(A-H,O-Z)

	DIMENSION TIMOBS(11*200),TOTLEV(11*200,11),TIM(11,200),
     1  XLEVEL(11,200)
      REAL MPERTU 
	INTEGER LASTL(11),LDAY(11,200),LMINS(11,200),DDAY(200),
     1  DMINS(200)

C  SUBROUTINE COMBINE IS CALLED BY SUBROUTINE CONVRT TO COMBINE ALL 
C  TIMES AND ALL NUMEQT SETS OF OBSERVATIONS INTO ONE BIG MATRIX.
C  NOTE THAT -99 IS PUT INTO EACH LEVEL ENTRY WHICH DOESN'T HAVE AN 
C  OBSERVATION AT THE ASSOCIATED TIME.

C  INPUT ARE:

C  NUMEQT = NO. OF OUTPUT EQUATIONS.
C  LASTL(IOUT) = NO. OF OBSERVATIONS FOR OUTPUT IOUT, IOUT=1,NUMEQT.
C  LDAY(IOUT,J) = TIME (IN DAYS) FOR THE JTH OBSERVED VALUE FOR OUTPUT 
C		  IOUT; J=1,LASTL(IOUT); IOUT=1,NUMEQT.
C  LMINS(IOUT,J) = TIME (IN MINUTES) FOR THE JTH OBSERVED VALUE FOR 
C		  OUTPUT IOUT; J=1,LASTL(IOUT); IOUT=1,NUMEQT.
C  XLEVEL(IOUT,J) = JTH OBSERVED VALUE FOR OUTPUT IOUT; J=1,LASTL(IOUT);
C		   IOUT=1,NUMEQT.
C  LASTD = NO. OF DOSES.
C  DDAY(I) = DAY FOR DOSE NO. I, I=1,LASTD.
C  DMINS(I) = MINS INTO THE DAY FOR DOSE NO. I, I=1,LASTD.
C  MPERTU = MINUTES PER TIME UNIT.


C  OUTPUT ARE:

C  NOBTIM = TOTAL NO. OF UNIQUE OBSERVATION TIMES, ACROSS ALL NUMEQT
C	    OUTPUT EQUATIONS.
C  TIMOBS(ITIM) = ITIM_TH OBSERVATION TIME; ITIM=1,NOBTIM.
C  TOTLEV(ITIM,IOUT) = IOUT_TH OBSERVED VALUE FOR ITIM_TH OBSERVATION 
C		 TIME; ITIM=1,NOBTIM; IOUT=1,NUMEQT.
C   	  	 NOTE THAT TOTLEV(ITIM,IOUT) = -99 --> OUTPUT EQ. IOUT 
C		 HAD NO OBSERVATION AT TIME = TIMOBS(ITIM).


C  ESTABLISH THE NON-ORDERED LIST OF ALL OBSERVATION TIMES, ACROSS ALL
C  NUMEQT OUTPUT EQUATIONS (TIMOBS), ALONG WITH THE ABSOLUTE TIME FROM
C  THE START OF THE DOSAGE REGIMEN FOR ALL OUTPUT EQUATIONS (TIM).

	ITIM = 0

	DO IOUT = 1,NUMEQT
         DO J = 1,LASTL(IOUT)
          TIM(IOUT,J) = REGTIM(LDAY(IOUT,J),LMINS(IOUT,J),LASTD,MPERTU,
     1    DDAY(1),DMINS(1))
	  ITIM = ITIM+1
	  TIMOBS(ITIM) = TIM(IOUT,J)
	 END DO
	END DO

C  CALL SUBROUTINE ORDTIM TO ORDER (FROM SMALL TO LARGE) AND MAKE 
C  UNIQUE THE TIMES IN TIMOBS. NOTE THAT NOBTIM RETURNS AS THE NO. OF 
C  UNIQUE TIMES IN TIMOBS.

	CALL ORDTIM(ITIM,TIMOBS,NOBTIM)

C  FOR EACH OF THE NOBTIM UNIQUE OBSERVATION TIMES, ESTABLISH THE
C  ROW OF OBSERVED VALUES (INCLUDING A -99 IF AN OUTPUT EQUATION
C  DOESN'T HAVE AN OBSERVED VALUE AT THAT OBSERVATION TIME).

	DO ITIM = 1,NOBTIM

	 DO IOUT=1,NUMEQT

	  DO J=1,LASTL(IOUT)
	   IF(TIM(IOUT,J) .EQ. TIMOBS(ITIM)) THEN
	    TOTLEV(ITIM,IOUT) = XLEVEL(IOUT,J)
	    GO TO 10
	   ENDIF
	  END DO

	  TOTLEV(ITIM,IOUT) = -99.

   10	 END DO

	END DO	

	RETURN
	END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
	SUBROUTINE ORDTIM(N,TIMOBS,NOBTIM)

C  THIS ROUTINE, CALLED BY SUBROUTINE COMBINE, INPUTS TIMOBS, A VECTOR
C  OF N NON-ORDERED, NON-UNIQUE TIMES, AND RETURNS, IN THE SAME 
C  VECTOR, THE ORDERED (SMALL TO LARGE), UNIQUE VALUES. IT ALSO RETURNS
C  NOBTIM = THE NO. OF UNIQUE VALUES IN TIMOBS.

C  FOR USCTOMED.FOR, ADD A IMPLICIT REAL*8(A-H,O-Z) STATEMENT TO ALL 
C  ROUTINES.
      IMPLICIT REAL*8(A-H,O-Z)

	DIMENSION TIMOBS(11*200),TIMTEMP(11*200)


C  FIND THE LARGEST VALUE IN TIMOBS. THIS WILL BE THE LAST VALUE IN THE 
C  ORDERED TIMOBS VECTOR. SINCE ALL TIMES ARE NON-NEGATIVE, INITIALIZE
C  CURMAX = A NEGATIVE NO.

	CURMAX = -1.0

	DO I=1,N
	 IF(TIMOBS(I) .GT. CURMAX) THEN
	  CURMAX = TIMOBS(I)
	 ENDIF	
	END DO


C  FIND THE SMALLEST TIME IN TIMOBS; THEN THE NEXT SMALLEST; ETC, 
C  PLACING THE VALUES TEMPORARILY INTO TIMTEMP. INITIALIZE THE 
C  PREVIOUS MINIMUM VALUE TO BE -1. ALSO, FOR EACH NEW SEARCH, THE
C  CURRENT MINIMUM TIME MUST BE INITIALIZED TO BE A LARGE POSITIVE 
C  VALUE. 

C  NOBTIM WILL BE THE RUNNING INDEX OF THE MOST RECENT ORDERED VALUE
C  PLACED INTO TIMTEMP.

	NOBTIM = 0
	PREVMIN = -1.0

   10	CURMIN = 1.D30
	DO I=1,N
	 T = TIMOBS(I)
	 IF(T .GT. PREVMIN .AND. T .LT. CURMIN) THEN
	  CURMIN = T
	 ENDIF	
	END DO

	NOBTIM = NOBTIM+1
	TIMTEMP(NOBTIM) = CURMIN
	PREVMIN = CURMIN

C  IF CURMIN = CURMAX, THE PROCESS IS OVER; OTHERWISE CONTINUE THE
C  PROCESS.

	IF(CURMIN .LT. CURMAX) GO TO 10

	DO I=1,NOBTIM
	 TIMOBS(I) = TIMTEMP(I)
	END DO

	RETURN
	END
	

