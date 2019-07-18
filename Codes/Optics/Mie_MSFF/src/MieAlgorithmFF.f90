! HAS: Camera, SphereManager, k, Eihat
! DOES: Apply the scatter logic for each sphere and for each target
! ASSUME: incident plane wave has unit amplitude
! ASSUME: Far-Field assumption between spheres

module MieAlgorithmFF
    use DEBUG
    use mytimer
    use class_Camera, only: Camera
    use class_SphereManager, only: SphereManager
    use class_Sphere
	use class_ScatterActuator !this module provides a factory-like-function that gives a ScatterActuator... which carries a strategy obtained from configuration inputfile as a keyword
    use iomod
    use mymath, only: cross_product
    
    implicit none
    private
    
    type(Camera), allocatable :: cam ! the camera to measure the fields
    type(SphereManager), allocatable :: sphmgr ! the spheres for scattering
	type(ScatterActuator), allocatable :: scatterer !the scatterer, which can contain one of different strategies. To scatter perform: call scatterer.scatter(<same args as mieAlgor had>)
    real*4 :: kihat(3) ! incident plane wave -> unit wave vector
    real*4 :: k       ! incident plane wave -> wave number [m-1]
    real*4 :: Eihat(3)! incident electric field polarisation -> unit vector. Orthogonal to kihat per definition. Linearly polarised per definition (real vector).
!   complex :: E0     ! incident field amplitude, Ei = Eihat * Re{ E0 * exp(i(kz-wt)) }

    real*4, parameter :: xhat(3) = (/ 1, 0, 0 /)
    real*4, parameter :: yhat(3) = (/ 0, 1, 0 /)
    real*4, parameter :: zhat(3) = (/ 0, 0, 1 /)

	double precision, parameter :: pi_d = 4.0D0 * atan(1.0d0)  ! Obtain pi

! Convergence criteria
    integer :: conv_minp, conv_maxp ! Minimum and maximum number of multiscattering orders to compute.

! Flags
    logical :: dop0 ! Include p=0 term on the camera measurement?
    
    public :: run
    
contains
    
! /************************\
! |           IO           |
! \************************/
        
    subroutine init(inputfile)
        character(len=*) :: inputfile
    ! Camera parameters
        integer :: nPixel1, nPixel2
        real*4 :: r0(3), r1(3), r2(3)
    ! SphereManager parameters
        real*4, allocatable :: spherePos(:,:)
        complex :: refrel
        real*4 :: refre, refim, refmed ! Re{refr. index of sphere}, Im{refr. index of sphere}, refr. index of surrounding medium
        real*4 :: wavel, x, rad ! wavelength (vacuum), size parameter, radius of sphere
    ! ScatterStrategy parameter		
        character(len=:), allocatable :: strategyKeyword ! Keyword of the scattering strategy to use

        call startSubClock()
 
        ! Debug value has not yet been read at this point. Workaround: move this to
        ! iomod.f90, and display right after it is read.
