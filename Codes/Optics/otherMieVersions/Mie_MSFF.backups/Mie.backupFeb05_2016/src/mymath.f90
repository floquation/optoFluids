module mymath

    implicit none
    private

    public :: cross_product
    interface cross_product
        procedure :: cross_product_integer
        procedure :: cross_product_real4
        procedure :: cross_product_real8
    end interface cross_product

contains

FUNCTION cross_product_integer(a, b) result(cross)
    INTEGER, DIMENSION(3) :: cross
    INTEGER, DIMENSION(3), INTENT(IN) :: a, b

    cross(1) = a(2) * b(3) - a(3) * b(2)
    cross(2) = a(3) * b(1) - a(1) * b(3)
    cross(3) = a(1) * b(2) - a(2) * b(1)
END FUNCTION cross_product_integer

FUNCTION cross_product_real4(a, b) result(cross)
    REAL*4, DIMENSION(3) :: cross
    REAL*4, DIMENSION(3), INTENT(IN) :: a, b

    cross(1) = a(2) * b(3) - a(3) * b(2)
    cross(2) = a(3) * b(1) - a(1) * b(3)
    cross(3) = a(1) * b(2) - a(2) * b(1)
END FUNCTION cross_product_real4

FUNCTION cross_product_real8(a, b) result(cross)
    REAL*8, DIMENSION(3) :: cross
    REAL*8, DIMENSION(3), INTENT(IN) :: a, b

    cross(1) = a(2) * b(3) - a(3) * b(2)
    cross(2) = a(3) * b(1) - a(1) * b(3)
    cross(3) = a(1) * b(2) - a(2) * b(1)
END FUNCTION cross_product_real8



end module mymath




! EOF
