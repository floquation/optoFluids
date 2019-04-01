! /************************\
! |     PRGM starter       | for MieAlgorithmFF.f90
! \************************/

program main
    use MieAlgorithmFF, only: run

    character(len=100) :: inputfile
	

    print *, 'Using modified algorithm -- Koen'
    call getarg(1,inputfile)
    call run(inputfile)
end program main
