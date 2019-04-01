module mybhmie

use Recur, only: calc_hankel
implicit none

private

public :: scatter

contains

subroutine scatter(X,REFREL,AMU,S1,S2,RHO)

!***********************************************************************
! Subroutine BHMIE is the Bohren-Huffman Mie scattering subroutine 
!    to calculate scattering by a homogenous isotropic sphere.     
! Given:                                                                
!    X = 2*pi*a/lambda                                                  
!    REFREL = (complex refr. index of sphere)/(real index of medium)    
!    AMU = Array of the cos(scattering angles) to-be-computed
!                             
! Returns:                                                              
!    S1(size(AMU)) = -i*f_22 (incid. E perp. to scatt. plane,        
!                                scatt. E perp. to scatt. plane)        
!    S2(size(AMU)) = -i*f_11 (incid. E parr. to scatt. plane,        
!                                scatt. E parr. to scatt. plane)                              
!                                                                       
! Original program taken from Bohren and Huffman (1983), Appendix A     
! Modified by B.T.Draine, Princeton Univ. Obs., 90/10/26                
!    in order to compute <cos(theta)>
! Converted to Fortran 90 by Michael A. Walters, SSEC, UW-Madison
!    January 18, 2002.  Also changed modified error messages for use
!    with web program
! Modified by K. van As, TU Delft (February 2nd, 2015)
!	 in order to return only [S] to minimise computation and
!	 to take arbitrary angles as an argument to the subroutine
! Modified by K. van der Sanden, TU Delft (June 5th, 2016)
!    in order to also take distance between particles into account
!
!
! 15/02/02 (KVA): Adapted for my purposes (see above)
! 02/01/18 (MAW): Converted to Fortran 90
! 91/05/07 (BTD): Modified to allow NANG=1                              
! 91/08/15 (BTD): Corrected error (failure to initialize P)             
! 91/08/15 (BTD): Modified to enhance vectorizability.                  
! 91/08/15 (BTD): Modified to make NANG=2 if called with NANG=1         
! 91/08/15 (BTD): Changed definition of QBACK.                          
! 92/01/08 (BTD): Converted to full double precision and double complex 
!                 eliminated 2 unneed lines of code                     
!                 eliminated redundant variables (e.g. APSI,APSI0)      
!                 renamed RN -> EN = double precision N                 
!                 Note that DOUBLE COMPLEX and DCMPLX are not part      
!                 of f77 standard, so this version may not be fully     
!                 portable.  In event that portable version is          
!                 needed, use src/bhmie_f77.f                           
! 93/06/01 (BTD): Changed AMAX1 to generic function MAX                 
!***********************************************************************


! Declare parameters:
  integer(8), parameter :: NMXX = 150000
  double precision, parameter :: PII = 4.0D0 * atan(1.0d0)  ! Obtain pi

! Arguments:
  real, intent (in) :: X
  complex, intent (in) :: REFREL
  double precision, intent (in) :: AMU(:) !cos(scattering angle)
  real(8), dimension(:), intent(in) :: RHO(:)
  complex, intent (out) :: S1(:), S2(:)

! Local variables:
  integer :: NANG
  integer :: J, N, NSTOP, NMX, NN
  double precision :: CHI,CHI0,CHI1,DX,EN,P,PSI,PSI0,PSI1, &
       THETA,XSTOP,YMOD                                 
  double precision :: PI,PI0,PI1,TAU                                                ! Koen: No longer arrays (of size [SIZE(AMU)] ) since loops are switched                                      
  complex (kind = kind(1.0d0)) :: DREFRL, XI, XI1, Y
  complex (kind = kind(1.0d0)) :: D(NMXX)
  character (len = 64) :: message
  
! Added/Modified by Koen:
    complex(8), dimension(:), allocatable :: HN, DHN                                ! Done to store the spherical Hankels
    complex (kind = kind(1.0d0)), dimension(:), allocatable :: AN, BN, FN           ! Done to switch loops (J and N)

  NANG = SIZE(AMU)

! Safety checks                                                      
  if(NANG /= SIZE(S1) .OR. NANG /= SIZE(S2))                  &
    stop 'Error: AMU=cos(S_ANGLES), S1 and S2 must be of the same size'

! y = mx
  DX = X 
  DREFRL = REFREL 
  Y = X * DREFRL 
  YMOD = abs(Y)

! Series expansion terminated after NSTOP terms                      
! Logarithmic derivatives calculated from NMX on down                
  XSTOP = X + 4.0 * X**0.3333 + 2.0 
  NMX = max(XSTOP,YMOD) + 15

