

program intentOutArray
	use foo, only: bar

	implicit none
	
	integer, parameter :: nang = 11
	integer :: i, x
	complex :: y(2*nang-1)

	x = 15
	
	CALL bar(x,y)
	
	WRITE(6,13)
	do i = 1, size(y)
	WRITE(6,*) y(i)
	end do

13  FORMAT(5x,"result = ")



end program intentOutArray


! EOF
