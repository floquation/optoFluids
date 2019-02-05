module class_Sphere
    use mybhmie, only: mieAlgor => scatter
    
    implicit none
    private
    
    type, public :: Sphere
        private
        
        real :: x 			! Size parameter (x:=2*pi*a/lambda)
        complex :: refrel 	! Refractive index of sphere / refr. index of medium
        real*4 :: r(3) 		! Position of origin w.r.t. global coordinates
        contains
        private
        procedure, public :: create
        procedure, public :: destroy
        procedure, public :: toString
        procedure, public :: scatter => getScatMatrix
        procedure, public :: getPosition
    end type Sphere
contains
    
    subroutine create(this, x, refrel, r)
        class(Sphere) :: this
        real, intent(in) :: x
        complex, intent(in) :: refrel
        real*4, intent(in) :: r(3)
        
        this%x = x
        this%refrel = refrel
        this%r = r
        write(6,*) "Created sphere:" // this%toString()
    end subroutine create
    
    subroutine destroy(this)
        class(Sphere) :: this
        ! Nothing to do.
    end subroutine destroy
    
    subroutine getScatMatrix(this, numAngle, sAngle, S1, S2)
        class(Sphere), intent(in) :: this
        integer, intent(in) :: numAngle
        real*8, intent(in) :: sAngle(numAngle)
        complex, intent(out) :: S1(numAngle), S2(numAngle)
        
        call mieAlgor(this%x, this%refrel, sAngle, S1, S2)
    end subroutine getScatMatrix
    
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

    function getPosition(this) result(myPos)
        class(Sphere) :: this
        real*4 :: myPos(3)
        myPos = this%r
    end function
    
end module class_Sphere









