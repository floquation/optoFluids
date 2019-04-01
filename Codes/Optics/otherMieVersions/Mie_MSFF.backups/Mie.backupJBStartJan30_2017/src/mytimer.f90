module mytimer

implicit none
public

integer (kind=4) :: t0g, t1g, t2g, rate, tmax

public :: timestamp, printElapsedTime, printGlobalElapsedTime
public :: printLocalElapsedTime, startClock, startSubClock, watchClock

contains

function timestamp ( ) result (str)

!*****************************************************************************80
!
!! TIMESTAMP prints the current YMDHMS date as a time stamp.
!
!  Example:
!
!    May 31 2001   9:45:54.872 AM
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    31 May 2001
!
!  Author:
!
!    John Burkardt
!
!  Parameters:
!
!    None
!
!  Edits:
!
!    Converted from a subroutine to a function by Kevin van As
!
  implicit none

  character( len = 250 ) :: tmpStr
  character(:), allocatable :: str

  character ( len = 8 ) ampm
  integer ( kind = 4 ) d
  character ( len = 8 ) date
  integer ( kind = 4 ) h
  integer ( kind = 4 ) m
  integer ( kind = 4 ) mm
  character ( len = 9 ), parameter, dimension(12) :: month = (/ &
    'January  ', 'February ', 'March    ', 'April    ', &
    'May      ', 'June     ', 'July     ', 'August   ', &
    'September', 'October  ', 'November ', 'December ' /)
  integer ( kind = 4 ) n
  integer ( kind = 4 ) s
  character ( len = 10 ) time
  integer ( kind = 4 ) values(8)
  integer ( kind = 4 ) y
  character ( len = 5 ) zone

  call date_and_time ( date, time, zone, values )

  y = values(1)
  m = values(2)
  d = values(3)
  h = values(5)
  n = values(6)
  s = values(7)
  mm = values(8)

  if ( h < 12 ) then
    ampm = 'AM'
  else if ( h == 12 ) then
    if ( n == 0 .and. s == 0 ) then
      ampm = 'Noon'
    else
      ampm = 'PM'
    end if
  else
    h = h - 12
    if ( h < 12 ) then
      ampm = 'PM'
    else if ( h == 12 ) then
      if ( n == 0 .and. s == 0 ) then
        ampm = 'Midnight'
      else
        ampm = 'AM'
      end if
    end if
  end if

  write ( tmpStr, '(a,1x,i2,1x,i4,2x,i2,a1,i2.2,a1,i2.2,a1,i3.3,1x,a)' ) &
    trim ( month(m) ), d, y, h, ':', n, ':', s, '.', mm, trim ( ampm )

  str = trim(tmpStr)
end function timestamp

function printElapsedTime(t1, t2, clock_rate, msg) result(str)
!*****************************************************************************80
!
!! PRINTELAPSEDTIME prints the elapsed DHMS time given dt=t2-t1 and the clock_rate
!
!  Licensing:
!
!    This code is distributed under the GNU LGPL license.
!
!  Modified:
!
!    21 May 2015
!
!  Author:
!
!    Kevin van As
!
!  Parameters:
!
!    t1,t2 : two number of ticks, where delta number of ticks = t2-t1
!    clock_rate : how many ticks / second the clocks tick at
!      --> then, dt = (t2-t1)/clock_rate
!
    character(:), allocatable, intent(in) :: msg
    character(:), allocatable :: str
    character(250) :: tmpStr, tmpStr2
    character(20) :: tmpStr3
    integer (kind=4) :: t1, t2, clock_rate
    real (kind=8) :: dt
    
    integer (kind=4) :: tday, thour, tmin, tsec, tms, tns
    real (kind=8) :: acc
    
    dt = real ( t2 - t1, kind = 8 ) / real ( clock_rate, kind = 8 ) ! Elapsed time in seconds
    acc = real(1,kind=8)/real(clock_rate,kind=8) ! Accuracy of the clock in seconds
    
!    write(6,*) "dt=", dt
!    write(6,*) "dt[ms]=", int(dt*1E3)
    
!    dt = 5*60*60*24+2*60*60+54*60+3.123456789
!    write(6,*) "pretend dt=", dt
    tns = (dt-int(dt))*1E9
    tms = (dt-int(dt))*1E3
    tsec = int(dt)
    tmin = int(tsec/60)
    thour = int(tmin/60)
    tday = int(thour/24)
    
    tns = tns-tms*1E6
!    write(6,*) "tns=", tns
!    write(6,*) "tms=", tms
    tsec = tsec-tmin*60
!    write(6,*) "tsec=", tsec
    tmin = tmin-thour*60
!    write(6,*) "tmin=", tmin
    thour = thour-tday*24
!    write(6,*) "thour=", thour
!    write(6,*) "tday=", tday
    
    write(tmpStr3,*) tday
    write(tmpStr3,*) trim((tmpStr3)), "d"
    write(tmpStr2,*) trim((tmpStr3))

    write(tmpStr3,*) thour
    write(tmpStr3,*) trim((tmpStr3)), "h"
    write(tmpStr,*) trim(tmpStr2)
    write(tmpStr2,*) trim(tmpStr), " ", trim(adjustl(tmpStr3))

    write(tmpStr3,*) tmin
    write(tmpStr3,*) trim((tmpStr3)), "m"
    write(tmpStr,*) trim(tmpStr2)
    write(tmpStr2,*) trim(tmpStr), " ", trim(adjustl(tmpStr3))

    if (acc<0.99*60) then
        write(tmpStr3,*) tsec
        write(tmpStr3,*) trim((tmpStr3)), "s"
        write(tmpStr,*) trim(tmpStr2)
        write(tmpStr2,*) trim(tmpStr), " ", trim(adjustl(tmpStr3))
    end if
    if (acc<0.99*1) then
        write(tmpStr3,*) tms
        write(tmpStr3,*) trim((tmpStr3)), "ms"
        write(tmpStr,*) trim(tmpStr2)
        write(tmpStr2,*) trim(tmpStr), " ", trim(adjustl(tmpStr3))
    end if
    if (acc<0.99*1E-3) then
        write(tmpStr3,*) tns
        write(tmpStr3,*) trim((tmpStr3)), "ns"
        write(tmpStr,*) trim(tmpStr2)
        write(tmpStr2,*) trim(tmpStr), " ", trim(adjustl(tmpStr3))
    end if
    write(tmpStr,*) trim(tmpStr2)
    write(tmpStr2,*) "<-- ", msg, " -- Elapsed Time = ", trim(adjustl(tmpStr)), " -->"
    str = trim(adjustl(tmpStr2))
end function printElapsedTime

function printGlobalElapsedTime() result(str)
    character(:), allocatable :: str
    character(:), allocatable :: msg
    msg = "global"
    call watchClock()
    str = printElapsedTime(t0g,t2g,rate,msg)
end function printGlobalElapsedTime
function printLocalElapsedTime() result(str)
    character(:), allocatable :: str
    character(:), allocatable :: msg
    msg = "local"
    call watchClock()
    str = printElapsedTime(t1g,t2g,rate,msg)
end function printLocalElapsedTime

subroutine startClock()
    call system_clock( t0g, rate, tmax )
end subroutine
subroutine startSubClock()
    call system_clock( t1g, rate, tmax )
end subroutine
subroutine watchClock()
    call system_clock( t2g, rate, tmax )
end subroutine


end module mytimer
! EOF
