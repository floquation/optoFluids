module foo
implicit none
private

public :: bar

contains

subroutine bar(x, y)
	
	integer, intent(in) :: x
	complex, intent(out) :: y(:)
	
	y = x + 1

	y(1) = (5, 2)

end subroutine bar

end module foo


! EOF
