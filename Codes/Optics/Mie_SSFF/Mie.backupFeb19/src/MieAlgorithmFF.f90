! HAS: Camera, SphereManager, khat
! DOES: Pass khat and camera to SphereManager
! ASSUME: incident plane wave has unit amplitude
! ASSUME: Far-Field assumption between spheres

module MieAlgorithmFF
    use class_Camera, only: Camera
    use class_SphereManager, only: SphereManager
    use class_Sphere
    use mybhmie, only: mieAlgor => scatter
    use mymath, only: cross_product
    
    implicit none
    private
    
    type(Camera), allocatable :: cam ! the camera to measure the fields
    type(SphereManager), allocatable :: sphmgr ! the spheres for scattering
    real*4 :: khat(3) ! incident plane wave -> unit wave vector
    real*4 :: k       ! incident plane wave -> wave number [m-1]
    
    public :: run
    
contains
    
! /************************\
! |         IO             |
! \************************/
        
    subroutine init()
  ! Input parameters
        ! TODO: Load parameters from file. Now: hard-code
    ! Camera parameters
        integer :: nPixel1, nPixel2
        real*4 :: r0(3), r1(3), r2(3)
    ! SphereManager parameters
        integer :: numSpheres = 1
        complex :: refrel
        real*4 :: refre, refim, refmed, wavel, x, rad
        ! Initialisation values
        nPixel1 = 11
        nPixel2 = 11
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
        k=2.*3.14159265*refmed/wavel
        x=k*rad
        WRITE (6,13) rad,wavel
        WRITE (6,14) x
        
  ! Derived parameters / Create objects
        allocate(cam,sphmgr)
        cam = Camera(nPixel1, nPixel2, r0, r1, r2)
        sphmgr = SphereManager(numSpheres, x, refrel)
        khat = khat / sqrt(dot_product(khat,khat))

        write(6,*) "+++ (MieAlgorithmFF.init) khat = ", khat       
 
    ! Format statements
12      FORMAT (5X,"REFMED = ",F8.4,3X,"REFRE = ",E14.6,3X,"REFIM = ",E14.6)
13      FORMAT (5X,"SPHERE RADIUS = ",F7.3,3X,"WAVELENGTH = ", F7.4)
14      FORMAT (5X,"SIZE PARAMETER = ",F8.3/)
    end subroutine init

    subroutine output()
        !cam%writeOutput(fileHandle) or cam%toString() ...
    end subroutine

! /************************\
! |     Algorithm Logic    |
! \************************/
        
    subroutine scatter()
        real*8, allocatable :: SAngles(:)       ! All scattering angles which require computation; size = (numAngles = number of targets)
        real*8, allocatable :: r_trgt(:,:)      ! All positions which require the scattered electric field; size = (xyz,numAngles)
        complex, allocatable :: S1(:), S2(:)    ! The scattered amplitude matrices; size = (numAngles)
        complex, allocatable :: eField(:,:)     ! size = (xyz,numAngles)
        real*4 :: x                             ! size parameter
        complex :: refrel                       ! relative refractive index
        integer :: i, Nsph, numAngles
        class(Sphere), pointer :: psph          ! Pointer to the 'current' sphere in the iterator loop 

        r_trgt = cam%getPixelCoords()
    ! For each sphere, compute the electric field
        Nsph = sphmgr%getNumSpheres()
        do i = 1, Nsph; psph => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            ! Safety statement. Should never be needed...
            ! Skip a sphere and print a warning when it is non-existant.
            ! I.e., when sphmgr does not know the sphere belonging to index 'i'.
            if (.not. associated(psph)) then; write(6,*) "---WARNING--- MieAlgorithmFF.scatter(): 'psph' is not associated!!!"; &
                                              write(6,*) "              Skipping the pressent sphere index: ", i; cycle; end if
            write(6,*) "+++ MieAlgorithmFF.scatter(): ", psph%toString()
        ! Get the current sphere's information and the scattering angles w.r.t. the sphere
            call sphmgr%computeScatterParams(psph, r_trgt, khat, x, refrel, SAngles)
            write(6,*) "+++ MieAlgorithmFF.scatter(): x, refrel = ", x, refrel
            write(6,*) "+++ MieAlgorithmFF.scatter(): SAngles = ["
            write(6,*) SAngles
            write(6,*) "];"

        ! Obtain the amplitude scattering matrices (S) for each scattering angle for the present sphere.
        ! These need to be allocated for each sphere and deallocated right after having used them to find the E-fields.
            numAngles = size(SAngles)
            allocate(S1(numAngles),S2(numAngles))
            call mieAlgor(x, refrel, SAngles, S1, S2)
            allocate(eField(3,numAngles))
            call SMatrix2EField(S1,S2,r_trgt,eField)
            deallocate(S1,S2)
!            call cam%addEField(eField)
            deallocate(eField)
        end do; nullify(psph)
    end subroutine

! Converts the SMatrix to the EField
! It is trusted that S1, S2, r_trgt and E have the appropriate sizes, resp.: (numAngles), (numAngles), (xyz,numAngles), (xyz,numAngles)
    subroutine SMatrix2EField(S1,S2,r_trgt,eField)
        complex, intent(in) :: S1(:), S2(:)     ! The scattered amplitude matrices (array: scattering angle)
        real*8, intent(in) :: r_trgt(:,:)       ! All positions which require the scattered electric field
        complex, intent(out) :: eField(:,:)     ! size = (xyz,nPixel)
        real*8 :: z
        real*8 :: phase_term
        real*8 :: Ep_hat, El_hat
       
    ! Determine initial phase (propto distance between plane wave source and sphere)
        ! pathlength = |rsph_ortho| = rsph.dot.khat   -> given that |khat|=1
        z = dot_product(rsph,khat)
        ! If we wish to measure at a given time, the light arriving at the measurement point needs
        ! to be sampled from a different point for each scatterer (sphere).
        ! This sneaks into Mie theory in the term exp(-iwt): each scatterer has its own time, which may be converted to
        ! 'sampling at a different point', by the easy formule for a plane wave: exp(i(kz-wt)).
        ! Sampling at a different position automatically yields a different phase (but the same amplitude for a plane wave, of course).
        ! At a given time, we have a phase delay of the incident field w.r.t. some origin: E(r,t)=E(0,t)*exp(ikz).
        phase_term = exp(COMPLEX(0,1)*k*z)
        
        ! r_trgt describes the position of the target. r_sph is the position of the sphere.
        ! 
    ! Determine the scattering plane in terms of the perpendicular and parallel component of the Efield:
        Ep_hat = cross_product(khat,dr) 
    end subroutine SMatrix2EField

! /************************\
! |    Public Subroutines  |
! \************************/
        
    subroutine run()
        call init()     ! Read input parameters, declare constants, instantiate objects
        call scatter()  ! Call the scatter logic
        call output()   ! Write output fields
    end subroutine run
    
end module MieAlgorithmFF






! /************************\
! |     PRGM starter       |
! \************************/

program main
    use MieAlgorithmFF, only: run
    call run()
end program main




! EOF
