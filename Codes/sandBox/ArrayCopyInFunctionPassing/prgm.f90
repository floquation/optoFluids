program prgm
	implicit none

	call doStuff()

contains

	subroutine doStuff()
		real*4, allocatable :: A(:)
		real*4, allocatable :: B(:)

		write(6,*) "initialise A"
		call init(A)
		write(6,*) "A=", A

		write(6,*) "Call B=A+1 and A=A+2 in a function."
		B = editArray(A)
		write(6,*) "A=", A ! changed
		write(6,*) "B=", B ! set for first time
		
		write(6,*) "initialise A"
		call init(A)
		write(6,*) "A=", A

		write(6,*) "Call B=A+1 and A=A+2 in a function which uses intent(in)."
		B = editArrayIntentIn(A)
		write(6,*) "A=", A ! unchanged
		write(6,*) "B=", B ! set for first time

!		Conclusions:
!		Arrays are passed by-reference. I.e., functions may change the value for the main program.
!		intent(in) is for compilation. The compiler prevents editting intent(in) variables.
	end subroutine
	
	subroutine init(A)
		real*4, allocatable, intent(out) :: A(:)
		A = (/ 1, 2, 3, 4, 5, 6, 7 /)		
	end subroutine

	function editArray(A) result(B)
		real*4 :: A(:), B(size(A))
		B = A + 1
		A = A + 2
	end function editArray

	function editArrayIntentIn(A) result(B)
		real*4, intent(in) :: A(:)
		real*4 :: B(size(A))
		B = A + 1
!		A = A + 2 ! Does not compile
	end function editArrayIntentIn


end program prgm
