
      module namespacename 
         type classname
            complex :: inst_field1
         contains
            ! declare some instance constructors
            initial,pass :: classname_ctor0
            initial,pass :: classname_ctor1
            initial,pass :: classname_ctor2
         end type classname   
      contains
         subroutine classname_ctor0(this)
           type(classname) :: this
           this%inst_field1 = cmplx(0.,0.) 
         end subroutine classname_ctor0
         subroutine classname_ctor1(this,Value)
           type(classname) :: this
           real,value :: Value
           this%inst_field1 = cmplx(Value,0.)
         end subroutine classname_ctor1
         subroutine classname_ctor2(this,Value1,Value2)
           type(classname) :: this
           real,value :: Value1,Value2
           this%inst_field1 = cmplx(Value1,Value2)
         end subroutine classname_ctor2
      end module namespacename

      program tconst
        use namespacename
        type(classname) :: ex0
        type(classname) :: ex1 = classname(5.)    ! invokes classname_ctor1
        type(classname) :: ex2 = classname(5.,5.) ! invokes classname_ctor2
        type(classname), pointer :: ex3,ex4
        ! the constructor classname_ctor0 is invoked sometime 
        ! before the following statement is executed
         print *,ex0%inst_field1
        ! the following allocate statement causes the 
        ! constructor classname_ctor1 to be invoked
        allocate(ex3,source=classname(1.))
        ! the following allocate statement causes the 
        ! constructor classname_ctor2 to be invoked
        allocate(ex4,source=classname(1.,1.))
      end
        
