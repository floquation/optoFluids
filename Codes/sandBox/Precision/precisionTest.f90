program precisionTest
	
	implicit none

	call testReal()

contains

subroutine testReal()

	real :: x = 6.12345678901234567890d0, x2 = 60.12345678901234567890d0
	real :: x3 = 600.12345678901234567890d0, x7 = 6.12345678901234567890d0 * 10**7
	real :: x8 = 6.12345678901234567890d0 * 10**8

	real*4 :: y = 4.12345678901234567890d0
	real*8 :: z = 8.12345678901234567890d0
	real*8 :: z270 = 6.123456789012345000067890d270

	real (kind=selected_real_kind(p=6)) :: a = 6.12345678901234567890d0
	real (kind=selected_real_kind(p=7)) :: b = 7.12345678901234567890d0
	real (kind=selected_real_kind(p=8)) :: c = 8.12345678901234567890d0

	real*8 :: u, v, w

	write (6,*) "x= ", x
	write (6,*) "eps(x)= ", epsilon(x)
	write (6,*) "x2=", x2
	write (6,*) "x3=", x3
	write (6,*) "x7=", x7
	write (6,*) "eps(x7)= ", epsilon(x7)
	write (6,*) "x8=", x8
	write (6,*) "eps(x8)= ", epsilon(x8)

	write(6,*) ""

	write (6,*) "y= ", y
	write (6,*) "z= ", z
	write (6,*) "eps(z)= ", epsilon(z)
	write (6,*) "z270=", z270
	write (6,*) "eps(z270)= ", epsilon(z270)
	write (6,*) "exponent(z270)= ", floor(dlog10((z270)))
	write (6,*) "z270 back to 10^0= ", z270 * (1d1)**(-floor(dlog10((z270))))

	write(6,*) ""

	write (6,*) "a= ", a
	write (6,*) "eps(a)= ", epsilon(a)
	write (6,*) "b= ", b
	write (6,*) "eps(b)= ", epsilon(b)
	write (6,*) "c= ", c
	write (6,*) "eps(c)= ", epsilon(c)

	write(6,*) ""
	
	u = 6.12345678901234567890d250
	v = u + 100*epsilon(u)
	w = v - u

	write (6,*) "u= ", u
	write (6,*) "v=u+100*eps(u)= ", v
	write (6,*) "w=v-u= ", w

end subroutine testReal


end program precisionTest
