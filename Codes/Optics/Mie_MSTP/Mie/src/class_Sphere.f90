module class_Sphere
    use DEBUG

    implicit none
    private
    
    type, public :: Sphere
        private
        
        real :: x           ! Size parameter (x:=2*pi*a/lambda)
        complex :: refrel   ! Refractive index of sphere / refr. index of medium
        real*4 :: r(3)      ! Position of origin w.r.t. global coordinates

        ! Amplitude scattering matrices:
        !  First index (j') is 'from', second index (j) is 'to', but it is in fact symmetrical.
        !  Hence only i~=j>j'~=i needs to be stored. Store it as a lower triangular matrix in a 1D form:
        !   -> http://en.wikipedia.org/wiki/Packed_storage_matrix#Code_examples_.28Fortran.29
        !  S1_2D(j',j) = S1_1D(j'+k), where k = n(j-1) - j(j-1)/2,
        !   where S1_2D is a nxn matrix and S1_1D is a n(n-1)/2 vector.
        complex, allocatable, public :: S1(:) ! size = (n(n-1)/2) = number of terms in lwr triangle - terms with j=i .or. j'=i      ! Koen : Include diagonal 
                                                                                                                                    !       (backscattering)
        complex, allocatable, public :: S2(:) ! size = (n(n-1)/2) ""
        ! Electric field coming IN to the present sphere FROM the sphere of the 2nd ArrayIndex.
        complex, allocatable, public :: eField_new(:,:) ! (cur. scat. order) size = (xyz,Nsph). index2=i is unused.
        complex, allocatable, public :: eField_old(:,:) ! (from prev. scat. order) size = (xyz,Nsph) index2=i is unused.
        complex, allocatable, public :: eField_acm(:,:) ! (accumulated) size = (xyz,Nsph) index2=i refers to inc. field (p=1 scat. order)
        ! Scientific computing code... A lot faster if these are public, although bad practice in ordinary OOP.
    contains
        private
        final :: destroy
        procedure, public :: allocateS
        procedure, public :: deallocateS
        procedure, public :: allocateE
        procedure, public :: deallocateE
        procedure, public :: nextIteration
        procedure, public :: toString
        procedure, public :: getPosition
        procedure, public :: getX
        procedure, public :: getRefrel
        procedure, public :: ProjectPosition
    end type Sphere
    interface Sphere ! Constructor: http://climate-cms.unsw.wikispaces.net/Object-oriented+Fortran#Constructors
        procedure :: create
    end interface Sphere
contains

! /************************\
! | Constructor/Destructor |
! \************************/
    
    function create(x, refrel, r) result(pthis)
        class(Sphere), pointer :: pthis
        real, intent(in) :: x
        complex, intent(in) :: refrel
        real*4, intent(in) :: r(3)
       
        allocate(pthis)
         
        pthis%x = x
        pthis%refrel = refrel
        pthis%r = r
        call debugmsg(3, "Sphere","New sphere created: " // pthis%toString())
    end function create
    
    subroutine destroy(this)
        type(Sphere) :: this
        call this%deallocateS
        call this%deallocateE
    end subroutine destroy

    subroutine allocateS(this,Nsph)
        class(Sphere) :: this
        integer, intent(in) :: Nsph ! Number of spheres incl. self
          call debugmsg(3,"Sphere","Allocating [S] with size: ", Nsph*(Nsph-1)/2)
        allocate(this%S1(Nsph*(Nsph-1)/2),this%S2(Nsph*(Nsph-1)/2))
          call debugmsg(8,"Sphere"," --> Checksum = 2*size?: ", size(this%S1)+size(this%S2))
        this%S1 = 0
        this%S2 = 0
          call debugmsg(8,"Sphere"," --> this%S1 = ", this%S1)
          call debugmsg(8,"Sphere"," --> this%S2 = ", this%S2)
    end subroutine allocateS

    subroutine deallocateS(this)
        class(Sphere) :: this
          call debugmsg(3,"Sphere","Deallocating S for " // this%toString())
        deallocate(this%S1,this%S2)
    end subroutine deallocateS

    subroutine allocateE(this,Nsph)
        class(Sphere) :: this
        integer, intent(in) :: Nsph ! Number of spheres incl. self
        allocate(this%eField_new(3,Nsph))
        allocate(this%eField_old(3,Nsph))
        allocate(this%eField_acm(3,Nsph))
        this%eField_acm(:,:) = 0
        this%eField_new(:,:) = 0
        this%eField_old(:,:) = 0
    end subroutine allocateE

    subroutine deallocateE(this)
        class(Sphere) :: this
        deallocate(this%eField_new,this%eField_old,this%eField_acm)
    end subroutine deallocateE

! Moves eField_new to eField_old and clears eField_new afterwards
!  TODO: Currently new is copied to old. That is not desirable.
    subroutine nextIteration(this)
        class(Sphere) :: this
          call debugmsg(6,"Sphere","nextIteration... " // this%toString())
          call debugmsg(8,"Sphere","this%eField_new (before) ", this%eField_new)
          call debugmsg(8,"Sphere","this%eField_old (before) ", this%eField_old)
!        deallocate(this%eField_old)
        this%eField_old = this%eField_new ! Let "old" refer to "new"'s memory location
!        deallocate(this%eField_new) ! Make "new" forget its memory location
!        allocate(this%eField_new(size(this%eField_new(:,1)),size(this%eField_new(1,:)))) ! Assign a new memory location to "new"
        this%eField_new(:,:) = 0
          call debugmsg(8,"Sphere","this%eField_new (after) ", this%eField_new)
          call debugmsg(8,"Sphere","this%eField_old (after) ", this%eField_old)
    end subroutine nextIteration


! /************************\
! |    Getters/Setters     |
! \************************/

! Projects the location of the sphere (r(3)) on the given unit vector (uvec(3)).
!  Returns the magnitude of the projection. I.e., simply: <r,uvec>.
!  The direction is, evidently, uvec.
    function ProjectPosition(this,uvec) result(proj)
        class(Sphere) :: this
        real*4, intent(in)  :: uvec(3)
        real*4 :: proj
        proj = dot_product(this%r,uvec)
    end function ProjectPosition

! Returns a clone of the position
    function getPosition(this) result(myPos) ! TODO: This is called way too frequently to copy
        class(Sphere) :: this
        real*4 :: myPos(3)
        myPos = this%r
    end function getPosition

    function getX(this) result(x)
        class(Sphere) :: this
        real*4 :: x
        x = this%x
!        call debugmsg(5,"Sphere","Calling getX. this%x = ", this%x)
    end function getX

    function getRefrel(this) result(refrel)
        class(Sphere) :: this
        complex :: refrel
        refrel = this%refrel
    end function getRefrel

!Write the position data to the files given by filehandles 'fileX' and 'fileY'
    function toString(this) result(str)
        class(Sphere) :: this
        character(len=50) :: str_x, str_refrel, str_r(size(this%r))
        character(:), allocatable :: str
        integer :: i
        
        ! num2str
        write(str_x,*) this%x
        write(str_refrel,*) this%refrel
        do i = 1, size(this%r)
            write(str_r(i),*) this%r(i)
        end do
        
        ! build the toString
        str = "Sphere(x=" // trim(adjustl(str_x)) // ",refrel=" // trim(adjustl(str_refrel)) // ",r={"
        str = trim(adjustl(str)) // trim(adjustl(str_r(1)))
        do i = 2, size(this%r)
            str = trim(adjustl(str)) // "," // trim(adjustl(str_r(i)))
        end do
        str = trim(adjustl(str)) // "})"
    end function toString

end module class_Sphere









