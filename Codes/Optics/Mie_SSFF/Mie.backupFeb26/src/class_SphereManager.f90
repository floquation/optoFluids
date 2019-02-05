module class_SphereManager
    use class_Sphere, only: Sphere
    
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
        procedure         :: initSpheres
        procedure, public :: getNumSpheres, getSphere
        procedure, public :: computeScatteringAngles
    end type SphereManager
    interface SphereManager ! Constructor: http://climate-cms.unsw.wikispaces.net/Object-oriented+Fortran#Constructors
        procedure :: create
    end interface SphereManager
contains

! /************************\
! | Constructor/Destructor |
! \************************/
        
    function create(spherePos, x, refrel) result(this)
        type(SphereManager) :: this
        real*4, intent(in) :: spherePos(:,:)
        real, intent(in) :: x
        complex, intent(in) :: refrel
       
        this%x = x
        this%refrel = refrel
        call this%initSpheres(spherePos)
    end function create

    subroutine destroy(this)
        type(SphereManager) :: this
        if(associated(this%sphereList)) deallocate(this%sphereList)
    end subroutine destroy

! /************************\
! |       Subroutines      |
! \************************/
       
    subroutine computeScatteringAngles(this, psph, r_trgt, khat, SAngles)
        class(SphereManager) :: this
        class(Sphere), pointer, intent(in) :: psph          ! Pointer to the 'current' sphere in the iterator loop 
        real*8, allocatable, intent(in) :: r_trgt(:,:)      ! All positions which require the scattered electric field (xyz,numAngles)
        real*4, intent(in) :: khat(3)                       ! incident plane wave
        real*8, allocatable, intent(out) :: SAngles(:)      ! All scattering angles which require computation (numAngles)

        integer :: i, numAngles
        real*4 :: rsph(3), dr(3)
        
        numAngles = size(r_trgt,2)
        allocate(SAngles(numAngles))
        rsph = psph%getPosition() ! Position of scatterer
        do i = 1, numAngles ! For each target (and thus for each scattering angle)
                write(6,*) "+++ SphereManager: i = ", i
                write(6,*) "+++ SphereManager: rsph = ", rsph, "; r_trgt = ", r_trgt(:,i)
    ! Determine the scattering angle for each target
                !Scattering direction = r_target - r_sphere
                dr = r_trgt(:,i) - rsph
                write(6,*) "+++ SphereManager: dr = ", dr
                SAngles(i) = acos(dot_product(dr,khat)/&
                    sqrt(dot_product(dr,dr)))
                write(6,*) "+++ SphereManager: SAngles(i) = acos(<dr,khat>/<dr,dr>) = ", sAngles(i)

        end do
        
       ! Return scattering angles (SAngles) and scattering planes (Eihat_p, Eihat_l and Eshat_l) 
    end subroutine computeScatteringAngles

! Initialises all spheres based on the given input positions
    subroutine initSpheres(this, spherePos)
        class(SphereManager) :: this
        real*4, intent(in) :: spherePos(:,:)
        integer :: i, numSpheres
        numSpheres = size(spherePos,2)
        allocate(this%sphereList(numSpheres))
        do i = 1, numSpheres
            this%sphereList(i) = Sphere(this%x, this%refrel, spherePos(:,i))
        end do
    end subroutine initSpheres
    
! /************************\
! |    Getters/Setters     |
! \************************/

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
