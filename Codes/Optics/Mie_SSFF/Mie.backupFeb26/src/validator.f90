PROGRAM CALLBH !(INPUT=TTY,OUTPUT=TTY,TAPE5=TTY)
    use mybhmie, only: MYBHMIE_scatter => scatter
    use bhmie, only: BHMIE_scatter => scatter
    use booleanFunctions, only: isApproxEqual
    IMPLICIT NONE
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	CALLBH CALCULATES THE SIZE PARAMETER (X) AND RELATIVE
!	REFRACTIVE INDEX (REFREL) FOR A GIVEN SPHERE REFRACTIVE
!	INDEX, MEDIUM REFRACTIVE INDEX, RADIUS, AND FREE SPACE
!	WAVELENGTH. IT THEN CALLS BHMIE, THE SUBROUTINE THAT COMPUTES
!	AMPLITUDE SCATTERING MATRIX ELEMENTS AND EFFICIENCIES
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    
! Type declarations
    double precision, parameter :: PII = 4.0D0 * atan(1.0d0)  ! Obtain pi
    INTEGER, PARAMETER :: NANG_half = 10
    INTEGER, PARAMETER :: NANG = NANG_half*2-1
    double precision :: S_ANGLES(NANG)
    COMPLEX :: REFREL, S1(NANG), S2(NANG), S1_org(NANG), S2_org(NANG)
    REAL :: REFMED, REFRE, REFIM, RAD, WAVEL, X, &
        QSCA, QEXT, QBACK, GSCA
    INTEGER :: NAN, AJ
    
    LOGICAL :: errorEncountered = .false.
    
    character(len=*), parameter:: frmt666 = '(//,"<< ERROR - VALIDATION FAILED >>"/)'
    
! Finish type declarations
    WRITE (6,11)
    
! Init scattering angles
    call initScatAngles(S_ANGLES)

!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	REFMED = (REAL) REFRACTIVE INDEX OF SURROUNDING MEDIUM
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    REFMED = 1.0
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	REFRACTIVE INDEX OF SPHERE = REFRE + i*REFIM
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    REFRE = 1.55
    REFIM = 0.0
    REFREL = CMPLX(REFRE,REFIM)/REFMED
    WRITE (6,12) REFMED, REFRE, REFIM
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	RADIUS (RAD) AND WAVELENGTH (WAVEL) SAME UNITS
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    RAD=0.525
    WAVEL=0.6328
    X=2.*3.14159265*RAD*REFMED/WAVEL
    WRITE (6,13) RAD,WAVEL
    WRITE (6,14) X
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	NANG = NUMBER OF ANGLES BETWEEN 0 AND 180 DEGREES
!	MATRIX ELEMENTS CALCULATED AT NANG ANGLES
!	INCLUDING 0, AND 180 DEGREES
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    WRITE (6,*) "Now running BHMIE subroutine"
    CALL MYBHMIE_scatter(X,REFREL,S_ANGLES,S1,S2)
    CALL BHMIE_scatter(X,REFREL,NANG_half,S1_org,S2_org,QEXT,QSCA,QBACK,GSCA)
    
    
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	VALIDATION
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    
    call testSMatrix(S1,S2,S_ANGLES)
    call compareResults(S1,S2,S1_org,S2_org,S_ANGLES)
    
