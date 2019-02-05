PROGRAM myFirstFortran
	IMPLICIT NONE
	INTEGER :: a = 10, b = 20
	WRITE(*,*) Add(a,b)
	WRITE(*,*) b
	WRITE(*,*) Add(a,b)
CONTAINS
	INTEGER FUNCTION Add(x,y)
		IMPLICIT NONE
		INTEGER, INTENT(IN):: x,y
		b = x+y
		Add = b
	END FUNCTION Add
END PROGRAM myFirstFortran
