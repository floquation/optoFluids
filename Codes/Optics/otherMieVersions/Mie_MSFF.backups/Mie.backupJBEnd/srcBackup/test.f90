module Polymers

  implicit none
  private


    logical, parameter, public :: DEBUG = .false.
    REAL, PARAMETER :: PI = 3.1415927

    public polymer
    type polymer
        private

        real(8), allocatable :: pos(:,:)    !Bead positions
        real(8) :: phi_last                 !Angle with x-axis of the line connecting the last 2 beads
        real(8) :: weight, weight3                   !Current potential energy stored in the polymer: exp(-beta*E)

    contains
    private

        procedure, public :: destroy
        procedure, public :: create
        procedure, public :: add_bead
        procedure, public :: toString
        procedure         :: computeAddedEnergy
        procedure         :: setDuplicateVars
        procedure         :: duplicate

    end type

!Polymers variables
    integer, public :: max_poly_length, max_num_poly    !cst from input
    integer, public :: num_thetha                       !cst from input
    real(8), public :: temperature                      !cst from input
    real(8), public :: alpha_UpLim, alpha_LowLim        !cst from input
    !Variables that change over-time (I separate them for multi-threading reasons):
    type(polymer), public, allocatable :: polymerList(:) !Contains all fully-grown polymers
    integer, public, allocatable :: threadPolymerList(:) !Contains the thread# which created the polymer at the given polymer-index from polymerList
    integer, public :: cur_num_poly = 0
    real(8), public, allocatable :: avWeight(:)         !Average weight as function of polymer length
    integer, public, allocatable :: avWeightSize(:)     !Number of samples within the averaging. Used to add a new number to the average: av_new = (av_old*N_old+new_value)/(N_old+1)
    real(8), public :: greatest_duplication_fraction    !Do not duplicate polymers after a certain length has been reached.
    real(8), public :: sigma                            !LJ Potential variable

contains

!This subroutine adds a polymer to our database;
    subroutine addPolymer(p)
        type(polymer), intent(in):: p
        integer :: omp_get_thread_num
    !$OMP CRITICAL (polyListWriting)
        if(cur_num_poly < max_num_poly) then
            cur_num_poly = cur_num_poly + 1
            polymerList(cur_num_poly) = p
            threadPolymerList(cur_num_poly) = omp_get_thread_num();
            print *, 'Polymer added. Currently we have ... polymers.', cur_num_poly
        else
            print *, 'WARNING: polymerList is full, but still trying to add more polymers'
        end if
    !$OMP END CRITICAL (polyListWriting)
    end subroutine addPolymer

  subroutine create(this,N)
    class(polymer) :: this
    integer, intent(in) :: N !max # of beads

  !Allocate vars
    allocate (this%pos(2,N))
  !Create initial beads
    this%pos(1,1) = 0d0
    this%pos(2,1) = 0d0
    this%pos(1,2) = 1d0
    this%pos(2,2) = 0d0
    this%phi_last = 0
  !Compute initial energy !Should return zero, because we take LJsigma = 1.
    this%weight = exp(-this%computeAddedEnergy(2)/temperature)
  end subroutine

  subroutine destroy(this)
    class(polymer) :: this

  !Deallocate vars
    deallocate(this%pos)
  end subroutine