! Print a final message at the bottom as a 'summary'
    if(errorEncountered) then
        WRITE(0,*) ""
        WRITE(0,*) "       <<                          >>      "
        WRITE(0,*) "     << ERRORS HAVE BEEN ENCOUNTERED >>    "
        WRITE(0,*) "       <<                          >>      "
        WRITE(0,*) ""
    else
        WRITE(0,*) ""
        WRITE(0,*) "       <<                          >>      "
        WRITE(0,*) "     <<     VALIDATION SUCCEEDED     >>    "
        WRITE(0,*) "       <<                          >>      "
        WRITE(0,*) ""
    end if
    
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	FORMATTING STATEMENTS:
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
11  FORMAT (/"SPHERE SCATTERING PROGRAM - validator"//)
12  FORMAT (5X,"REFMED = ",F8.4,3X,"REFRE = ",E14.6,3X,"REFIM = ",E14.6)
13  FORMAT (5X,"SPHERE RADIUS = ",F7.3,3X,"WAVELENGTH = ", F7.4)
14  FORMAT (5X,"SIZE PARAMETER = ",F8.3/)
    STOP


contains

subroutine initScatAngles (S_ANGLES)

    double precision, intent(out) :: S_ANGLES(:)

    double precision :: DANG
    integer :: J, NANG

! Finish declarations

    NANG = SIZE(S_ANGLES)
    DANG = PII / dble(NANG - 1) 
    do J = 1, NANG
        S_ANGLES(J) = dble(J-1) * DANG 
    enddo
    
end subroutine

subroutine testSMatrix (S1,S2,S_ANGLES)
!	This routine tests whether the amplitude matrices satisfy standard properties:
!	1) S12, S34 = 0 for theta \in {0,180}
!	2) S34^2 + S33^2 + S12^2 = S11^2

    complex, intent(in) :: S1(:), S2(:)
    double precision, intent(in) :: S_ANGLES(:)

    real, parameter :: r_numberOne = 1
    double precision :: scatAngle_degr
    double precision, parameter :: dp_numberOne = 1

    real :: S11NOR, S11, S12, S33, S34, S_SUM, POL

    integer :: J

    WRITE (6,17)
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!	S33 AND S34 MATRIX ELEMENTS NORMALISED BY S11
!	S11 IS NORMALIZED TO 1.0 IN THE FORWARD DIRECTION
!	POL=DEGREE OF POLARIZATION (INCIDENT UNPOLARIZED LIGHT)
!	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    S11NOR=0.5*(CABS(S2(1))**2+CABS(S1(1))**2) ! = S11(1)
    DO J=1,NANG
        AJ = J
        S11 = 0.5*CABS(S2(J))*CABS(S2(J))
        S11 = S11 + 0.5*CABS(S1(J))*CABS(S1(J))
        S12 = 0.5*CABS(S2(J))*CABS(S2(J))
        S12 = S12 - 0.5*CABS(S1(J))*CABS(S1(J))
        POL = -S12/S11
        S33 = REAL(S2(J)*CONJG(S1(J)))
        S33 = S33/S11
        S34 = AIMAG(S2(J)*CONJG(S1(J)))
        S34 = S34/S11
        S11 = S11/S11NOR
        S_SUM = S34**2+S33**2+POL**2

        WRITE (6,75)    180*S_ANGLES(J)/PII, S11, POL, S33, S34, S_SUM

        ! Test property (1): S12 = S34 = 0 in forward and backward direction
        !S12 = S12 + 1
        scatAngle_degr=180*S_ANGLES(J)/PII
        if (isApproxEqual(scatAngle_degr,0*dp_numberOne) .AND. &
            .not. isApproxEqual(S12,0*r_numberOne)) then
            write(0,frmt666)
            write(0,*) "S12 is not 0 in the forward direction"
            write(0,*) "Data (max. precision): angle = ", scatAngle_degr, "; S12 = ", S12
            write(0,*) ""
            errorEncountered = .true.
        end if
        if (isApproxEqual(scatAngle_degr,0*dp_numberOne) .AND. &
            .not. isApproxEqual(S34,0*r_numberOne)) then
            write(0,frmt666)
            write(0,*) "S34 is not 0 in the forward direction"
            write(0,*) "Data (max. precision): angle = ", scatAngle_degr, "; S34 = ", S34
            write(0,*) ""
            errorEncountered = .true.
        end if
        if (isApproxEqual(scatAngle_degr,180*dp_numberOne) .AND. &
            .not. isApproxEqual(S12,0*r_numberOne)) then
            write(0,frmt666)
            write(0,*) "S12 is not 0 in the backward direction"
            write(0,*) "Data (max. precision): angle = ", scatAngle_degr, "; S12 = ", S12
            write(0,*) ""
            errorEncountered = .true.
        end if
        if (isApproxEqual(scatAngle_degr,180*dp_numberOne) .AND. &
            .not. isApproxEqual(S34,0*r_numberOne)) then
            write(0,frmt666)
            write(0,*) "S34 is not 0 in the backward direction"
            write(0,*) "Data (max. precision): angle = ", scatAngle_degr, "; S34 = ", S34
            write(0,*) ""
            errorEncountered = .true.
        end if
        
        ! Test property (2): S_SUM = 1
        !write(6,*) KIND(S_SUM), r_eq_err, S_SUM, 1-S_SUM
        !S_SUM = S_SUM+1
        if (.not. isApproxEqual(S_SUM,r_numberOne)) then
            write(0,frmt666)
            write(0,*) "S34^2 + S33^2 + S12^2 != S11^2."
            write(0,*) "Data (max. precision): 'should be exactly 1' = ", S_SUM
            write(0,*) ""
            errorEncountered = .true.
        end if
    end do