! BTD experiment 91/1/15: add one more term to series and compare result
!      NMX=AMAX1(XSTOP,YMOD)+16                                         
! test: compute 7001 wavelengths between .0001 and 1000 micron          
! for a=1.0micron SiC grain.  When NMX increased by 1, only a single    
! computed number changed (out of 4*7001) and it only changed by 1/8387 
! conclusion: we are indeed retaining enough terms in series!           
  NSTOP = XSTOP

  if (NMX .gt. NMXX) then
     write(0,*) 'Error: NMX > NMXX=', NMXX,' for |m|x=', YMOD
     stop
  endif
  
!  do J = 1, NANG ! Obtain cos(theta)
!     AMU(J) = cos(S_ANGLES(J))
!  enddo

!  do J = 1, NANG           !Not needed now loops are switched -- Koen
!     PI0(J) = 0.0 
!     PI1(J) = 1.0
!  enddo
  
  NN = NANG
  do J = 1, NN              ! Note Koen: This is needed because it also determines the size. If size was allocated S1 = (0.0, 0.0) would do (might speed up code?).
     S1(J) = (0.0, 0.0) 
     S2(J) = (0.0, 0.0) 
  enddo
  
312 FORMAT("J=",I3)

! Logarithmic derivative D(J) calculated by downward recurrence      
! beginning with initial value (0.,0.) at J=NMX                      
  D(NMX) = (0.0, 0.0) 
  NN = NMX - 1
  do N = 1, NN 
     EN = NMX - N + 1 
     D(NMX-N) = (EN/Y) - (1.0/(D(NMX-N+1) + EN/Y)) 
  enddo

! Riccati-Bessel functions with real argument X                      
! calculated by upward recurrence                                    
  PSI0 = cos(DX) 
  PSI1 = sin(DX) 
  CHI0 = -sin(DX) 
  CHI1 = cos(DX) 
  XI1 = dcmplx(PSI1, -CHI1) 
  P = -1.0

! Koen: Loops switched around

! Allocate the space for the arrays
allocate( AN(NSTOP),BN(NSTOP),FN(NSTOP),HN(0:NSTOP),DHN(0:NSTOP) )

! First loop over the order and store AN, BN, FN
do N = 1,NSTOP
    
    EN = N 
    FN(N) = (complex(0,1))**EN * (2.0E0*EN + 1.0) / (EN*(EN + 1.0)) 
     
!   for given N, PSI  = psi_n        CHI  = chi_n                         
!                PSI1 = psi_{n-1}    CHI1 = chi_{n-1}                     
!                PSI0 = psi_{n-2}    CHI0 = chi_{n-2}                     
!   Calculate psi_n and chi_n               
                              
    PSI = (2.0E0*EN - 1.0) * PSI1/DX - PSI0 
    CHI = (2.0E0*EN - 1.0) * CHI1/DX - CHI0 
    XI = dcmplx(PSI, -CHI)

!    Compute AN and BN:                                                 
    AN(N) = (D(N)/DREFRL + EN/DX)*PSI - PSI1 
    AN(N) = AN(N)/((D(N)/DREFRL + EN/DX)*XI - XI1) 
    BN(N) = (DREFRL*D(N) + EN/DX)*PSI - PSI1 
    BN(N) = BN(N)/((DREFRL*D(N) + EN/DX)*XI - XI1)
    
    PSI0 = PSI1 
    PSI1 = PSI 
    CHI0 = CHI1 
    CHI1 = CHI 
    XI1 = dcmplx(PSI1, -CHI1) 
    
end do

! Then start looping over every angle and corresponding distance (in other words: loop over the sources and targets).
do J = 1,NANG
    
    !Initialize PI
    PI0 = 0.0
    PI1 = 1.0    

    !Initialize spherical Hankel functions
    call calc_hankel(NSTOP+1,RHO(J),HN(0:NSTOP),DHN(0:NSTOP)) ! NSTOP+1, because orders 0-10 are 11 orders

    ! Finally evaluate the sum over this specific angle
    do N = 1,NSTOP
        EN = N
        PI = PI1
        TAU = EN*AMU(J)*PI - (EN + 1.0)*PI0
        
        S1(J) = S1(J) + FN(N)*(complex(0,1)*AN(N)*PI*(HN(N)+RHO(J)*DHN(N)) - BN(N)*TAU*RHO(J)*HN(N))/RHO(J) !Implemented Distance Dependence
        S2(J) = S2(J) + FN(N)*(complex(0,1)*AN(N)*TAU*(HN(N)+RHO(J)*DHN(N)) - BN(N)*PI*RHO(J)*HN(N))/RHO(J) !Implemented Distance Dependence
        
        ! Compute next value of PI_n
        ! For this specific angle, calculate pi_n+1
        PI1 = ((2.0*EN + 1.0)*AMU(J)*PI - (EN + 1.0)*PI0)/EN 
        PI0 = PI
    end do
    
        
end do

! Summation for every particle is complete
! Have summed sufficient terms. 

! Deallocate space
deallocate( AN,BN,FN,HN,DHN )               

  return 
end subroutine scatter   

end module mybhmie


!EOF
