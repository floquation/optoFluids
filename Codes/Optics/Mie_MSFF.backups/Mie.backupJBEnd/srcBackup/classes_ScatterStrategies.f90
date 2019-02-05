module classes_ScatterStrategies
use iomod, only: skipcomments => skipcomments
use DEBUG
use mybhmie, only: mieAlgor => scatter !simply refer to the mybhmie algorithm immediately in the same style as before

private

	double precision, parameter :: pi_d = 4.0D0 * atan(1.0d0)  ! Obtain pi

	! Start class definition
		! This class is the ScatterStrategy <<interface>> (<<abstract>>)
	type, public, abstract :: ScatterStrategy
	contains
		procedure(scatterStrategyProcedure), deferred :: actuate ! This method should generally be a "pass" method (not "nopass") to pass "this" to the algorithms. In case not needed just don't use it.
	end type
	abstract interface !this abstract interface is fortran style to define the prototype scatter() method above.
		subroutine scatterStrategyProcedure(this, X, REFREL, AMU, S1, S2)
			import ScatterStrategy
			class(ScatterStrategy) :: this	
			real, intent (in) :: X
	  		complex, intent (in) :: REFREL
	 		double precision, intent (in) :: AMU(:) !cos(scattering angle)
	  	    complex, intent (out) :: S1(:), S2(:)
		end subroutine
	end interface
	! End class definition

	! Start class definition
		! This class gives the first concrete strategy: the old style: do full bhmie scatter calculations each time
	type, public, extends(ScatterStrategy) :: FullBHMieStrategy
	contains
		procedure, public :: actuate => fullBHMieAlgor
	end type
	interface FullBHMieStrategy !constructor stuff.. yaay fortran OOP... oh well
		procedure :: newFullBHMieStrategy
	end interface
	! End class definition

	! Start class definition
		! This class gives the second concrete strategy: linear interpolation
	type, public, extends(ScatterStrategy) :: InterpolationStrategy
	private
		double precision, allocatable :: AMU(:) ! cos(samplingAngles)
		integer :: sampleRate ! Unit: per unit angle
		complex, allocatable :: S1(:), S2(:)		  ! Scattering matrix elements S1 and S2 for the samplingAngles in AMU
	contains
	private
		procedure, public :: actuate => interpolationAlgor
		procedure :: init => initInterpolationAlgor
		procedure, nopass :: configReader => interpolationConfigReader
	end type
	interface InterpolationStrategy !constructor stuff.. yaay fortran OOP... oh well
		procedure :: newInterpolationStrategy
	end interface
	! End class definition