17  FORMAT (//,2X,"ANGLE",7X,"S11",13X,"POL",12X,"S33",11X,"S34",10X,"SANITY=1"//)
75  FORMAT (1X,F6.2,2X,E13.6,2X,E13.6,2X,E13.6,2X,E13.6,2X,E13.6)

end subroutine

subroutine compareResults (myS1,myS2,bhS1,bhS2,S_ANGLES)
    
    complex, intent(in) :: myS1(:), myS2(:), bhS1(:), bhS2(:)
    double precision, intent(in) :: S_ANGLES(:)
    
    integer :: J
    character(len=10) :: frmt_E_cmplx
    character(len=256) :: frmt76

    character(len=256) :: str_myS1r, str_myS1i, str_myS2r, str_myS2i, &
                            str_bhS1r, str_bhS1i, str_bhS2r, str_bhS2i

    write(frmt_E_cmplx, '("E",I4,".",I4)') 37,30
!	write(frmt76,*) '(1X,F6.2,2X,"my = ",' // frmt_E_cmplx // '," +",' // frmt_E_cmplx // &
!		'," i",7X,' // frmt_E_cmplx // '," +",' // frmt_E_cmplx // '," i",/,9X,"bh = ",' // &
!		frmt_E_cmplx // '," +",' // frmt_E_cmplx // '," i",7X,' // frmt_E_cmplx // '," +",' // &
!		frmt_E_cmplx // '," i")'
    write(frmt76,*) '(1X,F6.2,2X,"my = ",A," +",A' // &
        '," i",7X,A," +",A," i",/,9X,"bh = ",A," +",A," i",7X,A," +",A," i")'
    
    write(6,*) frmt_E_cmplx

! Finish declarations
    
    
    WRITE (6,18)
    do J=1,NANG
        write (str_myS1r,*) real(myS1(J))
        write (str_myS1i,*) aimag(myS1(J))
        write (str_myS2r,*) real(myS2(J))
        write (str_myS2i,*) aimag(myS2(J))
        write (str_bhS1r,*) real(bhS1(J))
        write (str_bhS1i,*) aimag(bhS1(J))
        write (str_bhS2r,*) real(bhS2(J))
        write (str_bhS2i,*) aimag(bhS2(J))
        WRITE (6,frmt76) 180*S_ANGLES(J)/PII, trim(str_myS1r), trim(str_myS1i), trim(str_myS2r), &
        trim(str_myS2i), trim(str_bhS1r), trim(str_bhS1i), trim(str_bhS2r), trim(str_bhS2i)

        if (.not. isApproxEqual(myS1(J),bhS1(J))) then
            write(0,frmt666)
            write(0,*) "Amplitude matrix of the Bohren-Huffman code differs."
            write(0,*) "Data (max. precision): myS1 = ", myS1(J), "; bhS1 = ", bhS1(J), ";"
            write(0,*) ""
            errorEncountered = .true.
        end if
    end do
    
    
18  FORMAT (//,2X,"angle",18X,"S1 (RE + IM i)",30X,"S2 (RE + IM i)"//)
76  FORMAT (1X,F6.2,2X,"my = ",E17.10," +",E17.10," i",7X,E17.10," +",E17.10," i",&
/,9X,"bh = ",E36.30," +",E17.10," i",7X,E17.10," +",E17.10," i")

end subroutine compareResults

END PROGRAM CALLBH













! EOF
