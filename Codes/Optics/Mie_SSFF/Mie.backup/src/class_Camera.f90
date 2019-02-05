! - Struct to hold an array of electric fields. The Camera accumulates the fields from all scatterers.
! - Compute intensities for output
! - Compute pixel locations based on:
!   -- # pixels on screen (2D)
!   -- r0 (3D); position of camera center
!   -- r1 and r2 (3D); two vectors with length of width/2 resp. height/2 indicating shape/orientation of the screen

module class_Camera
    implicit none
    private
    
    type, public :: Camera
        private
        double precision, allocatable :: eField(:,:) ! size = (nPixel in dir. of r1, nPixel in dir. of r2)
        real*4 :: r1(3), r2(3), r0(3)
        real*4, allocatable :: rp(:,:,:) ! Position of each individual pixel. Order: (xyz, pixelID1, pixelID2)
    contains
        private
        procedure, public :: create
        procedure, public :: destroy
        procedure	  :: generatePixels
        procedure, public :: getPixelCoords
    end type Camera
contains
    
! /************************\
! | Constructor/Destructor |
! \************************/
    
!	r1 and r2 are two directions describing the screen. These may not be parallel.
!		Their length should be half the width/height.
!	r0 is the center position of the screen w.r.t. some origin
!	nPixel# are the number of pixels in the directions of r1 and r2.
    subroutine create(this, nPixel1, nPixel2, r0, r1, r2)
        class(Camera) :: this
        integer, intent(in) :: nPixel1, nPixel2
        real*4, intent(in) :: r1(3), r2(3), r0(3)
        
        this%r0 = r0
        this%r1 = r1
        this%r2 = r2
        allocate(this%eField(nPixel1,nPixel2))
        allocate(this%rp(3,nPixel1,nPixel2)) ! Column-Major ordering: the three coordinates are accessed together efficiently
        call this%generatePixels()
    end subroutine
    
    subroutine destroy(this)
        class(Camera) :: this
        deallocate(this%eField)
        deallocate(this%rp)
    end subroutine

!	Converts r1, r2, nPixel1 and nPixel2 into rp(3,nPixel1,nPixel2): the positions of all pixels.
    subroutine generatePixels(this)
        class(Camera) :: this
        integer :: i, j1, j2, num_j1, num_j2, num_i
        
        num_j2 = size(this%rp,3)
        num_j1 = size(this%rp,2)
        num_i  = size(this%rp,1)
        do j2 = 1,num_j2 ! Pixels in r2 dir.
        do j1 = 1,num_j1 ! Pixels in r1 dir.
            do i = 1,num_i ! Coordinates (x,y,z)
                this%rp(i,j1,j2) = this%r0(i)-this%r1(i)-this%r2(i)+&
                (this%r1(i)*j1)/num_j1+(this%r2(i)*j2)/num_j2
            end do
        end do
        end do
    end subroutine

! /************************\
! |      Getters           |
! \************************/

! 	Returns a COPY of the entire screen.
    function getPixelCoords(this) result(r)
        class(Camera) :: this
        real*4, allocatable :: r(:,:,:)
        r = this%rp
    end function getPixelCoords
    
end module class_Camera




!EOF
