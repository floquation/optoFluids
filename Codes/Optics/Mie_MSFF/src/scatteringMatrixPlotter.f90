program scatteringMatrixPlotter
	use iomod
	use class_ScatterActuator
    use class_Camera, only: Camera ! Only needed because iomod is re-used.
	use DEBUG

	implicit none

    character(len=100) :: inputfile
	character(len=100) :: outputfile
	type(ScatterActuator), allocatable :: scatterer !the scatterer, which can contain one of different strategies. To scatter perform: call scatterer.scatter(<same args as mieAlgor had>)
	double precision, parameter :: pi = 4.0D0 * atan(1.0d0)  ! Obtain pi
	integer, parameter :: numAngles = 1001
	integer :: i
	double precision, allocatable:: AMU(:)
	COMPLEX, allocatable :: S1(:), S2(:)
	COMPLEX :: refrel
	REAL :: refmed, refre, refim, rad, wavel, x
	character(len=:), allocatable :: strategyKeyword ! Keyword of the scattering strategy to use

	! Dummies for readParameters(...)
    type(Camera), allocatable :: cam
    real*4, allocatable :: spherePos(:,:)
	real*4 :: kihat(3)
    real*4 :: k     
    real*4 :: Eihat(3)
    integer :: conv_minp, conv_maxp 
    logical :: dop0

    call getarg(1,inputfile)
	call getarg(2,outputfile)

	call debugmsg(2, "scatteringMatrixPlotter", "Calculating scattering matrix elements using configurtion " // inputfile)

    call readParameters(inputfile, refre, refim, refmed, wavel, rad, kihat, Eihat, spherePos, &
                        cam, conv_minp, conv_maxp, dop0, strategyKeyword)

    refrel = cmplx(refre,refim)/refmed
    k=2.*pi*refmed/wavel
    x=k*rad

	scatterer = ScatterActuatorFromKeyword(trim(strategyKeyword), inputfile)
	
	allocate(AMU(numAngles), S1(numAngles), S2(numAngles))
	do i = 1, numAngles
		AMU(i) = cos(dble(i-1)*(1d+0/(numAngles-1))*pi)
	end do

	call scatterer%scatter(x, refrel, AMU, S1, S2)

	call writeToFile(outputfile)

	call debugmsg(2, "scatteringMatrixPlotter", "Exiting")

contains

	subroutine writeToFile(outputfile)
		character(len=100), intent(in) :: outputfile
		
		call debugmsg(2, "scatteringMatrixPlotterIO", "Writing to outputfile " // outputfile)

		open(unit=11, file=outputfile, form="FORMATTED", status="REPLACE", action="WRITE")
		do i = 1, numAngles
			write(unit=11,fmt=' (1X,F7.3,7X,E17.10," +",E17.10," i",7X,E17.10," +",E17.10," i")') acos(AMU(i))*180/pi, S1(i), S2(i)
		end do
		close(unit=11)

	end subroutine
end program
