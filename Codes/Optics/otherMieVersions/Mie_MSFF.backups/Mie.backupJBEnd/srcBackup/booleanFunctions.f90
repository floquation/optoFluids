module booleanFunctions
    
    implicit none
    private
    
! Data declarations
    
    double precision :: dp_example
    integer, parameter :: dp = KIND(dp_example)
    real :: sp_example
    integer, parameter :: sp = KIND(sp_example)
    
! Public statements
    
    public :: isApproxEqual
    
! Interfaces
    
    interface isApproxEqual
        module procedure isApproxEqual_doubleprecision, isApproxEqual_real, &
            isApproxEqual_dp_mach, isApproxEqual_real_mach, &
            isApproxEqual_complex_mach, isApproxEqual_complex
    end interface
    
contains
    
    
! isApproxEqual with custom precision
    
logical function isApproxEqual_doubleprecision (num1, num2, err)
    double precision, intent(in) :: num1, num2, err
    
    isApproxEqual_doubleprecision = merge(abs(num1-num2), abs(num1-num2)/num2, num2==0) .lt. err
end function isApproxEqual_doubleprecision 
    
logical function isApproxEqual_real (num1, num2, err)
    real, intent(in) :: num1, num2, err
    
    isApproxEqual_real = merge(abs(num1-num2), abs(num1-num2)/num2, num2==0) .lt. err
end function isApproxEqual_real
    
logical function isApproxEqual_complex (num1, num2, err)
    complex, intent(in) :: num1, num2
    real, intent(in) :: err
    
    isApproxEqual_complex = merge(abs(num1-num2), abs((num1-num2)/num2), abs(num2)==0) .lt. err
end function isApproxEqual_complex
    
! isApproxEqual with machine precision
    
logical function isApproxEqual_dp_mach (num1, num2)
    double precision, intent(in) :: num1, num2
    double precision :: err
     
    err = (10._dp)**(-(precision(num1)-2))
    
!	write(6,*) "dp: err = ", err, " prec(num1) = ", precision(num1), &
!		" --- Called for: ", num1, num2, " (abs(num1-num2)/num2) = ", abs(num1-num2)/num2
    
    isApproxEqual_dp_mach = merge(abs(num1-num2), abs(num1-num2)/num2, num2==0) .lt. err
end function isApproxEqual_dp_mach

logical function isApproxEqual_real_mach (num1, num2)
    real, intent(in) :: num1, num2
    real :: err
    
    err = (10._sp)**(-(precision(num1)-2))
    
!	write(6,*) "sp: err = ", err, " prec(num1) = ", precision(num1), &
!		" --- Called for: ", num1, num2, " (abs(num1-num2)/num2) = ", abs(num1-num2)/num2
    
    isApproxEqual_real_mach = merge(abs(num1-num2), abs(num1-num2)/num2, num2==0) .lt. err
end function isApproxEqual_real_mach

logical function isApproxEqual_complex_mach (num1, num2)
    complex, intent(in) :: num1, num2
    real :: err
    
    err = (10._sp)**(-(precision(num1)-2))
    
!	write(6,*) "complex: err = ", err, " prec(num1) = ", precision(num1), &
!		" --- Called for: ", num1, num2, " {abs((num1-num2)/num2)} = ", abs((num1-num2)/num2)
    
    isApproxEqual_complex_mach = merge(abs(num1-num2), abs((num1-num2)/num2), abs(num2)==0) .lt. err
end function isApproxEqual_complex_mach


end module booleanFunctions
