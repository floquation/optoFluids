module Recur

implicit none

private

public :: calc_hankel

contains 

subroutine calc_hankel(nc, r, hn, chn)
    
    ! Subroutine calculates Bessel/Hankel functions

        real(8), intent(in) :: r
        integer, intent(in) :: nc  
        real(8), dimension(:) :: bj(nc), by(nc), cbj(nc), cby(nc)
        complex(8), dimension (:), intent(out) :: hn(nc), chn(nc)
        real(4) :: rn
        integer :: n, nst
        real(8), dimension(3) :: t
        
        ! Initialize arrays
        bj = 0; by = 0; cbj = 0; cby = 0; hn = 0; chn = 0
        
        ! First orders
        bj(1) = dsin(r)/r                           !First order of first kind Bessel
        by(1) = -dcos(r)/r                          !First order of second kind Bessel
        bj(2) = dsin(r)/(r*r) - dcos(r)/r           !Second order of first kind Bessel
        by(2) = -dcos(r)/(r*r) - dsin(r)/r          !Second order of second kind Bessel
        
        ! Warning for very high orders
        if (nc .GT. 100) then
            print *, 'Untested! Nc > 100!'
        end if
        
        if ((-0.012*nc*nc + 2.15*nc -15.6) .LT. r) then
        
            ! Calculate higher orders by upward recursion
            do n = 3, nc
                rn = real(n-2)
                by(n) = (2.0d0*rn+1.0d0)*by(n-1)/r - by(n-2)
                bj(n) = (2.0d0*rn+1.0d0)*bj(n-1)/r - bj(n-2)
            end do
        
        else
        
            print *, "Argument too small, using downward recursion"
            
            ! Set the starting order for downward recursion (needs to be high?)
            nst = nc + int((101.0+r)**0.5)
            
            ! Initialise down recursion to the cutoff order
            t(3) = 0.0
            t(2) = 1.0d-300
            
            ! Start recurring down till order nc-2
            do n = nst-1, nc-1, -1
                rn = real(n)
                t(1) = (2.0*rn+1.0)*t(2)/r - t(3)   !One order down
                t(3) = t(2)                         !Update old orders
                t(2) = t(1)                         !Update old orders
            end do
            
            ! Now recur down from order nc-2 to 0
            bj(nc) = t(3)
            bj(nc-1) = t(2)
            do n = nc-2, 1, -1
                rn = real(n)
                bj(n) = (2.0*rn+1.0)*bj(n+1)/r - bj(n+2)
            end do
            
            ! Since this only gives the ratio between Bessel functions, multiply by this constant to fix them
            bj = bj * (dsin(r)/r)/bj(1)
            
            ! Calculate higher orders of second kind by upward recursion
            do n = 3, nc
                rn = real(n-2)
                by(n) = (2.0d0*rn+1.0d0)*by(n-1)/r - by(n-2)
            end do
            
        end if
        
        ! The first kind Hankel function is simply a combination of the two Bessel functions
        hn = dcmplx(bj,by)
        
        
        !Now calculate the derivative
        
        !Manually input zeroth order derivatives
        cbj(1) = (dcos(r)-dsin(r)/r)/r
        cby(1) = (dsin(r)+dcos(r)/r)/r
        
        !Compute higher orders
        do n = 2,nc
            rn = real(n)
            cbj(n) = bj(n-1) - (n+1.0d0)*bj(n)/r
            cby(n) = by(n-1) - (n+1.0d0)*by(n)/r
        end do
        
        !Combine for the derivative of the Hankel function
        chn = dcmplx(cbj, cby)
           
    end subroutine
    
end module
