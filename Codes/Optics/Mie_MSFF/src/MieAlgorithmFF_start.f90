! /************************\
! |     PRGM starter       | for MieAlgorithmFF.f90
! \************************/

program main
    use MieAlgorithmFF, only: run

    character(len=1000) :: inputfile

    call getarg(1,inputfile)
    call run(inputfile)
end program main
