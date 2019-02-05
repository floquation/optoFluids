module mybhmie

implicit none

private

public :: scatter

contains

subroutine scatter(X,REFREL,AMU,S1,S2)

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
  integer, parameter :: NMXX = 150000
  double precision, parameter :: PII = 4.0D0 * atan(1.0d0)  ! Obtain pi

! Arguments:
  real, intent (in) :: X
  complex, intent (in) :: REFREL
  double precision, intent (in) :: AMU(:) !cos(scattering angle)
  complex, intent (out) :: S1(:), S2(:)

! Local variables:
  integer :: NANG
  integer :: J, N, NSTOP, NMX, NN
  double precision :: CHI,CHI0,CHI1,DX,EN,FN,P,PSI,PSI0,PSI1, &
       THETA,XSTOP,YMOD                                 
  double precision :: PI(SIZE(AMU)),PI0(SIZE(AMU)),PI1(SIZE(AMU)),  &
       TAU(SIZE(AMU))                                      
  complex (kind = kind(1.0d0)) :: AN, BN, DREFRL, XI, XI1, Y 
  complex (kind = kind(1.0d0)) :: D(NMXX)
  character (len = 64) :: message

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
  do J = 1, NANG 
     PI0(J) = 0.0 
     PI1(J) = 1.0
  enddo
  NN = NANG
  do J = 1, NN 
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
!!$  XI1 = cmplx(PSI1, -CHI1, kind = kind(1.0d0)) 
  XI1 = cmplx(PSI1, -CHI1) 
  P = -1.0
  do N = 1, NSTOP 
     EN = N 
     FN = (2.0E0*EN + 1.0) / (EN*(EN + 1.0)) 
!    for given N, PSI  = psi_n        CHI  = chi_n                         
!                 PSI1 = psi_{n-1}    CHI1 = chi_{n-1}                     
!                 PSI0 = psi_{n-2}    CHI0 = chi_{n-2}                     
!    Calculate psi_n and chi_n                                             
     PSI = (2.0E0*EN - 1.0) * PSI1/DX - PSI0 
     CHI = (2.0E0*EN - 1.0) * CHI1/DX - CHI0 
!!$     XI = cmplx(PSI, -CHI, kind = kind(1.0d0))
     XI = cmplx(PSI, -CHI)

!    Compute AN and BN:                                                 
     AN = (D(N)/DREFRL + EN/DX)*PSI - PSI1 
     AN = AN/((D(N)/DREFRL + EN/DX)*XI - XI1) 
     BN = (DREFRL*D(N) + EN/DX)*PSI - PSI1 
     BN = BN/((DREFRL*D(N) + EN/DX)*XI - XI1) 

!    Now calculate scattering intensity pattern                         
!    First do angles from 0 to 90                                       
     do J = 1, NANG 
        PI(J) = PI1(J) 
        TAU(J) = EN*AMU(J)*PI(J) - (EN + 1.0)*PI0(J) 
        S1(J) = S1(J) + FN*(AN*PI(J) + BN*TAU(J)) 
        S2(J) = S2(J) + FN*(AN*TAU(J) + BN*PI(J)) 
     enddo

     PSI0 = PSI1 
     PSI1 = PSI 
     CHI0 = CHI1 
     CHI1 = CHI 
!!$     XI1 = cmplx(PSI1, -CHI1, kind = kind(1.0d0)) 
     XI1 = cmplx(PSI1, -CHI1) 

!    Compute pi_n for next value of n                                   
!    For each angle J, compute pi_n+1                                   
!    from PI = pi_n , PI0 = pi_n-1                                      
     do J = 1, NANG 
        PI1(J) = ((2.0*EN + 1.0)*AMU(J)*PI(J) - (EN + 1.0)*PI0(J))/EN 
        PI0(J) = PI(J)
     enddo

  enddo ! End sum over n

! Have summed sufficient terms.                

  return 
end subroutine scatter



end module mybhmie


!EOF
