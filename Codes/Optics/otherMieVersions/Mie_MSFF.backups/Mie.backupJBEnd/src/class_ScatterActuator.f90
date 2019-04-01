module class_ScatterActuator
use classes_ScatterStrategies
use DEBUG
implicit none
private
	
	! Allow access only the 'factory-like' function. All the rest is private, the whole ScatterActuator class as well
	public :: ScatterActuatorFromKeyword

	! Start class definition
		! This class provides the context for the strategies.. the "actuator", which is to be named "scatterer" in MieAlgorithmFF.f90, for the nice syntax: call scatterer%scatter()
	type, public :: ScatterActuator
	private
		class(ScatterStrategy), allocatable :: strategy
	contains
		procedure, public :: scatter
	end type
	interface ScatterActuator
		procedure :: create !constructor to be called C++ style:           type(scatterActuator) :: a = scatterActuator(arguments)
	end interface
	! End class definition

contains

	! /************************\
	! | 	 		    Constructor	 			  |
	! \************************/

    function create(strategy) result(this)
    	type(ScatterActuator) :: this
		class(scatterStrategy), intent(in) :: strategy
        
		allocate(this%strategy, source = strategy)
    end function

	subroutine scatter(this, X, REFREL, AMU, S1, S2)
		class(ScatterActuator) :: this
		real, intent (in) :: X
  		complex, intent (in) :: REFREL
		double precision, intent (in) :: AMU(:) !cos(scattering angle)
  		complex, intent (out) :: S1(:), S2(:)

		call this%strategy%actuate(X, REFREL, AMU, S1, S2)
	end subroutine
	
	! /************************\
	! | 	 			  Strategy 					 |		! Add your strategy
	! | 	 	  		  selection			   		 |		! to case structure
	! | 	   		   (factory-like)				 |		! in function below
	! \************************/

	! This case structure inside this factory represents the bookkeeping of the available strategies. Made a new strategy? Add a case here! Bad practice? Yep..
	function ScatterActuatorFromKeyword(keyword, generalInputFile) result(scatterActObj)
		! Arguments
		character(len=*), intent(in) :: keyword
		character(len=*), intent(in) :: generalInputFile

		! Returned object
		type(scatterActuator) :: scatterActObj

		! Local variables
		logical :: interpolConfigExists
		character(len=18) :: interpolConfigFile = "interpolConfig.dat" ! Hardcoded config file name, adjust when wanted.
		
		! Violates open-closed principle but a nicer method, for example, factory pattern with class registration, requires some functionality Fortran doesn't really provide
		! (For example for class registration in other OOP languages one can use a 'static' block, always called somewhere before objects of a class can be instantiated. This 'static' block (or static constrctr)
		! initializes a class if you will, and is called only once automagically, always. It can be used to register a new strategy class to a factory, without altering the factory (which can also be made with cases as here).
		! Again, this is too advanced for FORTRAN.

		! Any checks for the strategies are to be performed here as well, since here the strategy can be defaulted to the original strategy upon failures.
		select case (keyword) ! Keyword as to be provided in inputfile | Upon addition of new strategy, decide whether the strategy needs some initialization info from the original InputFile, and pass it as needed.
		case("FullBHMie")
			scatterActObj = ScatterActuator(fullBHMieStrategy()) ! The original strategy did not need initialization stuff from the original inputfile. So it is not passed.
		case ("Interpolate")
			inquire(file=interpolConfigFile,exist=interpolConfigExists)
			if (interpolConfigExists) then
				scatterActObj = ScatterActuator(interpolationStrategy(generalInputFile, interpolConfigFile)) ! Interpolation strategy does need some init stuff from original inputfile, so it is passed.
			else
				scatterActObj = ScatterActuator(fullBHMieStrategy())	
				call debugmsg(1,"ScatterStrategySelector","Interpolation strategy requires configuration file " // interpolConfigFile // &
										", which was not found. Defaulted to fullBHMieStrategy.")
			end if
		case default
			scatterActObj = ScatterActuator(fullBHMieStrategy())
			call debugmsg(1, "ScatterStrategySelector", "Scatter strategy " // keyword // " not found, defaulted to fullBHMieStrategy.")
		end select
	end function

end module class_ScatterActuator

!EOF