!         call debugmsg(0, "MieAlgorithmFF","************************************************************")
!         call debugmsg(0, "MieAlgorithmFF","Starting to load from inputfile: '" // trim(adjustl(inputfile)) // "'")
!         call debugmsg(0, "MieAlgorithmFF","************************************************************")

    ! Obtain parameters from the input file
        call readParameters(inputfile, refre, refim, refmed, wavel, rad, kihat, Eihat, spherePos, &
                            cam, conv_minp, conv_maxp, dop0, strategyKeyword)
        
    ! Derived parameters / Create objects
        refrel = cmplx(refre,refim)/refmed
        k=2.*pi_d*refmed/wavel
        x=k*rad

        call debugmsg(3,"MieAlgorithmFF","refrel = ",refrel)
        call debugmsg(3,"MieAlgorithmFF","k = ",k)
        call debugmsg(3,"MieAlgorithmFF","x = ",x)
        
        ! Check if kihat is orthogonal to Eihat !TODO: Approximation equal???
        if (dot_product(kihat,Eihat) /= 0) then
            write(0,*) "---ERROR--- Specified kihat and Eihat are not orthogonal. Found the following inner product: ", &
                    dot_product(kihat,Eihat)
            kihat = kihat / sqrt(dot_product(kihat,kihat))
            Eihat = Eihat / sqrt(dot_product(Eihat,Eihat))
            write(0,*) "            Which implies the following angle between the two vectors (degrees): ", &
                    acos(dot_product(kihat,Eihat))*180/pi_d
            call exit(0) 
        end if
        kihat = kihat / sqrt(dot_product(kihat,kihat))
        Eihat = Eihat / sqrt(dot_product(Eihat,Eihat))

        call debugmsg(3,"MieAlgorithmFF","kihat = ",kihat)
        call debugmsg(3,"MieAlgorithmFF","Eihat = ",Eihat)

        !allocate(cam, sphmgr, scatterer)
        allocate(sphmgr, scatterer)
        !cam = Camera(nPixel1, nPixel2, r0, r1, r2)
        sphmgr = SphereManager(spherePos, x, refrel)

        ! This is the new scatterer abstraction. Calculates scattering matrix either using the old style (mieAlgor each time), 
        ! or the new style: interpolation (runs mybhmie once on initialization)
        scatterer = ScatterActuatorFromKeyword(strategyKeyword, inputfile)

        write(6,*) printLocalElapsedTime()
    end subroutine init

    subroutine output()
        call startSubClock()

        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call debugmsg(1, "MieAlgorithmFF","Starting to write output to files... Calling iomod%writeOutput(cam).")
        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call flush(6) ! Important progress point -> flush stdout
        
        call writeCoords(cam) !'iomod' knows where to output the files. 'cam' knows what to output.
        call writeOutput(cam) !'iomod' knows where to output the files. 'cam' knows what to output.

        write(6,*) printLocalElapsedTime()
    end subroutine

! /************************\
! |    		 Algorithm Logic  		  |
! \************************/
        
    subroutine initialScatter()
        real*8, allocatable :: CosSAngles(:)    ! All scattering angles which require computation; size = (numAngles = number of targets)
        complex, allocatable :: S1(:), S2(:)    ! The scattered amplitude matrices; size = (numAngles)
        complex, allocatable :: eField(:,:)     ! size = (xyz,numAngles)
        integer :: i, j, l, Nsph
        integer :: step                         ! counter that is 0 if j<i and 1 if j>i. This allows me to skip i=j in a vector.
        ! Pointer to the 'current' sphere in the iterator loop. Respectively: current (i), target (j) and source (l):
        class(Sphere), pointer :: psphi, psphj, psphl  
        real*4 :: rsphi(3), dr(3), dr_in(3)

        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call debugmsg(1, "MieAlgorithmFF","Starting scattering routine. Iterating over all spheres.")
        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call flush(6) ! Important progress point -> flush stdout

        call startSubClock()

    ! Prepare initialScatter
        Nsph = sphmgr%getNumSpheres()

        ! Safety statement. Should never be needed...
        ! Terminate the program if there is a sphere which is non-existent.
        ! I.e., when sphmgr does not know the sphere belonging to index 'i'.
        do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            if (.not. associated(psphi)) then; write(6,*) "---ERROR--- MieAlgorithmFF.initialScatter(): 'psph' is not associated!!!"; &
                                               write(6,*) "              It involved the sphere index: ", i; call exit(0); end if 
            ! And use this loop, while we're at it, to allocate the arrays for each sphere (eField):
            call psphi%allocateE(Nsph)
        end do; nullify(psphi)
        
       if(conv_maxp>2) then ! Scattering matrix of individual spheres are only required in the multiScatter() routine: p>2.
        do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            call psphi%allocateS(Nsph)
        end do; nullify(psphi)
       end if ! conv_maxp > 2

    ! Start initialScatter
        do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            call debugmsg(2, "MieAlgorithmFF","Starting initialScattering routine for sphere: ", i)
            !call flush(6) ! Important progress point -> flush stdout
            
            rsphi = psphi%getPosition() ! Position of scatterer
    ! Move the initial field to i (initial phase delay)
          ! Compute E_i0^0 and store it in E_ii^accum
            ! Determine initial phase (propto distance between plane wave source and sphere)
            ! If we wish to measure at a given time, the light arriving at the measurement point needs
            !  to be sampled from a different point for each scatterer (sphere).
            !  This sneaks into Mie theory in the term exp(-iwt): each scatterer has its own time, which may be converted to
            !  'sampling at a different point', by the easy formule for a plane wave: exp(i(kz-wt)).
            !  Sampling at a different position automatically yields a different phase (but the same amplitude for a plane wave, of course).
            !  At a given time, we have a phase delay of the incident field w.r.t. some origin: E(r,t)=E(0,t)*exp(ikz).
            ! Now use that: pathlength = |rsph_ortho| = rsph.dot.kihat   -> given that |kihat|=1
           !E_i0^0 = E_0 * exp(i*initialPhase)
           !E_ii^accum = Ei0^0 (This is the only p=1 scattering term)
            psphi%eField_acm(:,i) = Eihat * exp(COMPLEX(0,1)*k*dot_product(rsphi,kihat)) ! exp(i k_0 dot_product r_sph); k_0 = k kihat;
              call debugmsg(5,"MieAlgorithmFF","eField_acm(:,i) [effect of incident wave, p=1] = ",psphi%eField_acm(:,i))
            
           if(conv_maxp >= 2) then
    ! Scatter the initial field via i to j (p=2) 
            ! Compute the first order scattering term, which involves the incident field being scattered from the first sphere to the second.
          ! Compute [S]_ji0
            ! First determine all scattering angles, because the Mie algorithm is a lot faster if computed in batches,
            !  because the Bessel functions etc. may be re-used.
            allocate(CosSAngles(Nsph-1),S1(Nsph-1),S2(Nsph-1)) ! TODO: Code crashes here???
            step=0 ! Used to skip i==j in the array. Worthwhile, because otherwise the Mie algorithm computes N too many terms.
            do j = 1, Nsph; psphj => sphmgr%getSphere(j)  ! Iterator loop over all spheres
                if(j==i) then; step=1; cycle; end if ! j /= i
                dr = psphj%getPosition() - rsphi
                !CosSAngles(j-step) = dot_product(dr,kihat)/sqrt(dot_product(dr,dr))
                CosSAngles(j-step) = calcCosSAngle(dr,kihat,i,j,-1)
            end do; nullify(psphj)
            call debugmsg(4,"MieAlgorithmFF","--SAngles(fixed i, varying j) = ", acos(CosSAngles)*180/pi_d)
            call scatterer%scatter(psphi%getX(), psphi%getRefrel(), CosSAngles, S1, S2)
            call debugmsg(5,"MieAlgorithmFF","The scattering matrix for this sphere is S1: ", S1)
            call debugmsg(5,"MieAlgorithmFF","The scattering matrix for this sphere is S2: ", S2)
            ! We now have the scattering matrices for the incident field via i to j.
            deallocate(CosSAngles)
            step=0
            do j = 1, Nsph; psphj => sphmgr%getSphere(j)  ! Iterator loop over all spheres
                if(j==i) then; step=1; cycle; end if ! j /= i
              ! Compute E_ji^new from E_i0^0 using [S]_ji0
                  call debugmsg(4,"MieAlgorithmFF","Beginning S2E for spheres (i,j,arg) = ", (/i,j,j-step/))
                  call debugmsg(7,"MieAlgorithmFF","psphj%eField_new(:,i) (before S2E) = ", psphj%eField_new(:,i));
                call SMatrix2EField(S1(j-step),S2(j-step),psphj%getPosition()-rsphi, &
                                    kihat,psphi%eField_acm(:,i),psphj%eField_new(:,i))
                call debugmsg(5,"MieAlgorithmFF","psphj%eField_new(:,i) = ", psphj%eField_new(:,i));
              ! Store in E_ji^accum
                psphj%eField_acm(:,i) = psphj%eField_acm(:,i) + psphj%eField_new(:,i)
                  call debugmsg(5,"MieAlgorithmFF","psphj%eField_acm(:,i) = ", psphj%eField_acm(:,i));
            end do; nullify(psphj)
          ! Clear [S]_ji0
            deallocate(S1,S2)

           if(conv_maxp > 2) then
    ! Prepare for multiscattering by computing ALL intersphere scattering matrices (needed for p>2)
              call debugmsg(3, "MieAlgorithmFF","-Starting to compute all intersphere scattering matrices involving sphere ", i)
            ! Compute [S]_jil (from l, to j, via i)
            l = size(psphi%S1) ! Use the variable 'l' for a second to allocate all vectors to same size:
            allocate(CosSAngles(l),STAT=l)
              call debugmsg(4,"MieAlgorithmFF","Allocation status of allocate(CosSAngles(size(psphi%S1))) = ", l)
            step = 0
            do j = 1, Nsph; psphj => sphmgr%getSphere(j)  ! Iterator loop over all spheres -> target
                if(j==i) then; step = step + i - 1; cycle; end if ! j /= i (scattering cannot happen towards self)
                dr = psphj%getPosition() - rsphi ! From present sphere to its target
                do l = 1, Nsph; psphl => sphmgr%getSphere(l)  ! Iterator loop over all spheres -> source
                    if(j<=l) then; cycle; end if ! j > l (lower triangle)
                    if(l==i) then; step = step + 1; cycle; end if ! l /= i (scattering must come from a different sphere)
                      call debugmsg(4,"MieAlgorithmFF","--       (i,j,l,step,arg) = ", (/ i, j, l, step, l+(j-1)*(j-2)/2 - step /))
                    dr_in = rsphi - psphl%getPosition() ! From a source to the present sphere
                      call debugmsg(6,"MieAlgorithmFF","dr(j,i) = ",dr)
                      call debugmsg(6,"MieAlgorithmFF","dr_in(i,l) = ",dr_in)
                    CosSAngles(l+(j-1)*(j-2)/2 - step) = calcCosSAngle(dr,dr_in,i,j,l)
                      call debugmsg(6,"MieAlgorithmFF","--CosSAngle(arg) = ", CosSAngles(l+(j-1)*(j-2)/2-step))
                      call debugmsg(4,"MieAlgorithmFF","--SAngle(arg) = ", acos(CosSAngles(l+(j-1)*(j-2)/2 - step))*180/pi_d)
                end do; nullify(psphl)
            end do; nullify(psphj)
            ! Compute with a batch of scattering angles:
            !  Then the Mie algorithm is effectively a lot faster, since Bessel functions etc. may be re-used.
            call scatterer%scatter(psphi%getX(), psphi%getRefrel(), CosSAngles, psphi%S1, psphi%S2)
            ! psphi now has its scattering matrices filled (except for the constant backscattering term, to be computed later.) 
              call debugmsg(6,"MieAlgorithmFF","The scattering angles for this sphere are: ", acos(CosSAngles)*180/pi_d)
              call debugmsg(6,"MieAlgorithmFF","The scattering matrix for this sphere is psphi%S1: ", psphi%S1)
              call debugmsg(6,"MieAlgorithmFF","The scattering matrix for this sphere is psphi%S2: ", psphi%S2)
            deallocate(CosSAngles)

            ! Compute the backscattering matrix, which is required N^2 times (but is constant): [S]_jij
            !  I do not make the assumption that x and refrel are the same for each sphere.
            !  I'll remain general at the expense of storing N of the same matrices in case x and refrel are equal.
            call scatterer%scatter(psphi%getX(), psphi%getRefrel(), (/ -1d0 /), psphi%S1_bs, psphi%S2_bs)
              call debugmsg(5,"MieAlgorithmFF","The backscattering matrix for this sphere is (/S1, S2/): ",&
                            (/psphi%S1_bs, psphi%S2_bs/))
            
           end if ! conv_maxp >  2
           end if ! conv_maxp >= 2
        end do; nullify(psphi)

        write(6,*) printLocalElapsedTime()
    end subroutine

    subroutine multiScatter()
        integer :: i,j,l,step            ! counters for spheres
        integer :: itNum                            ! Iteration number == (scat. order - 2 == p-2)
        integer :: Nsph
        class(Sphere), pointer :: psphi, psphl, psphj ! From sphere l via sphere i to sphere j
        real*4 :: rsphi(3)                     ! position of sphere i
        real*4 :: dr(3), dr_in(3)                 ! direction and magnitude from source via scatterer to target
        complex :: eField_tmp(3)             ! Temporarily store the eField in this variable for accumulation
        double precision :: maxENew          ! To do automagical convergence criterion
        double precision, parameter :: maxENewCriterion = 1d-8 ! Set to some number. 1d-4 would be 0.01% of incident light.
        !OLD: complex(8) :: temp(3)										! Temp for maxENew
        logical :: continueIterating       

        Nsph = sphmgr%getNumSpheres()
        
        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call debugmsg(1, "MieAlgorithmFF","Starting multiScatter routine. Iterating over all " // & 
                          "scattering orders unless already converged.")
        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call flush(6) ! Important progress point -> flush stdout

        call startSubClock()

        maxENew = 0
        do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres: scatterer
            maxENew = max(maxENew, maxval(sqrt(real(sum(psphi%eField_new*conjg(psphi%eField_new), dim=1))))) ! Maximum value of modulus of new E field over spheres ! OLD: sum(..,dim=2)/dble(Nsph-1) ! Average over other spheres of new Ex, Ey, and Ez scattering via this sphere.
        end do; nullify(psphi)
        !OLD: maxENew = maxENew/dble(Nsph) ! Average over spheres of new light scattering via each sphere
        call debugmsg(2,"MieAlgorithmFF","MaxENew = ",maxENew)

        ! Check new contributions and divide by the amplitude of incoming light which is now just 1. Currently, the demand is that the bounced-around light is not yet reduced to (maxENewCriterion*100)% of the incoming light 
        continueIterating = maxENew > maxENewCriterion

        ! Iterate until convergence
        itNum = 0
        do while (continueIterating)
        ! Prepare iteration
            itNum = itNum + 1 
            call debugmsg(1, "MieAlgorithmFF","**** multiScatter: scattering order p = ", (itNum+2))
            call flush(6) ! Important progress point -> flush stdout
            do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres: scatterer
                call psphi%nextIteration 
                  call debugmsg(8,"MieAlgorithmFF","this%eField_new (outside routine) ", psphi%eField_new)
                  call debugmsg(8,"MieAlgorithmFF","this%eField_old (outside routine) ", psphi%eField_old)
            end do; nullify(psphi)
            
        ! Iterate: For each sphere i, scatter to each sphere j~=i from each sphere l~=i.
            do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres: scatterer
                rsphi = psphi%getPosition()
                step = 0
                  call debugmsg(3,"MieAlgorithmFF","-- (j>l) Storage: +=psphj%eField_new(:,i). (i) = ", i)
                do j = 1, Nsph; psphj => sphmgr%getSphere(j)  ! Iterator loop over all spheres: target
                    if(j==i) then; step = step + i - 1; cycle; end if ! j /= i (scattering cannot happen towards self)
                    ! E_ji^new = Psi_ji sum_l [S]_jil E_il^old
                    dr = psphj%getPosition() - rsphi
                    do l = 1, j-1; psphl => sphmgr%getSphere(l)  ! Iterator loop over all spheres: source ! j > l (lower triangle)
                        if(l==i) then; step = step + 1; cycle; end if ! l /= i (scattering cannot happen from self)
                        ! First: do this for l = source, j = target
                        dr_in = rsphi - psphl%getPosition()
                          call debugmsg(4,"MieAlgorithmFF","-- (j>l) Storage: +=psphj%eField_new(:,i). (i,j,l,step,arg) = ",&
                                            (/ i, j, l, step, l+(j-1)*(j-2)/2 - step /))
                        call SMatrix2EField(psphi%S1(l+(j-1)*(j-2)/2 - step),psphi%S2(l+(j-1)*(j-2)/2 - step),dr,&
                                            dr_in,psphi%eField_old(:,l),eField_tmp)
                        psphj%eField_new(:,i) = psphj%eField_new(:,i) + eField_tmp ! E_ji ~ sum over all l

                        ! Second: do this for j = source, l = target (roles INTERCHANGED!)
                        !  This is equivalent to running the case j<l, but executed in an order which allows me to
                        !   move through the scattering matrix (stored in a packed vector format) sequentially, without any jumps.
                        !   So, instead of considering j<l, I consider j>l only, but interchange the role of j and l.
                        !    Evidently, this is equivalent.
                        !  Note that the index of the scattering matrix remains unchanged. It is only defined for j>l.
                        !   The case with l>j requires to use the scattering matrix with the indexes switched (transpose).
                        !   But we already have the roles of l and j switched, so the index is already the right one.
                          call debugmsg(4,"MieAlgorithmFF","Interchanging role of j and l: 'l>j'. &
                                            Storage: +=psphl%eField_new(:,i).")
                        call SMatrix2EField(psphi%S1(l+(j-1)*(j-2)/2 - step),psphi%S2(l+(j-1)*(j-2)/2 - step),-dr_in,&
                                            -dr,psphi%eField_old(:,j),eField_tmp)
                        psphl%eField_new(:,i) = psphl%eField_new(:,i) + eField_tmp ! E_li ~ sum over all j
                    end do; nullify(psphl)
                    ! Third: the case that j==l (backscattering) -> use the backscattering matrix:
                    !  By construction, [S]_bs is vector of size 1, hence the (1).
                      call debugmsg(4,"MieAlgorithmFF","-- (j=l) Storage: +=psphj%eField_new(:,i). (i,j) = ",(/ i, j/))
                    call SMatrix2EField(psphi%S1_bs(1),psphi%S2_bs(1),dr,&
                                        -dr,psphi%eField_old(:,j),eField_tmp)
                    psphj%eField_new(:,i) = psphj%eField_new(:,i) + eField_tmp ! E_ji ~ sum over all l
                end do; nullify(psphj)
            end do; nullify(psphi)
            ! Finished the intersphere multiscattering process.

              call debugmsg(3,"MieAlgorithmFF"," Finished the present MultiScattering iteration... &
                                                    Accumulating the result. p = ", (itNum+2))
            
        ! Accumulate
            ! Store the result in the accumulator to scatter this scattering order to the camera later.
            !  E_ji^accum += E_ji^new
            maxENew = 0
            do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres: scatterer
                maxENew = max(maxENew, maxval(sqrt(real(sum(psphi%eField_new*conjg(psphi%eField_new), dim=1))))) ! Maximum value of modulus of new E field over spheres
                psphi%eField_acm(:,:) = psphi%eField_acm(:,:) + psphi%eField_new(:,:)
                call debugmsg(4,"MieAlgorithmFF","Multiscattering result: i  = ", i)
                call debugmsg(4,"MieAlgorithmFF","Multiscattering result: E_il^new(xyz,l)  = ", psphi%eField_new(:,:))
                call debugmsg(4,"MieAlgorithmFF","Multiscattering result: E_il^acm(xyz,l)  = ", psphi%eField_acm)
            end do; nullify(psphi)
		!OLD: maxENew = maxENew/dble(Nsph) ! Average over spheres of average over all other spheres of new light scattering via each sphere
		call debugmsg(2,"MieAlgorithmFF","MaxENew = ",maxENew)
            
        ! Convergence criterion: Until p=conv_maxp (iterating inclusively) or when the bounced-around light is reduced to (maxENewCriterion*100)% of the incoming light at each sphere
            continueIterating = ( itNum+2 < conv_minp .or. itNum+2 < conv_maxp) .and. maxENew > maxENewCriterion
        end do

          call debugmsg(2,"MieAlgorithmFF","Finished multiscattering routine. Deallocating. p_max = ", (itNum+2))

    ! Finish multiscatter: deallocate scattering matrix (NOT eField! We still need that one for the camera!)
        do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres
            call psphi%deallocateS
        end do; nullify(psphi)

        write(6,*) printLocalElapsedTime()
    end subroutine

    subroutine scatter2Camera()
        real*4, allocatable :: r_cam(:,:)   ! position of the camera pixels
        real*4 :: rsphi(3)                     ! position of sphere i
        real*4 :: dr(3), dr_in(3)                 ! direction and magnitude from source via scatterer to target
        integer :: numPixels, Nsph          ! maximum loop counters
        integer :: c, i, l                  ! counter
        class(Sphere), pointer :: psphi, psphl
        complex, allocatable :: eField(:,:) ! size = (xyz,nPixel)
        real*8, allocatable :: CosSAngles(:)    ! All scattering angles which require computation; size = (numAngles = number of targets)
        complex, allocatable :: S1(:), S2(:)    ! The scattered amplitude matrices; size = (numAngles)

        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call debugmsg(1, "MieAlgorithmFF","Starting scatter2Camera routine. Iterating over all spheres.")
        call debugmsg(2, "MieAlgorithmFF","************************************************************")
        call flush(6) ! Important progress point -> flush stdout
        
        call startSubClock()

        r_cam = cam%getPixelCoords()
        numPixels=size(r_cam(1,:))
        call debugmsg(4,"MieAlgorithmFF","numPixels = ", numPixels)
        allocate(eField(3,numPixels))
	if(conv_maxp >= 1) then
		Nsph = sphmgr%getNumSpheres()
		allocate(CosSAngles(numPixels*Nsph)) ! For each pixel, Nsph-1 source spheres plus the incident field = Nsph sources.
		allocate(S1(numPixels*Nsph),S2(numPixels*Nsph))
		do i = 1, Nsph; psphi => sphmgr%getSphere(i)  ! Iterator loop over all spheres: scatterer
		    	rsphi = psphi%getPosition()
			! Compute [S]_cil (including "l==i", where l=i refers to the case of the incident wave (p=1 scat. order))
			!  And thus l does not refer to a sphere in this case.
			call debugmsg(2,"MieAlgorithmFF","Computing scattering matrices (sphere l via sphere i to camera pixel c), i=",i)
            call flush(6) ! Important progress point -> flush stdout
			do l = 1, Nsph; psphl => sphmgr%getSphere(l)  ! Iterator loop over all spheres: source
				if(l==i) then ! "l==i" is used for the incident field. I.e., l does not refer to a sphere here.
					dr_in = kihat
				else
					dr_in = rsphi - psphl%getPosition()
				end if
				do c = 1, numPixels ! Loop over all camera pixels: target
					dr = r_cam(:,c) - rsphi
					call debugmsg(5,"MieAlgorithmFF","--       (i,c,l,arg) = ", (/ i, c, l, c+numPixels*(l-1) /)) 
					!CosSAngles(c+numPixels*(l-1)) = dot_product(dr,dr_in)/&
					!                (sqrt(dot_product(dr,dr))*sqrt(dot_product(dr_in,dr_in)))
					CosSAngles(c+numPixels*(l-1)) = calcCosSAngle(dr,dr_in,i,c,l)
				end do 
			end do; nullify(psphl)
			call scatterer%scatter(psphi%getX(), psphi%getRefrel(), CosSAngles, S1, S2) ! We now have all i-to-c scattering matrices for all c.
			call debugmsg(4,"MieAlgorithmFF","The i2c scat. angles for this sphere are: ", acos(CosSAngles)*180/pi_d)
			call debugmsg(4,"MieAlgorithmFF","The i2c scat. matrix for this sphere is S1_cil (i cnst): ", S1)
			call debugmsg(4,"MieAlgorithmFF","The i2c scat. matrix for this sphere is S2_cil (i cnst): ", S2)
		    
			! Compute E_ci += [S]_cil E_il^accum
			! Compute E_ci = Psi_ci E_ci (spherical wave factor "Psi=exp(ikr)/-ikr" may be done later)
			call debugmsg(3,"MieAlgorithmFF","Computing electric fields on the camera. i=",i)
			do l = 1, Nsph; psphl => sphmgr%getSphere(l)  ! Iterator loop over all spheres: source
		        	if(l==i) then ! "l==i" is used for the incident field. I.e., l does not refer to a sphere here.
					dr_in = kihat
				else
					dr_in = rsphi - psphl%getPosition()
				end if
				do c = 1, numPixels ! Loop over all camera pixels: target
					dr = r_cam(:,c) - rsphi
					call debugmsg(4,"MieAlgorithmFF","--       (i,c,l,arg) = ", (/ i, c, l, c+numPixels*(l-1) /)) 
					call SMatrix2EField(S1(c+numPixels*(l-1)),S2(c+numPixels*(l-1)),dr, &
										dr_in,psphi%eField_acm(:,l),eField(:,c))
				end do 
				call debugmsg(5,"MieAlgorithmFF","eField(xyz,{c}) for present i,l = ", eField);
				! E_c = sum_i sum_l [S]_cil E_il Psi_il with Psi_il spherical wave factor
				!  The sum is performed inside cam%addEField. We are currently inside a loop over both i and l.
				call cam%addEField(eField)
			end do; nullify(psphl)
			! Clear [S]_cil ... But we need not, since the next loop will simply overwrite.
		end do; nullify(psphi)
		deallocate(CosSAngles,S1,S2) ! Deallocate here, not inside loop. The mem is reused inside the loop by overwriting for each i.
	endif ! conv_maxp >= 1

	! Add the (p=0) term to the camera. I.e., the direct incident field, without being scattered by any sphere.
	if (dop0) then
		do c = 1, numPixels ! Loop over all camera pixels: target
			eField(:,c) = Eihat * exp(COMPLEX(0,1)*k*dot_product(r_cam(:,c),kihat)) ! exp(i k_0 dot_product r_trgt); k_0 = k kihat;
		end do 
		call debugmsg(4,"MieAlgorithmFF","E_c^{p=0} [effect of the incident field on the camera] = ",eField)
		call cam%addEField(eField)
	end if
        deallocate(eField)

        write(6,*) printLocalElapsedTime()
    end subroutine

! Converts the SMatrix to the EField
!  Simply put: Es = [S] Ei * (spherical wave factor)
!  No allocation is done in this subroutine.
    subroutine SMatrix2EField(S1,S2,dr,k_in,Ei,Es)
        class(Sphere), pointer :: psph      ! Pointer to the 'current' sphere in the iterator loop 
        complex, intent(in) :: S1, S2       ! The scattered amplitude matrix
        real*4, intent(in) :: dr(3)         ! Direction and distance from the first particle (scatterer) to the target
        real*4, intent(in) :: k_in(3)       ! Direction of the incident field (any length vector)
        real*4             :: khatin(3)     ! Direction of the incident field (unit vector)
        complex, intent(in) :: Ei(3)        ! Incident electric field
        complex, intent(out) :: Es(3)       ! Scattered electric field at the position of the target
        
        real*4 :: Eihat_p(3)     ! Unit vector in the direction perpendicular to the scattering plane; Eihat_l = Eihat_p x kihat (xyz)
        real*4 :: Eihat_l(3)     ! Unit vector in the direction orthogonal to kihat, but within the scattering plane (xyz)
        real*4 :: Eshat_l(3)     ! Unit vector in the direction orthogonal to kihat_scattered, but within the scattering plane (xyz)
            ! kihat x Eihat_l = Eihat_p = Eshat_p = dr x Eshat_l = Eihat_p
        
        complex :: Eil        ! Incident  parallel      component of electric field
        complex :: Eip        ! Incident  perpendicular component of electric field
        complex :: Esl        ! Scattered parallel      component of electric field
        complex :: Esp        ! Scattered perpendicular component of electric field

        real*4 :: r
        complex :: ikr

        call debugmsg(6,"MieAlgorithmFF","/------------ S2E begin ------------\")

        khatin = k_in / sqrt(dot_product(k_in,k_in))

        call debugmsg(5,"MieAlgorithmFF","Ei = ", Ei)

        ! Scattering direction = r_target - r_sphere. This was input to this subroutine in dr. r is its length.
        r = sqrt(dot_product(dr,dr))
        call debugmsg(6,"MieAlgorithmFF","dr = ", dr)
        call debugmsg(6,"MieAlgorithmFF","k_in = ", k_in)
        call debugmsg(6,"MieAlgorithmFF","r = ", r)
        
    ! Determine the scattering plane in terms of the perpendicular and parallel component of the Efield:
        Eihat_p = cross_product(khatin,dr)
        call debugmsg(6,"MieAlgorithmFF","Eihat_p (1st guess) = ", Eihat_p)
        if(dot_product(Eihat_p,Eihat_p) .eq. 0) then
            ! null-vector. I.e., we do not have a scattering plane, but a scattering line.
            ! Define Eihat_p arbitrarily, but still orthogonal to khatin (and thus dr): Say // Ei.
            Eihat_p = cross_product(khatin,xhat)
            call debugmsg(6,"MieAlgorithmFF","Eihat_p was zero. (2nd guess) = ", Eihat_p)
            !if(ALL(Eihat_p == (/ 0., 0., 0. /))) then
            if(dot_product(Eihat_p,Eihat_p) .eq. 0) then
                Eihat_p = cross_product(khatin,yhat)
                call debugmsg(6,"MieAlgorithmFF","Eihat_p was zero. (3rd guess) = ", Eihat_p)
            end if
!            if(dot_product(khatin,Eihat_p) .ne. 0) then !TODO: Find Eihat_p such that this error may be removed.
!                if(abs(dot_product(khatin,Eihat_p)) .gt. 1E-9) then !TODO: Find Eihat_p such that this error may be removed.
!                    write(0,*) "---ERROR--- MieAlgorithmFF.S2E: Specified kihatin and Eihat_p are not orthogonal.&
!                            Found the following inner product: ", &
!                            dot_product(khatin,Eihat_p)
!                    call exit(0)
!                end if
!                write(0,*) "---WARNING--- MieAlgorithmFF.S2E: Specified kihatin and Eihat_p are not orthogonal.&
!                        Found the following inner product: ", &
!                        dot_product(khatin,Eihat_p)
!            end if
        end if
        ! Good Eihat_p! But we need to normalise it.
        Eihat_p = Eihat_p / sqrt(dot_product(Eihat_p,Eihat_p))
        Eihat_l = cross_product(Eihat_p,khatin) ! CP with khat_initial
        Eshat_l = cross_product(Eihat_p,dr)     ! CP with khat_scattered
            Eshat_l = Eshat_l / sqrt(dot_product(Eshat_l,Eshat_l))
        call debugmsg(6,"MieAlgorithmFF","Eihat_p = ", Eihat_p)
        call debugmsg(6,"MieAlgorithmFF","Eihat_l = ", Eihat_l)
        call debugmsg(6,"MieAlgorithmFF","Eshat_l = ", Eshat_l)
        
    ! Determine the parallel and perpendicular component of the incident electric field
        Eil = dot_product(Ei,Eihat_l)
        Eip = dot_product(Ei,Eihat_p)
        
        call debugmsg(6,"MieAlgorithmFF","Eil = ", Eil)
        call debugmsg(6,"MieAlgorithmFF","Eip = ", Eip)
        
        call debugmsg(5,"MieAlgorithmFF.S2E","(S1(p),S2(l)) = ", (/ S1, S2 /))
    ! Determine the scattered electric field (l and p component), without the r-dependent phase
        Esl = S2 * Eil
        Esp = S1 * Eip
        
        call debugmsg(6,"MieAlgorithmFF","Esl = ", Esl)
        call debugmsg(6,"MieAlgorithmFF","Esp = ", Esp)
        
    ! Determine the scattered electric field (in xyz components), without the r-dependent phase, but including the initial phase
        Es = Esl*Eshat_l + Esp*Eihat_p
        
        call debugmsg(6,"MieAlgorithmFF","Es = ", Es)
        
    ! Include the distance to the target (phase delay, and spherical wave amplitude drop): exp(ikr)/(-ikr)
        ! The phase delay is exp(i k dot_product (r_target-r_source)) = exp(i (k dr_hat) dot_product dr) == exp(ikr)
        ikr = COMPLEX(0,1)*k*r
        call debugmsg(6,"MieAlgorithmFF","ikr = ", ikr)
        call debugmsg(6,"MieAlgorithmFF","exp(ikr)/(-ikr) = ", exp(ikr)/(-ikr))
        Es = Es * exp(ikr)/(-ikr)
        call debugmsg(5,"MieAlgorithmFF","Es = ", Es)
    ! Done, EXCEPT for a factor exp(-iwt). But if we report on the intensity, it will drop out anyway.
        call debugmsg(6,"MieAlgorithmFF","\------------ S2E end ------------/")
    end subroutine SMatrix2EField

    function calcCosSAngle(r1,r2,i,j,l) result(csa)
        real*4, intent(in) :: r1(3), r2(3) ! Two vectors which span an angle.
        real*8 :: csa ! cos(spanned angle), cos(scattering angle)
        real*4 :: ip0, ip1, ip2
        integer, intent(in) :: i,j,l ! Indices of particles involved. Only used for an informative error message.
        
        ip0 = dot_product(r1,r2)
        ip1 = dot_product(r1,r1)
        ip2 = dot_product(r2,r2)

        if (ip1 .lt. 1e-40 .or. ip2 .lt. 1e-40 .or. ip1*ip2 .lt. 1e-40) then ! technically, the smallest number is ~1.7xxxxxxxe-38, but at reduced precision in the non-exponent, it can go to e-7*e-38=e-45.. so let's just take 40..
            write(0,*) "---ERROR--- Particles are pretty much on top of each other."
            write(0,*) "             r1=",r1,", r2=",r2
            write(0,*) "             ip0=",ip0,", ip1=",ip1,", ip2=",ip2
            write(0,*) "             Involved particles: i=",i,", j=",j," l=",l
            call exit(1)
        end if

        ! Cosine law for inner products.
        csa = ip0/sqrt(ip1*ip2)

	call debugmsg(5,"cos(angle) calculator","ip0 = ", ip0)
	call debugmsg(5,"cos(angle) calculator","ip1 = ", ip1)
	call debugmsg(5,"cos(angle) calculator","ip2 = ", ip2)
	call debugmsg(5,"cos(angle) calculator","csa = ", csa )
        ! Bounds checking. Will result in NaN intensity otherwise. Interesting only for small transgressions beyond +- 1
	! Weirdness: managed to get NaN regardless of these checks.. so something must've been NaN beforehand!
	! Ofcourse there was.... if ip1*ip2 is smaller than the smallest representable number, than bam, csa = NaN...
	! And then these bound checks will not do anything
	! These bound-checks seem nice.. but there is also such a thing as +-Infinity (instead of NaN).. 
	! Then these boundchecks fix it, while it should not be fixed
	! It all boils down to making sure particles are not on top of one another, and exit if they are.
        if(csa>1) csa=1
        if(csa<-1) csa=-1
    end function calcCosSAngle

! /************************\
! |    	Public Subroutines  		 |
! \************************/
        
    subroutine run(inputfile)
        character(len=*) :: inputfile

        call debugmsg(0,"Starter",timestamp())
        call startClock()
        call init(inputfile)    ! Read input parameters, declare constants, instantiate objects

        if(conv_maxp >= 1)&      ! Only do initialScatter() for p>=1. I.e., when the spheres matter at all.
            call initialScatter()   ! Call the scatter logic for the incident PW

        if(conv_maxp > 2)&       ! Only do multiScatter() for p>=3. These scattering orders do not directly relate to the incident field.
            call multiScatter()     ! Call the scatter logic for the multiscattering process

        call scatter2Camera()   ! Scatter the fields of all scattering orders, accumulated at the spheres, to the camera

        call output()           ! Write output fields

        write(6,*) printGlobalElapsedTime()
        call debugmsg(0,"Starter",timestamp())
    end subroutine run
    
end module MieAlgorithmFF








! EOF
