! Module with debug switch
! Per convention, debugLevel = 0 should print no messages at all.
! debugLevel = 5 should print all messages available.
! The user of this module is expected to adhere to this convention.
module DEBUG
    
    implicit none
    public
    
    integer :: debugLevel = 0
   
    interface debugmsg
        module procedure debugmsg_, debugmsg_real4, debugmsg_real8, debugmsg_int, &
            debugmsg_cmplx, debugmsg_real4vec, debugmsg_real8vec, debugmsg_cmplxvec, &
            debugmsg_real4mat, debugmsg_real8mat, debugmsg_cmplxmat
    end interface debugmsg
    
    private :: num2str, getDebugMsgHeader
contains

    function num2str(lvl,nDigits) result(str)
        integer, intent(in) :: lvl, nDigits
        character (len=nDigits) :: str
        character (len=100) frmt
        write(frmt,*) '(I',nDigits,')'
        write(str,frmt) lvl
    end function num2str

    function getDebugMsgHeader(lvl, caller) result(str)
        character (len=*), intent(in) :: caller
        integer, intent(in) :: lvl
        character (len=200) :: str
        str = "+++ (" // trim(adjustl(num2str(lvl,3))) // ") " // caller // " +++: "
    end function getDebugMsgHeader

! Scalars
    
    subroutine debugmsg_(lvl, caller, msg)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg)
    end subroutine debugmsg_
    
    subroutine debugmsg_real4(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*4, intent(in) :: val
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_real4
    
    subroutine debugmsg_real8(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*8, intent(in) :: val
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_real8
    
    subroutine debugmsg_int(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        integer, intent(in) :: val
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_int
    
    subroutine debugmsg_cmplx(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        complex, intent(in) :: val
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_cmplx
    
! Vectors

    subroutine debugmsg_real4vec(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*4, intent(in) :: val(:)
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_real4vec

    subroutine debugmsg_real8vec(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*8, intent(in) :: val(:)
        if(lvl <= debugLevel) write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg), val
    end subroutine debugmsg_real8vec
    
    subroutine debugmsg_cmplxvec(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        complex, intent(in) :: val(:)
        character (len=100) frmt
        integer :: i, N
        if(lvl <= debugLevel) then
            write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " " // trim(msg)
            N = size(val,1)
            if( N <= 3 ) then ! Horizontally if small vector
                write(frmt,*) '(1X,',size(val,1),'(E15.8," +",E15.8," i",5X))'
                write(6,frmt) val(:)
            else ! Vertically if long vector
                write(frmt,*) '(1X,',1,'(G15.8," +",G15.8," i",5X))'
                do i = 1, N
                    write(6,frmt) val(i)
                end do
            end if
        end if
    end subroutine debugmsg_cmplxvec


! Matrices

    subroutine debugmsg_real4mat(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*4, intent(in) :: val(:,:)
        integer :: i, N
        if(lvl <= debugLevel) then
            write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " (first index horizontally) " // trim(msg)
            N = size(val,2)
            do i = 1, N
                write(6,*) val(:,i)
            end do
        end if
    end subroutine debugmsg_real4mat

    subroutine debugmsg_real8mat(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        real*8, intent(in) :: val(:,:)
        integer :: i, N
        if(lvl <= debugLevel) then
            write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " (first index horizontally) " // trim(msg)
            N = size(val,2)
            do i = 1, N
                write(6,*) val(:,i)
            end do
        end if
    end subroutine debugmsg_real8mat

    subroutine debugmsg_cmplxmat(lvl, caller, msg, val)
        character (len=*), intent(in) :: caller, msg
        integer, intent(in) :: lvl
        complex, intent(in) :: val(:,:)
        character (len=100) frmt
        integer :: i, N
        if(lvl <= debugLevel) then
            write(frmt,*) '(1X,',size(val,1),'(E15.8," +",E15.8," i",5X))'
            write(6,*) trim(getDebugMsgHeader(lvl,caller)) // " (first index horizontally) " // trim(msg)
            N = size(val,2)
            do i = 1, N
                write(6,frmt) val(:,i)
            end do
        end if
    end subroutine debugmsg_cmplxmat

    
    
end module DEBUG





!EOF
