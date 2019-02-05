! HAS: Camera, SphereManager, khat
! DOES: Pass khat and camera to SphereManager
! ASSUME: incident plane wave has unit amplitude
! ASSUME: Far-Field assumption between spheres

module MieAlgorithmFF
    use class_Camera, only: Camera
    use class_SphereManager, only: SphereManager
    
    implicit none
    private
    
    class(Camera), allocatable :: cam ! the camera to measure the fields
    class(SphereManager), allocatable :: sphmgr ! the spheres for scattering
    real*4 :: khat(3) ! incident plane wave
    
    public :: run
    
contains
    
    subroutine init()
        ! TODO: Load parameters from file. Now: hard-code
    ! Camera parameters
        integer :: nPixel1, nPixel2
    	real*4 :: r0(3), r1(3), r2(3)
    ! SphereManager parameters
        integer :: numSpheres = 1
        complex :: refrel
        real*4 :: refre, refim, refmed, wavel, x, rad
        ! MieAlgorithmFF parameters
        real*4 :: khat(3)
        ! Initialisation values
        nPixel1 = 100
        nPixel2 = 100
        r0  =   (/ 0, 0, 0 /)
        r1  =   (/ 1, 0, 0 /)
        r2  =   (/ 0, 1, 0 /)
        khat=   (/ 0, 0, 1 /)
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    !	REFMED = (REAL) REFRACTIVE INDEX OF SURROUNDING MEDIUM
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        refmed = 1.0
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    !	REFRACTIVE INDEX OF SPHERE = REFRE + i*REFIM
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        refre = 1.55
        refim = 0.0
        refrel = cmplx(refre,refim)/refmed
        WRITE (6,12) refmed, refre, refim
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    !	RADIUS (RAD) AND WAVELENGTH (WAVEL) SAME UNITS
    !	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        rad=0.525
        wavel=0.6328
        x=2.*3.14159265*rad*refmed/wavel
        WRITE (6,13) rad,wavel
        WRITE (6,14) x
        
    ! Create objects
        allocate(cam,sphmgr)
        call cam%create(nPixel1, nPixel2, r0, r1, r2)
        call sphmgr%create(numSpheres, x, refrel)
        khat = khat / sqrt(dot_product(khat,khat)) ! Ensure khat is a unit vector, which it is per definition.
        
    ! Format statements
12      FORMAT (5X,"REFMED = ",F8.4,3X,"REFRE = ",E14.6,3X,"REFIM = ",E14.6)
13      FORMAT (5X,"SPHERE RADIUS = ",F7.3,3X,"WAVELENGTH = ", F7.4)
14      FORMAT (5X,"SIZE PARAMETER = ",F8.3/)
    end subroutine init

    subroutine run()
        call init()
        call sphmgr%doScattering(cam,khat)
    end subroutine run
    
end module MieAlgorithmFF


program main
    use MieAlgorithmFF, only: run
    call run()
end program main
