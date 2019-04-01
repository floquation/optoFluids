! Module which contains the I/O subroutines for the MieAlgorithm.
module iomod
    use DEBUG
    use class_Camera, only: Camera
    
    implicit none
    private

    character (len=250) :: pixelCoordsOutFile
    character (len=250) :: intensityOutFile
    
    public :: readParameters, readPositions
    public :: writeOutput
    
contains
    
    subroutine readParameters(inputfile, refre, refim, refmed, wavel, rad, khat, Eihat, spherePos, &
                                nPixel1, nPixel2, r0, r1, r2, conv_minp, conv_maxp, dop0)
        character(len=*), intent(in) :: inputfile
        character (len=250) :: line

    ! Directions
        real*4, intent(out) :: khat(3) ! incident plane wave -> unit wave vector
        real*4, intent(out) :: Eihat(3)! incident electric field polarisation -> unit vector. Orthogonal to khat per definition. Linearly polarised per definition (real vector).
    ! Camera parameters
        integer, intent(out) :: nPixel1, nPixel2
        real*4, intent(out) :: r0(3), r1(3), r2(3)
    ! SphereManager parameters
        real*4, allocatable, intent(out) :: spherePos(:,:)
        real*4, intent(out) :: refre, refim, refmed, wavel, rad
        integer, intent(out) :: conv_minp, conv_maxp   ! Limits of the scattering order (used for convergence)
        logical :: dop0

        character (len=250) :: prtcPosFile
        logical inputfileExists

 
        inquire(file=inputfile,exist=inputfileExists)
        if(.not. inputfileExists) then
            write(0,*) "---ERROR--- Specified inputfile does not exist: ", inputfile
            call exit(0) 
        end if
        open(unit=10, file=inputfile, form="FORMATTED", status="OLD", action="READ")

    ! Read DEBUG parameter
        call skipcomments (10, line,'!') 
        read(line, fmt=*) debugLevel
        call debugmsg(3, "IO","DebugLevel = ", debugLevel)
       
        call debugmsg(3, "IO","File opened, starting reading: " // inputfile)

    ! Constants 
        call skipcomments (10, line,'!') 
        read(line, fmt=*) refre
        call debugmsg(3, "IO","refre = ", refre)
        call skipcomments (10, line,'!')
        read(line, fmt=*) refim
        call debugmsg(3, "IO","refim = ", refim)
        call skipcomments (10, line,'!')
        read(line, fmt=*) refmed
        call debugmsg(3, "IO","refmed = ", refmed)
        
        call skipcomments (10, line,'!')
        read(line, fmt=*) wavel
        call debugmsg(3, "IO","wavel = ", wavel)
        call skipcomments (10, line,'!')
        read(line, fmt=*) rad
        call debugmsg(3, "IO","rad = ", rad)

        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) khat
        call debugmsg(3, "IO","khat = ", khat)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) Eihat
        call debugmsg(3, "IO","Eihat = ", Eihat)

    ! Sphere positions
        call skipcomments (10, line,'!')
        read(line, fmt=*) prtcPosFile
        call debugmsg(3, "IO","prtcPosFile = " // prtcPosFile)

    ! Camera
        call skipcomments (10, line,'!')  
        read(line, fmt=*) nPixel1
        call debugmsg(3, "IO","nPixel1 = ", nPixel1)
        call skipcomments (10, line,'!')
        read(line, fmt=*) nPixel2
        call debugmsg(3, "IO","nPixel2 = ", nPixel2)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r0
        call debugmsg(3, "IO","r0 = ", r0)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r1
        call debugmsg(3, "IO","r1 = ", r1)
        call skipcomments (10, line,'!')
        line = obtainVector(line) 
        read(line, fmt=*) r2
        call debugmsg(3, "IO","r2 = ", r2)

    ! Convergence 
        call skipcomments (10, line,'!') 
        read(line, fmt=*) conv_minp
        call debugmsg(3, "IO","convergence min_p = ", conv_minp)
        call skipcomments (10, line,'!') 
        read(line, fmt=*) conv_maxp
        call debugmsg(3, "IO","convergence max_p = ", conv_maxp)

    ! Output
        call skipcomments (10, line,'!') 
        read(line, fmt=*) dop0
        call debugmsg(3, "IO","Include p=0 term = ", dop0)
        call skipcomments (10, line,'!')
        read(line, fmt=*) pixelCoordsOutFile 
        call debugmsg(3, "IO","pixelCoordsOutFile = " // trim(pixelCoordsOutFile))
        call skipcomments (10, line,'!')
        read(line, fmt=*) intensityOutFile
        call debugmsg(3, "IO","intensityOutFile = " // trim(intensityOutFile))

        close(unit=10)
        call debugmsg(3, "IO","Finished reading. File closed: " // inputfile)

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
        call debugmsg(2, "IO","File opened, starting reading: " // filename)

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
        call debugmsg(3, "IO","r = ", r)
        
        ! Remainder of file is not interesting
        close(unit=10)
        call debugmsg(2, "IO","Finished reading. File closed: " // filename)
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
    
    subroutine writeOutput(cam)
        type(Camera), intent(in)     :: cam
        real*4, allocatable :: intensity(:)
        real*4, allocatable :: coords(:,:)
        character (len=100) frmt
        integer i,N

        call debugmsg(2, "IO","Obtaining intensity, and writing to file '" // trim(intensityOutFile) // "'")
        intensity = cam%getIntensity() ! (pixel)
        write(frmt,*) '(1X,E15.8)'
        N = size(intensity,1)
        open(unit=11, file=intensityOutFile, form="FORMATTED", status="REPLACE", action="WRITE")
        do i=1,N
            write(unit=11,fmt=*) intensity(i)
        end do
        close(unit=11)
        deallocate(intensity)

        call debugmsg(2, "IO","Obtaining pixel coordinates, and writing to file '" // trim(pixelCoordsOutFile) // "'")
        coords = cam%getPixelcoords() ! (xyz,pixel)
        write(frmt,*) '(1X,',size(coords,1),'(E15.8,1X))'
        N = size(coords,2)
        open(unit=11, file=pixelCoordsOutFile, form="FORMATTED", status="REPLACE", action="WRITE")
        do i=1,N
            write(unit=11,fmt=*) coords(:,i)
        end do
        close(unit=11)
        deallocate(coords)

        
        !inquire(file=pixelCoordsOutFile,exist=fileExists) ! TODO: Check if file already exists and prompt overwrite?
        !if(fileExists) then
        !end if
    end subroutine writeOutput

end module iomod
