program prgm


call foo()    

contains


subroutine foo()

    real*4, pointer :: r(:) => null()

    if(associated(r)) then
        write(6,*) "r is associated"
    else
        write(6,*) "r is NOT associated"
    end if

    write(6,*) "allocate r(10)"
    allocate(r(10))

    
    if(associated(r)) then
        write(6,*) "r is associated"
    else
        write(6,*) "r is NOT associated"
    end if

    write(6,*) "deallocate r"
    deallocate(r)

    if(associated(r)) then
        write(6,*) "r is associated"
    else
        write(6,*) "r is NOT associated"
    end if

end subroutine foo

end program prgm
