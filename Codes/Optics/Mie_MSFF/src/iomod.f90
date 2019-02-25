! Kevin van As
!  Module which contains the I/O subroutines for the MieAlgorithm.
! Jorne Boterman:
!  For the configurability of scattering strategies I'm going to have to break the localized-to-one-module-IO design.
!  Perhaps this can be changed to used a general set of IO methods the strategies can use as needed... later.
! Kevin van As
!  - Now reads all strings while using an allocatable and a common buffer
! 
module iomod
    use DEBUG
    use mytimer
    use class_Camera, only: Camera
    
    implicit none
    private

    character (len=:), allocatable :: pixelCoordsOutFile
    character (len=:), allocatable :: intensityOutFile
    
    public :: readParameters, readPositions
    public :: writeCoords, writeOutput

    public :: skipcomments, removecomment
    
contains
    
    subroutine readParameters(inputfile, refre, refim, refmed, wavel, rad, khat, Eihat, spherePos, &
                                cam, conv_minp, conv_maxp, dop0, strategyKeyword)
        character(len=*), intent(in) :: inputfile
        logical inputfileExists

    ! Helpers
        character(len=250) :: line
        character(len=250) :: stringBuffer

    ! Directions
        real*4, intent(out) :: khat(3) ! incident plane wave -> unit wave vector
        real*4, intent(out) :: Eihat(3)! incident electric field polarisation -> unit vector. Orthogonal to khat per definition. Linearly polarised per definition (real vector).
    ! Camera parameters
        type(Camera), allocatable, intent(out) :: cam ! the camera to measure the fields
        integer :: nPixel1, nPixel2
        real*4 :: r0(3), r1(3), r2(3)
        logical :: onlyWriteCoords ! If true, only writes the pixel coordinates, and then terminates the program.
    ! SphereManager parameters
        character(len=:), allocatable :: prtcPosFile
        real*4, allocatable, intent(out) :: spherePos(:,:)
        real*4, intent(out) :: refre, refim, refmed, wavel, rad
    ! Multiscattering
        integer, intent(out) :: conv_minp, conv_maxp   ! Limits of the scattering order (used for convergence)
        logical :: dop0 ! "do p_0", include the p=0 term in the final result
    ! Scattering strategy parameter
        character(len=:), allocatable, intent(out) :: strategyKeyword
 
        inquire(file=inputfile,exist=inputfileExists)
        if(.not. inputfileExists) then
            write(0,*) "---ERROR--- Specified inputfile does not exist: ", inputfile
            call exit(0) 
        end if
        open(unit=10, file=inputfile, form="FORMATTED", status="OLD", action="READ")

