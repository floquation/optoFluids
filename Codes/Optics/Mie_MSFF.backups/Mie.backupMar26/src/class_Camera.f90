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
        procedure, public :: addEField, getIntensity
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

        integer :: i, j, imax, jmax       

        if (nPixel1 < 1 .or. nPixel2 < 1) then
            write(0,*) "nPixel1 and nPixel2 cannot be less than 1. Found resp.: ", nPixel1, nPixel2
            stop 0
        end if
 
        this%r0 = r0
        this%r1 = r1
        this%r2 = r2
        this%nPixel1 = nPixel1
        this%nPixel2 = nPixel2
        allocate(this%eField(3,nPixel1*nPixel2))
        imax = size(this%eField,1)
        jmax = size(this%eField,2)
        do i = 1,imax
            do j = 1,jmax
                this%eField(i,j) = 0
            end do
        end do
        allocate(this%rp(3,nPixel1*nPixel2)) ! Column-Major ordering: the three coordinates are accessed together efficiently
        call this%generatePixels()
    end function create
    
    subroutine destroy(this)
        type(Camera) :: this
        if(allocated(this%eField))  deallocate(this%eField)
        if(allocated(this%rp))      deallocate(this%rp)
    end subroutine destroy

!	Converts r1, r2, nPixel1 and nPixel2 into rp(3,nPixel1*nPixel2): the positions of all pixels.
    subroutine generatePixels(this)
        class(Camera) :: this
        integer :: i, j, j1, j2, num_j1, num_j2, num_i
        
        num_j2 = this%nPixel2
        num_j1 = this%nPixel1
        num_i  = size(this%rp,1)
        if (num_j1 > 1 .and. num_j2 > 1) then
            do j2 = 1,num_j2 ! Pixels in r2 dir.
            do j1 = 1,num_j1 ! Pixels in r1 dir.
                j = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
                do i = 1,num_i ! Coordinates (x,y,z)
                    this%rp(i,j) = this%r0(i)-this%r1(i)-this%r2(i)+&
                        2*(this%r1(i)*(j1-1))/(num_j1-1)+2*(this%r2(i)*(j2-1))/(num_j2-1)
                end do
            end do
            end do
        elseif (num_j1 == 1 .and. num_j2 > 1) then
            j1 = 1
            do j2 = 1,num_j2 ! Pixels in r2 dir.
                j = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
                do i = 1,num_i ! Coordinates (x,y,z)
                    this%rp(i,j) = this%r0(i)-this%r2(i)+&
                        2*(this%r2(i)*(j2-1))/(num_j2-1)
                end do
            end do
        elseif (num_j1 > 1 .and. num_j2 == 1) then
            j2 = 1
            do j1 = 1,num_j1 ! Pixels in r1 dir.
                j = (j2-1)*num_j1 + j1 ! 1D representation of the 2D (j1,j2) index pair
                do i = 1,num_i ! Coordinates (x,y,z)
                    this%rp(i,j) = this%r0(i)-this%r1(i)+&
                        2*(this%r1(i)*(j1-1))/(num_j1-1)
                end do
            end do
        elseif (num_j1 == 1 .and. num_j2 == 1) then
            this%rp(:,1) = this%r0(:)
        end if
        call debugmsg(3, "Camera","r = ", this%rp)
    end subroutine

! /************************\
! |      Subroutines       |
! \************************/

    subroutine addEField(this, eField)
        class(Camera) :: this
        complex, intent(in) :: eField(:,:) ! size = (xyz,nPixel)
        
        call debugmsg(4,"Camera","eField_in   size1 = ", size(eField,1))
        call debugmsg(4,"Camera","eField_in   size2 = ", size(eField,2))
        call debugmsg(4,"Camera","eField_this size1 = ", size(this%eField,1))
        call debugmsg(4,"Camera","eField_this size2 = ", size(this%eField,2))

        if( size(eField,1) /= size(this%eField,1) .or. &
            size(eField,2) /= size(this%eField,2) ) then
            write(6,*) "---ERROR--- Array sizes of the electric fields do not match. Should be: ", &
                        size(this%eField,1), size(this%eField,2), ", but received: ", &
                        size(eField,1), size(eField,2), "!"
            call exit(0) 
        end if
        
        call debugmsg(4,"Camera","eField_before = ", this%eField)
        this%eField = this%eField + eField
        call debugmsg(4,"Camera","eField_after = ", this%eField)
    end subroutine addEField

! /************************\
! |      Getters           |
! \************************/

! 	Returns a COPY of the entire screen.
    function getPixelCoords(this) result(r)
        class(Camera) :: this
        real*4, allocatable :: r(:,:)
        r = this%rp
    end function getPixelCoords

! Compute the intensity as |E|^2. The scaling factor would be dependent on the camera properties...
!  Note that the factor exp(-iwt) was not included in the electric fields.
!  If we use this equation to compute the intensity, this factor will drop out anyway -> I /= I(t)
    function getIntensity(this) result(intensity)
        class(Camera) :: this
        real*4 :: intensity(size(this%eField,2)) ! Size = nPixels
        integer :: pixel, nPixels
        
        nPixels = size(this%eField,2)
        do pixel = 1, nPixels
            call debugmsg(5,"Camera","eField(xyz,pixel) = ", this%eField(:,pixel))
            intensity(pixel) = dot_product(this%eField(:,pixel),this%eField(:,pixel)) ! I propto |E|^2
            call debugmsg(5,"Camera","intensity(pixel) = ", intensity(pixel))
        end do
        call debugmsg(2,"Camera","intensity = ", intensity)
    end function getIntensity
    
end module class_Camera




!EOF