!Adds a bead to "this". If it is fit, the polymer will branch [without duplicating].
!Once any polymer reaches its maximum length, it is duplicated and added to polymerList.
!Once a polymer is too weak, the method will return. No polymer is destroyed, since the same polymer instance is used.
!So: one instance (A) is used to grow many different polymers.
!Fully grown polymers are duplicated, while we continue to overwrite A to grow new polymers from a different branch of A.
!If A dies, a new A is created in the main loop. (Each thread, j, owns its own A_j as well.)
  recursive subroutine add_bead(this,level)
    class(polymer) :: this
    integer, intent(in) :: level
    integer :: j
    real(8) :: phi, thetha, cur_weight, rndm
    real(8), allocatable :: w(:)

    if(cur_num_poly >= max_num_poly)then
        return !Force the recursion to stop immediately, once we already have enough polymers.
    end if

    !Allocate arrays
    allocate(w(num_thetha))

    !Find the thetha's and their associated energy values
    do j = 1, num_thetha
        thetha = 2 * PI * (j) / num_thetha
        !print *, ' thetha = ', thetha

        !new angle w.r.t. x-axis
        !print *, 'phi_last =', this%phi_last
        phi = this%phi_last + thetha

        !Add a 'ghost' bead to the polymer
        this%pos(1,level) = this%pos(1,level-1) + cos(phi) !x of new bead
        this%pos(2,level) = this%pos(2,level-1) + sin(phi) !y of new bead

        !Computes the ADDED energy (compares newest bead with all old beads):
        w(j) = exp(-this%computeAddedEnergy(level)/temperature) !Note that we do not need the old energy, because it will appear in every w(j): exp(-Eold/T)*exp(-Ej/T) and thus will not affect the probability.
    end do

    !Find the winning thetha
    j = rouletteWheel(w)

    !Add the actual bead and energy to the polymer
    thetha = 2 * PI * (j) / num_thetha
    phi = this%phi_last + thetha
    this%pos(1,level) = this%pos(1,level-1) + cos(phi)
    this%pos(2,level) = this%pos(2,level-1) + sin(phi)
    this%weight = this%weight * w(j)
    this%phi_last = phi

    !Multiply polymer weight by a constant:
    this%weight = this%weight / (0.75 * num_thetha) !TODO: Doesn't behave properly

    !Manipulate other weight variables:
    !$OMP CRITICAL (avWeight)
    !Atomic block: only 1 thread may change these variables at the same time. The two variables are closely connected.
    avWeight(level) = (avWeight(level)*avWeightSize(level)+this%weight)/(avWeightSize(level)+1) !Update average weigth
    avWeightSize(level) = avWeightSize(level)+1
    !$OMP END CRITICAL (avWeight)

    if(level==3) then
        this%weight3 = this%weight  !Store weigth at length 3 for the UpLim and LowLim calculation
        this%weight3 = 1 !TODO: OVERWRITE
    end if

    !Clean-up current iteration
    deallocate(w)

    !Prepare the next iteration
    if(level < max_poly_length) then
        !Continue recursively
        if(DEBUG)print *, level, 'weight = ', this%weight, 'lowLim = ', (alpha_LowLim * avWeight(level)/this%weight3), &
            'highLim = ', (alpha_UpLim * avWeight(level)/this%weight3), 'weight3 = ', this%weight3
        if(this%weight <= alpha_LowLim * avWeight(level)/this%weight3) then !Equals sign kills zero weight polymers guaranteedly
            call random_number(rndm)
            if(rndm<0.5) then
                this%weight = this%weight * 2
                call this%add_bead(level+1)
            else
                 if(DEBUG)print *, 'kill a polymer'
            end if
        else if(this%weight > alpha_UpLim * avWeight(level)/this%weight3 .AND.&
             level < greatest_duplication_fraction*max_poly_length) then
            if(DEBUG)print *, 'duplicate a polymer'
            cur_weight = this%weight        !Required because I am re-using the same polymer instance. This%weight gets to be overwritten by the first add_bead and thus would be corrupted for the second.
            this%weight = 0.5 * cur_weight
            call this%add_bead(level+1)
            this%weight = 0.5 * cur_weight
            this%phi_last = phi             !Required for the same corruption reason, even though this would have been no biggy; we would simply have had other thetha steps than {Pi/N, 3Pi/2N, ...}, i.e., {Pi/N-phi, 3Pi/2N -phi, ...}. No problem.
            call this%add_bead(level+1)
        else
            call this%add_bead(level+1) !Normal recursion
        end if
    else
         if(DEBUG)print *, 'finished growing: maximum length reached; CurNumPoly = ', cur_num_poly+1
        !Finished growing; end recursion:
        call addPolymer(this%duplicate())
    end if
  end subroutine add_bead

!Potential Energy Computation
  function computeAddedEnergy(this, level) result(Eout)
    class(polymer) :: this
    integer, intent(in) :: level
    real(8):: Eout
    real(8) :: rSq
    integer:: i

    Eout = 0
    do i = 1, level-1
        rSq = (this%pos(1,level)-this%pos(1,i))**2 + (this%pos(2,level)-this%pos(2,i))**2
        Eout = Eout + 4 * ( (sigma**2/rSq)**6 - (sigma**2/rSq)**3 ) !0.25 and 0.5 are sigma^12 resp. sigma^6 for sigma = 2^(-1/6). I.e., the equilibrium distance == 1

        !print *, ' rSq = ', rSq, 'Eout = ', Eout
    end do
    !print *, 'Eout = ', Eout

  end function computeAddedEnergy

!Monte Carlo Probability
  function rouletteWheel(w) result(i)
    real(8), intent(in) :: w(:)
    integer :: i
    real(8):: rndm
    real(8) :: Wtot

    !Scale the random number between 0 and sum(w) (instead of dividing w by sum(w) which may give division by 0 for poor polymers).
    Wtot = sum(w)
    call random_number(rndm)
    rndm = rndm * Wtot

    Wtot = 0
    do i = 1, size(w)
        Wtot = Wtot + w(i)
        if(rndm<=Wtot) then
            return
        end if
    end do

  end function rouletteWheel

!DUPLICATION
  function duplicate(this) result(poly)
    class(polymer) :: this
    type(polymer) :: poly
    integer :: N
    real(8), allocatable:: pos_new(:,:)
    integer:: i

    N = SIZE(this%pos(1,:))

    allocate(pos_new(2,N))

    !Duplicate all arrays
    do i = 1, N
        pos_new(:,i) = this%pos(:,i)
    end do

    !Create the polymer
    call poly%create(N)
    call poly%setDuplicateVars(pos_new,this%phi_last,this%weight)
  end function

  subroutine setDuplicateVars(this, posIn, phiIn, weightIn)
    class(polymer) :: this
    real(8), intent(in) :: posIn(:,:), phiIn, weightIn

    this%phi_last = phiIn
    this%pos = posIn
    this%weight = weightIn

  end subroutine setDuplicateVars

!Write the position data to the files given by filehandles 'fileX' and 'fileY'
  subroutine toString(this, fileX, fileY)
    class(polymer) :: this
    integer, intent(in) :: fileX
    integer, intent(in) :: fileY
    integer :: i

    do i = 1,max_poly_length-1
        write (fileX,'(E10.4,", ")', advance='no') this%pos(1,i)
        write (fileY,'(E10.4,", ")', advance='no') this%pos(2,i)
    end do
    write (fileX,'(E10.4)', advance='yes') this%pos(1,i)
    write (fileY,'(E10.4)', advance='yes') this%pos(2,i)

  end subroutine toString


end module Polymers

