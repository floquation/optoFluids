module TimingModule
    implicit none
    private
	
    logical :: isRunning = .false.
    integer:: lastTime
    integer:: elapsedTime
	
    public startTimer, stopTimer, resetTimer, printTimer
	
contains
	
    subroutine startTimer()
        isRunning = .true.
        call system_clock(count = lastTime)
    end subroutine
	
    subroutine stopTimer()
        integer clock
        call system_clock(count = clock)
        elapsedTime = elapsedTime + clock - lastTime
        isRunning = .false.
    end subroutine
	
    subroutine resetTimer()
        if(isRunning) call stopTimer()
        elapsedTime = 0
    end subroutine
	
    subroutine printTimer()
        if(isRunning) then
            call stopTimer()
            print *, "&&&&TIMER MESSAGE&&&& - Elapsed time =", elapsedTime*1d-3
            call startTimer()
        else
            print *, "&&&&TIMER MESSAGE&&&& - Elapsed time =", elapsedTime*1d-3
        end if
    end subroutine
	
end module TimingModule
