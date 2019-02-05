module someModule
	implicit none
	private
	
	real*4, allocatable, target :: C(:)

	public :: getC_clone, getC, printC, initC
contains

	subroutine initC(Imax)
		integer, intent(in) :: Imax
		integer :: I
		write(6,*) "  Imax=", Imax
		if(allocated(C)) deallocate(C)
		allocate(C(Imax))
		C = (/ (I, I=1,Imax) /)
	end subroutine initC
	
	function getC_clone() result(D)
		real*4, allocatable :: D(:)
		D = C
	end function getC_clone

	function getC() result(Cptr)
		real*4, pointer :: Cptr(:)
		Cptr => C
		write(6,*) " pointer Cptr is now pointing to C"
	end function getC

	subroutine printC
		write(6,*) "C=", C
	end subroutine printC
	
end module someModule

program prgm2
	use someModule
	use TimingModule
	implicit none

! For timing reasons:
	logical, parameter :: doPrintC = .false.
	integer, parameter :: numElements = 5*10**8

! To see whether the original array is changed:
!	logical, parameter :: doPrintC = .true.
!	integer, parameter :: numElements = 10

	call doStuff()

contains

	subroutine doStuff()
		real*4, allocatable :: A(:)
		real*4, pointer :: Aptr(:)

! First test	
		write(6,*) "initialise C"
		call initC(numElements)
		if(doPrintC) call printC()

		write(6,*) "Call getC_clone and edit the result by doing +1"
		call startTimer()
		A = getC_clone()
		A = A + 1
		call printTimer()
		if(doPrintC) call printC()

! Second test
		call resetTimer()
		write(6,*) "initialise C"
		call initC(numElements)
		if(doPrintC) call printC()

		write(6,*) "Call getC and edit the result by doing +1"
		call startTimer()
		Aptr => getC()
		Aptr = Aptr+1
		call printTimer()
		if(doPrintC) call printC()


!		Conclusions:
!		One must use a pointer to get an edittable version of an array
!		For 5*10**8 elements getC_clone takes about 1.62 seconds, while getC takes about 0.57 seconds - which is including the +1 operation.
	end subroutine


end program prgm2
