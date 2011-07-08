PROGRAM shp_write_test
USE shapelib
IMPLICIT NONE

INTEGER,PARAMETER :: lencharattr=40, nshp=4, tshp=shpt_polygonz

TYPE(shpfileobject) :: shphandle
TYPE(shpobject) :: shpobj
INTEGER :: i, j
CHARACTER(len=1024) :: filename

INTEGER :: nshpr, tshpr, nfield, nrec, nd
REAL(kind=c_double) :: minbound(4), maxbound(4)
CHARACTER(len=lencharattr) :: charattrr
INTEGER :: intattrr
REAL(kind=c_double) :: doubleattrr

!CALL getarg(1,filename)
!IF (filename == '') THEN
!  PRINT'(A)','Usage: shape_test <shp_file>'
!  STOP
!ENDIF
filename = 'testshape'

! ==================== WRITE ====================

shphandle = shpcreate(TRIM(filename), shpt_polygonz)
IF (shpfileisnull(shphandle) .OR. dbffileisnull(shphandle)) THEN
  PRINT*,'Error opening ',TRIM(filename),' for writing'
  STOP 1
ENDIF

j = dbfaddfield(shphandle, 'name', ftstring, lencharattr, 0)
IF (j /= 0) THEN
  PRINT*,'Error in dbfaddfield',0,j
  STOP 1
ENDIF
j = dbfaddfield(shphandle, 'number', ftinteger, 10, 0)
IF (j /= 1) THEN
  PRINT*,'Error in dbfaddfield',1,j
  STOP 1
ENDIF
j = dbfaddfield(shphandle, 'size', ftdouble, 30, 20)
IF (j /= 2) THEN
  PRINT*,'Error in dbfaddfield',2,j
  STOP 1
ENDIF

DO i = 0, nshp - 1
  PRINT*,'Creating shape',i
  shpobj = shpcreatesimpleobject(tshp, &
   SIZE(makesimpleshp(i, 0)), &
   makesimpleshp(i, 0), &
   makesimpleshp(i, 1), &
   makesimpleshp(i, 2))

  j = shpwriteobject(shphandle, -1, shpobj)
  IF (j /= i) THEN
    PRINT*,'Error in shpwriteobject',i,j
    STOP 1
  ENDIF
  CALL shpdestroyobject(shpobj)

  j = dbfwriteattribute(shphandle, i, 0, makechardbf(i))
  IF (j /= 1) THEN
    PRINT*,'Error in dbfwriteattribute, char',j
    STOP 1
  ENDIF
  j = dbfwriteattribute(shphandle, i, 1, makeintdbf(i))
  IF (j /= 1) THEN
    PRINT*,'Error in dbfwriteattribute, int',j
    STOP 1
  ENDIF
  j = dbfwriteattribute(shphandle, i, 2, makedoubledbf(i))
  IF (j /= 1) THEN
    PRINT*,'Warning in dbfwriteattribute, double',j
  ENDIF

ENDDO

CALL shpclose(shphandle)

! ==================== READ ====================

shphandle = shpopen(TRIM(filename), 'rb') 
IF (shpfileisnull(shphandle) .OR. dbffileisnull(shphandle)) THEN
  PRINT*,'Error opening ',TRIM(filename),' for reading'
  STOP 1
ENDIF

CALL shpgetinfo(shphandle, nshpr, tshpr, minbound, maxbound, nfield, nrec)
IF (nshpr /= nshp) THEN
  PRINT*,'Error in shpgetinfo, wrong number of shapes',nshp,nshpr
  STOP 1
ENDIF
IF (tshpr /= tshp) THEN
  PRINT*,'Error in shpgetinfo, wrong type of shapes',tshp,tshpr
  STOP 1
ENDIF

DO i = 0, nshp - 1
  PRINT*,'Checking shape',i
  shpobj = shpreadobject(shphandle, i)
  IF (shpisnull(shpobj)) THEN
    PRINT*,'Error in shpreadobject',i
    STOP 1
  ENDIF

  IF (shpobj%nvertices /= SIZE(makesimpleshp(i,0))) THEN
    PRINT*,'Error in shpreadobject, wrong number of vertices',i,&
     SIZE(makesimpleshp(i,0)),shpobj%nvertices
    STOP 1
  ENDIF

  IF (ANY(shpobj%padfx(:) /= makesimpleshp(i,0))) THEN
    PRINT*,'Error in shpreadobject, discrepancies in x',i
    PRINT*,makesimpleshp(i,0)
    PRINT*,shpobj%padfx(:)
    STOP 1
  ENDIF

  IF (ANY(shpobj%padfy(:) /= makesimpleshp(i,1))) THEN
    PRINT*,'Error in shpreadobject, discrepancies in y',i
    PRINT*,makesimpleshp(i,1)
    PRINT*,shpobj%padfy(:)
    STOP 1
  ENDIF

  IF (ANY(shpobj%padfz(:) /= makesimpleshp(i,2))) THEN
    PRINT*,'Error in shpreadobject, discrepancies in z',i
    PRINT*,makesimpleshp(i,2)
    PRINT*,shpobj%padfz(:)
    STOP 1
  ENDIF

  CALL dbfreadattribute(shphandle, i, 0, charattrr)
  IF (charattrr /= makechardbf(i)) THEN
    PRINT*,'Error in dbfreadattribute, discrepancies in char'
    PRINT*,makechardbf(i)
    PRINT*,charattrr
    STOP 1
  ENDIF

  CALL dbfreadattribute(shphandle, i, 1, intattrr)
  IF (intattrr /= makeintdbf(i)) THEN
    PRINT*,'Error in dbfreadattribute, discrepancies in int'
    PRINT*,makeintdbf(i)
    PRINT*,intattrr
    STOP 1
  ENDIF

  CALL dbfreadattribute(shphandle, i, 2, doubleattrr)
  IF (doubleattrr /= makedoubledbf(i)) THEN
    PRINT*,'Warning in dbfreadattribute, discrepancies in double'
    PRINT*,makedoubledbf(i)
    PRINT*,doubleattrr
  ENDIF

  CALL shpdestroyobject(shpobj)

ENDDO

CALL shpclose(shphandle)

CONTAINS

! Functions for generating predictable shp and dbf values
FUNCTION makesimpleshp(nshp, ncoord) RESULT(shp)
INTEGER,INTENT(in) :: nshp, ncoord
REAL(kind=c_double) :: shp(nshp+2)

INTEGER :: i

shp(:) = (/(-100.0_c_double + &
 10.0_c_double*i + 100.0_c_double*nshp + 1000.0_c_double*ncoord, &
 i=1, SIZE(shp))/)

END FUNCTION makesimpleshp

FUNCTION makechardbf(nshp) RESULT(dbf)
INTEGER,INTENT(in) :: nshp
CHARACTER(len=lencharattr) :: dbf

INTEGER :: i

DO i = 1, LEN(dbf)
  dbf(i:i) = CHAR(32 + MOD(i+2*nshp,32))
ENDDO

END FUNCTION makechardbf

FUNCTION makeintdbf(nshp) RESULT(dbf)
INTEGER,INTENT(in) :: nshp
INTEGER :: dbf

dbf = -118 + 47*nshp

END FUNCTION makeintdbf

FUNCTION makedoubledbf(nshp) RESULT(dbf)
INTEGER,INTENT(in) :: nshp
REAL(kind=c_double) :: dbf

dbf = -5.894823E+12_c_double + 8.4827943E+11*nshp

END FUNCTION makedoubledbf

END PROGRAM shp_write_test
