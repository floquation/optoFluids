! HAS: Camera, SphereManager, khat
! DOES: Pass khat and camera to SphereManager
! ASSUME: incident plane wave has unit amplitude
! ASSUME: Far-Field assumption between spheres

module MieAlgorithmFF
    use DEBUG
    use class_Camera, only: Camera
    use class_SphereManager, only: SphereManager
    use class_Sphere
    use iomod
    use mymath, only: cross_product
    use mybhmie, only: mieAlgor => scatter
    
    implicit none
    private
    
    type(Camera), allocatable :: cam ! the camera to measure the fields
    type(SphereManager), allocatable :: sphmgr ! the spheres for scattering
    real*4 :: khat(3) ! incident plane wave -> unit wave vector
    real*4 :: k       ! incident plane wave -> wave number [m-1]
    real*4 :: Eihat(3)! incident electric field polarisation -> unit vector. Orthogonal to khat per definition. Linearly polarised per definition (real vector).
!   complex :: E0     ! incident field amplitude, Ei = Eihat * Re{ E0 * exp(i(kz-wt)) }

    real*4, parameter :: xhat(3) = (/ 1, 0, 0 /)
    real*4, parameter :: yhat(3) = (/ 0, 1, 0 /)
    real*4, parameter :: zhat(3) = (/ 0, 0, 1 /)
    
    public :: run
    
contains
    
! /************************\
! |         IO             |
! \************************/
        
    subroutine init(inputfile)
        character(len=*) :: inputfile
    ! Camera parameters
        integer :: nPixel1, nPixel2
        real*4 :: r0(3), r1(3), r2(3)
    ! SphereManager parameters
        real*4, allocatable :: spherePos(:,:)
        complex :: refrel
        real*4 :: refre, refim, refmed ! Re{refr. index of sphere}, Im{refr. index of sphere}, refr. index of surrounding medium
        real*4 :: wavel, x, rad ! wavelength (vacuum), size parameter, radius of sphere
    
    ! Obtain parameters from the input file
        call readParameters(inputfile, refre, refim, refmed, wavel, rad, khat, Eihat, spherePos, nPixel1, nPixel2, r0, r1, r2)
        
    ! Derived parameters / Create objects
        refrel = cmplx(refre,refim)/refmed
        k=2.*3.14159265*refmed/wavel
        x=k*rad

        call debugmsg(1,"MieAlgorithmFF","refrel = ",refrel)
        call debugmsg(1,"MieAlgorithmFF","k = ",k)
        call debugmsg(1,"MieAlgorithmFF","x = ",x)
        
        ! Check if khat is orthogonal to Eihat !TODO: Approximation equal???
        if (dot_product(khat,Eihat) /= 0) then
            write(0,*) "---ERROR--- Specified khat and Eihat are not orthogonal. Found the following inner product: ", &
                    dot_product(khat,Eihat)
            khat = khat / sqrt(dot_product(khat,khat))
            Eihat = Eihat / sqrt(dot_product(Eihat,Eihat))
            write(0,*) "            Which implies the following angle between the two vectors (degrees): ", &
                    acos(dot_product(khat,Eihat))*180/3.141592654
            call exit(0) 
        end if
        khat = khat / sqrt(dot_product(khat,khat))
        Eihat = Eihat / sqrt(dot_product(Eihat,Eihat))

        call debugmsg(1,"MieAlgorithmFF","khat = ",khat)
        call debugmsg(1,"MieAlgorithmFF","Eihat = ",Eihat)

        allocate(cam,sphmgr)
        cam = Camera(nPixel1, nPixel2, r0, r1, r2)
        sphmgr = SphereManager(spherePos, x, refrel)
    end subroutine init

    subroutine output()
        call debugmsg(1, "MieAlgorithmFF","Starting to write output to files... Calling iomod%writeOutput(cam).")
        call writeOutput(cam) !'iomod' knows where to output the files. 'cam' knows what to output.
    end subroutine

