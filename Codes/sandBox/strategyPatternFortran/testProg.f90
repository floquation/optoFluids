module strategies
implicit none
	
	private :: newAggressive, newDefensive, initAggressiveStrategy, moveAggressive, moveDefensive

	type, abstract :: strategy !this is the <<interface>> strategy
	contains
		procedure(moveCommand), deferred, nopass :: move
	end type

	abstract interface !based on the movecommand procedure
		subroutine moveCommand
		end subroutine
	end interface

	type, extends(strategy) :: AggressiveStrategy !these are the concrete strategy objects
	contains
	private
		procedure, nopass, public :: move => moveAggressive !containing an implementaion of the movecommand procedure
		procedure, nopass :: init => initAggressiveStrategy !and possible other methods as needed
	end type

	interface AggressiveStrategy !Defines a constructor for concrete strategy
		procedure :: newAggressive
	end interface

	type, extends(strategy) :: DefensiveStrategy !Concrete strategy object
	contains
		procedure, nopass :: move => moveDefensive
	end type

	interface DefensiveStrategy !Defines constructor for concrete strategy
		procedure :: newDefensive
	end interface

contains

	function newAggressive() result(this) !Constructs a moveAggressive strategy
		type(AggressiveStrategy) :: this
		call this%init !Where in this strategy some extra initialization method is provided
	end function

	function newDefensive() result(this) !Constructs a moveDefensive strategy (support for the OOP-way of calling: without first declaring an object outside this module, but just calling moveDefensive() as a constructor)
		type(DefensiveStrategy) :: this
	end function

	subroutine initAggressiveStrategy !Extra init provided for aggressive strategy
		write(*,*) "Initializing aggressive strategy"
	end subroutine

	subroutine moveAggressive !Actual implementation of move() for aggressive strategy
		write (*,*) "The robot moves along like an aggressive inline skater"
	end subroutine

	subroutine moveDefensive !Actual implementation of move() for defensive strategy
		write (*,*) "The robot moves along like a defensive driver"
	end subroutine

end module

module class_Robot
use strategies, only: strategy
implicit none
	
	! Properly shield functions and subroutines from unwanted direct calling-capabilities (unless via OOP route)
	private :: newRobot, move

	type Robot
		character(len=20) :: name
		class(strategy), allocatable :: moveStrategy
	contains
		procedure :: move
	end type

	interface Robot
		procedure :: newRobot
	end interface

contains
	
	function newRobot(name, strategyParam) result(this)
		character(len=*), intent(in) :: name
		class(strategy), intent(in) :: strategyParam
		type(Robot) :: this

		this%name = name
		allocate(this%moveStrategy, source = strategyParam)
	end function

	subroutine move(this)
		class(Robot), intent(in) :: this
		call this%moveStrategy%move()
	end subroutine
	
end module

module RobotFactory
use strategies
use class_Robot
implicit none
contains

	subroutine readRobotConfig(inputfile, robotConfig)
		character(len=*), intent(in) :: inputfile
		character(len=:), allocatable, intent(out) :: robotConfig
		logical inputfileExists
		character(len = 200) :: line

		inquire(file=inputfile,exist=inputfileExists)
        if(.not. inputfileExists) then
            write(0,*) "---ERROR--- Specified inputfile does not exist: ", inputfile
            call exit(0) 
        end if
        open(unit=10, file=inputfile, form="FORMATTED", status="OLD", action="READ")
		read(10, fmt=*) line
		close(unit=10)
		allocate(robotConfig, source = trim(line))
	end subroutine	

	function constructRobot(name, strategyName) result(bot)
		character(len=*),intent(in) :: name
		character(len=*),intent(in) :: strategyName
		type(Robot) :: bot
		
		select case (strategyName)
		case ("aggressive") 
			bot = Robot(name, AggressiveStrategy())
		case("defensive") 
			bot = Robot(name, DefensiveStrategy())
		case default 
			write(*,*) "Robot movement strategy named ", strategyName, " not found."
			write(*,*) "Defaulting to defensive strategy"
			bot = Robot(name, DefensiveStrategy())
		end select
	end function
		
end module

program testProg
use RobotFactory
use class_Robot
implicit none

	character(len=:), allocatable :: roboConfig, roboConfig2
	type(Robot) :: r1, r2

	call readRobotConfig("robotConfig", roboConfig)
	call readRobotConfig("robot2Config", roboConfig2)

	r1 = constructRobot("ComBot",roboConfig)
	r2 = constructRobot("SweetBot", roboConfig2)

	call r1%move
	call r2%move

end program
