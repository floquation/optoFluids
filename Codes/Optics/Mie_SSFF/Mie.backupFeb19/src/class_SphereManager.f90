module class_SphereManager
    use class_Sphere, only: Sphere
    use class_Camera, only: Camera
    
    implicit none
    private
    
    type, public :: SphereManager
        private
        type(Sphere), pointer :: sphereList(:) => null() ! List of all scatterers
        real :: x
        complex :: refrel
    contains
        private
        final :: destroy
!        procedure, public :: doScattering
        procedure         :: global2local, initSpheres
        procedure, public :: getNumSpheres, getSphere
        procedure, public :: computeScatterParams
    end type SphereManager
    interface SphereManager ! Constructor: http://climate-cms.unsw.wikispaces.net/Object-oriented+Fortran#Constructors
        procedure :: create
    end interface SphereManager
contains

! /************************\
! | Constructor/Destructor |
! \************************/
        
    function create(numSpheres, x, refrel) result(this)
        type(SphereManager) :: this
        integer, intent(in) :: numSpheres
        real, intent(in) :: x
        complex, intent(in) :: refrel
        
        this%x = x
        this%refrel = refrel
        allocate(this%sphereList(numSpheres))
        call this%initSpheres()
    end function create

    subroutine destroy(this)
        type(SphereManager) :: this
        if(associated(this%sphereList)) deallocate(this%sphereList)
    end subroutine destroy

! /************************\
! |       Subroutines      |
! \************************/
        
! Gathers the input of the Mie algorithm (x, refrel, scattering angles)
!   for the given input arguments (sphere, incident wave direction, targets)
    subroutine computeScatterParams(this, psph, r_trgt, khat, x, refrel, SAngles)
        class(SphereManager) :: this
        class(Sphere), pointer, intent(in) :: psph          ! Pointer to the 'current' sphere in the iterator loop 
        real*8, allocatable, intent(in) :: r_trgt(:,:)        ! All positions which require the scattered electric field
        real*4, intent(in) :: khat(3)                       ! incident plane wave
        real*4, intent(out) :: x                            ! size parameter
        complex, intent(out) :: refrel                      ! relative refractive index
        real*8, allocatable, intent(out) :: SAngles(:)      ! All scattering angles which require computation

        integer :: i, numAngles
        real*4 :: rsph(3), dr(3)

        numAngles = size(r_trgt,2)
        allocate(SAngles(numAngles))
        rsph = psph%getPosition() ! Position of scatterer
        do i = 1, numAngles 
                write(6,*) "+++ SphereManager: i = ", i
                write(6,*) "+++ SphereManager: rsph = ", rsph, "; r_trgt = ", r_trgt(:,i)
                ! Determine scattering angle
                !Scattering direction = r_target - r_sphere
                dr = r_trgt(:,i) - rsph
                write(6,*) "+++ SphereManager: dr = ", dr
                SAngles(i) = acos(dot_product(dr,khat)/&
                    sqrt(dot_product(dr,dr)))
                write(6,*) "+++ SphereManager: SAngles(i) = acos(<dr,khat>/<dr,dr>) = ", sAngles(i)
        end do
        x = psph%getX()
        refrel = psph%getRefrel() 
    end subroutine computeScatterParams