!        prtcPosFile = "\!test \! Not a comment     !But this is a comment" ! Test the removecomment function
!        call removecomment(prtcPosFile,'!','\')
!        print *, prtcPosFile

    ! Read DEBUG parameter
        call skipcomments (10, line,'!') 
        read(line, fmt=*) debugLevel

        ! Print these lines right after debugLevel is read, as we need its value...
        call debugmsg(2, "IO","************************************************************")
        call debugmsg(1, "IO","Starting to load from inputfile: '" // trim(adjustl(inputfile)) // "'")
        call debugmsg(2, "IO","************************************************************")
        call debugmsg(3, "IO","File opened, starting reading: " // inputfile)

        call debugmsg(2, "IO","DebugLevel = ", debugLevel)

    ! Constants 
        call skipcomments (10, line,'!') 
        read(line, fmt=*) refre
        call debugmsg(2, "IO","refre = ", refre)
        call skipcomments (10, line,'!')
        read(line, fmt=*) refim
        call debugmsg(2, "IO","refim = ", refim)
        call skipcomments (10, line,'!')
        read(line, fmt=*) refmed
        call debugmsg(2, "IO","refmed = ", refmed)
        
        call skipcomments (10, line,'!')
        read(line, fmt=*) wavel
        call debugmsg(2, "IO","wavel = ", wavel)
        call skipcomments (10, line,'!')
        read(line, fmt=*) rad
        call debugmsg(2, "IO","rad = ", rad)

        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) khat
        call debugmsg(2, "IO","khat = ", khat)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) Eihat
        call debugmsg(2, "IO","Eihat = ", Eihat)

    ! Sphere positions
        call skipcomments (10, line,'!')
        read(line, fmt='(A)') stringBuffer
        call removecomment(stringBuffer,'!','\')
        allocate(prtcPosFile, source = trim(stringBuffer))
        call debugmsg(2, "IO","prtcPosFile = " // prtcPosFile)

    ! Camera
        call skipcomments (10, line,'!')  
        read(line, fmt=*) nPixel1
        call debugmsg(2, "IO","nPixel1 = ", nPixel1)
        call skipcomments (10, line,'!')
        read(line, fmt=*) nPixel2
        call debugmsg(2, "IO","nPixel2 = ", nPixel2)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r0
        call debugmsg(2, "IO","r0 = ", r0)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r1
        call debugmsg(2, "IO","r1 = ", r1)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r2
        call debugmsg(2, "IO","r2 = ", r2)

        allocate(cam)
        cam = Camera(nPixel1, nPixel2, r0, r1, r2)

    ! Convergence 
        call skipcomments (10, line,'!') 
        read(line, fmt=*) conv_minp
        call debugmsg(2, "IO","convergence min_p = ", conv_minp)
        call skipcomments (10, line,'!') 
        read(line, fmt=*) conv_maxp
        call debugmsg(2, "IO","convergence max_p = ", conv_maxp)

    ! Output
        call skipcomments (10, line,'!') 
        read(line, fmt=*) dop0
        call debugmsg(2, "IO","Include p=0 term = ", dop0)
        call skipcomments (10, line,'!')
        read(line, fmt='(A)') stringBuffer 
        call removecomment(stringBuffer,'!','\')
        allocate(pixelCoordsOutFile, source = trim(stringBuffer))
        call debugmsg(2, "IO","pixelCoordsOutFile = " // pixelCoordsOutFile)
        call skipcomments (10, line,'!')
        read(line, fmt='(A)') stringBuffer
        call removecomment(stringBuffer,'!','\')
        allocate(intensityOutFile, source = trim(stringBuffer))
        call debugmsg(2, "IO","intensityOutFile = " // intensityOutFile)

        call skipcomments (10, line,'!')
        read(line, fmt=*) onlyWriteCoords
        call debugmsg(2, "IO","Only write pixel coords = ", onlyWriteCoords)

    ! Scatter Strategy
        call skipcomments(10, line,'!')
        read(line, fmt='(A)') stringBuffer
        call removecomment(stringBuffer,'!','\')
        allocate(strategyKeyword, source = trim(stringBuffer))
        call debugmsg(2, "IO","strategyKeyword = " // strategyKeyword)

    ! Done reading

        close(unit=10)
        call debugmsg(3, "IO","Finished reading. File closed: " // inputfile)

        if(onlyWriteCoords) then
            call writeCoords(cam)
            call debugmsg(2, "IO","************************************************************")
            call debugmsg(1, "IO","Operating in 'only write pixel coordinates'-mode. Writing to: '" &
                // trim(pixelCoordsOutFile) // "'")
            call debugmsg(2, "IO","************************************************************")
            write(6,*) printGlobalElapsedTime()
            call debugmsg(0, "IO", timestamp())
            call exit(0)
        endif

    ! Read sphere positions
        call readPositions(prtcPosFile, spherePos)

    end subroutine readParameters
    
    subroutine readPositions(filename,r)
        character (len=*), intent(in) :: filename
        real*4, allocatable, intent(out) :: r(:,:)
        integer :: i, numPos
        character (len=250) :: line
       
        logical inputfileExists     
 
        inquire(file=filename,exist=inputfileExists)
        if(.not. inputfileExists) then
            write(0,*) "---ERROR--- Specified ParticlePosition file does not exist: ", trim(filename)
            call exit(0) 
        end if
        open(unit=10, file=filename, form="FORMATTED", status="OLD", action="READ")
        call debugmsg(3, "IO","File opened, starting reading: " // filename)

    ! Number of positions
        call skipcomments (10, line,'!')
        read(line, fmt=*) numPos
      
        allocate(r(3,numPos))
 
        ! Read opening bracket of the matrix, but don't store it 
        call skipcomments (10, line,'!')
        read(line, fmt=*)
    ! Read all (numPos) positions
        do i = 1, numPos
            call skipcomments (10, line,'!')
            line = obtainVector(line) 
            read(line, fmt=*) r(:,i)
        end do
        call debugmsg(4, "IO","r = ", r)
        
        ! Remainder of file is not interesting, so ignore it.
        close(unit=10)
        call debugmsg(3, "IO","Finished reading. File closed: " // filename)
    end subroutine readPositions

! Obtain the vector-part of a string. I.e., everything between "(" and ")".
    function obtainVector(line) result(str)
        character (len=*), intent(in) :: line
        character(:), allocatable :: str
        integer :: bracketOpen, bracketClose
        
        bracketOpen = index(line,"(")
        bracketClose = index(line,")")
        str = line( (bracketOpen+1) : (bracketClose-1) )
    end function obtainVector 

! Reads the next non-comment non-empty line.
! ref: http://www.tek-tips.com/viewthread.cfm?qid=1465029 
    subroutine skipcomments (chan, line, commentchar)
        integer, intent(in) :: chan
        character (len=*), intent(inout) :: line
        character (len=*), intent(in) :: commentchar

    10  continue
        read (chan, '(A)') line
!        write(6,*) "+++ IO: line = ", line
        if (line(1:1) .eq. commentchar) goto 10
        if (len(trim(line)) == 0) goto 10
        return
    end subroutine skipcomments
    
    subroutine removecomment (line, commentchar, escapechar)
        character (len=*), intent(inout) :: line
        character (len=*), intent(in) :: commentchar
        character (len=*), intent(in) :: escapechar
        integer i        
        
        if (line(1:1) .eq. commentchar) then
            line = ""
            return
        end if
        do i=2,len(trim(line))
            if (line(i:i) .eq. commentchar .and. line(i-1:i-1) .ne. escapechar) then
                line = trim(line(1:i-1))
                return
            end if
        end do
    end subroutine removecomment
    
    subroutine writeCoords(cam)
        type(Camera), intent(in)     :: cam
        real*4, allocatable :: coords(:,:)
        character (len=100) frmt
        integer i,N

        ! Write pixel coordinates
        if (pixelCoordsOutFile .ne. "DONOTWRITE") then
            call debugmsg(3, "IO","Obtaining pixel coordinates, and writing to file '" // trim(pixelCoordsOutFile) // "'")
            coords = cam%getPixelcoords() ! (xyz,pixel)
            write(frmt,*) '(1X,',size(coords,1),'(E15.8,1X))'
            N = size(coords,2)
            i = index(pixelCoordsOutFile,'/',back=.true.)
            if (trim(adjustl(pixelCoordsOutFile(1:i))) .ne. "") then ! Make containing directory if there is one
                call system('mkdir -p ' // trim(pixelCoordsOutFile(1:i)))
            end if
            open(unit=11, file=pixelCoordsOutFile, form="FORMATTED", status="REPLACE", action="WRITE")
            do i=1,N
                write(unit=11,fmt=*) coords(:,i)
            end do
            close(unit=11)
            deallocate(coords)
        end if
    end subroutine writeCoords

    subroutine writeOutput(cam)
        type(Camera), intent(in)     :: cam
        real*4, allocatable :: intensity(:)
        character (len=100) frmt
        integer i,N

        ! Write intensity
        if (intensityOutFile .ne. "DONOTWRITE") then
            call debugmsg(3, "IO","Obtaining intensity, and writing to file '" // trim(intensityOutFile) // "'")
            intensity = cam%getIntensity() ! (pixel)
            write(frmt,*) '(1X,E15.8)'
            N = size(intensity,1)
            i = index(intensityOutFile,'/',back=.true.)
            if (trim(adjustl(intensityOutFile(1:i))) .ne. "") then ! Make containing directory if there is one
                call system('mkdir -p ' // trim(intensityOutFile(1:i)))
            end if
            open(unit=11, file=intensityOutFile, form="FORMATTED", status="REPLACE", action="WRITE")
            do i=1,N
                write(unit=11,fmt=*) intensity(i)
            end do
            close(unit=11)
            deallocate(intensity)
        end if
        
        !inquire(file=pixelCoordsOutFile,exist=fileExists) ! TODO: Check if file already exists and prompt overwrite?
        !if(fileExists) then
        !end if
    end subroutine writeOutput

end module iomod
