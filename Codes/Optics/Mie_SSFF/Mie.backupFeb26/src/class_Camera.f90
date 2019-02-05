! - Struct to hold an array of electric fields. The Camera accumulates the fields from all scatterers.
! - Compute intensities for output
! - Compute pixel locations based on:
!   -- # pixels on screen (2D)
!   -- r0 (3D); position of camera center
!   -- r1 and r2 (3D); two vectors with length of width/2 resp. height/2 indicating shape/orientation of the screen

module class_Camera
    use DEBUG

    implicit none
    private
    
    type, public :: Camera
        private
        complex, allocatable :: eField(:,:) ! size = (xyz,nPixel)
        real*4 :: r1(3), r2(3), r0(3)
        real*4, allocatable :: rp(:,:) ! Position of each individual pixel. Order: (xyz,nPixel)
        integer :: nPixel1, nPixel2
    contains
        private
        final :: destroy
        procedure         :: generatePixels
        procedure, public :: getPixelCoords
        procedure, public :: addEField
    end type Camera
    interface Camera ! Constructor: http://climate-cms.unsw.wikispaces.net/Object-oriented+Fortran#Constructors
        procedure :: create
    end interface Camera
contains
    
! /************************\
! | Constructor/Destructor |
! \************************/
    
!	r1 and r2 are two directions describing the screen. These may not be parallel.
!		Their length should be half the width/height.
!	r0 is the center position of the screen w.r.t. some origin
!	nPixel# are the number of pixels in the directions of r1 and r2.
    function create(nPixel1, nPixel2, r0, r1, r2) result(this)
        type(Camera) :: this
        integer, intent(in) :: nPixel1, nPixel2
        real*4, intent(in) :: r1(3), r2(3), r0(3)
       
        if (nPixel1 < 2 .or. nPixel2 < 2) then
            write(0,*) "nPixel1 and nPixel2 cannot be less than 2. Found resp.: ", nPixel1, nPixel2
            stop 0
        end if
 
        this%r0 = r0
        this%r1 = r1
        this%r2 = r2
        this%nPixel1 = nPixel1
        this%nPixel2 = nPixel2
        allocate(this%eField(3,nPixel1*nPixel2))
        allocate(this%rp(3,nPixel1*nPixel2)) ! Column-Major ordering: the three coordinates are accessed together efficiently
        call this%generatePixels()
    end function create
    
    subroutine destroy(this)
        type(Camera) :: this
        if(allocated(this%eField))  deallocate(this%eField)
        if(allocated(this%rp))      deallocate(this%rp)
    end subroutine destroy

!	Converts r1, r2, nPixel1 and nPixel2 into rp(3,nPixel1,nPixel2): the positions of all pixels.
    subroutine generatePixels(this)
        class(Camera) :: this
        integer :: i, j, j1, j2, num_j1, num_j2, num_i
        
        num_j2 = this%nPixel2
        num_j1 = this%nPixel1
        num_i  = size(this%rp,1)
        do j2 = 1,num_j2 ! Pixels in r2 dir.
        do j1 = 1,num_j1 ! Pixels in r1 dir.
            j = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
            do i = 1,num_i ! Coordinates (x,y,z)
                this%rp(i,j) = this%r0(i)-this%r1(i)-this%r2(i)+&
                    2*(this%r1(i)*(j1-1))/(num_j1-1)+2*(this%r2(i)*(j2-1))/(num_j2-1)
            end do
        end do
        end do
        call debugmsg(1, "Camera","r = ", this%rp)
    end subroutine

! /************************\
! |      Subroutines       |
! \************************/

    subroutine addEField(this, eField)
        class(Camera) :: this
        complex, intent(in) :: eField(:,:) ! size = (xyz,nPixel)
        
        this%eField = this%eField + eField
    end subroutine

! /************************\
! |      Getters           |
! \************************/

! 	Returns a COPY of the entire screen.
    function getPixelCoords(this) result(r)
        class(Camera) :: this
        real*4, allocatable :: r(:,:)
        r = this%rp
    end function getPixelCoords
    
end module class_Camera




!EOF
