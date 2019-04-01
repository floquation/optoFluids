module class_Sphere
    use DEBUG

    implicit none
    private
    
    type, public :: Sphere
        private
        
        real :: x           ! Size parameter (x:=2*pi*a/lambda)
        complex :: refrel   ! Refractive index of sphere / refr. index of medium
        real*4 :: r(3)      ! Position of origin w.r.t. global coordinates
    contains
        private
        final :: destroy
        procedure, public :: toString
!        procedure, public :: scatter => getScatMatrix
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
        call debugmsg(1, "Sphere","New sphere created: " // pthis%toString())
    end function create
    
    subroutine destroy(this)
        type(Sphere) :: this
        ! Nothing to do.
    end subroutine destroy

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
    function getPosition(this) result(myPos)
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
        str = "Sphere(x=" // trim(str_x) // ",refrel=" // trim(str_refrel) // ",r={"
        str = trim(str) // trim(str_r(1))
        do i = 2, size(this%r)
            str = trim(str) // "," // trim(str_r(i))
        end do
        str = trim(str) // "})"
    end function toString

end module class_Sphere









