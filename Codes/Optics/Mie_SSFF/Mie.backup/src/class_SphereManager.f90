module class_SphereManager
    use class_Sphere, only: Sphere
    use class_Camera, only: Camera
    
    implicit none
    private
    
    type, public :: SphereManager
        private
        class(Sphere), allocatable :: sphereList(:) ! List of all scatterers
        real :: x
        complex :: refrel
    contains
        private
        procedure, public :: create, destroy
        procedure, public :: doScattering
        procedure 	  :: global2local, initSpheres
    end type SphereManager
contains
    
! Constructor/Destructor
    subroutine create(this, numSpheres, x, refrel)
        class(SphereManager) :: this
        integer, intent(in) :: numSpheres
        real, intent(in) :: x
        complex, intent(in) :: refrel
        
        this%x = x
        this%refrel = refrel
        allocate(this%sphereList(numSpheres))
        call this%initSpheres()
    end subroutine

    subroutine destroy(this)
        class(SphereManager) :: this
        deallocate(this%sphereList)
    end subroutine

! Scattering of incident PW
!	Scatters the incident PW (in the direction khat) towards the camera.
!	NOTE: khat must be a unit vector. The caller is trusted to take care of this.
!		Otherwise runtime errors may occur.
    subroutine doScattering(this, cam, khat)
        class(SphereManager) :: this
        class(Camera), intent(in) :: cam
        real*4, intent(in) :: khat(3)
        integer :: i, j1, j2, num_j1, num_j2, trgt, numAngle
        real*4 :: rsph(3), rcurtrgt(3), dr(3)
        real*4, allocatable :: rtrgt(:,:,:)
        real*8, allocatable :: sAngles(:) ! The scattering angles
        complex, allocatable :: S1(:), S2(:) ! Scattering matrices to-be-returned by each sphere
        
        write(6,*) "(SphereManager) Starting scattering."
        
        rtrgt = cam%getPixelCoords()
        
        ! Scatter the incident PW on all spheres and measure the electric field for each camerapixel.
        num_j2 = size(rtrgt,3)
        num_j1 = size(rtrgt,2)
        numAngle = num_j1*num_j2 ! Total number of pixels (and thus scattering angles)
        allocate(sAngles(numAngle),S1(numAngle),S2(numAngle))
        do i = 1, size(this%sphereList) ! For each scatterer
        ! First, determine the scattering angles
            rsph = this%sphereList(i)%getPosition() ! Position of scatterer
            do j2 = 1,num_j2 ! Pixels in r2 dir.
            do j1 = 1,num_j1 ! Pixels in r1 dir.
                trgt = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
                ! rtrgt(:,j1,j2) now refers to the coordinate of the pixel at position (j1,j2):
                rcurtrgt = rtrgt(:,j1,j2)
                ! Determine scattering angle
                !Scattering direction = r_target - r_sphere
                dr = rcurtrgt - rsph
                sAngles(trgt) = acos(dot_product(dr,khat)/&
                    sqrt(dot_product(dr,dr)))
            end do !j1
            end do !j2
        ! Second, compute all scattering matrices
            call this%sphereList(i)%scatter(numAngle,sAngles,S1,S2)
        ! Third, send the electric fields to the camera
        !TODO:lasteditpoint
        ! Fourth... We are done with the present sphere. Continue with the next sphere. (Single-scattering)
        end do
        
    end subroutine doScattering
    
! Initialises all spheres based on an TODO: input file
    subroutine initSpheres(this)
        class(SphereManager) :: this
        integer :: i
        real*4 :: r(3) ! Position of the sphere being currently read from file
        r = (/ 1, 1, 1 /)
        do i = 1, size(this%sphereList)
            ! Read position and make sphere TODO
            call this%sphereList(i)%create(this%x, this%refrel, r)
        end do
    end subroutine initSpheres
    
! Converts a global position vector to a position vector in the sphere's coordinates
    subroutine global2local(this)
        class(SphereManager) :: this
        
    end subroutine global2local
    
end module class_SphereManager