!! Scattering of incident PW
!!	Scatters the incident PW (in the direction khat) towards the camera.
!!	NOTE: khat must be a unit vector. The caller is trusted to take care of this.
!!		Otherwise runtime errors may occur.
!    subroutine doScattering(this, cam, khat)
!        class(SphereManager) :: this
!        class(Camera), intent(in) :: cam
!        real*4, intent(in) :: khat(3)
!        integer :: i, j1, j2, num_j1, num_j2, trgt, numAngle
!        real*4 :: rsph(3), rcurtrgt(3), dr(3)
!        real*4, allocatable :: rtrgt(:,:,:)
!        real*8, allocatable :: sAngles(:) ! The scattering angles
!        complex, allocatable :: S1(:), S2(:) ! Scattering matrices to-be-returned by each sphere
!        
!        write(6,*) "(SphereManager) Starting scattering."
!        
!        rtrgt = cam%getPixelCoords()
!        
!        ! Scatter the incident PW on all spheres and measure the electric field for each camerapixel.
!        num_j2 = size(rtrgt,3)
!        num_j1 = size(rtrgt,2)
!        numAngle = num_j1*num_j2 ! Total number of pixels (and thus scattering angles)
!        allocate(sAngles(numAngle),S1(numAngle),S2(numAngle))
!        do i = 1, size(this%sphereList) ! For each scatterer
!        ! First, determine the scattering angles
!            rsph = this%sphereList(i)%getPosition() ! Position of scatterer
!            do j2 = 1,num_j2 ! Pixels in r2 dir.
!            do j1 = 1,num_j1 ! Pixels in r1 dir.
!                trgt = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
!                ! rtrgt(:,j1,j2) now refers to the coordinate of the pixel at position (j1,j2):
!                rcurtrgt = rtrgt(:,j1,j2)
!                ! Determine scattering angle
!                !Scattering direction = r_target - r_sphere
!                dr = rcurtrgt - rsph
!                sAngles(trgt) = acos(dot_product(dr,khat)/&
!                    sqrt(dot_product(dr,dr)))
!            end do !j1
!            end do !j2
!        ! Second, compute all scattering matrices
!            call this%sphereList(i)%scatter(numAngle,sAngles,S1,S2)
!        ! Third, send the electric fields to the camera
!        !TODO:lasteditpoint
!        ! Fourth... We are done with the present sphere. Continue with the next sphere. (Single-scattering)
!        end do
!        
!    end subroutine doScattering
    
! Initialises all spheres based on an TODO: input file
    subroutine initSpheres(this)
        class(SphereManager) :: this
        integer :: i
        real*4 :: r(3) ! Position of the sphere being currently read from file
        r = (/ 1, 1, 1 /)
        do i = 1, this%getNumSpheres()
            ! Read position and make sphere TODO
            this%sphereList(i) = Sphere(this%x, this%refrel, r)
        end do
    end subroutine initSpheres
    
! /************************\
! |    Getters/Setters     |
! \************************/

! Converts a global position vector to a position vector in the sphere's coordinates
    subroutine global2local(this,psph,r_trgt,zhat,dr)
        class(SphereManager) :: this
        class(Sphere), pointer, intent(in) :: psph          ! Pointer to the requested sphere
        real*8, allocatable, intent(in) :: r_trgt(:,:)      ! All positions which require the scattered electric field
        real*4, intent(in) :: zhat(3)                       ! Z-axis for sphere (to determine scattering angle)
        real*8, allocatable, intent(out) :: SAngles(:)      ! All scattering angles which require computation
        
        integer :: i, numAngles
        real*4 :: rsph(3), dr(3)
        
        numAngles = size(r_trgt,2)
        
        SAngles(i) = acos(dot_product(dr,khat)/ sqrt(dot_product(dr,dr)))
        write(6,*) "+++ SphereManager: SAngles(i) = acos(<dr,khat>/<dr,dr>) = ", sAngles(i)
    end subroutine global2local

! Returns the number of spheres = size of 'sphereList'
    function getNumSpheres(this) result(N)
        class(SphereManager) :: this
        integer :: N
        N = size(this%sphereList) 
    end function getNumSpheres

! Returns a pointer to the sphere with index 'i' in 'sphereList'.
! If 'i' is out of bounds, a '.not. associated' pointer is returned.
    function getSphere(this,i) result (psph)
        class(SphereManager) :: this
        integer, intent(in) :: i
        class(Sphere), pointer :: psph
        nullify(psph) ! Changes status of psph to '.not. associated', instead of 'undefined'.
        if ( i >= 1 .and. i <= this%getNumSpheres() ) then
            psph => this%sphereList(i)
        end if
    end function getSphere
    
end module class_SphereManager








! EOF