! /************************\
! |     Algorithm Logic    |
! \************************/
        
    subroutine scatter()
        real*8, allocatable :: SAngles(:)       ! All scattering angles which require computation; size = (numAngles = number of targets)
        real*8, allocatable :: r_trgt(:,:)      ! All positions which require the scattered electric field; size = (xyz,numAngles)
        complex, allocatable :: S1(:), S2(:)    ! The scattered amplitude matrices; size = (numAngles)
        complex, allocatable :: eField(:,:)     ! size = (xyz,numAngles)
        integer :: i, Nsph, numAngles
        class(Sphere), pointer :: psph          ! Pointer to the 'current' sphere in the iterator loop 
        
        
        call debugmsg(1, "MieAlgorithmFF","Starting scattering routine. Iterating over all spheres")
        r_trgt = cam%getPixelCoords()
    ! For each sphere, compute the electric field
        Nsph = sphmgr%getNumSpheres()
        do i = 1, Nsph; psph => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            ! Safety statement. Should never be needed...
            ! Skip a sphere and print a warning when it is non-existant.
            ! I.e., when sphmgr does not know the sphere belonging to index 'i'.
            if (.not. associated(psph)) then; write(6,*) "---WARNING--- MieAlgorithmFF.scatter(): 'psph' is not associated!!!"; &
                                              write(6,*) "              Skipping the pressent sphere index: ", i; cycle; end if
            call debugmsg(2, "MieAlgorithmFF","Starting scattering routine for sphere: " // psph%toString() // " - with index ", i)
        ! Get the current sphere's information and the scattering angles w.r.t. the sphere
            call debugmsg(2, "MieAlgorithmFF","Starting to compute scattering angles. Iterate over scattering angles.")
            call sphmgr%computeScatteringAngles(psph, r_trgt, khat, SAngles)
            
        ! Obtain the amplitude scattering matrices (S) for each scattering angle for the present sphere.
        ! These need to be allocated for each sphere and deallocated right after having used them to find the E-fields.
            numAngles = size(SAngles)
            allocate(S1(numAngles),S2(numAngles))
            call debugmsg(2, "MieAlgorithmFF","Calling MieAlgorithm")
            call mieAlgor(psph%getX(), psph%getRefrel(), SAngles, S1, S2)
            allocate(eField(3,numAngles))
            call debugmsg(3, "MieAlgorithmFF","S1 = ", S1)
            call debugmsg(3, "MieAlgorithmFF","S2 = ", S2)
            call debugmsg(2, "MieAlgorithmFF","Converting S-matrix to E-field")
            call SMatrix2EField(psph,S1,S2,r_trgt,eField)
            deallocate(S1,S2)
            call debugmsg(2, "MieAlgorithmFF","Registering the E-field in the camera")
            call cam%addEField(eField)
            deallocate(eField)
        end do; nullify(psph)
    end subroutine

! Converts the SMatrix to the EField
! It is trusted that S1, S2, r_trgt and E have the appropriate sizes, resp.: (numAngles), (numAngles), (xyz,numAngles), (xyz,numAngles)
    subroutine SMatrix2EField(psph, S1,S2,r_trgt,Es)
        class(Sphere), pointer :: psph          ! Pointer to the 'current' sphere in the iterator loop 
        complex, intent(in) :: S1(:), S2(:)     ! The scattered amplitude matrices (numAngles)
        real*8, intent(in) :: r_trgt(:,:)       ! All positions which require the scattered electric field
        complex, intent(out) :: Es(:,:)         ! Scattered electric field at positions {r_trgt} (xyz,nPixel)

        real*4 :: Eihat_p(3)     ! Unit vector in the direction perpendicular to the scattering plane; Eihat_l = Eihat_p x khat (xyz)
        real*4 :: Eihat_l(3)     ! Unit vector in the direction orthogonal to khat, but within the scattering plane (xyz)
        real*4 :: Eshat_l(3)     ! Unit vector in the direction orthogonal to khat_scattered, but within the scattering plane (xyz)
            ! khat x Eihat_l = Eihat_p = Eshat_p = dr x Eshat_l = Eihat_p

        complex :: Eil        ! Incident  parallel      component of electric field (numAngles)
        complex :: Eip        ! Incident  perpendicular component of electric field (numAngles)
        complex :: Esl        ! Scattered parallel      component of electric field (numAngles)
        complex :: Esp        ! Scattered perpendicular component of electric field (numAngles)

        real*8 :: z
        complex :: iniphase
        real*8 :: r
        complex :: ikr
        integer :: i, numAngles
        real*4 :: rsph(3), dr(3)

    ! Determine initial phase (propto distance between plane wave source and sphere)
        ! If we wish to measure at a given time, the light arriving at the measurement point needs
        !  to be sampled from a different point for each scatterer (sphere).
        !  This sneaks into Mie theory in the term exp(-iwt): each scatterer has its own time, which may be converted to
        !  'sampling at a different point', by the easy formule for a plane wave: exp(i(kz-wt)).
        !  Sampling at a different position automatically yields a different phase (but the same amplitude for a plane wave, of course).
        !  At a given time, we have a phase delay of the incident field w.r.t. some origin: E(r,t)=E(0,t)*exp(ikz).
        ! Now use that: pathlength = |rsph_ortho| = rsph.dot.khat   -> given that |khat|=1
        z = psph%ProjectPosition(khat)
        iniphase = exp(COMPLEX(0,1)*k*z) ! exp(i k_0 dot_product r_sph); k_0 = k khat;
        
        call debugmsg(4,"MieAlgorithmFF","z = ",z)
        call debugmsg(4,"MieAlgorithmFF","iniphase = ",iniphase)
        
    ! Compute scattered electric field for each scattering angle
        rsph = psph%getPosition() ! Position of scatterer
        numAngles = size(S1)
        call debugmsg(4,"MieAlgorithmFF","rsph = ",rsph)
        call debugmsg(4,"MieAlgorithmFF","numAngles = ",numAngles)
        do i = 1, numAngles ! For each target (and thus for each scattering angle)
            call debugmsg(4,"MieAlgorithmFF","*** next target ***", i)
        ! Prepare the current loop
            !Scattering direction = r_target - r_sphere
            dr = r_trgt(:,i) - rsph
            r = sqrt(dot_product(dr,dr))
            call debugmsg(4,"MieAlgorithmFF","dr = ", dr)
            call debugmsg(4,"MieAlgorithmFF","r = ", r)
 
        ! Determine the scattering plane in terms of the perpendicular and parallel component of the Efield:
            Eihat_p = cross_product(khat,dr)
            call debugmsg(5,"MieAlgorithmFF","Eihat_p (1st guess) = ", Eihat_p)
            if(ALL(Eihat_p == (/ 0., 0., 0. /))) then
                ! null-vector. I.e., we do not have a scattering plane, but a scattering line. Define Eihat_p arbitrarily, say // Eihat.
                Eihat_p = Eihat
                ! The present Eihat_p is already a unit vector, since Eihat is a unit vector.
                call debugmsg(5,"MieAlgorithmFF","Eihat_p was zero. (2nd guess) = ", Eihat_p)
            else
                ! Good Eihat_p! But we need to normalise it.
                Eihat_p = Eihat_p / sqrt(dot_product(Eihat_p,Eihat_p))
            end if
            Eihat_l = cross_product(Eihat_p,khat) ! CP with khat_initial
            Eshat_l = cross_product(Eihat_p,dr)   ! CP with khat_scattered
                Eshat_l = Eshat_l / sqrt(dot_product(Eshat_l,Eshat_l))
            call debugmsg(4,"MieAlgorithmFF","Eihat_p = ", Eihat_p)
            call debugmsg(4,"MieAlgorithmFF","Eihat_l = ", Eihat_l)
            call debugmsg(4,"MieAlgorithmFF","Eshat_l = ", Eshat_l)
            
        ! Determine the parallel and perpendicular component of the incident electric field
            Eil = dot_product(Eihat,Eihat_l)
            Eip = dot_product(Eihat,Eihat_p)
            
            call debugmsg(4,"MieAlgorithmFF","Eil = ", Eil)
            call debugmsg(4,"MieAlgorithmFF","Eip = ", Eip)

        ! Include the initial phase within the incident electric field
            Eil = Eil * iniphase
            Eip = Eip * iniphase

            call debugmsg(4,"MieAlgorithmFF","Eil*iniphase = ", Eil)
            call debugmsg(4,"MieAlgorithmFF","Eip*iniphase = ", Eip)
            
        ! Determine the scattered electric field (l and p component), without the r-dependent phase, but including the initial phase
            Esl = S2(i) * Eil
            Esp = S1(i) * Eip

            call debugmsg(4,"MieAlgorithmFF","Esl = ", Esl)
            call debugmsg(4,"MieAlgorithmFF","Esp = ", Esp)
            
        ! Determine the scattered electric field (in xyz components), without the r-dependent phase, but including the initial phase
            Es(:,i) = Esl*Eshat_l + Esp*Eihat_p

            call debugmsg(4,"MieAlgorithmFF","Es(:,i) = ", Es(:,i))
            
        ! Include the distance to the target (phase delay, and spherical wave amplitude drop): exp(ikr)/(-ikr)
            ! The phase delay is exp(i k dot_product (r_cam-rsph)) = exp(i (k dr_hat) dot_product dr) = exp(ikr)
            ikr = COMPLEX(0,1)*k*r
            call debugmsg(4,"MieAlgorithmFF","ikr = ", ikr)
            call debugmsg(4,"MieAlgorithmFF","exp(ikr)/(-ikr) = ", exp(ikr)/(-ikr))
            Es(:,i) = Es(:,i) * exp(ikr)/(-ikr)
            call debugmsg(4,"MieAlgorithmFF","Es(:,i) = ", Es(:,i))
        ! Done, EXCEPT for a factor exp(-iwt). But if we report on the intensity, it will drop out anyway.
        end do
    end subroutine SMatrix2EField

! /************************\
! |    Public Subroutines  |
! \************************/
        
    subroutine run(inputfile)
        character(len=*) :: inputfile
        call init(inputfile)    ! Read input parameters, declare constants, instantiate objects
        call scatter()          ! Call the scatter logic
        call output()           ! Write output fields
    end subroutine run
    
end module MieAlgorithmFF








! EOF