contains
	
	! /************************\
	! |				   Strategy					  |
	! | 	  		  Constructors	    		  |
	! \************************/

	function newFullBHMieStrategy() result(this)
		type(FullBHMieStrategy) :: this
	end function

	function newInterpolationStrategy(generalConfigFile, strategyConfigFile) result(this)
		character(len=*), intent(in) :: generalConfigFile
		character(len=*), intent(in) :: strategyConfigFile
		type(InterpolationStrategy) :: this

		call this%init(generalConfigFile, strategyConfigFile) ! The initial calculations are performed upon object creation/initialization.
	end function

	! /************************\
	! |				  Strategy				  	  |
	! | 	    	      Methods		 		      |
	! \************************/

	! /************************\
	! | 	 			 fullBHMie	   				  |
	! \************************/

	! This method is essentially a wrapper to allow the abstract class to define a "pass" procedure
	! Meaning that the first argument can be "this". With the keyword "nopass" this is not the case
	! Some strategies however may need "this" (interpolation does)
	subroutine fullBHMieAlgor(this, X, REFREL, AMU, S1, S2)
		! Arguments
		class(FullBHMieStrategy) :: this
    		real, intent (in) :: X
  		complex, intent (in) :: REFREL
 		double precision, intent (in) :: AMU(:) !cos(scattering angle)
  		complex, intent (out) :: S1(:), S2(:)

		call mieAlgor(X,REFREL,AMU,S1,S2)
	end subroutine

	! /************************\
	! | 			  Interpolation	  			  |
	! \************************/

	! Actual implementation of scatter() procedure for interpolation algorithm
	subroutine interpolationAlgor(this, X, REFREL, AMU, S1, S2)
		! Arguments
		class(InterpolationStrategy) :: this
    		real, intent (in) :: X
  		complex, intent (in) :: REFREL
 		double precision, intent (in) :: AMU(:) !cos(scattering angle)
  		complex, intent (out) :: S1(:), S2(:)

		! Local stuff
		integer :: biggerIndex
		double precision :: angle, angleRounded, interpolConstant
		integer :: angleIndex, angleNearestIndex

		!interpolation algorithm here:
		call debugmsg(3, "InterpolationAlgor", "TODO: Error handling, weird cases etc")
		do i = 1,size(AMU)
			angle = acos(AMU(i))*180d+0/(pi_d)
			angleRounded = nint(angle*dble(this%sampleRate))/dble(this%sampleRate) ! Rounded to angle numbers
			angleIndex = nint((angleRounded*dble(this%sampleRate)) + 1) ! Such that the correct index can be found
			angleNearestIndex = angleIndex + sign(1d+0, angle-angleRounded) ! This is the index either above or below the angleIndex, the angle lies inbetween those corresponding to angleIndex and angleNearestIndex
			
			call debugmsg(5, "InterpolationStrategy", "Angle: " , angle)
			call debugmsg(5, "InterpolationStrategy", "AngleRounded: " , angleRounded )
			call debugmsg(5, "InterpolationStrategy", "angleIndex: ", angleIndex)
			call debugmsg(5, "InterpolationStrategy", "angleNearestIndex: " , angleNearestIndex)

			biggerIndex = angleNearestIndex ! Assume that the rounding to make angleRounded was downwards (thus angle > angleRounded)
			if(angleNearestIndex < angleIndex) biggerIndex = angleIndex ! If rounding was upwards, change the biggerIndex (index of the upper bound of the interpolation domain)

			if(abs(angle-angleRounded) < 1d-50) then ! Approximately equal angles, then the index should not be biggerIndex-1, but just angleIndex
				S1(i) = this%S1(angleIndex)
				S2(i) = this%S2(angleIndex)
			else 
				! Weighted average (linear interpolation): y = y0 + ((x-x0)/(x1-x0)) * (y1 - y0); y0 is lower bound (so at index biggerIndex-1). 
				! Weight is distance to actual point x in units of the interval size, constribution is y1-y0 = interval along y.
				interpolConstant = (AMU(i) - this%AMU(biggerIndex-1)) / (this%AMU(biggerIndex) - this%AMU(biggerIndex-1)) ! ((x-x0)/(x1-x0))
				S1(i) = this%S1(biggerIndex - 1) + interpolConstant*( this%S1(biggerIndex) - this%S1(biggerIndex - 1) )
				S2(i) = this%S2(biggerIndex - 1) + interpolConstant*( this%S2(biggerIndex) - this%S2(biggerIndex - 1) )
			end if
		end do

		! Old algorithm, double loop pain.
		!integer :: equalsIndex
		!do i = 1, size(AMU)
		!	equalsIndex = -1
		!	biggerIndex = -1
		!	do j = 1, size(this%AMU)
		!		if(AMU(i) == this%AMU(j)) then
		!			equalsIndex = j
		!			EXIT ! Breaks inner loop
		!		end if
		!		if (AMU(i) > this%AMU(j)) then ! Since this%AMU runs from 1 to -1, when AMU(index) is bigger, the numbers of the closest to the left and right are found. Only works due to ordering really.			
		!			biggerIndex = j
		!			EXIT ! Breaks inner loop
		!		end if			
		!	end do
		!	if (equalsIndex > 0) then ! Have a match, do not need to interpolate
		!		S1(i) = this%S1(equalsIndex)
		!		S2(i) = this%S2(equalsIndex)
		!	else if (biggerIndex > 0) then ! Not an exact match (most cases), need to interpolate now
		!		! Weighted average (linear interpolation): y = y0 + ((x-x0)/(x1-x0)) * (y1 - y0); y0 is lower bound. weight is distance to actual point x in units of the interval size, constribution is y1-y0 = interval along y.
		!		S1(i) = this%S1(biggerIndex - 1) + ( (AMU(i) - this%AMU(biggerIndex-1)) / (this%AMU(biggerIndex) - this%AMU(biggerIndex-1)) ) & 
		!					*( this%S1(biggerIndex) - this%S1(biggerIndex - 1) )
		!		S2(i) = this%S2(biggerIndex - 1) + ( (AMU(i) - this%AMU(biggerIndex-1)) / (this%AMU(biggerIndex) - this%AMU(biggerIndex-1)) ) & 
		!					*( this%S2(biggerIndex) - this%S2(biggerIndex - 1) )	
		!	else ! Something is very wrong, as the number apparently is not nicely inside this%AMU's range. Throw a tantrum:			
		!		call debugmsg(0, "InterpolationStrategy", "Error: Requested cos(angle) is not within -1 to 1. Are you using cosine of angles?")
		!		call debugmsg(3, "InterpolationStrategy", "Diagnostics: Requested cos(angle) = ", AMU(i))			
		!	end if
		!end do
	end subroutine

	! This will provide the init for interpolation: "run bhmie one time for set of angles, so interpolation can be used from then on"
	subroutine initInterpolationAlgor(this, generalConfigFile, strategyConfigFile)
		! Arguments
		class(InterpolationStrategy), intent(inout) :: this
		character(len=*), intent(in) :: generalConfigFile
		character(len=*), intent(in) :: strategyConfigFile

		! Variables to be obtained from configuration files
		real :: X
		complex :: REFREL

		! Derived parameters
		integer :: numSamples

		call debugmsg(2, "InterpolationStrategy","Performing initialization of interpolation strategy")
		call debugmsg(2, "InterpolationStrategy", "TODO: Add error handling, debugmessages w/e")

		call this%ConfigReader(generalConfigFile, strategyConfigFile, this%sampleRate, X, REFREL)

		numSamples = this%sampleRate*180 + 1
		allocate(this%AMU(numSamples), this%S1(numSamples), this%S2(numSamples))
		do i = 1, numSamples
			this%AMU(i) = cos((dble(i-1)/dble(this%sampleRate))*pi_d/180d+0)
		end do

		call mieAlgor(X, REFREL, this%AMU, this%S1, this%S2) ! Perform the bhmie algorithm for the angle samples
	end subroutine

	! Custom read routine for interpolation strategy: Read stuff from interpolation strategy configuration file and general configuration file (inputfile)
	subroutine interpolationConfigReader(generalConfigFile, configFile, sampleRate, X, REFREL)
		character(len=*), intent(in) :: generalConfigFile
		character(len=*), intent(in) :: configFile
		integer, intent(out) :: sampleRate
		real, intent(out) :: X
		complex, intent(out) :: REFREL

		! Local vars needed to construct the vars
		character(len = 200) :: buffer
		real :: refrRe, refrIm, refrMed, wavel, rad

		! Section on the interpolation configuration file
        open(unit=11, file=configFile, form="FORMATTED", status="OLD", action="READ")
        call skipcomments (11, buffer,'!')
        read(buffer, fmt=*) sampleRate ! interpolConfigFile only has one setting really, bam put to output
		close(unit=11)
		! End section

		! Section on the general configuration file, to obtain X and REFREL
        open(unit=11, file=generalConfigFile, form="FORMATTED", status="OLD", action="READ")
		call skipcomments (11, buffer,'!') ! These lines are to skip
		read(buffer, fmt=*) buffer			  ! the debuglevel setting
		call skipcomments (11, buffer,'!')
		read(buffer, fmt=*) refrRe
		call skipcomments (11, buffer,'!')
		read(buffer, fmt=*) refrIm
		call skipcomments (11, buffer,'!')
		read(buffer, fmt=*) refrMed
		call skipcomments (11, buffer,'!')
		read(buffer, fmt=*) wavel
		call skipcomments (11, buffer,'!')
		read(buffer, fmt=*) rad
		close(unit=11) !The rest of the file is not interesting now
		! End section
		
		! Calculate output
		REFREL = cmplx(refrRe,refrIm)/refrMed
		X = rad*2.*pi_d*refrMed/wavel
	end subroutine

end module classes_ScatterStrategies

!EOF
