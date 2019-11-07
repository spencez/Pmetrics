! MODULE Global variables for DVODE i.e. a COMMON block
! That is shared between all threads
      MODULE dvode_globals

! Double precision
      ! wmy2017Oct18 -- http://www.fortran90.org/src/best-practices.html
      !   and http://fortranwiki.org/fortran/show/Real+precision
      !
      ! note: Both of the following work for non openmp program
      !      integer, parameter:: dp = kind(0.d0)   ! should be equiv. to real*8
        integer, parameter :: dp = selected_real_kind(15, 307) ! 64 bit

! ODE Tolerances
!        real(dp), dimension(20) :: ATOL

      END MODULE
!------------------------------------------------------------------------


! This is an EMPTY subroutine to test the INTERFACE

      SUBROUTINE DVODEEE ( F, NEQ, Y, T, TOUT, ITOL, RtolIn, ATOL, ITASK, &
      ISTATE, IOPT, RWORK, LRW, IWORK, LIW, JAC, MF, RPAR, IPAR )

      use dvode_globals

      EXTERNAL F, JAC

      real(dp), intent(INOUT) :: T, TOUT
      real(dp), dimension(:), intent(INOUT) :: Y, RWORK, RPAR
      real(dp), intent(IN) :: RtolIn
      real(dp), dimension(:), intent(IN) :: ATOL

      integer,  intent(INOUT) :: ISTATE
      integer,  dimension(:), intent(INOUT) :: IWORK, IPAR
      integer, intent(IN) :: NEQ, ITOL, ITASK, IOPT , LRW, LIW, MF

! wmy2017Oct13 --New local variables
      integer JSUB, IG, status
      real(dp) :: RTOL  ! int in main must be RTOL(:) here
      integer latol, lrpar, lipar, lrwork, liwork
      integer lstate   ! 'ly' is a hard search string
      doubleprecision :: tmpfloat01

! Block A.

         tmpfloat01 = 7.0

!         write (*,*) "In DVODE_v01.f90", INIT

         JSUB = ipar(34)
         IG = ipar(35)
         RTOL = RtolIn
         latol = size( ATOL ); lstate = size( Y ); lrwork = size( rwork )
         lrpar = size( RPAR ); lipar = size( IPAR ); liwork = size( iwork )

         write (*,*) "sizeof( ATOL, Y, rwork, iwork, rpar, ipar) =",     &
           latol, lstate, lrwork, liwork, lrpar, lipar
         write (*,*) JSUB, IG, "MF,LIW,LRW,NEQ",MF,LIW,LRW,NEQ
         write (*,*) JSUB, IG, "ITASK,ISTATE,IOPT", ITASK,ISTATE,IOPT
         write (*,*) JSUB, IG, "IWORK",IWORK(1)

         write (*,*) "tmpfloat01", tmpfloat01
         write (*,*) "RTOL", RTOL
         write (*,*) "RtolIn", RtolIn

! All doubles (even scalars) cause Illegal Instruction : 4
!  at first reference:
         write (*,*) JSUB, IG, "ATOL",ATOL(1),ATOL(20)
         write (*,*) JSUB, IG, "RTOL,ITOL",RTOL,ITOL
         write (*,*) JSUB, IG, "RPAR", RPAR(24), RPAR(25)
         write (*,*) JSUB, IG, "Y",Y(1),Y(2),Y(3)
         write (*,*) JSUB, IG, "RWORK",RWORK(1),RWORK(2)
         write (*,*) JSUB, IG, "TIN,TOUT",T,TOUT

         write (*,*) JSUB, IG, "Testing ISTATE", ISTATE

         if (JSUB == 2)  then
            write (*,*) "JSUB = 2; exiting"
            call exit(status)
         endif
      RETURN
      END SUBROUTINE DVODEEE

!-----------------------------------------------------------------------
!*DECK DVODE_REAL
      SUBROUTINE DVODE ( F, NEQ, Y, T, TOUT, ITOL, RtolIn, ATOL, ITASK, &
      ISTATE, IOPT, RWORK, LRW, IWORK, LIW, JAC, MF, RPAR, IPAR )

      use dvode_globals

      EXTERNAL F, JAC

! wmy2017Oct18 -- local variable SIZE replaced by SSSIZE b/c calling
!   size() to get length of assumed shape 1D arrays causes compiler
!   to balk at naming a variable SIZE.
!

! wmy2017Oct18 -- These declarations:
!      DOUBLE PRECISION Y, T, TOUT, RTOL, ATOL, RWORK, RPAR
!      INTEGER NEQ, ITOL, ITASK, ISTATE, IOPT, LRW, IWORK, LIW, MF, IPAR
!
! ... are replaced by these declarations:
!
      real(dp), intent(INOUT) :: T
      real(dp), intent(IN) :: TOUT
      real(dp), dimension(:), intent(INOUT) :: Y, RWORK, RPAR

      integer,  intent(INOUT) :: ISTATE
      integer,  dimension(:), intent(INOUT) :: IWORK, IPAR

      real(dp), intent(IN) :: RtolIn
      real(dp), dimension(:), intent(IN) :: ATOL

     integer, intent(IN) :: NEQ, ITOL, ITASK, IOPT , LRW, LIW, MF
!
! wmy 2017Nov15 -- Corrected T and TOUT intent, intent is specified in
! section Part i below
!
! wmy2017Oct18 -- below lines were around line 1050, below. They are
!  moved here and replaced by above declarations
!      DIMENSION Y ( * ), ATOL ( * ), RWORK (LRW), IWORK ( LIW )         &
!        , RPAR ( * ), IPAR ( * )
!

! wmy2017Oct13 -- New local variables
! these are volatile; should not need !$omp ThreadPrivate
      integer JSUB, IG
      double precision :: RTOL
      integer latol, lrpar, lipar, lrwork, liwork
      integer lstate   ! use this instead of 'ly'
!
! note: latol, lrpar, lstate,  not necessary:
!    Only the first NEQ elements of y and atol are accessed;
!    access into rpar and ipar are hard coded and never in
!    a do loop. 'lrwork' = LRW and 'liwork' = LIW, and are
!    passed in as arguments.
!

! wmy2017Nov15 -- Should probably rewrite the ODE to 
!   use RTOL a scalar; an array of length 1 is less
!   portable.
!       save RTOL
! !$omp Threadprivate(RTOL)

!
! wmy2017Oct13 -- Removed \BLAS and \LAPACK routines that are
!   included in other files of the main program, or are now part
!   of GCC : IDAMAX, DAXPY, DCOPY, DDOT, DSCAL, DNRM2 -- Note these
!   subroutines are still included in the file dvodeoriginal.f90,
!   which is the base code from which this file is generated, and
!   where they must be included in order to run example.f90
!

!-----------------------------------------------------------------------
! DVODE: Variable-coefficient Ordinary Differential Equation solver,
! with fixed-leading-coefficient implementation.
! This version is in double precision.
!
! DVODE solves the initial value problem for stiff or nonstiff
! systems of first order ODEs,
!     dy/dt = f(t,y) ,  or, in component form,
!     dy(i)/dt = f(i) = f(i,t,y(1),y(2),...,y(NEQ)) (i = 1,...,NEQ).
! DVODE is a package based on the EPISODE and EPISODEB packages, and
! on the ODEPACK user interface standard, with minor modifications.
!-----------------------------------------------------------------------
! Authors:
!               Peter N. Brown and Alan C. Hindmarsh
!               Center for Applied Scientific Computing, L-561
!               Lawrence Livermore National Laboratory
!               Livermore, CA 94551
! and
!               George D. Byrne
!               Illinois Institute of Technology
!               Chicago, IL 60616
!-----------------------------------------------------------------------
! References:
!
! 1. P. N. Brown, G. D. Byrne, and A. C. Hindmarsh, "VODE: A Variable
!    Coefficient ODE Solver," SIAM J. Sci. Stat. Comput., 10 (1989),
!    pp. 1038-1051.  Also, LLNL Report UCRL-98412, June 1988.
! 2. G. D. Byrne and A. C. Hindmarsh, "A Polyalgorithm for the
!    Numerical Solution of Ordinary Differential Equations,"
!    ACM Trans. Math. Software, 1 (1975), pp. 71-96.
! 3. A. C. Hindmarsh and G. D. Byrne, "EPISODE: An Effective Package
!    for the Integration of Systems of Ordinary Differential
!    Equations," LLNL Report UCID-30112, Rev. 1, April 1977.
! 4. G. D. Byrne and A. C. Hindmarsh, "EPISODEB: An Experimental
!    Package for the Integration of Systems of Ordinary Differential
!    Equations with Banded Jacobians," LLNL Report UCID-30132, April
!    1976.
! 5. A. C. Hindmarsh, "ODEPACK, a Systematized Collection of ODE
!    Solvers," in Scientific Computing, R. S. Stepleman et al., eds.,
!    North-Holland, Amsterdam, 1983, pp. 55-64.
! 6. K. R. Jackson and R. Sacks-Davis, "An Alternative Implementation
!    of Variable Step-Size Multistep Formulas for Stiff ODEs," ACM
!    Trans. Math. Software, 6 (1980), pp. 295-318.
!-----------------------------------------------------------------------
! Summary of usage.
!
! Communication between the user and the DVODE package, for normal
! situations, is summarized here.  This summary describes only a subset
! of the full set of options available.  See the full description for
! details, including optional communication, nonstandard options,
! and instructions for special situations.  See also the example
! problem (with program and output) following this summary.
!
! A. First provide a subroutine of the form:
!           SUBROUTINE F (NEQ, T, Y, YDOT, RPAR, IPAR)
!           DOUBLE PRECISION T, Y(NEQ), YDOT(NEQ), RPAR
! which supplies the vector function f by loading YDOT(i) with f(i).
!
! B. Next determine (or guess) whether or not the problem is stiff.
! Stiffness occurs when the Jacobian matrix df/dy has an eigenvalue
! whose real part is negative and large in magnitude, compared to the
! reciprocal of the t span of interest.  If the problem is nonstiff,
! use a method flag MF = 10.  If it is stiff, there are four standard
! choices for MF (21, 22, 24, 25), and DVODE requires the Jacobian
! matrix in some form.  In these cases (MF .gt. 0), DVODE will use a
! saved copy of the Jacobian matrix.  If this is undesirable because of
! storage limitations, set MF to the corresponding negative value
! (-21, -22, -24, -25).  (See full description of MF below.)
! The Jacobian matrix is regarded either as full (MF = 21 or 22),
! or banded (MF = 24 or 25).  In the banded case, DVODE requires two
! half-bandwidth parameters ML and MU.  These are, respectively, the
! widths of the lower and upper parts of the band, excluding the main
! diagonal.  Thus the band consists of the locations (i,j) with
! i-ML .le. j .le. i+MU, and the full bandwidth is ML+MU+1.
!
! C. If the problem is stiff, you are encouraged to supply the Jacobian
! directly (MF = 21 or 24), but if this is not feasible, DVODE will
! compute it internally by difference quotients (MF = 22 or 25).
! If you are supplying the Jacobian, provide a subroutine of the form:
!           SUBROUTINE JAC (NEQ, T, Y, ML, MU, PD, NROWPD, RPAR, IPAR)
!           DOUBLE PRECISION T, Y(NEQ), PD(NROWPD,NEQ), RPAR
! which supplies df/dy by loading PD as follows:
!     For a full Jacobian (MF = 21), load PD(i,j) with df(i)/dy(j),
! the partial derivative of f(i) with respect to y(j).  (Ignore the
! ML and MU arguments in this case.)
!     For a banded Jacobian (MF = 24), load PD(i-j+MU+1,j) with
! df(i)/dy(j), i.e. load the diagonal lines of df/dy into the rows of
! PD from the top down.
!     In either case, only nonzero elements need be loaded.
!
! D. Write a main program which calls subroutine DVODE once for
! each point at which answers are desired.  This should also provide
! for possible use of logical unit 6 for output of error messages
! by DVODE.  On the first call to DVODE, supply arguments as follows:
! F      = Name of subroutine for right-hand side vector f.
!          This name must be declared external in calling program.
! NEQ    = Number of first order ODEs.
! Y      = Array of initial values, of length NEQ.
! T      = The initial value of the independent variable.
! TOUT   = First point where output is desired (.ne. T).
! ITOL   = 1 or 2 according as ATOL (below) is a scalar or array.
! RTOL   = Relative tolerance parameter (scalar).
! ATOL   = Absolute tolerance parameter (scalar or array).
!          The estimated local error in Y(i) will be controlled so as
!          to be roughly less (in magnitude) than
!             EWT(i) = RTOL*abs(Y(i)) + ATOL     if ITOL = 1, or
!             EWT(i) = RTOL*abs(Y(i)) + ATOL(i)  if ITOL = 2.
!          Thus the local error test passes if, in each component,
!          either the absolute error is less than ATOL (or ATOL(i)),
!          or the relative error is less than RTOL.
!          Use RTOL = 0.0 for pure absolute error control, and
!          use ATOL = 0.0 (or ATOL(i) = 0.0) for pure relative error
!          control.  Caution: Actual (global) errors may exceed these
!          local tolerances, so choose them conservatively.
! ITASK  = 1 for normal computation of output values of Y at t = TOUT.
! ISTATE = Integer flag (input and output).  Set ISTATE = 1.
! IOPT   = 0 to indicate no optional input used.
! RWORK  = Real work array of length at least:
!             20 + 16*NEQ                      for MF = 10,
!             22 +  9*NEQ + 2*NEQ**2           for MF = 21 or 22,
!             22 + 11*NEQ + (3*ML + 2*MU)*NEQ  for MF = 24 or 25.
! LRW    = Declared length of RWORK (in user's DIMENSION statement).
! IWORK  = Integer work array of length at least:
!             30        for MF = 10,
!             30 + NEQ  for MF = 21, 22, 24, or 25.
!          If MF = 24 or 25, input in IWORK(1),IWORK(2) the lower
!          and upper half-bandwidths ML,MU.
! LIW    = Declared length of IWORK (in user's DIMENSION statement).
! JAC    = Name of subroutine for Jacobian matrix (MF = 21 or 24).
!          If used, this name must be declared external in calling
!          program.  If not used, pass a dummy name.
! MF     = Method flag.  Standard values are:
!          10 for nonstiff (Adams) method, no Jacobian used.
!          21 for stiff (BDF) method, user-supplied full Jacobian.
!          22 for stiff method, internally generated full Jacobian.
!          24 for stiff method, user-supplied banded Jacobian.
!          25 for stiff method, internally generated banded Jacobian.
! RPAR,IPAR = user-defined real and integer arrays passed to F and JAC.
! Note that the main program must declare arrays Y, RWORK, IWORK,
! and possibly ATOL, RPAR, and IPAR.
!
! E. The output from the first call (or any call) is:
!      Y = Array of computed values of y(t) vector.
!      T = Corresponding value of independent variable (normally TOUT).
! ISTATE = 2  if DVODE was successful, negative otherwise.
!          -1 means excess work done on this call. (Perhaps wrong MF.)
!          -2 means excess accuracy requested. (Tolerances too small.)
!          -3 means illegal input detected. (See printed message.)
!          -4 means repeated error test failures. (Check all input.)
!          -5 means repeated convergence failures. (Perhaps bad
!             Jacobian supplied or wrong choice of MF or tolerances.)
!          -6 means error weight became zero during problem. (Solution
!             component i vanished, and ATOL or ATOL(i) = 0.)
!
! F. To continue the integration after a successful return, simply
! reset TOUT and call DVODE again.  No other parameters need be reset.
!
!-----------------------------------------------------------------------
! EXAMPLE PROBLEM
!
! The following is a simple example problem, with the coding
! needed for its solution by DVODE.  The problem is from chemical
! kinetics, and consists of the following three rate equations:
!     dy1/dt = -.04*y1 + 1.e4*y2*y3
!     dy2/dt = .04*y1 - 1.e4*y2*y3 - 3.e7*y2**2
!     dy3/dt = 3.e7*y2**2
! on the interval from t = 0.0 to t = 4.e10, with initial conditions
! y1 = 1.0, y2 = y3 = 0.  The problem is stiff.
!
! The following coding solves this problem with DVODE, using MF = 21
! and printing results at t = .4, 4., ..., 4.e10.  It uses
! ITOL = 2 and ATOL much smaller for y2 than y1 or y3 because
! y2 has much smaller values.
! At the end of the run, statistical quantities of interest are
! printed. (See optional output in the full description below.)
! To generate Fortran source code, replace C in column 1 with a blank
! in the coding below.
!
!     EXTERNAL FEX, JEX
!     DOUBLE PRECISION ATOL, RPAR, RTOL, RWORK, T, TOUT, Y
!     DIMENSION Y(3), ATOL(3), RWORK(67), IWORK(33)
!     NEQ = 3
!     Y(1) = 1.0D0
!     Y(2) = 0.0D0
!     Y(3) = 0.0D0
!     T = 0.0D0
!     TOUT = 0.4D0
!     ITOL = 2
!     RTOL = 1.D-4
!     ATOL(1) = 1.D-8
!     ATOL(2) = 1.D-14
!     ATOL(3) = 1.D-6
!     ITASK = 1
!     ISTATE = 1
!     IOPT = 0
!     LRW = 67
!     LIW = 33
!     MF = 21
!     DO 40 IOUT = 1,12
!       CALL DVODE(FEX,NEQ,Y,T,TOUT,ITOL,RTOL,ATOL,ITASK,ISTATE,
!    1            IOPT,RWORK,LRW,IWORK,LIW,JEX,MF,RPAR,IPAR)
!       WRITE(6,20)T,Y(1),Y(2),Y(3)
! 20    FORMAT(' At t =',D12.4,'   y =',3D14.6)
!       IF (ISTATE .LT. 0) GO TO 80
! 40    TOUT = TOUT*10.
!     WRITE(6,60) IWORK(11),IWORK(12),IWORK(13),IWORK(19),
!    1            IWORK(20),IWORK(21),IWORK(22)
! 60  FORMAT(/' No. steps =',I4,'   No. f-s =',I4,
!    1       '   No. J-s =',I4,'   No. LU-s =',I4/
!    2       '  No. nonlinear iterations =',I4/
!    3       '  No. nonlinear convergence failures =',I4/
!    4       '  No. error test failures =',I4/)
!     STOP
! 80  WRITE(6,90)ISTATE
! 90  FORMAT(///' Error halt: ISTATE =',I3)
!     STOP
!     END
!
!     SUBROUTINE FEX (NEQ, T, Y, YDOT, RPAR, IPAR)
!     DOUBLE PRECISION RPAR, T, Y, YDOT
!     DIMENSION Y(NEQ), YDOT(NEQ)
!     YDOT(1) = -.04D0*Y(1) + 1.D4*Y(2)*Y(3)
!     YDOT(3) = 3.D7*Y(2)*Y(2)
!     YDOT(2) = -YDOT(1) - YDOT(3)
!     RETURN
!     END
!
!     SUBROUTINE JEX (NEQ, T, Y, ML, MU, PD, NRPD, RPAR, IPAR)
!     DOUBLE PRECISION PD, RPAR, T, Y
!     DIMENSION Y(NEQ), PD(NRPD,NEQ)
!     PD(1,1) = -.04D0
!     PD(1,2) = 1.D4*Y(3)
!     PD(1,3) = 1.D4*Y(2)
!     PD(2,1) = .04D0
!     PD(2,3) = -PD(1,3)
!     PD(3,2) = 6.D7*Y(2)
!     PD(2,2) = -PD(1,2) - PD(3,2)
!     RETURN
!     END
!
! The following output was obtained from the above program on a
! Cray-1 computer with the CFT compiler.
!
! At t =  4.0000e-01   y =  9.851680e-01  3.386314e-05  1.479817e-02
! At t =  4.0000e+00   y =  9.055255e-01  2.240539e-05  9.445214e-02
! At t =  4.0000e+01   y =  7.158108e-01  9.184883e-06  2.841800e-01
! At t =  4.0000e+02   y =  4.505032e-01  3.222940e-06  5.494936e-01
! At t =  4.0000e+03   y =  1.832053e-01  8.942690e-07  8.167938e-01
! At t =  4.0000e+04   y =  3.898560e-02  1.621875e-07  9.610142e-01
! At t =  4.0000e+05   y =  4.935882e-03  1.984013e-08  9.950641e-01
! At t =  4.0000e+06   y =  5.166183e-04  2.067528e-09  9.994834e-01
! At t =  4.0000e+07   y =  5.201214e-05  2.080593e-10  9.999480e-01
! At t =  4.0000e+08   y =  5.213149e-06  2.085271e-11  9.999948e-01
! At t =  4.0000e+09   y =  5.183495e-07  2.073399e-12  9.999995e-01
! At t =  4.0000e+10   y =  5.450996e-08  2.180399e-13  9.999999e-01
!
! No. steps = 595   No. f-s = 832   No. J-s =  13   No. LU-s = 112
!  No. nonlinear iterations = 831
!  No. nonlinear convergence failures =   0
!  No. error test failures =  22
!-----------------------------------------------------------------------
! Full description of user interface to DVODE.
!
! The user interface to DVODE consists of the following parts.
!
! i.   The call sequence to subroutine DVODE, which is a driver
!      routine for the solver.  This includes descriptions of both
!      the call sequence arguments and of user-supplied routines.
!      Following these descriptions is
!        * a description of optional input available through the
!          call sequence,
!        * a description of optional output (in the work arrays), and
!        * instructions for interrupting and restarting a solution.
!
! ii.  Descriptions of other routines in the DVODE package that may be
!      (optionally) called by the user.  These provide the ability to
!      alter error message handling, save and restore the internal
!      COMMON, and obtain specified derivatives of the solution y(t).
!
! iii. Descriptions of COMMON blocks to be declared in overlay
!      or similar environments.
!
! iv.  Description of two routines in the DVODE package, either of
!      which the user may replace with his own version, if desired.
!      these relate to the measurement of errors.
!
!-----------------------------------------------------------------------
! Part i.  Call Sequence.
!
! The call sequence parameters used for input only are
!     F, NEQ, TOUT, ITOL, RTOL, ATOL, ITASK, IOPT, LRW, LIW, JAC, MF,
! and those used for both input and output are
!     Y, T, ISTATE.
! The work arrays RWORK and IWORK are also used for conditional and
! optional input and optional output.  (The term output here refers
! to the return from subroutine DVODE to the user's calling program.)
!
! The legality of input parameters will be thoroughly checked on the
! initial call for the problem, but not checked thereafter unless a
! change in input parameters is flagged by ISTATE = 3 in the input.
!
! The descriptions of the call arguments are as follows.
!
! F      = The name of the user-supplied subroutine defining the
!          ODE system.  The system must be put in the first-order
!          form dy/dt = f(t,y), where f is a vector-valued function
!          of the scalar t and the vector y.  Subroutine F is to
!          compute the function f.  It is to have the form
!               SUBROUTINE F (NEQ, T, Y, YDOT, RPAR, IPAR)
!               DOUBLE PRECISION T, Y(NEQ), YDOT(NEQ), RPAR
!          where NEQ, T, and Y are input, and the array YDOT = f(t,y)
!          is output.  Y and YDOT are arrays of length NEQ.
!          Subroutine F should not alter Y(1),...,Y(NEQ).
!          F must be declared EXTERNAL in the calling program.
!
!          Subroutine F may access user-defined real and integer
!          work arrays RPAR and IPAR, which are to be dimensioned
!          in the main program.
!
!          If quantities computed in the F routine are needed
!          externally to DVODE, an extra call to F should be made
!          for this purpose, for consistent and accurate results.
!          If only the derivative dy/dt is needed, use DVINDY instead.
!
! NEQ    = The size of the ODE system (number of first order
!          ordinary differential equations).  Used only for input.
!          NEQ may not be increased during the problem, but
!          can be decreased (with ISTATE = 3 in the input).
!
! Y      = A real array for the vector of dependent variables, of
!          length NEQ or more.  Used for both input and output on the
!          first call (ISTATE = 1), and only for output on other calls.
!          On the first call, Y must contain the vector of initial
!          values.  In the output, Y contains the computed solution
!          evaluated at T.  If desired, the Y array may be used
!          for other purposes between calls to the solver.
!
!          This array is passed as the Y argument in all calls to
!          F and JAC.
!
! T      = The independent variable.  In the input, T is used only on
!          the first call, as the initial point of the integration.
!          In the output, after each call, T is the value at which a
!          computed solution Y is evaluated (usually the same as TOUT).
!          On an error return, T is the farthest point reached.
!
! TOUT   = The next value of t at which a computed solution is desired.
!          Used only for input.
!
!          When starting the problem (ISTATE = 1), TOUT may be equal
!          to T for one call, then should .ne. T for the next call.
!          For the initial T, an input value of TOUT .ne. T is used
!          in order to determine the direction of the integration
!          (i.e. the algebraic sign of the step sizes) and the rough
!          scale of the problem.  Integration in either direction
!          (forward or backward in t) is permitted.
!
!          If ITASK = 2 or 5 (one-step modes), TOUT is ignored after
!          the first call (i.e. the first call with TOUT .ne. T).
!          Otherwise, TOUT is required on every call.
!
!          If ITASK = 1, 3, or 4, the values of TOUT need not be
!          monotone, but a value of TOUT which backs up is limited
!          to the current internal t interval, whose endpoints are
!          TCUR - HU and TCUR.  (See optional output, below, for
!          TCUR and HU.)
!
! ITOL   = An indicator for the type of error control.  See
!          description below under ATOL.  Used only for input.
!
! RTOL   = A relative error tolerance parameter, either a scalar or
!          an array of length NEQ.  See description below under ATOL.
!          Input only.
!
! ATOL   = An absolute error tolerance parameter, either a scalar or
!          an array of length NEQ.  Input only.
!
!          The input parameters ITOL, RTOL, and ATOL determine
!          the error control performed by the solver.  The solver will
!          control the vector e = (e(i)) of estimated local errors
!          in Y, according to an inequality of the form
!                      rms-norm of ( e(i)/EWT(i) )   .le.   1,
!          where       EWT(i) = RTOL(i)*abs(Y(i)) + ATOL(i),
!          and the rms-norm (root-mean-square norm) here is
!          rms-norm(v) = sqrt(sum v(i)**2 / NEQ).  Here EWT = (EWT(i))
!          is a vector of weights which must always be positive, and
!          the values of RTOL and ATOL should all be non-negative.
!          The following table gives the types (scalar/array) of
!          RTOL and ATOL, and the corresponding form of EWT(i).
!
!             ITOL    RTOL       ATOL          EWT(i)
!              1     scalar     scalar     RTOL*ABS(Y(i)) + ATOL
!              2     scalar     array      RTOL*ABS(Y(i)) + ATOL(i)
!              3     array      scalar     RTOL(i)*ABS(Y(i)) + ATOL
!              4     array      array      RTOL(i)*ABS(Y(i)) + ATOL(i)
!
!          When either of these parameters is a scalar, it need not
!          be dimensioned in the user's calling program.
!
!          If none of the above choices (with ITOL, RTOL, and ATOL
!          fixed throughout the problem) is suitable, more general
!          error controls can be obtained by substituting
!          user-supplied routines for the setting of EWT and/or for
!          the norm calculation.  See Part iv below.
!
!          If global errors are to be estimated by making a repeated
!          run on the same problem with smaller tolerances, then all
!          components of RTOL and ATOL (i.e. of EWT) should be scaled
!          down uniformly.
!
! ITASK  = An index specifying the task to be performed.
!          Input only.  ITASK has the following values and meanings.
!          1  means normal computation of output values of y(t) at
!             t = TOUT (by overshooting and interpolating).
!          2  means take one step only and return.
!          3  means stop at the first internal mesh point at or
!             beyond t = TOUT and return.
!          4  means normal computation of output values of y(t) at
!             t = TOUT but without overshooting t = TCRIT.
!             TCRIT must be input as RWORK(1).  TCRIT may be equal to
!             or beyond TOUT, but not behind it in the direction of
!             integration.  This option is useful if the problem
!             has a singularity at or beyond t = TCRIT.
!          5  means take one step, without passing TCRIT, and return.
!             TCRIT must be input as RWORK(1).
!
!          Note:  If ITASK = 4 or 5 and the solver reaches TCRIT
!          (within roundoff), it will return T = TCRIT (exactly) to
!          indicate this (unless ITASK = 4 and TOUT comes before TCRIT,
!          in which case answers at T = TOUT are returned first).
!
! ISTATE = an index used for input and output to specify the
!          the state of the calculation.
!
!          In the input, the values of ISTATE are as follows.
!          1  means this is the first call for the problem
!             (initializations will be done).  See note below.
!          2  means this is not the first call, and the calculation
!             is to continue normally, with no change in any input
!             parameters except possibly TOUT and ITASK.
!             (If ITOL, RTOL, and/or ATOL are changed between calls
!             with ISTATE = 2, the new values will be used but not
!             tested for legality.)
!          3  means this is not the first call, and the
!             calculation is to continue normally, but with
!             a change in input parameters other than
!             TOUT and ITASK.  Changes are allowed in
!             NEQ, ITOL, RTOL, ATOL, IOPT, LRW, LIW, MF, ML, MU,
!             and any of the optional input except H0.
!             (See IWORK description for ML and MU.)
!          Note:  A preliminary call with TOUT = T is not counted
!          as a first call here, as no initialization or checking of
!          input is done.  (Such a call is sometimes useful to include
!          the initial conditions in the output.)
!          Thus the first call for which TOUT .ne. T requires
!          ISTATE = 1 in the input.
!
!          In the output, ISTATE has the following values and meanings.
!           1  means nothing was done, as TOUT was equal to T with
!              ISTATE = 1 in the input.
!           2  means the integration was performed successfully.
!          -1  means an excessive amount of work (more than MXSTEP
!              steps) was done on this call, before completing the
!              requested task, but the integration was otherwise
!              successful as far as T.  (MXSTEP is an optional input
!              and is normally 500.)  To continue, the user may
!              simply reset ISTATE to a value .gt. 1 and call again.
!              (The excess work step counter will be reset to 0.)
!              In addition, the user may increase MXSTEP to avoid
!              this error return.  (See optional input below.)
!          -2  means too much accuracy was requested for the precision
!              of the machine being used.  This was detected before
!              completing the requested task, but the integration
!              was successful as far as T.  To continue, the tolerance
!              parameters must be reset, and ISTATE must be set
!              to 3.  The optional output TOLSF may be used for this
!              purpose.  (Note: If this condition is detected before
!              taking any steps, then an illegal input return
!              (ISTATE = -3) occurs instead.)
!          -3  means illegal input was detected, before taking any
!              integration steps.  See written message for details.
!              Note:  If the solver detects an infinite loop of calls
!              to the solver with illegal input, it will cause
!              the run to stop.
!          -4  means there were repeated error test failures on
!              one attempted step, before completing the requested
!              task, but the integration was successful as far as T.
!              The problem may have a singularity, or the input
!              may be inappropriate.
!          -5  means there were repeated convergence test failures on
!              one attempted step, before completing the requested
!              task, but the integration was successful as far as T.
!              This may be caused by an inaccurate Jacobian matrix,
!              if one is being used.
!          -6  means EWT(i) became zero for some i during the
!              integration.  Pure relative error control (ATOL(i)=0.0)
!              was requested on a variable which has now vanished.
!              The integration was successful as far as T.
!
!          Note:  Since the normal output value of ISTATE is 2,
!          it does not need to be reset for normal continuation.
!          Also, since a negative input value of ISTATE will be
!          regarded as illegal, a negative output value requires the
!          user to change it, and possibly other input, before
!          calling the solver again.
!
! IOPT   = An integer flag to specify whether or not any optional
!          input is being used on this call.  Input only.
!          The optional input is listed separately below.
!          IOPT = 0 means no optional input is being used.
!                   Default values will be used in all cases.
!          IOPT = 1 means optional input is being used.
!
! RWORK  = A real working array (double precision).
!          The length of RWORK must be at least
!             20 + NYH*(MAXORD + 1) + 3*NEQ + LWM    where
!          NYH    = the initial value of NEQ,
!          MAXORD = 12 (if METH = 1) or 5 (if METH = 2) (unless a
!                   smaller value is given as an optional input),
!          LWM = length of work space for matrix-related data:
!          LWM = 0             if MITER = 0,
!          LWM = 2*NEQ**2 + 2  if MITER = 1 or 2, and MF.gt.0,
!          LWM = NEQ**2 + 2    if MITER = 1 or 2, and MF.lt.0,
!          LWM = NEQ + 2       if MITER = 3,
!          LWM = (3*ML+2*MU+2)*NEQ + 2 if MITER = 4 or 5, and MF.gt.0,
!          LWM = (2*ML+MU+1)*NEQ + 2   if MITER = 4 or 5, and MF.lt.0.
!          (See the MF description for METH and MITER.)
!          Thus if MAXORD has its default value and NEQ is constant,
!          this length is:
!             20 + 16*NEQ                    for MF = 10,
!             22 + 16*NEQ + 2*NEQ**2         for MF = 11 or 12,
!             22 + 16*NEQ + NEQ**2           for MF = -11 or -12,
!             22 + 17*NEQ                    for MF = 13,
!             22 + 18*NEQ + (3*ML+2*MU)*NEQ  for MF = 14 or 15,
!             22 + 17*NEQ + (2*ML+MU)*NEQ    for MF = -14 or -15,
!             20 +  9*NEQ                    for MF = 20,
!             22 +  9*NEQ + 2*NEQ**2         for MF = 21 or 22,
!             22 +  9*NEQ + NEQ**2           for MF = -21 or -22,
!             22 + 10*NEQ                    for MF = 23,
!             22 + 11*NEQ + (3*ML+2*MU)*NEQ  for MF = 24 or 25.
!             22 + 10*NEQ + (2*ML+MU)*NEQ    for MF = -24 or -25.
!          The first 20 words of RWORK are reserved for conditional
!          and optional input and optional output.
!
!          The following word in RWORK is a conditional input:
!            RWORK(1) = TCRIT = critical value of t which the solver
!                       is not to overshoot.  Required if ITASK is
!                       4 or 5, and ignored otherwise.  (See ITASK.)
!
! LRW    = The length of the array RWORK, as declared by the user.
!          (This will be checked by the solver.)
!
! IWORK  = An integer work array.  The length of IWORK must be at least
!             30        if MITER = 0 or 3 (MF = 10, 13, 20, 23), or
!             30 + NEQ  otherwise (abs(MF) = 11,12,14,15,21,22,24,25).
!          The first 30 words of IWORK are reserved for conditional and
!          optional input and optional output.
!
!          The following 2 words in IWORK are conditional input:
!            IWORK(1) = ML     These are the lower and upper
!            IWORK(2) = MU     half-bandwidths, respectively, of the
!                       banded Jacobian, excluding the main diagonal.
!                       The band is defined by the matrix locations
!                       (i,j) with i-ML .le. j .le. i+MU.  ML and MU
!                       must satisfy  0 .le.  ML,MU  .le. NEQ-1.
!                       These are required if MITER is 4 or 5, and
!                       ignored otherwise.  ML and MU may in fact be
!                       the band parameters for a matrix to which
!                       df/dy is only approximately equal.
!
! LIW    = the length of the array IWORK, as declared by the user.
!          (This will be checked by the solver.)
!
! Note:  The work arrays must not be altered between calls to DVODE
! for the same problem, except possibly for the conditional and
! optional input, and except for the last 3*NEQ words of RWORK.
! The latter space is used for internal scratch space, and so is
! available for use by the user outside DVODE between calls, if
! desired (but not for use by F or JAC).
!
! JAC    = The name of the user-supplied routine (MITER = 1 or 4) to
!          compute the Jacobian matrix, df/dy, as a function of
!          the scalar t and the vector y.  It is to have the form
!               SUBROUTINE JAC (NEQ, T, Y, ML, MU, PD, NROWPD,
!                               RPAR, IPAR)
!               DOUBLE PRECISION T, Y(NEQ), PD(NROWPD,NEQ), RPAR
!          where NEQ, T, Y, ML, MU, and NROWPD are input and the array
!          PD is to be loaded with partial derivatives (elements of the
!          Jacobian matrix) in the output.  PD must be given a first
!          dimension of NROWPD.  T and Y have the same meaning as in
!          Subroutine F.
!               In the full matrix case (MITER = 1), ML and MU are
!          ignored, and the Jacobian is to be loaded into PD in
!          columnwise manner, with df(i)/dy(j) loaded into PD(i,j).
!               In the band matrix case (MITER = 4), the elements
!          within the band are to be loaded into PD in columnwise
!          manner, with diagonal lines of df/dy loaded into the rows
!          of PD. Thus df(i)/dy(j) is to be loaded into PD(i-j+MU+1,j).
!          ML and MU are the half-bandwidth parameters. (See IWORK).
!          The locations in PD in the two triangular areas which
!          correspond to nonexistent matrix elements can be ignored
!          or loaded arbitrarily, as they are overwritten by DVODE.
!               JAC need not provide df/dy exactly.  A crude
!          approximation (possibly with a smaller bandwidth) will do.
!               In either case, PD is preset to zero by the solver,
!          so that only the nonzero elements need be loaded by JAC.
!          Each call to JAC is preceded by a call to F with the same
!          arguments NEQ, T, and Y.  Thus to gain some efficiency,
!          intermediate quantities shared by both calculations may be
!          saved in a user COMMON block by F and not recomputed by JAC,
!          if desired.  Also, JAC may alter the Y array, if desired.
!          JAC must be declared external in the calling program.
!               Subroutine JAC may access user-defined real and integer
!          work arrays, RPAR and IPAR, whose dimensions are set by the
!          user in the main program.
!
! MF     = The method flag.  Used only for input.  The legal values of
!          MF are 10, 11, 12, 13, 14, 15, 20, 21, 22, 23, 24, 25,
!          -11, -12, -14, -15, -21, -22, -24, -25.
!          MF is a signed two-digit integer, MF = JSV*(10*METH + MITER).
!          JSV = SIGN(MF) indicates the Jacobian-saving strategy:
!            JSV =  1 means a copy of the Jacobian is saved for reuse
!                     in the corrector iteration algorithm.
!            JSV = -1 means a copy of the Jacobian is not saved
!                     (valid only for MITER = 1, 2, 4, or 5).
!          METH indicates the basic linear multistep method:
!            METH = 1 means the implicit Adams method.
!            METH = 2 means the method based on backward
!                     differentiation formulas (BDF-s).
!          MITER indicates the corrector iteration method:
!            MITER = 0 means functional iteration (no Jacobian matrix
!                      is involved).
!            MITER = 1 means chord iteration with a user-supplied
!                      full (NEQ by NEQ) Jacobian.
!            MITER = 2 means chord iteration with an internally
!                      generated (difference quotient) full Jacobian
!                      (using NEQ extra calls to F per df/dy value).
!            MITER = 3 means chord iteration with an internally
!                      generated diagonal Jacobian approximation
!                      (using 1 extra call to F per df/dy evaluation).
!            MITER = 4 means chord iteration with a user-supplied
!                      banded Jacobian.
!            MITER = 5 means chord iteration with an internally
!                      generated banded Jacobian (using ML+MU+1 extra
!                      calls to F per df/dy evaluation).
!          If MITER = 1 or 4, the user must supply a subroutine JAC
!          (the name is arbitrary) as described above under JAC.
!          For other values of MITER, a dummy argument can be used.
!
! RPAR     User-specified array used to communicate real parameters
!          to user-supplied subroutines.  If RPAR is a vector, then
!          it must be dimensioned in the user's main program.  If it
!          is unused or it is a scalar, then it need not be
!          dimensioned.
!
! IPAR     User-specified array used to communicate integer parameter
!          to user-supplied subroutines.  The comments on dimensioning
!          RPAR apply to IPAR.
!-----------------------------------------------------------------------
! Optional Input.
!
! The following is a list of the optional input provided for in the
! call sequence.  (See also Part ii.)  For each such input variable,
! this table lists its name as used in this documentation, its
! location in the call sequence, its meaning, and the default value.
! The use of any of this input requires IOPT = 1, and in that
! case all of this input is examined.  A value of zero for any
! of these optional input variables will cause the default value to be
! used.  Thus to use a subset of the optional input, simply preload
! locations 5 to 10 in RWORK and IWORK to 0.0 and 0 respectively, and
! then set those of interest to nonzero values.
!
! NAME    LOCATION      MEANING AND DEFAULT VALUE
!
! H0      RWORK(5)  The step size to be attempted on the first step.
!                   The default value is determined by the solver.
!
! HMAX    RWORK(6)  The maximum absolute step size allowed.
!                   The default value is infinite.
!
! HMIN    RWORK(7)  The minimum absolute step size allowed.
!                   The default value is 0.  (This lower bound is not
!                   enforced on the final step before reaching TCRIT
!                   when ITASK = 4 or 5.)
!
! MAXORD  IWORK(5)  The maximum order to be allowed.  The default
!                   value is 12 if METH = 1, and 5 if METH = 2.
!                   If MAXORD exceeds the default value, it will
!                   be reduced to the default value.
!                   If MAXORD is changed during the problem, it may
!                   cause the current order to be reduced.
!
! MXSTEP  IWORK(6)  Maximum number of (internally defined) steps
!                   allowed during one call to the solver.
!                   The default value is 500.
!
! MXHNIL  IWORK(7)  Maximum number of messages printed (per problem)
!                   warning that T + H = T on a step (H = step size).
!                   This must be positive to result in a non-default
!                   value.  The default value is 10.
!
!-----------------------------------------------------------------------
! Optional Output.
!
! As optional additional output from DVODE, the variables listed
! below are quantities related to the performance of DVODE
! which are available to the user.  These are communicated by way of
! the work arrays, but also have internal mnemonic names as shown.
! Except where stated otherwise, all of this output is defined
! on any successful return from DVODE, and on any return with
! ISTATE = -1, -2, -4, -5, or -6.  On an illegal input return
! (ISTATE = -3), they will be unchanged from their existing values
! (if any), except possibly for TOLSF, LENRW, and LENIW.
! On any error return, output relevant to the error will be defined,
! as noted below.
!
! NAME    LOCATION      MEANING
!
! HU      RWORK(11) The step size in t last used (successfully).
!
! HCUR    RWORK(12) The step size to be attempted on the next step.
!
! TCUR    RWORK(13) The current value of the independent variable
!                   which the solver has actually reached, i.e. the
!                   current internal mesh point in t.  In the output,
!                   TCUR will always be at least as far from the
!                   initial value of t as the current argument T,
!                   but may be farther (if interpolation was done).
!
! TOLSF   RWORK(14) A tolerance scale factor, greater than 1.0,
!                   computed when a request for too much accuracy was
!                   detected (ISTATE = -3 if detected at the start of
!                   the problem, ISTATE = -2 otherwise).  If ITOL is
!                   left unaltered but RTOL and ATOL are uniformly
!                   scaled up by a factor of TOLSF for the next call,
!                   then the solver is deemed likely to succeed.
!                   (The user may also ignore TOLSF and alter the
!                   tolerance parameters in any other way appropriate.)
!
! NST     IWORK(11) The number of steps taken for the problem so far.
!
! NFE     IWORK(12) The number of f evaluations for the problem so far.
!
! NJE     IWORK(13) The number of Jacobian evaluations so far.
!
! NQU     IWORK(14) The method order last used (successfully).
!
! NQCUR   IWORK(15) The order to be attempted on the next step.
!
! IMXER   IWORK(16) The index of the component of largest magnitude in
!                   the weighted local error vector ( e(i)/EWT(i) ),
!                   on an error return with ISTATE = -4 or -5.
!
! LENRW   IWORK(17) The length of RWORK actually required.
!                   This is defined on normal returns and on an illegal
!                   input return for insufficient storage.
!
! LENIW   IWORK(18) The length of IWORK actually required.
!                   This is defined on normal returns and on an illegal
!                   input return for insufficient storage.
!
! NLU     IWORK(19) The number of matrix LU decompositions so far.
!
! NNI     IWORK(20) The number of nonlinear (Newton) iterations so far.
!
! NCFN    IWORK(21) The number of convergence failures of the nonlinear
!                   solver so far.
!
! NETF    IWORK(22) The number of error test failures of the integrator
!                   so far.
!
! The following two arrays are segments of the RWORK array which
! may also be of interest to the user as optional output.
! For each array, the table below gives its internal name,
! its base address in RWORK, and its description.
!
! NAME    BASE ADDRESS      DESCRIPTION
!
! YH      21             The Nordsieck history array, of size NYH by
!                        (NQCUR + 1), where NYH is the initial value
!                        of NEQ.  For j = 0,1,...,NQCUR, column j+1
!                        of YH contains HCUR**j/factorial(j) times
!                        the j-th derivative of the interpolating
!                        polynomial currently representing the
!                        solution, evaluated at t = TCUR.
!
! ACOR     LENRW-NEQ+1   Array of size NEQ used for the accumulated
!                        corrections on each step, scaled in the output
!                        to represent the estimated local error in Y
!                        on the last step.  This is the vector e in
!                        the description of the error control.  It is
!                        defined only on a successful return from DVODE.
!
!-----------------------------------------------------------------------
! Interrupting and Restarting
!
! If the integration of a given problem by DVODE is to be
! interrrupted and then later continued, such as when restarting
! an interrupted run or alternating between two or more ODE problems,
! the user should save, following the return from the last DVODE call
! prior to the interruption, the contents of the call sequence
! variables and internal COMMON blocks, and later restore these
! values before the next DVODE call for that problem.  To save
! and restore the COMMON blocks, use subroutine DVSRCO, as
! described below in part ii.
!
! In addition, if non-default values for either LUN or MFLAG are
! desired, an extra call to XSETUN and/or XSETF should be made just
! before continuing the integration.  See Part ii below for details.
!
!-----------------------------------------------------------------------
! Part ii.  Other Routines Callable.
!
! The following are optional calls which the user may make to
! gain additional capabilities in conjunction with DVODE.
! (The routines XSETUN and XSETF are designed to conform to the
! SLATEC error handling package.)
!
!     FORM OF CALL                  FUNCTION
!  CALL XSETUN(LUN)           Set the logical unit number, LUN, for
!                             output of messages from DVODE, if
!                             the default is not desired.
!                             The default value of LUN is 6.
!
!  CALL XSETF(MFLAG)          Set a flag to control the printing of
!                             messages by DVODE.
!                             MFLAG = 0 means do not print. (Danger:
!                             This risks losing valuable information.)
!                             MFLAG = 1 means print (the default).
!
!                             Either of the above calls may be made at
!                             any time and will take effect immediately.
!
!  CALL DVSRCO(RSAV,ISAV,JOB) Saves and restores the contents of
!                             the internal COMMON blocks used by
!                             DVODE. (See Part iii below.)
!                             RSAV must be a real array of length 49
!                             or more, and ISAV must be an integer
!                             array of length 40 or more.
!                             JOB=1 means save COMMON into RSAV/ISAV.
!                             JOB=2 means restore COMMON from RSAV/ISAV.
!                                DVSRCO is useful if one is
!                             interrupting a run and restarting
!                             later, or alternating between two or
!                             more problems solved with DVODE.
!
!  CALL DVINDY(,,,,,)         Provide derivatives of y, of various
!        (See below.)         orders, at a specified point T, if
!                             desired.  It may be called only after
!                             a successful return from DVODE.
!
! The detailed instructions for using DVINDY are as follows.
! The form of the call is:
!
!  CALL DVINDY (T, K, RWORK(21), NYH, DKY, IFLAG)
!
! The input parameters are:
!
! T         = Value of independent variable where answers are desired
!             (normally the same as the T last returned by DVODE).
!             For valid results, T must lie between TCUR - HU and TCUR.
!             (See optional output for TCUR and HU.)
! K         = Integer order of the derivative desired.  K must satisfy
!             0 .le. K .le. NQCUR, where NQCUR is the current order
!             (see optional output).  The capability corresponding
!             to K = 0, i.e. computing y(T), is already provided
!             by DVODE directly.  Since NQCUR .ge. 1, the first
!             derivative dy/dt is always available with DVINDY.
! RWORK(21) = The base address of the history array YH.
! NYH       = Column length of YH, equal to the initial value of NEQ.
!
! The output parameters are:
!
! DKY       = A real array of length NEQ containing the computed value
!             of the K-th derivative of y(t).
! IFLAG     = Integer flag, returned as 0 if K and T were legal,
!             -1 if K was illegal, and -2 if T was illegal.
!             On an error return, a message is also written.
!-----------------------------------------------------------------------
! Part iii.  COMMON Blocks.
! If DVODE is to be used in an overlay situation, the user
! must declare, in the primary overlay, the variables in:
!   (1) the call sequence to DVODE,
!   (2) the two internal COMMON blocks
!         /DVOD01/  of length  81  (48 double precision words
!                         followed by 33 integer words),
!         /DVOD02/  of length  9  (1 double precision word
!                         followed by 8 integer words),
!
! If DVODE is used on a system in which the contents of internal
! COMMON blocks are not preserved between calls, the user should
! declare the above two COMMON blocks in his main program to insure
! that their contents are preserved.
!
!-----------------------------------------------------------------------
! Part iv.  Optionally Replaceable Solver Routines.
!
! Below are descriptions of two routines in the DVODE package which
! relate to the measurement of errors.  Either routine can be
! replaced by a user-supplied version, if desired.  However, since such
! a replacement may have a major impact on performance, it should be
! done only when absolutely necessary, and only with great caution.
! (Note: The means by which the package version of a routine is
! superseded by the user's version may be system-dependent.)
!
! (a) DEWSET.
! The following subroutine is called just before each internal
! integration step, and sets the array of error weights, EWT, as
! described under ITOL/RTOL/ATOL above:
!     SUBROUTINE DEWSET (NEQ, ITOL, RTOL, ATOL, YCUR, EWT)
! where NEQ, ITOL, RTOL, and ATOL are as in the DVODE call sequence,
! YCUR contains the current dependent variable vector, and
! EWT is the array of weights set by DEWSET.
!
! If the user supplies this subroutine, it must return in EWT(i)
! (i = 1,...,NEQ) a positive quantity suitable for comparison with
! errors in Y(i).  The EWT array returned by DEWSET is passed to the
! DVNORM routine (See below.), and also used by DVODE in the computation
! of the optional output IMXER, the diagonal Jacobian approximation,
! and the increments for difference quotient Jacobians.
!
! In the user-supplied version of DEWSET, it may be desirable to use
! the current values of derivatives of y.  Derivatives up to order NQ
! are available from the history array YH, described above under
! Optional Output.  In DEWSET, YH is identical to the YCUR array,
! extended to NQ + 1 columns with a column length of NYH and scale
! factors of h**j/factorial(j).  On the first call for the problem,
! given by NST = 0, NQ is 1 and H is temporarily set to 1.0.
! NYH is the initial value of NEQ.  The quantities NQ, H, and NST
! can be obtained by including in DEWSET the statements:
!     DOUBLE PRECISION RVOD, H, HU
!     COMMON /DVOD01/ RVOD(48), IVOD(33)
!     COMMON /DVOD02/ HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!     NQ = IVOD(28)
!     H = RVOD(21)
! Thus, for example, the current value of dy/dt can be obtained as
! YCUR(NYH+i)/H  (i=1,...,NEQ)  (and the division by H is
! unnecessary when NST = 0).
!
! (b) DVNORM.
! The following is a real function routine which computes the weighted
! root-mean-square norm of a vector v:
!     D = DVNORM (N, V, W)
! where:
!   N = the length of the vector,
!   V = real array of length N containing the vector,
!   W = real array of length N containing weights,
!   D = sqrt( (1/N) * sum(V(i)*W(i))**2 ).
! DVNORM is called with N = NEQ and with W(i) = 1.0/EWT(i), where
! EWT is as set by subroutine DEWSET.
!
! If the user supplies this function, it should return a non-negative
! value of DVNORM suitable for use in the error control in DVODE.
! None of the arguments should be altered by DVNORM.
! For example, a user-supplied DVNORM routine might:
!   -substitute a max-norm of (V(i)*W(i)) for the rms-norm, or
!   -ignore some components of V in the norm, with the effect of
!    suppressing the error control on those components of Y.
!-----------------------------------------------------------------------
! REVISION HISTORY (YYYYMMDD)
!  19890615  Date Written.  Initial release.
!  19890922  Added interrupt/restart ability, minor changes throughout.
!  19910228  Minor revisions in line format,  prologue, etc.
!  19920227  Modifications by D. Pang:
!            (1) Applied subgennam to get generic intrinsic names.
!            (2) Changed intrinsic names to generic in comments.
!            (3) Added !*DECK lines before each routine.
!  19920721  Names of routines and labeled Common blocks changed, so as
!            to be unique in combined single/double precision code (ACH)
!  19920722  Minor revisions to prologue (ACH).
!  19920831  Conversion to double precision done (ACH).
!  19921106  Fixed minor bug: ETAQ,ETAQM1 in DVSTEP SAVE statement (ACH)
!  19921118  Changed LUNSAV/MFLGSV to IXSAV (ACH).
!  19941222  Removed MF overwrite; attached sign to H in estimated secon
!            deriv. in DVHIN; misc. comment changes throughout (ACH).
!  19970515  Minor corrections to comments in prologue, DVJAC (ACH).
!  19981111  Corrected Block B by adding final line, GO TO 200 (ACH).
!  20020430  Various upgrades (ACH): Use ODEPACK error handler package.
!            Replaced D1MACH by DUMACH.  Various changes to main
!            prologue and other routine prologues.
!-----------------------------------------------------------------------
! Other Routines in the DVODE Package.
!
! In addition to subroutine DVODE, the DVODE package includes the
! following subroutines and function routines:
!  DVHIN     computes an approximate step size for the initial step.
!  DVINDY    computes an interpolated value of the y vector at t = TOUT.
!  DVSTEP    is the core integrator, which does one step of the
!            integration and the associated error control.
!  DVSET     sets all method coefficients and test constants.
!  DVNLSD    solves the underlying nonlinear system -- the corrector.
!  DVJAC     computes and preprocesses the Jacobian matrix J = df/dy
!            and the Newton iteration matrix P = I - (h/l1)*J.
!  DVSOL     manages solution of linear system in chord iteration.
!  DVJUST    adjusts the history array on a change of order.
!  DEWSET    sets the error weight vector EWT before each step.
!  DVNORM    computes the weighted r.m.s. norm of a vector.
!  DVSRCO    is a user-callable routine to save and restore
!            the contents of the internal COMMON blocks.
!  DACOPY    is a routine to copy one two-dimensional array to another.
!  DGEFA and DGESL   are routines from LINPACK for solving full
!            systems of linear algebraic equations.
!  DGBFA and DGBSL   are routines from LINPACK for solving banded
!            linear systems.
!  DAXPY, DSCAL, and DCOPY are basic linear algebra modules (BLAS).

! wmy2017Nov16 -- RTOL made a scalar
! wmy2017Oct16 -- Declare dimensions, too. Trying to write RPAR
!  still leads to illegal instruction : 4 !?
!      DIMENSION Y ( * ), RTOL ( * ), ATOL ( * ), RWORK (LRW), IWORK (   &
!      LIW), RPAR ( * ), IPAR ( * )
!      DIMENSION Y ( 20 ), ATOL ( 20 ), RWORK ( 1002 ),       &
!       IWORK ( 50 ), RPAR ( 257 ), IPAR ( 257 )
! wmy2017Oct17 -- All dimensions above are correct, but the program
!  still will not PASS IN floats!?!?! So just use the original
!  pointer notation.
! wmy2017Oct18 -- moved these to top of file
!      DIMENSION Y ( * ), ATOL ( * ), RWORK (LRW), IWORK ( LIW )         &
!        , RPAR ( * ), IPAR ( * )

!  DUMACH    sets the unit roundoff of the machine.
!  XERRWD, XSETUN, XSETF, IXSAV, and IUMACH handle the printing of all
!            error messages and warnings.  XERRWD is machine-dependent.
! Note:  DVNORM, DUMACH, IXSAV, and IUMACH are function routines.
! All the others are subroutines.
!
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND

      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for labeled COMMON block DVOD02 --------------------
!
      DOUBLEPRECISION HU

      INTEGER NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Type declarations for local variables --------------------------------
!
      EXTERNAL DVNLSD

      LOGICAL IHIT

      DOUBLEPRECISION ATOLI, BIG, EWTI, FOUR, H0, HMAX, HMX, HUN, ONE,  &
      PT2, RH, RTOLI, SSSIZE, TCRIT, TNEXT, TOLSF, TP, TWO, ZERO

      INTEGER I, IER, IFLAG, IMXER, JCO, KGO, LENIW, LENJ, LENP, LENRW, &
      LENWM, LF0, MBAND, MFA, ML, MORD, MU, MXHNL0, MXSTP0, NITER,      &
      NSLAST

      CHARACTER(80) MSG
!
! Type declaration for function subroutines called ---------------------
!
      DOUBLEPRECISION DUMACH, DVNORM
!
      DIMENSION MORD (2)
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to DVODE.
!-----------------------------------------------------------------------
      SAVE MORD, MXHNL0, MXSTP0
      SAVE ZERO, ONE, TWO, FOUR, PT2, HUN
!-----------------------------------------------------------------------
! The following internal COMMON blocks contain variables which are
! communicated between subroutines in the DVODE package, or which are
! to be saved between calls to DVODE.
! In each block, real variables precede integers.
! The block /DVOD01/ appears in subroutines DVODE, DVINDY, DVSTEP,
! DVSET, DVNLSD, DVJAC, DVSOL, DVJUST and DVSRCO.
! The block /DVOD02/ appears in subroutines DVODE, DVINDY, DVSTEP,
! DVNLSD, DVJAC, and DVSRCO.
!
! The variables stored in the internal COMMON blocks are as follows:
!
! ACNRM  = Weighted r.m.s. norm of accumulated correction vectors.
! CCMXJ  = Threshhold on DRC for updating the Jacobian. (See DRC.)
! CONP   = The saved value of TQ(5).
! CRATE  = Estimated corrector convergence rate constant.
! DRC    = Relative change in H*RL1 since last DVJAC call.
! EL     = Real array of integration coefficients.  See DVSET.
! ETA    = Saved tentative ratio of new to old H.
! ETAMAX = Saved maximum value of ETA to be allowed.
! H      = The step size.
! HMIN   = The minimum absolute value of the step size H to be used.
! HMXI   = Inverse of the maximum absolute value of H to be used.
!          HMXI = 0.0 is allowed and corresponds to an infinite HMAX.
! HNEW   = The step size to be attempted on the next step.
! HSCAL  = Stepsize in scaling of YH array.
! PRL1   = The saved value of RL1.
! RC     = Ratio of current H*RL1 to value on last DVJAC call.
! RL1    = The reciprocal of the coefficient EL(1).
! TAU    = Real vector of past NQ step sizes, length 13.
! TQ     = A real vector of length 5 in which DVSET stores constants
!          used for the convergence test, the error test, and the
!          selection of H at a new order.
! TN     = The independent variable, updated on each step taken.
! UROUND = The machine unit roundoff.  The smallest positive real number
!          such that  1.0 + UROUND .ne. 1.0
! ICF    = Integer flag for convergence failure in DVNLSD:
!            0 means no failures.
!            1 means convergence failure with out of date Jacobian
!                   (recoverable error).
!            2 means convergence failure with current Jacobian or
!                   singular matrix (unrecoverable error).
! INIT   = Saved integer flag indicating whether initialization of the
!          problem has been done (INIT = 1) or not.
! IPUP   = Saved flag to signal updating of Newton matrix.
! JCUR   = Output flag from DVJAC showing Jacobian status:
!            JCUR = 0 means J is not current.
!            JCUR = 1 means J is current.
! JSTART = Integer flag used as input to DVSTEP:
!            0  means perform the first step.
!            1  means take a new step continuing from the last.
!            -1 means take the next step with a new value of MAXORD,
!                  HMIN, HMXI, N, METH, MITER, and/or matrix parameters.
!          On return, DVSTEP sets JSTART = 1.
! JSV    = Integer flag for Jacobian saving, = sign(MF).
! KFLAG  = A completion code from DVSTEP with the following meanings:
!               0      the step was succesful.
!              -1      the requested error could not be achieved.
!              -2      corrector convergence could not be achieved.
!              -3, -4  fatal error in VNLS (can not occur here).
! KUTH   = Input flag to DVSTEP showing whether H was reduced by the
!          driver.  KUTH = 1 if H was reduced, = 0 otherwise.
! L      = Integer variable, NQ + 1, current order plus one.
! LMAX   = MAXORD + 1 (used for dimensioning).
! LOCJS  = A pointer to the saved Jacobian, whose storage starts at
!          WM(LOCJS), if JSV = 1.
! LYH, LEWT, LACOR, LSAVF, LWM, LIWM = Saved integer pointers
!          to segments of RWORK and IWORK.
! MAXORD = The maximum order of integration method to be allowed.
! METH/MITER = The method flags.  See MF.
! MSBJ   = The maximum number of steps between J evaluations, = 50.
! MXHNIL = Saved value of optional input MXHNIL.
! MXSTEP = Saved value of optional input MXSTEP.
! N      = The number of first-order ODEs, = NEQ.
! NEWH   = Saved integer to flag change of H.
! NEWQ   = The method order to be used on the next step.
! NHNIL  = Saved counter for occurrences of T + H = T.
! NQ     = Integer variable, the current integration method order.
! NQNYH  = Saved value of NQ*NYH.
! NQWAIT = A counter controlling the frequency of order changes.
!          An order change is about to be considered if NQWAIT = 1.
! NSLJ   = The number of steps taken as of the last Jacobian update.
! NSLP   = Saved value of NST as of last Newton matrix update.
! NYH    = Saved value of the initial value of NEQ.
! HU     = The step size in t last used.
! NCFN   = Number of nonlinear convergence failures so far.
! NETF   = The number of error test failures of the integrator so far.
! NFE    = The number of f evaluations for the problem so far.
! NJE    = The number of Jacobian evaluations so far.
! NLU    = The number of matrix LU decompositions so far.
! NNI    = Number of nonlinear iterations so far.
! NQU    = The method order last used.
! NST    = The number of steps taken for the problem so far.
!-----------------------------------------------------------------------
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
      COMMON / DVOD02 / HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,MORD,MXHNL0,MXSTP0,ZERO,ONE,TWO,  &
!$omp&FOUR,PT2,HUN)
!
      DATA MORD (1) / 12 /, MORD (2) / 5 /, MXSTP0 / 500 /, MXHNL0 / 10 &
      /
      DATA ZERO / 0.0D0 /, ONE / 1.0D0 /, TWO / 2.0D0 /, FOUR / 4.0D0 /,&
      PT2 / 0.2D0 /, HUN / 100.0D0 /
!-----------------------------------------------------------------------
! Block A.
! This code block is executed on every call.
! It tests ISTATE and ITASK for legality and branches appropriately.
! If ISTATE .gt. 1 but the flag INIT shows that initialization has
! not yet been done, an error return occurs.
! If ISTATE = 1 and TOUT = T, return immediately.
!
         JSUB = ipar(34)
         IG = ipar(35)
         RTOL = RtolIn

! All integers are correctly passed and referenced:
! note also that size ( <double precision array> ) returns the
!   correct length!!!
!         write (*,*) JSUB, IG, "In DVODE_v01.f90 :: INIT =", INIT,        &
!           "(TIN,TOUT)=",T,TOUT,"(ITASK,ISTATE)=",ITASK,ISTATE
         latol = size( ATOL ); lstate = size( Y ); lrwork = size( rwork )
         lrpar = size( RPAR ); lipar = size( IPAR ); liwork = size( iwork )
!         write (*,*) "sizeof( ATOL, Y, rwork, iwork, rpar, ipar) =",     &
!           latol, lstate, lrwork, liwork, lrpar, lipar
!         write (*,*) JSUB, IG, "MF,LIW,LRW,NEQ",MF,LIW,LRW,NEQ
!         write (*,*) JSUB, IG, "ITASK,ISTATE,IOPT", ITASK,ISTATE,IOPT
!         write (*,*) JSUB, IG, "IWORK",IWORK(1)

! All doubles (even scalars) cause Illegal Instruction : 4
!  at first reference:
! update: above is only true for many threads ... if threads
! are kept at 2 or 1, program runs perfectly, w/3, program
! runs to incorrect result.
!         write (*,*) JSUB, IG, "ATOL",ATOL(1),ATOL(20)
!         write (*,*) JSUB, IG, "RTOL,ITOL,RtolIn",RTOL,ITOL,RtolIn
!         write (*,*) JSUB, IG, "RPAR", RPAR(24), RPAR(25)
!         write (*,*) JSUB, IG, "Y",Y(1),Y(2),Y(3)
!         write (*,*) JSUB, IG, "RWORK",RWORK(1),RWORK(2)

!         write (*,*) JSUB, IG, "Testing ISTATE", ISTATE
!
! wmy2017Oct18 -- wrote test_mn.f and test_SR.f90 and compiled
!   both w/ -fopen -c, then -fopen to make executable and works!
! wmy2017Oct17 -- Following compilation instructions do not fix
!   the illegal instruction : 4 run-time error
! gfortran -O3 -w -fopenmp -fmax-stack-var-size=32768 -Wl, \
!   -stack_size -Wl,4000000  -o <exec> <files>
!

! wmy2017Oct17 -- following return will generate the illegal
!  instruction on subject 2, as expected
!          if (JSUB .eq. 1 ) return
!
!-----------------------------------------------------------------------
      IF (ISTATE.LT.1.OR.ISTATE.GT.3) GOTO 601
      IF (ITASK.LT.1.OR.ITASK.GT.5) GOTO 602
      IF (ISTATE.EQ.1) GOTO 10
      IF (INIT.NE.1) GOTO 603
      IF (ISTATE.EQ.2) GOTO 200
      GOTO 20
   10 INIT = 0
! wmy2017Oct16 -- debugging
! correct statement is:
!      IF (TOUT.EQ.T) RETURN
! above is replaced by follwing block to see if 
! the code returns as expected.
      IF (TOUT.EQ.T) then
        write (*,*) JSUB,IG,"is aborting DVODE_v01.f90 w/T=TOUT=",T
        RETURN
      end if
!-----------------------------------------------------------------------
! Block B.
! The next code block is executed for the initial call (ISTATE = 1),
! or for a continuation call with parameter changes (ISTATE = 3).
! It contains checking of all input and various initializations.
!
! First check legality of the non-optional input NEQ, ITOL, IOPT,
! MF, ML, and MU.
!-----------------------------------------------------------------------
   20 IF (NEQ.LE.0) GOTO 604
      IF (ISTATE.EQ.1) GOTO 25
      IF (NEQ.GT.N) GOTO 605
   25 N = NEQ
      IF (ITOL.LT.1.OR.ITOL.GT.4) GOTO 606
      IF (IOPT.LT.0.OR.IOPT.GT.1) GOTO 607
      JSV = SIGN (1, MF)
      MFA = ABS (MF)
      METH = MFA / 10
      MITER = MFA - 10 * METH
      IF (METH.LT.1.OR.METH.GT.2) GOTO 608
      IF (MITER.LT.0.OR.MITER.GT.5) GOTO 608
      IF (MITER.LE.3) GOTO 30
      ML = IWORK (1)
      MU = IWORK (2)
      IF (ML.LT.0.OR.ML.GE.N) GOTO 609
      IF (MU.LT.0.OR.MU.GE.N) GOTO 610
   30 CONTINUE
! Next process and check the optional input. ---------------------------
      IF (IOPT.EQ.1) GOTO 40
      MAXORD = MORD (METH)
      MXSTEP = MXSTP0
      MXHNIL = MXHNL0
      IF (ISTATE.EQ.1) H0 = ZERO
      HMXI = ZERO
      HMIN = ZERO
      GOTO 60
   40 MAXORD = IWORK (5)
      IF (MAXORD.LT.0) GOTO 611
      IF (MAXORD.EQ.0) MAXORD = 100
      MAXORD = MIN (MAXORD, MORD (METH) )
      MXSTEP = IWORK (6)
      IF (MXSTEP.LT.0) GOTO 612
      IF (MXSTEP.EQ.0) MXSTEP = MXSTP0
      MXHNIL = IWORK (7)
      IF (MXHNIL.LT.0) GOTO 613
      IF (MXHNIL.EQ.0) MXHNIL = MXHNL0
      IF (ISTATE.NE.1) GOTO 50
      H0 = RWORK (5)
      IF ( (TOUT - T) * H0.LT.ZERO) GOTO 614
   50 HMAX = RWORK (6)
      IF (HMAX.LT.ZERO) GOTO 615
      HMXI = ZERO
      IF (HMAX.GT.ZERO) HMXI = ONE / HMAX
      HMIN = RWORK (7)
      IF (HMIN.LT.ZERO) GOTO 616
!-----------------------------------------------------------------------
! Set work array pointers and check lengths LRW and LIW.
! Pointers to segments of RWORK and IWORK are named by prefixing L to
! the name of the segment.  E.g., the segment YH starts at RWORK(LYH).
! Segments of RWORK (in order) are denoted  YH, WM, EWT, SAVF, ACOR.
! Within WM, LOCJS is the location of the saved Jacobian (JSV .gt. 0).
!-----------------------------------------------------------------------
   60 LYH = 21
      IF (ISTATE.EQ.1) NYH = N
      LWM = LYH + (MAXORD+1) * NYH
      JCO = MAX (0, JSV)
      IF (MITER.EQ.0) LENWM = 0
      IF (MITER.EQ.1.OR.MITER.EQ.2) THEN
         LENWM = 2 + (1 + JCO) * N * N
         LOCJS = N * N + 3
      ENDIF
      IF (MITER.EQ.3) LENWM = 2 + N
      IF (MITER.EQ.4.OR.MITER.EQ.5) THEN
         MBAND = ML + MU + 1
         LENP = (MBAND+ML) * N
         LENJ = MBAND * N
         LENWM = 2 + LENP + JCO * LENJ
         LOCJS = LENP + 3
      ENDIF
      LEWT = LWM + LENWM
      LSAVF = LEWT + N
      LACOR = LSAVF + N
      LENRW = LACOR + N - 1
      IWORK (17) = LENRW
      LIWM = 1
      LENIW = 30 + N
      IF (MITER.EQ.0.OR.MITER.EQ.3) LENIW = 30
      IWORK (18) = LENIW
      IF (LENRW.GT.LRW) GOTO 617
      IF (LENIW.GT.LIW) GOTO 618
! Check RTOL and ATOL for legality. ------------------------------------
      RTOLI = RTOL
      ATOLI = ATOL (1)
      DO 70 I = 1, N
         IF (ITOL.GE.3) RTOLI = RTOL
         IF (ITOL.EQ.2.OR.ITOL.EQ.4) ATOLI = ATOL (I)
         IF (RTOLI.LT.ZERO) GOTO 619
         IF (ATOLI.LT.ZERO) GOTO 620
   70 END DO
      IF (ISTATE.EQ.1) GOTO 100
! If ISTATE = 3, set flag to signal parameter changes to DVSTEP. -------
      JSTART = - 1
      IF (NQ.LE.MAXORD) GOTO 90
! MAXORD was reduced below NQ.  Copy YH(*,MAXORD+2) into SAVF. ---------
      CALL DCOPY (N, RWORK (LWM), 1, RWORK (LSAVF), 1)
! Reload WM(1) = RWORK(LWM), since LWM may have changed. ---------------
   90 IF (MITER.GT.0) RWORK (LWM) = SQRT (UROUND)
      GOTO 200
!-----------------------------------------------------------------------
! Block C.
! The next block is for the initial call only (ISTATE = 1).
! It contains all remaining initializations, the initial call to F,
! and the calculation of the initial step size.
! The error weights in EWT are inverted after being loaded.
!-----------------------------------------------------------------------
  100 UROUND = DUMACH ()
      TN = T
      IF (ITASK.NE.4.AND.ITASK.NE.5) GOTO 110
      TCRIT = RWORK (1)
      IF ( (TCRIT - TOUT) * (TOUT - T) .LT.ZERO) GOTO 625
      IF (H0.NE.ZERO.AND. (T + H0 - TCRIT) * H0.GT.ZERO) H0 = TCRIT - T
  110 JSTART = 0
      IF (MITER.GT.0) RWORK (LWM) = SQRT (UROUND)
      CCMXJ = PT2
      MSBJ = 50
      NHNIL = 0
      NST = 0
      NJE = 0
      NNI = 0
      NCFN = 0
      NETF = 0
      NLU = 0
      NSLJ = 0
      NSLAST = 0
      HU = ZERO
      NQU = 0
! Initial call to F.  (LF0 points to YH(*,2).) -------------------------
      LF0 = LYH + NYH
      CALL F (N, T, Y, RWORK (LF0), RPAR, IPAR)
      NFE = 1
! Load the initial value vector in YH. ---------------------------------
      CALL DCOPY (N, Y, 1, RWORK (LYH), 1)
! Load and invert the EWT array.  (H is temporarily set to 1.0.) -------
      NQ = 1
      H = ONE
      CALL DEWSET (N, ITOL, RTOL, ATOL, RWORK (LYH), RWORK (LEWT) )
      DO 120 I = 1, N
         IF (RWORK (I + LEWT - 1) .LE.ZERO) GOTO 621
  120 RWORK (I + LEWT - 1) = ONE / RWORK (I + LEWT - 1)
      IF (H0.NE.ZERO) GOTO 180
! Call DVHIN to set initial step size H0 to be attempted. --------------
      CALL DVHIN (N, T, RWORK (LYH), RWORK (LF0), F, RPAR, IPAR, TOUT,  &
      UROUND, RWORK (LEWT), ITOL, ATOL, Y, RWORK (LACOR), H0, NITER,    &
      IER)
      NFE = NFE+NITER
      IF (IER.NE.0) GOTO 622
! Adjust H0 if necessary to meet HMAX bound. ---------------------------
  180 RH = ABS (H0) * HMXI
      IF (RH.GT.ONE) H0 = H0 / RH
! Load H with H0 and scale YH(*,2) by H0. ------------------------------
      H = H0
      CALL DSCAL (N, H0, RWORK (LF0), 1)
      GOTO 270
!-----------------------------------------------------------------------
! Block D.
! The next code block is for continuation calls only (ISTATE = 2 or 3)
! and is to check stop conditions before taking a step.
!-----------------------------------------------------------------------
  200 NSLAST = NST
      KUTH = 0
      GOTO (210, 250, 220, 230, 240), ITASK
  210 IF ( (TN - TOUT) * H.LT.ZERO) GOTO 250
      CALL DVINDY (TOUT, 0, RWORK (LYH), NYH, Y, IFLAG)
      IF (IFLAG.NE.0) GOTO 627
      T = TOUT
      GOTO 420
  220 TP = TN - HU * (ONE+HUN * UROUND)
      IF ( (TP - TOUT) * H.GT.ZERO) GOTO 623
      IF ( (TN - TOUT) * H.LT.ZERO) GOTO 250
      GOTO 400
  230 TCRIT = RWORK (1)
      IF ( (TN - TCRIT) * H.GT.ZERO) GOTO 624
      IF ( (TCRIT - TOUT) * H.LT.ZERO) GOTO 625
      IF ( (TN - TOUT) * H.LT.ZERO) GOTO 245
      CALL DVINDY (TOUT, 0, RWORK (LYH), NYH, Y, IFLAG)
      IF (IFLAG.NE.0) GOTO 627
      T = TOUT
      GOTO 420
  240 TCRIT = RWORK (1)
      IF ( (TN - TCRIT) * H.GT.ZERO) GOTO 624
  245 HMX = ABS (TN) + ABS (H)
      IHIT = ABS (TN - TCRIT) .LE.HUN * UROUND * HMX
      IF (IHIT) GOTO 400
      TNEXT = TN + HNEW * (ONE+FOUR * UROUND)
      IF ( (TNEXT - TCRIT) * H.LE.ZERO) GOTO 250
      H = (TCRIT - TN) * (ONE-FOUR * UROUND)
      KUTH = 1
!-----------------------------------------------------------------------
! Block E.
! The next block is normally executed for all calls and contains
! the call to the one-step core integrator DVSTEP.
!
! This is a looping point for the integration steps.
!
! First check for too many steps being taken, update EWT (if not at
! start of problem), check for too much accuracy being requested, and
! check for H below the roundoff level in T.
!-----------------------------------------------------------------------
  250 CONTINUE
      IF ( (NST - NSLAST) .GE.MXSTEP) GOTO 500
      CALL DEWSET (N, ITOL, RTOL, ATOL, RWORK (LYH), RWORK (LEWT) )
      DO 260 I = 1, N
         IF (RWORK (I + LEWT - 1) .LE.ZERO) GOTO 510
  260 RWORK (I + LEWT - 1) = ONE / RWORK (I + LEWT - 1)
  270 TOLSF = UROUND * DVNORM (N, RWORK (LYH), RWORK (LEWT) )
      IF (TOLSF.LE.ONE) GOTO 280
      TOLSF = TOLSF * TWO
      IF (NST.EQ.0) GOTO 626
      GOTO 520
  280 IF ( (TN + H) .NE.TN) GOTO 290
      NHNIL = NHNIL + 1
      IF (NHNIL.GT.MXHNIL) GOTO 290
      MSG = 'DVODE--  Warning: internal T (=R1) and H (=R2) are'
      CALL XERRWD (MSG, 50, 101, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      such that in the machine, T + H = T on the next step &
     & '
      CALL XERRWD (MSG, 60, 101, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      (H = step size). solver will continue anyway'
      CALL XERRWD (MSG, 50, 101, 1, 0, 0, 0, 2, TN, H)
      IF (NHNIL.LT.MXHNIL) GOTO 290
      MSG = 'DVODE--  Above warning has been issued I1 times.  '
      CALL XERRWD (MSG, 50, 102, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      it will not be issued again for this problem'
      CALL XERRWD (MSG, 50, 102, 1, 1, MXHNIL, 0, 0, ZERO, ZERO)
  290 CONTINUE
!-----------------------------------------------------------------------
! CALL DVSTEP (Y, YH, NYH, YH, EWT, SAVF, VSAV, ACOR,
!              WM, IWM, F, JAC, F, DVNLSD, RPAR, IPAR)
!-----------------------------------------------------------------------
      CALL DVSTEP (Y, RWORK (LYH), NYH, RWORK (LYH), RWORK (LEWT),      &
      RWORK (LSAVF), Y, RWORK (LACOR), RWORK (LWM), IWORK (LIWM),       &
      F, JAC, F, DVNLSD, RPAR, IPAR)
      KGO = 1 - KFLAG
! Branch on KFLAG.  Note: In this version, KFLAG can not be set to -3.
!  KFLAG .eq. 0,   -1,  -2
      GOTO (300, 530, 540), KGO
!-----------------------------------------------------------------------
! Block F.
! The following block handles the case of a successful return from the
! core integrator (KFLAG = 0).  Test for stop conditions.
!-----------------------------------------------------------------------
  300 INIT = 1
      KUTH = 0
      GOTO (310, 400, 330, 340, 350), ITASK
! ITASK = 1.  If TOUT has been reached, interpolate. -------------------
  310 IF ( (TN - TOUT) * H.LT.ZERO) GOTO 250
      CALL DVINDY (TOUT, 0, RWORK (LYH), NYH, Y, IFLAG)
      T = TOUT
      GOTO 420
! ITASK = 3.  Jump to exit if TOUT was reached. ------------------------
  330 IF ( (TN - TOUT) * H.GE.ZERO) GOTO 400
      GOTO 250
! ITASK = 4.  See if TOUT or TCRIT was reached.  Adjust H if necessary.
  340 IF ( (TN - TOUT) * H.LT.ZERO) GOTO 345
      CALL DVINDY (TOUT, 0, RWORK (LYH), NYH, Y, IFLAG)
      T = TOUT
      GOTO 420
  345 HMX = ABS (TN) + ABS (H)
      IHIT = ABS (TN - TCRIT) .LE.HUN * UROUND * HMX
      IF (IHIT) GOTO 400
      TNEXT = TN + HNEW * (ONE+FOUR * UROUND)
      IF ( (TNEXT - TCRIT) * H.LE.ZERO) GOTO 250
      H = (TCRIT - TN) * (ONE-FOUR * UROUND)
      KUTH = 1
      GOTO 250
! ITASK = 5.  See if TCRIT was reached and jump to exit. ---------------
  350 HMX = ABS (TN) + ABS (H)
      IHIT = ABS (TN - TCRIT) .LE.HUN * UROUND * HMX
!-----------------------------------------------------------------------
! Block G.
! The following block handles all successful returns from DVODE.
! If ITASK .ne. 1, Y is loaded from YH and T is set accordingly.
! ISTATE is set to 2, and the optional output is loaded into the work
! arrays before returning.
!-----------------------------------------------------------------------
  400 CONTINUE
      CALL DCOPY (N, RWORK (LYH), 1, Y, 1)
      T = TN
      IF (ITASK.NE.4.AND.ITASK.NE.5) GOTO 420
      IF (IHIT) T = TCRIT
  420 ISTATE = 2
      RWORK (11) = HU
      RWORK (12) = HNEW
      RWORK (13) = TN
      IWORK (11) = NST
      IWORK (12) = NFE
      IWORK (13) = NJE
      IWORK (14) = NQU
      IWORK (15) = NEWQ
      IWORK (19) = NLU
      IWORK (20) = NNI
      IWORK (21) = NCFN
      IWORK (22) = NETF
      RETURN
!-----------------------------------------------------------------------
! Block H.
! The following block handles all unsuccessful returns other than
! those for illegal input.  First the error message routine is called.
! if there was an error test or convergence test failure, IMXER is set.
! Then Y is loaded from YH, and T is set to TN.
! The optional output is loaded into the work arrays before returning.
!-----------------------------------------------------------------------
! The maximum number of steps was taken before reaching TOUT. ----------
  500 MSG = 'DVODE--  At current T (=R1), MXSTEP (=I1) steps   '
      CALL XERRWD (MSG, 50, 201, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      taken on this call before reaching TOUT     '
      CALL XERRWD (MSG, 50, 201, 1, 1, MXSTEP, 0, 1, TN, ZERO)
      ISTATE = - 1
      GOTO 580
! EWT(i) .le. 0.0 for some i (not at start of problem). ----------------
  510 EWTI = RWORK (LEWT + I - 1)
      MSG = 'DVODE--  At T (=R1), EWT(I1) has become R2 .le. 0.'
      CALL XERRWD (MSG, 50, 202, 1, 1, I, 0, 2, TN, EWTI)
      ISTATE = - 6
      GOTO 580
! Too much accuracy requested for machine precision. -------------------
  520 MSG = 'DVODE--  At T (=R1), too much accuracy requested  '
      CALL XERRWD (MSG, 50, 203, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      for precision of machine:   see TOLSF (=R2) '
      CALL XERRWD (MSG, 50, 203, 1, 0, 0, 0, 2, TN, TOLSF)
      RWORK (14) = TOLSF
      ISTATE = - 2
      GOTO 580
! KFLAG = -1.  Error test failed repeatedly or with ABS(H) = HMIN. -----
  530 MSG = 'DVODE--  At T(=R1) and step size H(=R2), the error'
      CALL XERRWD (MSG, 50, 204, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      test failed repeatedly or with abs(H) = HMIN'
      CALL XERRWD (MSG, 50, 204, 1, 0, 0, 0, 2, TN, H)
      ISTATE = - 4
      GOTO 560
! KFLAG = -2.  Convergence failed repeatedly or with ABS(H) = HMIN. ----
  540 MSG = 'DVODE--  At T (=R1) and step size H (=R2), the    '
      CALL XERRWD (MSG, 50, 205, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      corrector convergence failed repeatedly     '
      CALL XERRWD (MSG, 50, 205, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      or with abs(H) = HMIN   '
      CALL XERRWD (MSG, 30, 205, 1, 0, 0, 0, 2, TN, H)
      ISTATE = - 5
! Compute IMXER if relevant. -------------------------------------------
  560 BIG = ZERO
      IMXER = 1
      DO 570 I = 1, N
         SSSIZE = ABS (RWORK (I + LACOR - 1) * RWORK (I + LEWT - 1) )
         IF (BIG.GE.SSSIZE) GOTO 570
         BIG = SSSIZE
         IMXER = I
  570 END DO
      IWORK (16) = IMXER
! Set Y vector, T, and optional output. --------------------------------
  580 CONTINUE
      CALL DCOPY (N, RWORK (LYH), 1, Y, 1)
      T = TN
      RWORK (11) = HU
      RWORK (12) = H
      RWORK (13) = TN
      IWORK (11) = NST
      IWORK (12) = NFE
      IWORK (13) = NJE
      IWORK (14) = NQU
      IWORK (15) = NQ
      IWORK (19) = NLU
      IWORK (20) = NNI
      IWORK (21) = NCFN
      IWORK (22) = NETF
      RETURN
!-----------------------------------------------------------------------
! Block I.
! The following block handles all error returns due to illegal input
! (ISTATE = -3), as detected before calling the core integrator.
! First the error message routine is called.   If the illegal input
! is a negative ISTATE, the run is aborted (apparent infinite loop).
!-----------------------------------------------------------------------
  601 MSG = 'DVODE--  ISTATE (=I1) illegal '
      CALL XERRWD (MSG, 30, 1, 1, 1, ISTATE, 0, 0, ZERO, ZERO)
      IF (ISTATE.LT.0) GOTO 800
      GOTO 700
  602 MSG = 'DVODE--  ITASK (=I1) illegal  '
      CALL XERRWD (MSG, 30, 2, 1, 1, ITASK, 0, 0, ZERO, ZERO)
      GOTO 700
  603 MSG = 'DVODE--  ISTATE (=I1) .gt. 1 but DVODE not initialized     &
     & '
      CALL XERRWD (MSG, 60, 3, 1, 1, ISTATE, 0, 0, ZERO, ZERO)
      GOTO 700
  604 MSG = 'DVODE--  NEQ (=I1) .lt. 1     '
      CALL XERRWD (MSG, 30, 4, 1, 1, NEQ, 0, 0, ZERO, ZERO)
      GOTO 700
  605 MSG = 'DVODE--  ISTATE = 3 and NEQ increased (I1 to I2)  '
      CALL XERRWD (MSG, 50, 5, 1, 2, N, NEQ, 0, ZERO, ZERO)
      GOTO 700
  606 MSG = 'DVODE--  ITOL (=I1) illegal   '
      CALL XERRWD (MSG, 30, 6, 1, 1, ITOL, 0, 0, ZERO, ZERO)
      GOTO 700
  607 MSG = 'DVODE--  IOPT (=I1) illegal   '
      CALL XERRWD (MSG, 30, 7, 1, 1, IOPT, 0, 0, ZERO, ZERO)
      GOTO 700
  608 MSG = 'DVODE--  MF (=I1) illegal     '
      CALL XERRWD (MSG, 30, 8, 1, 1, MF, 0, 0, ZERO, ZERO)
      GOTO 700
  609 MSG = 'DVODE--  ML (=I1) illegal:  .lt.0 or .ge.NEQ (=I2)'
      CALL XERRWD (MSG, 50, 9, 1, 2, ML, NEQ, 0, ZERO, ZERO)
      GOTO 700
  610 MSG = 'DVODE--  MU (=I1) illegal:  .lt.0 or .ge.NEQ (=I2)'
      CALL XERRWD (MSG, 50, 10, 1, 2, MU, NEQ, 0, ZERO, ZERO)
      GOTO 700
  611 MSG = 'DVODE--  MAXORD (=I1) .lt. 0  '
      CALL XERRWD (MSG, 30, 11, 1, 1, MAXORD, 0, 0, ZERO, ZERO)
      GOTO 700
  612 MSG = 'DVODE--  MXSTEP (=I1) .lt. 0  '
      CALL XERRWD (MSG, 30, 12, 1, 1, MXSTEP, 0, 0, ZERO, ZERO)
      GOTO 700
  613 MSG = 'DVODE--  MXHNIL (=I1) .lt. 0  '
      CALL XERRWD (MSG, 30, 13, 1, 1, MXHNIL, 0, 0, ZERO, ZERO)
      GOTO 700
  614 MSG = 'DVODE--  TOUT (=R1) behind T (=R2)      '
      CALL XERRWD (MSG, 40, 14, 1, 0, 0, 0, 2, TOUT, T)
      MSG = '      integration direction is given by H0 (=R1)  '
      CALL XERRWD (MSG, 50, 14, 1, 0, 0, 0, 1, H0, ZERO)
      GOTO 700
  615 MSG = 'DVODE--  HMAX (=R1) .lt. 0.0  '
      CALL XERRWD (MSG, 30, 15, 1, 0, 0, 0, 1, HMAX, ZERO)
      GOTO 700
  616 MSG = 'DVODE--  HMIN (=R1) .lt. 0.0  '
      CALL XERRWD (MSG, 30, 16, 1, 0, 0, 0, 1, HMIN, ZERO)
      GOTO 700
  617 CONTINUE
      MSG = 'DVODE--  RWORK length needed, LENRW (=I1), exceeds LRW (=I2&
     &)'
      CALL XERRWD (MSG, 60, 17, 1, 2, LENRW, LRW, 0, ZERO, ZERO)
      GOTO 700
  618 CONTINUE
      MSG = 'DVODE--  IWORK length needed, LENIW (=I1), exceeds LIW (=I2&
     &)'
      CALL XERRWD (MSG, 60, 18, 1, 2, LENIW, LIW, 0, ZERO, ZERO)
      GOTO 700
  619 MSG = 'DVODE--  RTOL(I1) is R1 .lt. 0.0        '
      CALL XERRWD (MSG, 40, 19, 1, 1, I, 0, 1, RTOLI, ZERO)
      GOTO 700
  620 MSG = 'DVODE--  ATOL(I1) is R1 .lt. 0.0        '
      CALL XERRWD (MSG, 40, 20, 1, 1, I, 0, 1, ATOLI, ZERO)
      GOTO 700
  621 EWTI = RWORK (LEWT + I - 1)
      MSG = 'DVODE--  EWT(I1) is R1 .le. 0.0         '
      CALL XERRWD (MSG, 40, 21, 1, 1, I, 0, 1, EWTI, ZERO)
      GOTO 700
  622 CONTINUE
      MSG = 'DVODE--  TOUT (=R1) too close to T(=R2) to start integratio&
     &n'
      CALL XERRWD (MSG, 60, 22, 1, 0, 0, 0, 2, TOUT, T)
      GOTO 700
  623 CONTINUE
      MSG = 'DVODE--  ITASK = I1 and TOUT (=R1) behind TCUR - HU (= R2) &
     & '
      CALL XERRWD (MSG, 60, 23, 1, 1, ITASK, 0, 2, TOUT, TP)
      GOTO 700
  624 CONTINUE
      MSG = 'DVODE--  ITASK = 4 or 5 and TCRIT (=R1) behind TCUR (=R2)  &
     & '
      CALL XERRWD (MSG, 60, 24, 1, 0, 0, 0, 2, TCRIT, TN)
      GOTO 700
  625 CONTINUE
      MSG = 'DVODE--  ITASK = 4 or 5 and TCRIT (=R1) behind TOUT (=R2)  &
     & '
      CALL XERRWD (MSG, 60, 25, 1, 0, 0, 0, 2, TCRIT, TOUT)
      GOTO 700
  626 MSG = 'DVODE--  At start of problem, too much accuracy   '
      CALL XERRWD (MSG, 50, 26, 1, 0, 0, 0, 0, ZERO, ZERO)
      MSG = '      requested for precision of machine:   see TOLSF (=R1)&
     & '
      CALL XERRWD (MSG, 60, 26, 1, 0, 0, 0, 1, TOLSF, ZERO)
      RWORK (14) = TOLSF
      GOTO 700
  627 MSG = 'DVODE--  Trouble from DVINDY.  ITASK = I1, TOUT = R1.      &
     & '
      CALL XERRWD (MSG, 60, 27, 1, 1, ITASK, 0, 1, TOUT, ZERO)
!
  700 CONTINUE
      ISTATE = - 3
      RETURN
!
  800 MSG = 'DVODE--  Run aborted:  apparent infinite loop     '
      CALL XERRWD (MSG, 50, 303, 2, 0, 0, 0, 0, ZERO, ZERO)
      RETURN
!----------------------- End of Subroutine DVODE -----------------------
      END SUBROUTINE DVODE
!*DECK DVHIN
      SUBROUTINE DVHIN (N, T0, Y0, YDOT, F, RPAR, IPAR, TOUT, UROUND,   &
      EWT, ITOL, ATOL, Y, TEMP, H0, NITER, IER)
      EXTERNAL F
      DOUBLEPRECISION T0, Y0, YDOT, RPAR, TOUT, UROUND, EWT, ATOL, Y,   &
      TEMP, H0
      INTEGER N, IPAR, ITOL, NITER, IER
      DIMENSION Y0 ( * ), YDOT ( * ), EWT ( * ), ATOL ( * ), Y ( * ),   &
      TEMP ( * ), RPAR ( * ), IPAR ( * )
!-----------------------------------------------------------------------
! Call sequence input -- N, T0, Y0, YDOT, F, RPAR, IPAR, TOUT, UROUND,
!                        EWT, ITOL, ATOL, Y, TEMP
! Call sequence output -- H0, NITER, IER
! COMMON block variables accessed -- None
!
! Subroutines called by DVHIN:  F
! Function routines called by DVHI: DVNORM
!-----------------------------------------------------------------------
! This routine computes the step size, H0, to be attempted on the
! first step, when the user has not supplied a value for this.
!
! First we check that TOUT - T0 differs significantly from zero.  Then
! an iteration is done to approximate the initial second derivative
! and this is used to define h from w.r.m.s.norm(h**2 * yddot / 2) = 1.
! A bias factor of 1/2 is applied to the resulting h.
! The sign of H0 is inferred from the initial values of TOUT and T0.
!
! Communication with DVHIN is done with the following variables:
!
! N      = Size of ODE system, input.
! T0     = Initial value of independent variable, input.
! Y0     = Vector of initial conditions, input.
! YDOT   = Vector of initial first derivatives, input.
! F      = Name of subroutine for right-hand side f(t,y), input.
! RPAR, IPAR = Dummy names for user's real and integer work arrays.
! TOUT   = First output value of independent variable
! UROUND = Machine unit roundoff
! EWT, ITOL, ATOL = Error weights and tolerance parameters
!                   as described in the driver routine, input.
! Y, TEMP = Work arrays of length N.
! H0     = Step size to be attempted, output.
! NITER  = Number of iterations (and of f evaluations) to compute H0,
!          output.
! IER    = The error flag, returned with the value
!          IER = 0  if no trouble occurred, or
!          IER = -1 if TOUT and T0 are considered too close to proceed.
!-----------------------------------------------------------------------
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION AFI, ATOLI, DELYI, H, HALF, HG, HLB, HNEW, HRAT,  &
      HUB, HUN, PT1, T1, TDIST, TROUND, TWO, YDDNRM
      INTEGER I, ITER
!
! Type declaration for function subroutines called ---------------------
!
      DOUBLEPRECISION DVNORM
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE HALF, HUN, PT1, TWO
      DATA HALF / 0.5D0 /, HUN / 100.0D0 /, PT1 / 0.1D0 /, TWO / 2.0D0 /
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(HALF, HUN, PT1, TWO)
!
      NITER = 0
      TDIST = ABS (TOUT - T0)
      TROUND = UROUND * MAX (ABS (T0), ABS (TOUT) )
      IF (TDIST.LT.TWO * TROUND) GOTO 100
!
! Set a lower bound on h based on the roundoff level in T0 and TOUT. ---
      HLB = HUN * TROUND
! Set an upper bound on h based on TOUT-T0 and the initial Y and YDOT. -
      HUB = PT1 * TDIST
      ATOLI = ATOL (1)
      DO 10 I = 1, N
         IF (ITOL.EQ.2.OR.ITOL.EQ.4) ATOLI = ATOL (I)
         DELYI = PT1 * ABS (Y0 (I) ) + ATOLI
         AFI = ABS (YDOT (I) )
         IF (AFI * HUB.GT.DELYI) HUB = DELYI / AFI
   10 END DO
!
! Set initial guess for h as geometric mean of upper and lower bounds. -
      ITER = 0
      HG = SQRT (HLB * HUB)
! If the bounds have crossed, exit with the mean value. ----------------
      IF (HUB.LT.HLB) THEN
         H0 = HG
         GOTO 90
      ENDIF
!
! Looping point for iteration. -----------------------------------------
   50 CONTINUE
! Estimate the second derivative as a difference quotient in f. --------
      H = SIGN (HG, TOUT - T0)
      T1 = T0 + H
      DO 60 I = 1, N
   60 Y (I) = Y0 (I) + H * YDOT (I)
      CALL F (N, T1, Y, TEMP, RPAR, IPAR)
      DO 70 I = 1, N
   70 TEMP (I) = (TEMP (I) - YDOT (I) ) / H
      YDDNRM = DVNORM (N, TEMP, EWT)
! Get the corresponding new value of h. --------------------------------
      IF (YDDNRM * HUB * HUB.GT.TWO) THEN
         HNEW = SQRT (TWO / YDDNRM)
      ELSE
         HNEW = SQRT (HG * HUB)
      ENDIF
      ITER = ITER + 1
!-----------------------------------------------------------------------
! Test the stopping conditions.
! Stop if the new and previous h values differ by a factor of .lt. 2.
! Stop if four iterations have been done.  Also, stop with previous h
! if HNEW/HG .gt. 2 after first iteration, as this probably means that
! the second derivative value is bad because of cancellation error.
!-----------------------------------------------------------------------
      IF (ITER.GE.4) GOTO 80
      HRAT = HNEW / HG
      IF ( (HRAT.GT.HALF) .AND. (HRAT.LT.TWO) ) GOTO 80
      IF ( (ITER.GE.2) .AND. (HNEW.GT.TWO * HG) ) THEN
         HNEW = HG
         GOTO 80
      ENDIF
      HG = HNEW
      GOTO 50
!
! Iteration done.  Apply bounds, bias factor, and sign.  Then exit. ----
   80 H0 = HNEW * HALF
      IF (H0.LT.HLB) H0 = HLB
      IF (H0.GT.HUB) H0 = HUB
   90 H0 = SIGN (H0, TOUT - T0)
      NITER = ITER
      IER = 0
      RETURN
! Error return for TOUT - T0 too small. --------------------------------
  100 IER = - 1
      RETURN
!----------------------- End of Subroutine DVHIN -----------------------
      END SUBROUTINE DVHIN
!*DECK DVINDY
      SUBROUTINE DVINDY (T, K, YH, LDYH, DKY, IFLAG)
      DOUBLEPRECISION T, YH, DKY
      INTEGER K, LDYH, IFLAG
      DIMENSION YH (LDYH, * ), DKY ( * )
!-----------------------------------------------------------------------
! Call sequence input -- T, K, YH, LDYH
! Call sequence output -- DKY, IFLAG
! COMMON block variables accessed:
!     /DVOD01/ --  H, TN, UROUND, L, N, NQ
!     /DVOD02/ --  HU
!
! Subroutines called by DVINDY: DSCAL, XERRWD
! Function routines called by DVINDY: None
!-----------------------------------------------------------------------
! DVINDY computes interpolated values of the K-th derivative of the
! dependent variable vector y, and stores it in DKY.  This routine
! is called within the package with K = 0 and T = TOUT, but may
! also be called by the user for any K up to the current order.
! (See detailed instructions in the usage documentation.)
!-----------------------------------------------------------------------
! The computed values in DKY are gotten by interpolation using the
! Nordsieck history array YH.  This array corresponds uniquely to a
! vector-valued polynomial of degree NQCUR or less, and DKY is set
! to the K-th derivative of this polynomial at T.
! The formula for DKY is:
!              q
!  DKY(i)  =  sum  c(j,K) * (T - TN)**(j-K) * H**(-j) * YH(i,j+1)
!             j=K
! where  c(j,K) = j*(j-1)*...*(j-K+1), q = NQCUR, TN = TCUR, H = HCUR.
! The quantities  NQ = NQCUR, L = NQ+1, N, TN, and H are
! communicated by COMMON.  The above sum is done in reverse order.
! IFLAG is returned negative if either K or T is out of bounds.
!
! Discussion above and comments in driver explain all variables.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for labeled COMMON block DVOD02 --------------------
!
      DOUBLEPRECISION HU
      INTEGER NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION C, HUN, R, S, TFUZZ, TN1, TP, ZERO
      INTEGER I, IC, J, JB, JB2, JJ, JJ1, JP1
      CHARACTER(80) MSG
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE HUN, ZERO
!
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
      COMMON / DVOD02 / HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,HUN,ZERO)
!
      DATA HUN / 100.0D0 /, ZERO / 0.0D0 /
!
      IFLAG = 0
      IF (K.LT.0.OR.K.GT.NQ) GOTO 80
      TFUZZ = HUN * UROUND * (TN + HU)
      TP = TN - HU - TFUZZ
      TN1 = TN + TFUZZ
      IF ( (T - TP) * (T - TN1) .GT.ZERO) GOTO 90
!
      S = (T - TN) / H
      IC = 1
      IF (K.EQ.0) GOTO 15
      JJ1 = L - K
      DO 10 JJ = JJ1, NQ
   10 IC = IC * JJ
   15 C = REAL (IC)
      DO 20 I = 1, N
   20 DKY (I) = C * YH (I, L)
      IF (K.EQ.NQ) GOTO 55
      JB2 = NQ - K
      DO 50 JB = 1, JB2
         J = NQ - JB
         JP1 = J + 1
         IC = 1
         IF (K.EQ.0) GOTO 35
         JJ1 = JP1 - K
         DO 30 JJ = JJ1, J
   30    IC = IC * JJ
   35    C = REAL (IC)
         DO 40 I = 1, N
   40    DKY (I) = C * YH (I, JP1) + S * DKY (I)
   50 END DO
      IF (K.EQ.0) RETURN
   55 R = H** ( - K)
      CALL DSCAL (N, R, DKY, 1)
      RETURN
!
   80 MSG = 'DVINDY-- K (=I1) illegal      '
      CALL XERRWD (MSG, 30, 51, 1, 1, K, 0, 0, ZERO, ZERO)
      IFLAG = - 1
      RETURN
   90 MSG = 'DVINDY-- T (=R1) illegal      '
      CALL XERRWD (MSG, 30, 52, 1, 0, 0, 0, 1, T, ZERO)
      MSG = '      T not in interval TCUR - HU (= R1) to TCUR (=R2)     &
     & '
      CALL XERRWD (MSG, 60, 52, 1, 0, 0, 0, 2, TP, TN)
      IFLAG = - 2
      RETURN
!----------------------- End of Subroutine DVINDY ----------------------
      END SUBROUTINE DVINDY
!*DECK DVSTEP
      SUBROUTINE DVSTEP (Y, YH, LDYH, YH1, EWT, SAVF, VSAV, ACOR, WM,   &
      IWM, F, JAC, PSOL, VNLS, RPAR, IPAR)
      EXTERNAL F, JAC, PSOL, VNLS
      DOUBLEPRECISION Y, YH, YH1, EWT, SAVF, VSAV, ACOR, WM, RPAR
      INTEGER LDYH, IWM, IPAR
      DIMENSION Y ( * ), YH (LDYH, * ), YH1 ( * ), EWT ( * ), SAVF ( * )&
      , VSAV ( * ), ACOR ( * ), WM ( * ), IWM ( * ), RPAR ( * ),        &
      IPAR ( * )
!-----------------------------------------------------------------------
! Call sequence input -- Y, YH, LDYH, YH1, EWT, SAVF, VSAV,
!                        ACOR, WM, IWM, F, JAC, PSOL, VNLS, RPAR, IPAR
! Call sequence output -- YH, ACOR, WM, IWM
! COMMON block variables accessed:
!     /DVOD01/  ACNRM, EL(13), H, HMIN, HMXI, HNEW, HSCAL, RC, TAU(13),
!               TQ(5), TN, JCUR, JSTART, KFLAG, KUTH,
!               L, LMAX, MAXORD, N, NEWQ, NQ, NQWAIT
!     /DVOD02/  HU, NCFN, NETF, NFE, NQU, NST
!
! Subroutines called by DVSTEP: F, DAXPY, DCOPY, DSCAL,
!                               DVJUST, VNLS, DVSET
! Function routines called by DVSTEP: DVNORM
!-----------------------------------------------------------------------
! DVSTEP performs one step of the integration of an initial value
! problem for a system of ordinary differential equations.
! DVSTEP calls subroutine VNLS for the solution of the nonlinear system
! arising in the time step.  Thus it is independent of the problem
! Jacobian structure and the type of nonlinear system solution method.
! DVSTEP returns a completion flag KFLAG (in COMMON).
! A return with KFLAG = -1 or -2 means either ABS(H) = HMIN or 10
! consecutive failures occurred.  On a return with KFLAG negative,
! the values of TN and the YH array are as of the beginning of the last
! step, and H is the last step size attempted.
!
! Communication with DVSTEP is done with the following variables:
!
! Y      = An array of length N used for the dependent variable vector.
! YH     = An LDYH by LMAX array containing the dependent variables
!          and their approximate scaled derivatives, where
!          LMAX = MAXORD + 1.  YH(i,j+1) contains the approximate
!          j-th derivative of y(i), scaled by H**j/factorial(j)
!          (j = 0,1,...,NQ).  On entry for the first step, the first
!          two columns of YH must be set from the initial values.
! LDYH   = A constant integer .ge. N, the first dimension of YH.
!          N is the number of ODEs in the system.
! YH1    = A one-dimensional array occupying the same space as YH.
! EWT    = An array of length N containing multiplicative weights
!          for local error measurements.  Local errors in y(i) are
!          compared to 1.0/EWT(i) in various error tests.
! SAVF   = An array of working storage, of length N.
!          also used for input of YH(*,MAXORD+2) when JSTART = -1
!          and MAXORD .lt. the current order NQ.
! VSAV   = A work array of length N passed to subroutine VNLS.
! ACOR   = A work array of length N, used for the accumulated
!          corrections.  On a successful return, ACOR(i) contains
!          the estimated one-step local error in y(i).
! WM,IWM = Real and integer work arrays associated with matrix
!          operations in VNLS.
! F      = Dummy name for the user supplied subroutine for f.
! JAC    = Dummy name for the user supplied Jacobian subroutine.
! PSOL   = Dummy name for the subroutine passed to VNLS, for
!          possible use there.
! VNLS   = Dummy name for the nonlinear system solving subroutine,
!          whose real name is dependent on the method used.
! RPAR, IPAR = Dummy names for user's real and integer work arrays.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for labeled COMMON block DVOD02 --------------------
!
      DOUBLEPRECISION HU
      INTEGER NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION ADDON, BIAS1, BIAS2, BIAS3, CNQUOT, DDN, DSM, DUP,&
      ETACF, ETAMIN, ETAMX1, ETAMX2, ETAMX3, ETAMXF, ETAQ, ETAQM1,      &
      ETAQP1, FLOTL, ONE, ONEPSM, R, THRESH, TOLD, ZERO
      INTEGER I, I1, I2, IBACK, J, JB, KFC, KFH, MXNCF, NCF, NFLAG
!
! Type declaration for function subroutines called ---------------------
!
      DOUBLEPRECISION DVNORM
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE ADDON, BIAS1, BIAS2, BIAS3, ETACF, ETAMIN, ETAMX1, ETAMX2,   &
      ETAMX3, ETAMXF, ETAQ, ETAQM1, KFC, KFH, MXNCF, ONEPSM, THRESH,    &
      ONE, ZERO
!-----------------------------------------------------------------------
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
      COMMON / DVOD02 / HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,ADDON,BIAS1,BIAS2,BIAS3,ETACF, &
!$omp&ETAMIN,ETAMX1,ETAMX2,ETAMX3,ETAMXF,KFC,KFH,MXNCF,ONEPSM,THRESH, &
!$omp&ONE,ZERO)
!
! wmy2017Nov09 -- These are missing in above !$omp ThreadPrivate()
!$omp Threadprivate(ETAQ,ETAQM1)

      DATA KFC / - 3 /, KFH / - 7 /, MXNCF / 10 /
      DATA ADDON / 1.0D-6 /, BIAS1 / 6.0D0 /, BIAS2 / 6.0D0 /, BIAS3 /  &
      10.0D0 /, ETACF / 0.25D0 /, ETAMIN / 0.1D0 /, ETAMXF / 0.2D0 /,   &
      ETAMX1 / 1.0D4 /, ETAMX2 / 10.0D0 /, ETAMX3 / 10.0D0 /, ONEPSM /  &
      1.00001D0 /, THRESH / 1.5D0 /
      DATA ONE / 1.0D0 /, ZERO / 0.0D0 /
!
      KFLAG = 0
      TOLD = TN
      NCF = 0
      JCUR = 0
      NFLAG = 0
      IF (JSTART.GT.0) GOTO 20
      IF (JSTART.EQ. - 1) GOTO 100
!-----------------------------------------------------------------------
! On the first call, the order is set to 1, and other variables are
! initialized.  ETAMAX is the maximum ratio by which H can be increased
! in a single step.  It is normally 10, but is larger during the
! first step to compensate for the small initial H.  If a failure
! occurs (in corrector convergence or error test), ETAMAX is set to 1
! for the next increase.
!-----------------------------------------------------------------------
      LMAX = MAXORD+1
      NQ = 1
      L = 2
      NQNYH = NQ * LDYH
      TAU (1) = H
      PRL1 = ONE
      RC = ZERO
      ETAMAX = ETAMX1
      NQWAIT = 2
      HSCAL = H
      GOTO 200
!-----------------------------------------------------------------------
! Take preliminary actions on a normal continuation step (JSTART.GT.0).
! If the driver changed H, then ETA must be reset and NEWH set to 1.
! If a change of order was dictated on the previous step, then
! it is done here and appropriate adjustments in the history are made.
! On an order decrease, the history array is adjusted by DVJUST.
! On an order increase, the history array is augmented by a column.
! On a change of step size H, the history array YH is rescaled.
!-----------------------------------------------------------------------
   20 CONTINUE
      IF (KUTH.EQ.1) THEN
         ETA = MIN (ETA, H / HSCAL)
         NEWH = 1
      ENDIF
   50 IF (NEWH.EQ.0) GOTO 200
      IF (NEWQ.EQ.NQ) GOTO 150
      IF (NEWQ.LT.NQ) THEN
         CALL DVJUST (YH, LDYH, - 1)
         NQ = NEWQ
         L = NQ + 1
         NQWAIT = L
         GOTO 150
      ENDIF
      IF (NEWQ.GT.NQ) THEN
         CALL DVJUST (YH, LDYH, 1)
         NQ = NEWQ
         L = NQ + 1
         NQWAIT = L
         GOTO 150
      ENDIF
!-----------------------------------------------------------------------
! The following block handles preliminaries needed when JSTART = -1.
! If N was reduced, zero out part of YH to avoid undefined references.
! If MAXORD was reduced to a value less than the tentative order NEWQ,
! then NQ is set to MAXORD, and a new H ratio ETA is chosen.
! Otherwise, we take the same preliminary actions as for JSTART .gt. 0.
! In any case, NQWAIT is reset to L = NQ + 1 to prevent further
! changes in order for that many steps.
! The new H ratio ETA is limited by the input H if KUTH = 1,
! by HMIN if KUTH = 0, and by HMXI in any case.
! Finally, the history array YH is rescaled.
!-----------------------------------------------------------------------
  100 CONTINUE
      LMAX = MAXORD+1
      IF (N.EQ.LDYH) GOTO 120
      I1 = 1 + (NEWQ + 1) * LDYH
      I2 = (MAXORD+1) * LDYH
      IF (I1.GT.I2) GOTO 120
      DO 110 I = I1, I2
  110 YH1 (I) = ZERO
  120 IF (NEWQ.LE.MAXORD) GOTO 140
      FLOTL = REAL (LMAX)
      IF (MAXORD.LT.NQ - 1) THEN
         DDN = DVNORM (N, SAVF, EWT) / TQ (1)
         ETA = ONE / ( (BIAS1 * DDN) ** (ONE / FLOTL) + ADDON)
      ENDIF
      IF (MAXORD.EQ.NQ.AND.NEWQ.EQ.NQ + 1) ETA = ETAQ
      IF (MAXORD.EQ.NQ - 1.AND.NEWQ.EQ.NQ + 1) THEN
         ETA = ETAQM1
         CALL DVJUST (YH, LDYH, - 1)
      ENDIF
      IF (MAXORD.EQ.NQ - 1.AND.NEWQ.EQ.NQ) THEN
         DDN = DVNORM (N, SAVF, EWT) / TQ (1)
         ETA = ONE / ( (BIAS1 * DDN) ** (ONE / FLOTL) + ADDON)
         CALL DVJUST (YH, LDYH, - 1)
      ENDIF
      ETA = MIN (ETA, ONE)
      NQ = MAXORD
      L = LMAX
  140 IF (KUTH.EQ.1) ETA = MIN (ETA, ABS (H / HSCAL) )
      IF (KUTH.EQ.0) ETA = MAX (ETA, HMIN / ABS (HSCAL) )
      ETA = ETA / MAX (ONE, ABS (HSCAL) * HMXI * ETA)
      NEWH = 1
      NQWAIT = L
      IF (NEWQ.LE.MAXORD) GOTO 50
! Rescale the history array for a change in H by a factor of ETA. ------
  150 R = ONE
      DO 180 J = 2, L
         R = R * ETA
         CALL DSCAL (N, R, YH (1, J), 1)
  180 END DO
      H = HSCAL * ETA
      HSCAL = H
      RC = RC * ETA
      NQNYH = NQ * LDYH
!-----------------------------------------------------------------------
! This section computes the predicted values by effectively
! multiplying the YH array by the Pascal triangle matrix.
! DVSET is called to calculate all integration coefficients.
! RC is the ratio of new to old values of the coefficient H/EL(2)=h/l1.
!-----------------------------------------------------------------------
  200 TN = TN + H
      I1 = NQNYH + 1
      DO 220 JB = 1, NQ
         I1 = I1 - LDYH
         DO 210 I = I1, NQNYH
  210    YH1 (I) = YH1 (I) + YH1 (I + LDYH)
  220 END DO
      CALL DVSET
      RL1 = ONE / EL (2)
      RC = RC * (RL1 / PRL1)
      PRL1 = RL1
!
! Call the nonlinear system solver. ------------------------------------
!
      CALL VNLS (Y, YH, LDYH, VSAV, SAVF, EWT, ACOR, IWM, WM, F, JAC,   &
      PSOL, NFLAG, RPAR, IPAR)
!
      IF (NFLAG.EQ.0) GOTO 450
!-----------------------------------------------------------------------
! The VNLS routine failed to achieve convergence (NFLAG .NE. 0).
! The YH array is retracted to its values before prediction.
! The step size H is reduced and the step is retried, if possible.
! Otherwise, an error exit is taken.
!-----------------------------------------------------------------------
      NCF = NCF + 1
      NCFN = NCFN + 1
      ETAMAX = ONE
      TN = TOLD
      I1 = NQNYH + 1
      DO 430 JB = 1, NQ
         I1 = I1 - LDYH
         DO 420 I = I1, NQNYH
  420    YH1 (I) = YH1 (I) - YH1 (I + LDYH)
  430 END DO
      IF (NFLAG.LT. - 1) GOTO 680
      IF (ABS (H) .LE.HMIN * ONEPSM) GOTO 670
      IF (NCF.EQ.MXNCF) GOTO 670
      ETA = ETACF
      ETA = MAX (ETA, HMIN / ABS (H) )
      NFLAG = - 1
      GOTO 150
!-----------------------------------------------------------------------
! The corrector has converged (NFLAG = 0).  The local error test is
! made and control passes to statement 500 if it fails.
!-----------------------------------------------------------------------
  450 CONTINUE
      DSM = ACNRM / TQ (2)
      IF (DSM.GT.ONE) GOTO 500
!-----------------------------------------------------------------------
! After a successful step, update the YH and TAU arrays and decrement
! NQWAIT.  If NQWAIT is then 1 and NQ .lt. MAXORD, then ACOR is saved
! for use in a possible order increase on the next step.
! If ETAMAX = 1 (a failure occurred this step), keep NQWAIT .ge. 2.
!-----------------------------------------------------------------------
      KFLAG = 0
      NST = NST + 1
      HU = H
      NQU = NQ
      DO 470 IBACK = 1, NQ
         I = L - IBACK
  470 TAU (I + 1) = TAU (I)
      TAU (1) = H
      DO 480 J = 1, L
         CALL DAXPY (N, EL (J), ACOR, 1, YH (1, J), 1)
  480 END DO
      NQWAIT = NQWAIT - 1
      IF ( (L.EQ.LMAX) .OR. (NQWAIT.NE.1) ) GOTO 490
      CALL DCOPY (N, ACOR, 1, YH (1, LMAX), 1)
      CONP = TQ (5)
  490 IF (ETAMAX.NE.ONE) GOTO 560
      IF (NQWAIT.LT.2) NQWAIT = 2
      NEWQ = NQ
      NEWH = 0
      ETA = ONE
      HNEW = H
      GOTO 690
!-----------------------------------------------------------------------
! The error test failed.  KFLAG keeps track of multiple failures.
! Restore TN and the YH array to their previous values, and prepare
! to try the step again.  Compute the optimum step size for the
! same order.  After repeated failures, H is forced to decrease
! more rapidly.
!-----------------------------------------------------------------------
  500 KFLAG = KFLAG - 1
      NETF = NETF + 1
      NFLAG = - 2
      TN = TOLD
      I1 = NQNYH + 1
      DO 520 JB = 1, NQ
         I1 = I1 - LDYH
         DO 510 I = I1, NQNYH
  510    YH1 (I) = YH1 (I) - YH1 (I + LDYH)
  520 END DO
      IF (ABS (H) .LE.HMIN * ONEPSM) GOTO 660
      ETAMAX = ONE
      IF (KFLAG.LE.KFC) GOTO 530
! Compute ratio of new H to current H at the current order. ------------
      FLOTL = REAL (L)
      ETA = ONE / ( (BIAS2 * DSM) ** (ONE / FLOTL) + ADDON)
      ETA = MAX (ETA, HMIN / ABS (H), ETAMIN)
      IF ( (KFLAG.LE. - 2) .AND. (ETA.GT.ETAMXF) ) ETA = ETAMXF
      GOTO 150
!-----------------------------------------------------------------------
! Control reaches this section if 3 or more consecutive failures
! have occurred.  It is assumed that the elements of the YH array
! have accumulated errors of the wrong order.  The order is reduced
! by one, if possible.  Then H is reduced by a factor of 0.1 and
! the step is retried.  After a total of 7 consecutive failures,
! an exit is taken with KFLAG = -1.
!-----------------------------------------------------------------------
  530 IF (KFLAG.EQ.KFH) GOTO 660
      IF (NQ.EQ.1) GOTO 540
      ETA = MAX (ETAMIN, HMIN / ABS (H) )
      CALL DVJUST (YH, LDYH, - 1)
      L = NQ
      NQ = NQ - 1
      NQWAIT = L
      GOTO 150
  540 ETA = MAX (ETAMIN, HMIN / ABS (H) )
      H = H * ETA
      HSCAL = H
      TAU (1) = H
      CALL F (N, TN, Y, SAVF, RPAR, IPAR)
      NFE = NFE+1
      DO 550 I = 1, N
  550 YH (I, 2) = H * SAVF (I)
      NQWAIT = 10
      GOTO 200
!-----------------------------------------------------------------------
! If NQWAIT = 0, an increase or decrease in order by one is considered.
! Factors ETAQ, ETAQM1, ETAQP1 are computed by which H could
! be multiplied at order q, q-1, or q+1, respectively.
! The largest of these is determined, and the new order and
! step size set accordingly.
! A change of H or NQ is made only if H increases by at least a
! factor of THRESH.  If an order change is considered and rejected,
! then NQWAIT is set to 2 (reconsider it after 2 steps).
!-----------------------------------------------------------------------
! Compute ratio of new H to current H at the current order. ------------
  560 FLOTL = REAL (L)
      ETAQ = ONE / ( (BIAS2 * DSM) ** (ONE / FLOTL) + ADDON)
      IF (NQWAIT.NE.0) GOTO 600
      NQWAIT = 2
      ETAQM1 = ZERO
      IF (NQ.EQ.1) GOTO 570
! Compute ratio of new H to current H at the current order less one. ---
      DDN = DVNORM (N, YH (1, L), EWT) / TQ (1)
      ETAQM1 = ONE / ( (BIAS1 * DDN) ** (ONE / (FLOTL - ONE) ) + ADDON)
  570 ETAQP1 = ZERO
      IF (L.EQ.LMAX) GOTO 580
! Compute ratio of new H to current H at current order plus one. -------
      CNQUOT = (TQ (5) / CONP) * (H / TAU (2) ) **L
      DO 575 I = 1, N
  575 SAVF (I) = ACOR (I) - CNQUOT * YH (I, LMAX)
      DUP = DVNORM (N, SAVF, EWT) / TQ (3)
      ETAQP1 = ONE / ( (BIAS3 * DUP) ** (ONE / (FLOTL + ONE) ) + ADDON)
  580 IF (ETAQ.GE.ETAQP1) GOTO 590
      IF (ETAQP1.GT.ETAQM1) GOTO 620
      GOTO 610
  590 IF (ETAQ.LT.ETAQM1) GOTO 610
  600 ETA = ETAQ
      NEWQ = NQ
      GOTO 630
  610 ETA = ETAQM1
      NEWQ = NQ - 1
      GOTO 630
  620 ETA = ETAQP1
      NEWQ = NQ + 1
      CALL DCOPY (N, ACOR, 1, YH (1, LMAX), 1)
! Test tentative new H against THRESH, ETAMAX, and HMXI, then exit. ----
  630 IF (ETA.LT.THRESH.OR.ETAMAX.EQ.ONE) GOTO 640
      ETA = MIN (ETA, ETAMAX)
      ETA = ETA / MAX (ONE, ABS (H) * HMXI * ETA)
      NEWH = 1
      HNEW = H * ETA
      GOTO 690
  640 NEWQ = NQ
      NEWH = 0
      ETA = ONE
      HNEW = H
      GOTO 690
!-----------------------------------------------------------------------
! All returns are made through this section.
! On a successful return, ETAMAX is reset and ACOR is scaled.
!-----------------------------------------------------------------------
  660 KFLAG = - 1
      GOTO 720
  670 KFLAG = - 2
      GOTO 720
  680 IF (NFLAG.EQ. - 2) KFLAG = - 3
      IF (NFLAG.EQ. - 3) KFLAG = - 4
      GOTO 720
  690 ETAMAX = ETAMX3
      IF (NST.LE.10) ETAMAX = ETAMX2
  700 R = ONE / TQ (2)
      CALL DSCAL (N, R, ACOR, 1)
  720 JSTART = 1
      RETURN
!----------------------- End of Subroutine DVSTEP ----------------------
      END SUBROUTINE DVSTEP



!*DECK DVSET
      SUBROUTINE DVSET
!-----------------------------------------------------------------------
! Call sequence communication: None
! COMMON block variables accessed:
!     /DVOD01/ -- EL(13), H, TAU(13), TQ(5), L(= NQ + 1),
!                 METH, NQ, NQWAIT
!
! Subroutines called by DVSET: None
! Function routines called by DVSET: None
!-----------------------------------------------------------------------
! DVSET is called by DVSTEP and sets coefficients for use there.
!
! For each order NQ, the coefficients in EL are calculated by use of
!  the generating polynomial lambda(x), with coefficients EL(i).
!      lambda(x) = EL(1) + EL(2)*x + ... + EL(NQ+1)*(x**NQ).
! For the backward differentiation formulas,
!                                     NQ-1
!      lambda(x) = (1 + x/xi*(NQ)) * product (1 + x/xi(i) ) .
!                                     i = 1
! For the Adams formulas,
!                              NQ-1
!      (d/dx) lambda(x) = c * product (1 + x/xi(i) ) ,
!                              i = 1
!      lambda(-1) = 0,    lambda(0) = 1,
! where c is a normalization constant.
! In both cases, xi(i) is defined by
!      H*xi(i) = t sub n  -  t sub (n-i)
!              = H + TAU(1) + TAU(2) + ... TAU(i-1).
!
!
! In addition to variables described previously, communication
! with DVSET uses the following:
!   TAU    = A vector of length 13 containing the past NQ values
!            of H.
!   EL     = A vector of length 13 in which vset stores the
!            coefficients for the corrector formula.
!   TQ     = A vector of length 5 in which vset stores constants
!            used for the convergence test, the error test, and the
!            selection of H at a new order.
!   METH   = The basic method indicator.
!   NQ     = The current order.
!   L      = NQ + 1, the length of the vector stored in EL, and
!            the number of columns of the YH array being used.
!   NQWAIT = A counter controlling the frequency of order changes.
!            An order change is about to be considered if NQWAIT = 1.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION AHATN0, ALPH0, CNQM1, CORTES, CSUM, ELP, EM, EM0, &
      FLOTI, FLOTL, FLOTNQ, HSUM, ONE, RXI, RXIS, S, SIX, T1, T2, T3,   &
      T4, T5, T6, TWO, XI, ZERO
      INTEGER I, IBACK, J, JP1, NQM1, NQM2
!
      DIMENSION EM (13)
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE CORTES, ONE, SIX, TWO, ZERO
!
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
!
      DATA CORTES / 0.1D0 /
      DATA ONE / 1.0D0 /, SIX / 6.0D0 /, TWO / 2.0D0 /, ZERO / 0.0D0 /
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,CORTES, ONE, SIX, TWO, ZERO)
!
      FLOTL = REAL (L)
      NQM1 = NQ - 1
      NQM2 = NQ - 2
      GOTO (100, 200), METH
!
! Set coefficients for Adams methods. ----------------------------------
  100 IF (NQ.NE.1) GOTO 110
      EL (1) = ONE
      EL (2) = ONE
      TQ (1) = ONE
      TQ (2) = TWO
      TQ (3) = SIX * TQ (2)
      TQ (5) = ONE
      GOTO 300
  110 HSUM = H
      EM (1) = ONE
      FLOTNQ = FLOTL - ONE
      DO 115 I = 2, L
  115 EM (I) = ZERO
      DO 150 J = 1, NQM1
         IF ( (J.NE.NQM1) .OR. (NQWAIT.NE.1) ) GOTO 130
         S = ONE
         CSUM = ZERO
         DO 120 I = 1, NQM1
            CSUM = CSUM + S * EM (I) / REAL (I + 1)
  120    S = - S
         TQ (1) = EM (NQM1) / (FLOTNQ * CSUM)
  130    RXI = H / HSUM
         DO 140 IBACK = 1, J
            I = (J + 2) - IBACK
  140    EM (I) = EM (I) + EM (I - 1) * RXI
         HSUM = HSUM + TAU (J)
  150 END DO
! Compute integral from -1 to 0 of polynomial and of x times it. -------
      S = ONE
      EM0 = ZERO
      CSUM = ZERO
      DO 160 I = 1, NQ
         FLOTI = REAL (I)
         EM0 = EM0 + S * EM (I) / FLOTI
         CSUM = CSUM + S * EM (I) / (FLOTI + ONE)
  160 S = - S
! In EL, form coefficients of normalized integrated polynomial. --------
      S = ONE / EM0
      EL (1) = ONE
      DO 170 I = 1, NQ
  170 EL (I + 1) = S * EM (I) / REAL (I)
      XI = HSUM / H
      TQ (2) = XI * EM0 / CSUM
      TQ (5) = XI / EL (L)
      IF (NQWAIT.NE.1) GOTO 300
! For higher order control constant, multiply polynomial by 1+x/xi(q). -
      RXI = ONE / XI
      DO 180 IBACK = 1, NQ
         I = (L + 1) - IBACK
  180 EM (I) = EM (I) + EM (I - 1) * RXI
! Compute integral of polynomial. --------------------------------------
      S = ONE
      CSUM = ZERO
      DO 190 I = 1, L
         CSUM = CSUM + S * EM (I) / REAL (I + 1)
  190 S = - S
      TQ (3) = FLOTL * EM0 / CSUM
      GOTO 300
!
! Set coefficients for BDF methods. ------------------------------------
  200 DO 210 I = 3, L
  210 EL (I) = ZERO
      EL (1) = ONE
      EL (2) = ONE
      ALPH0 = - ONE
      AHATN0 = - ONE
      HSUM = H
      RXI = ONE
      RXIS = ONE
      IF (NQ.EQ.1) GOTO 240
      DO 230 J = 1, NQM2
! In EL, construct coefficients of (1+x/xi(1))*...*(1+x/xi(j+1)). ------
         HSUM = HSUM + TAU (J)
         RXI = H / HSUM
         JP1 = J + 1
         ALPH0 = ALPH0 - ONE / REAL (JP1)
         DO 220 IBACK = 1, JP1
            I = (J + 3) - IBACK
  220    EL (I) = EL (I) + EL (I - 1) * RXI
  230 END DO
      ALPH0 = ALPH0 - ONE / REAL (NQ)
      RXIS = - EL (2) - ALPH0
      HSUM = HSUM + TAU (NQM1)
      RXI = H / HSUM
      AHATN0 = - EL (2) - RXI
      DO 235 IBACK = 1, NQ
         I = (NQ + 2) - IBACK
  235 EL (I) = EL (I) + EL (I - 1) * RXIS
  240 T1 = ONE-AHATN0 + ALPH0
      T2 = ONE+REAL (NQ) * T1
      TQ (2) = ABS (ALPH0 * T2 / T1)
      TQ (5) = ABS (T2 / (EL (L) * RXI / RXIS) )
      IF (NQWAIT.NE.1) GOTO 300
      CNQM1 = RXIS / EL (L)
      T3 = ALPH0 + ONE / REAL (NQ)
      T4 = AHATN0 + RXI
      ELP = T3 / (ONE-T4 + T3)
      TQ (1) = ABS (ELP / CNQM1)
      HSUM = HSUM + TAU (NQ)
      RXI = H / HSUM
      T5 = ALPH0 - ONE / REAL (NQ + 1)
      T6 = AHATN0 - RXI
      ELP = T2 / (ONE-T6 + T5)
      TQ (3) = ABS (ELP * RXI * (FLOTL + ONE) * T5)
  300 TQ (4) = CORTES * TQ (2)
      RETURN
!----------------------- End of Subroutine DVSET -----------------------
      END SUBROUTINE DVSET



!*DECK DVJUST
      SUBROUTINE DVJUST (YH, LDYH, IORD)
      DOUBLEPRECISION YH
      INTEGER LDYH, IORD
      DIMENSION YH (LDYH, * )
!-----------------------------------------------------------------------
! Call sequence input -- YH, LDYH, IORD
! Call sequence output -- YH
! COMMON block input -- NQ, METH, LMAX, HSCAL, TAU(13), N
! COMMON block variables accessed:
!     /DVOD01/ -- HSCAL, TAU(13), LMAX, METH, N, NQ,
!
! Subroutines called by DVJUST: DAXPY
! Function routines called by DVJUST: None
!-----------------------------------------------------------------------
! This subroutine adjusts the YH array on reduction of order,
! and also when the order is increased for the stiff option (METH = 2).
! Communication with DVJUST uses the following:
! IORD  = An integer flag used when METH = 2 to indicate an order
!         increase (IORD = +1) or an order decrease (IORD = -1).
! HSCAL = Step size H used in scaling of Nordsieck array YH.
!         (If IORD = +1, DVJUST assumes that HSCAL = TAU(1).)
! See References 1 and 2 for details.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION ALPH0, ALPH1, HSUM, ONE, PROD, T1, XI, XIOLD,     &
      ZERO
      INTEGER I, IBACK, J, JP1, LP1, NQM1, NQM2, NQP1
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE ONE, ZERO
!
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,One,Zero)
!
      DATA ONE / 1.0D0 /, ZERO / 0.0D0 /
!
      IF ( (NQ.EQ.2) .AND. (IORD.NE.1) ) RETURN
      NQM1 = NQ - 1
      NQM2 = NQ - 2
      GOTO (100, 200), METH
!-----------------------------------------------------------------------
! Nonstiff option...
! Check to see if the order is being increased or decreased.
!-----------------------------------------------------------------------
  100 CONTINUE
      IF (IORD.EQ.1) GOTO 180
! Order decrease. ------------------------------------------------------
      DO 110 J = 1, LMAX
  110 EL (J) = ZERO
      EL (2) = ONE
      HSUM = ZERO
      DO 130 J = 1, NQM2
! Construct coefficients of x*(x+xi(1))*...*(x+xi(j)). -----------------
         HSUM = HSUM + TAU (J)
         XI = HSUM / HSCAL
         JP1 = J + 1
         DO 120 IBACK = 1, JP1
            I = (J + 3) - IBACK
  120    EL (I) = EL (I) * XI + EL (I - 1)
  130 END DO
! Construct coefficients of integrated polynomial. ---------------------
      DO 140 J = 2, NQM1
  140 EL (J + 1) = REAL (NQ) * EL (J) / REAL (J)
! Subtract correction terms from YH array. -----------------------------
      DO 170 J = 3, NQ
         DO 160 I = 1, N
  160    YH (I, J) = YH (I, J) - YH (I, L) * EL (J)
  170 END DO
      RETURN
! Order increase. ------------------------------------------------------
! Zero out next column in YH array. ------------------------------------
  180 CONTINUE
      LP1 = L + 1
      DO 190 I = 1, N
  190 YH (I, LP1) = ZERO
      RETURN
!-----------------------------------------------------------------------
! Stiff option...
! Check to see if the order is being increased or decreased.
!-----------------------------------------------------------------------
  200 CONTINUE
      IF (IORD.EQ.1) GOTO 300
! Order decrease. ------------------------------------------------------
      DO 210 J = 1, LMAX
  210 EL (J) = ZERO
      EL (3) = ONE
      HSUM = ZERO
      DO 230 J = 1, NQM2
! Construct coefficients of x*x*(x+xi(1))*...*(x+xi(j)). ---------------
         HSUM = HSUM + TAU (J)
         XI = HSUM / HSCAL
         JP1 = J + 1
         DO 220 IBACK = 1, JP1
            I = (J + 4) - IBACK
  220    EL (I) = EL (I) * XI + EL (I - 1)
  230 END DO
! Subtract correction terms from YH array. -----------------------------
      DO 250 J = 3, NQ
         DO 240 I = 1, N
  240    YH (I, J) = YH (I, J) - YH (I, L) * EL (J)
  250 END DO
      RETURN
! Order increase. ------------------------------------------------------
  300 DO 310 J = 1, LMAX
  310 EL (J) = ZERO
      EL (3) = ONE
      ALPH0 = - ONE
      ALPH1 = ONE
      PROD = ONE
      XIOLD = ONE
      HSUM = HSCAL
      IF (NQ.EQ.1) GOTO 340
      DO 330 J = 1, NQM1
! Construct coefficients of x*x*(x+xi(1))*...*(x+xi(j)). ---------------
         JP1 = J + 1
         HSUM = HSUM + TAU (JP1)
         XI = HSUM / HSCAL
         PROD = PROD * XI
         ALPH0 = ALPH0 - ONE / REAL (JP1)
         ALPH1 = ALPH1 + ONE / XI
         DO 320 IBACK = 1, JP1
            I = (J + 4) - IBACK
  320    EL (I) = EL (I) * XIOLD+EL (I - 1)
         XIOLD = XI
  330 END DO
  340 CONTINUE
      T1 = ( - ALPH0 - ALPH1) / PROD
! Load column L + 1 in YH array. ---------------------------------------
      LP1 = L + 1
      DO 350 I = 1, N
  350 YH (I, LP1) = T1 * YH (I, LMAX)
! Add correction terms to YH array. ------------------------------------
      NQP1 = NQ + 1
      DO 370 J = 3, NQP1
         CALL DAXPY (N, EL (J), YH (1, LP1), 1, YH (1, J), 1)
  370 END DO
      RETURN
!----------------------- End of Subroutine DVJUST ----------------------
      END SUBROUTINE DVJUST



!*DECK DVNLSD
      SUBROUTINE DVNLSD (Y, YH, LDYH, VSAV, SAVF, EWT, ACOR, IWM, WM, F,&
      JAC, PDUM, NFLAG, RPAR, IPAR)
      EXTERNAL F, JAC, PDUM
      DOUBLEPRECISION Y, YH, VSAV, SAVF, EWT, ACOR, WM, RPAR
      INTEGER LDYH, IWM, NFLAG, IPAR
      DIMENSION Y ( * ), YH (LDYH, * ), VSAV ( * ), SAVF ( * ), EWT ( * &
      ), ACOR ( * ), IWM ( * ), WM ( * ), RPAR ( * ), IPAR ( * )
!-----------------------------------------------------------------------
! Call sequence input -- Y, YH, LDYH, SAVF, EWT, ACOR, IWM, WM,
!                        F, JAC, NFLAG, RPAR, IPAR
! Call sequence output -- YH, ACOR, WM, IWM, NFLAG
! COMMON block variables accessed:
!     /DVOD01/ ACNRM, CRATE, DRC, H, RC, RL1, TQ(5), TN, ICF,
!                JCUR, METH, MITER, N, NSLP
!     /DVOD02/ HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Subroutines called by DVNLSD: F, DAXPY, DCOPY, DSCAL, DVJAC, DVSOL
! Function routines called by DVNLSD: DVNORM
!-----------------------------------------------------------------------
! Subroutine DVNLSD is a nonlinear system solver, which uses functional
! iteration or a chord (modified Newton) method.  For the chord method
! direct linear algebraic system solvers are used.  Subroutine DVNLSD
! then handles the corrector phase of this integration package.
!
! Communication with DVNLSD is done with the following variables. (For
! more details, please see the comments in the driver subroutine.)
!
! Y          = The dependent variable, a vector of length N, input.
! YH         = The Nordsieck (Taylor) array, LDYH by LMAX, input
!              and output.  On input, it contains predicted values.
! LDYH       = A constant .ge. N, the first dimension of YH, input.
! VSAV       = Unused work array.
! SAVF       = A work array of length N.
! EWT        = An error weight vector of length N, input.
! ACOR       = A work array of length N, used for the accumulated
!              corrections to the predicted y vector.
! WM,IWM     = Real and integer work arrays associated with matrix
!              operations in chord iteration (MITER .ne. 0).
! F          = Dummy name for user supplied routine for f.
! JAC        = Dummy name for user supplied Jacobian routine.
! PDUM       = Unused dummy subroutine name.  Included for uniformity
!              over collection of integrators.
! NFLAG      = Input/output flag, with values and meanings as follows:
!              INPUT
!                  0 first call for this time step.
!                 -1 convergence failure in previous call to DVNLSD.
!                 -2 error test failure in DVSTEP.
!              OUTPUT
!                  0 successful completion of nonlinear solver.
!                 -1 convergence failure or singular matrix.
!                 -2 unrecoverable error in matrix preprocessing
!                    (cannot occur here).
!                 -3 unrecoverable error in solution (cannot occur
!                    here).
! RPAR, IPAR = Dummy names for user's real and integer work arrays.
!
! IPUP       = Own variable flag with values and meanings as follows:
!              0,            do not update the Newton matrix.
!              MITER .ne. 0, update Newton matrix, because it is the
!                            initial step, order was changed, the error
!                            test failed, or an update is indicated by
!                            the scalar RC or step counter NST.
!
! For more details, see comments in driver subroutine.
!-----------------------------------------------------------------------
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for labeled COMMON block DVOD02 --------------------
!
      DOUBLEPRECISION HU
      INTEGER NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION CCMAX, CRDOWN, CSCALE, DCON, DEL, DELP, ONE, RDIV,&
      TWO, ZERO
      INTEGER I, IERPJ, IERSL, M, MAXCOR, MSBP
!
! Type declaration for function subroutines called ---------------------
!
      DOUBLEPRECISION DVNORM
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE CCMAX, CRDOWN, MAXCOR, MSBP, RDIV, ONE, TWO, ZERO
!
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
      COMMON / DVOD02 / HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,CCMAX,CRDOWN,MAXCOR,MSBP,RDIV, &
!$omp&ONE,TWO,ZERO)
! 
      DATA CCMAX / 0.3D0 /, CRDOWN / 0.3D0 /, MAXCOR / 3 /, MSBP / 20 /,&
      RDIV / 2.0D0 /
      DATA ONE / 1.0D0 /, TWO / 2.0D0 /, ZERO / 0.0D0 /
!-----------------------------------------------------------------------
! On the first step, on a change of method order, or after a
! nonlinear convergence failure with NFLAG = -2, set IPUP = MITER
! to force a Jacobian update when MITER .ne. 0.
!-----------------------------------------------------------------------
      IF (JSTART.EQ.0) NSLP = 0
      IF (NFLAG.EQ.0) ICF = 0
      IF (NFLAG.EQ. - 2) IPUP = MITER
      IF ( (JSTART.EQ.0) .OR. (JSTART.EQ. - 1) ) IPUP = MITER
! If this is functional iteration, set CRATE .eq. 1 and drop to 220
      IF (MITER.EQ.0) THEN
         CRATE = ONE
         GOTO 220
      ENDIF
!-----------------------------------------------------------------------
! RC is the ratio of new to old values of the coefficient H/EL(2)=h/l1.
! When RC differs from 1 by more than CCMAX, IPUP is set to MITER
! to force DVJAC to be called, if a Jacobian is involved.
! In any case, DVJAC is called at least every MSBP steps.
!-----------------------------------------------------------------------
      DRC = ABS (RC - ONE)
      IF (DRC.GT.CCMAX.OR.NST.GE.NSLP + MSBP) IPUP = MITER
!-----------------------------------------------------------------------
! Up to MAXCOR corrector iterations are taken.  A convergence test is
! made on the r.m.s. norm of each correction, weighted by the error
! weight vector EWT.  The sum of the corrections is accumulated in the
! vector ACOR(i).  The YH array is not altered in the corrector loop.
!-----------------------------------------------------------------------
  220 M = 0
      DELP = ZERO
      CALL DCOPY (N, YH (1, 1), 1, Y, 1)
      CALL F (N, TN, Y, SAVF, RPAR, IPAR)
      NFE = NFE+1
      IF (IPUP.LE.0) GOTO 250
!-----------------------------------------------------------------------
! If indicated, the matrix P = I - h*rl1*J is reevaluated and
! preprocessed before starting the corrector iteration.  IPUP is set
! to 0 as an indicator that this has been done.
!-----------------------------------------------------------------------
      CALL DVJAC (Y, YH, LDYH, EWT, ACOR, SAVF, WM, IWM, F, JAC, IERPJ, &
      RPAR, IPAR)
      IPUP = 0
      RC = ONE
      DRC = ZERO
      CRATE = ONE
      NSLP = NST
! If matrix is singular, take error return to force cut in step size. --
      IF (IERPJ.NE.0) GOTO 430
  250 DO 260 I = 1, N
  260 ACOR (I) = ZERO
! This is a looping point for the corrector iteration. -----------------
  270 IF (MITER.NE.0) GOTO 350
!-----------------------------------------------------------------------
! In the case of functional iteration, update Y directly from
! the result of the last function evaluation.
!-----------------------------------------------------------------------
      DO 280 I = 1, N
  280 SAVF (I) = RL1 * (H * SAVF (I) - YH (I, 2) )
      DO 290 I = 1, N
  290 Y (I) = SAVF (I) - ACOR (I)
      DEL = DVNORM (N, Y, EWT)
      DO 300 I = 1, N
  300 Y (I) = YH (I, 1) + SAVF (I)
      CALL DCOPY (N, SAVF, 1, ACOR, 1)
      GOTO 400
!-----------------------------------------------------------------------
! In the case of the chord method, compute the corrector error,
! and solve the linear system with that as right-hand side and
! P as coefficient matrix.  The correction is scaled by the factor
! 2/(1+RC) to account for changes in h*rl1 since the last DVJAC call.
!-----------------------------------------------------------------------
  350 DO 360 I = 1, N
  360 Y (I) = (RL1 * H) * SAVF (I) - (RL1 * YH (I, 2) + ACOR (I) )
      CALL DVSOL (WM, IWM, Y, IERSL)
      NNI = NNI + 1
      IF (IERSL.GT.0) GOTO 410
      IF (METH.EQ.2.AND.RC.NE.ONE) THEN
         CSCALE = TWO / (ONE+RC)
         CALL DSCAL (N, CSCALE, Y, 1)
      ENDIF
      DEL = DVNORM (N, Y, EWT)
      CALL DAXPY (N, ONE, Y, 1, ACOR, 1)
      DO 380 I = 1, N
  380 Y (I) = YH (I, 1) + ACOR (I)
!-----------------------------------------------------------------------
! Test for convergence.  If M .gt. 0, an estimate of the convergence
! rate constant is stored in CRATE, and this is used in the test.
!-----------------------------------------------------------------------
  400 IF (M.NE.0) CRATE = MAX (CRDOWN * CRATE, DEL / DELP)
      DCON = DEL * MIN (ONE, CRATE) / TQ (4)
      IF (DCON.LE.ONE) GOTO 450
      M = M + 1
      IF (M.EQ.MAXCOR) GOTO 410
      IF (M.GE.2.AND.DEL.GT.RDIV * DELP) GOTO 410
      DELP = DEL
      CALL F (N, TN, Y, SAVF, RPAR, IPAR)
      NFE = NFE+1
      GOTO 270
!
  410 IF (MITER.EQ.0.OR.JCUR.EQ.1) GOTO 430
      ICF = 1
      IPUP = MITER
      GOTO 220
!
  430 CONTINUE
      NFLAG = - 1
      ICF = 2
      IPUP = MITER
      RETURN
!
! Return for successful step. ------------------------------------------
  450 NFLAG = 0
      JCUR = 0
      ICF = 0
      IF (M.EQ.0) ACNRM = DEL
      IF (M.GT.0) ACNRM = DVNORM (N, ACOR, EWT)
      RETURN
!----------------------- End of Subroutine DVNLSD ----------------------
      END SUBROUTINE DVNLSD


!*DECK DVJAC
      SUBROUTINE DVJAC (Y, YH, LDYH, EWT, FTEM, SAVF, WM, IWM, F, JAC,  &
      IERPJ, RPAR, IPAR)
      EXTERNAL F, JAC
      DOUBLEPRECISION Y, YH, EWT, FTEM, SAVF, WM, RPAR
      INTEGER LDYH, IWM, IERPJ, IPAR
      DIMENSION Y ( * ), YH (LDYH, * ), EWT ( * ), FTEM ( * ), SAVF ( * &
      ), WM ( * ), IWM ( * ), RPAR ( * ), IPAR ( * )
!-----------------------------------------------------------------------
! Call sequence input -- Y, YH, LDYH, EWT, FTEM, SAVF, WM, IWM,
!                        F, JAC, RPAR, IPAR
! Call sequence output -- WM, IWM, IERPJ
! COMMON block variables accessed:
!     /DVOD01/  CCMXJ, DRC, H, RL1, TN, UROUND, ICF, JCUR, LOCJS,
!               MITER, MSBJ, N, NSLJ
!     /DVOD02/  NFE, NST, NJE, NLU
!
! Subroutines called by DVJAC: F, JAC, DACOPY, DCOPY, DGBFA, DGEFA,
!                              DSCAL
! Function routines called by DVJAC: DVNORM
!-----------------------------------------------------------------------
! DVJAC is called by DVNLSD to compute and process the matrix
! P = I - h*rl1*J , where J is an approximation to the Jacobian.
! Here J is computed by the user-supplied routine JAC if
! MITER = 1 or 4, or by finite differencing if MITER = 2, 3, or 5.
! If MITER = 3, a diagonal approximation to J is used.
! If JSV = -1, J is computed from scratch in all cases.
! If JSV = 1 and MITER = 1, 2, 4, or 5, and if the saved value of J is
! considered acceptable, then P is constructed from the saved J.
! J is stored in wm and replaced by P.  If MITER .ne. 3, P is then
! subjected to LU decomposition in preparation for later solution
! of linear systems with P as coefficient matrix. This is done
! by DGEFA if MITER = 1 or 2, and by DGBFA if MITER = 4 or 5.
!
! Communication with DVJAC is done with the following variables.  (For
! more details, please see the comments in the driver subroutine.)
! Y          = Vector containing predicted values on entry.
! YH         = The Nordsieck array, an LDYH by LMAX array, input.
! LDYH       = A constant .ge. N, the first dimension of YH, input.
! EWT        = An error weight vector of length N.
! SAVF       = Array containing f evaluated at predicted y, input.
! WM         = Real work space for matrices.  In the output, it containS
!              the inverse diagonal matrix if MITER = 3 and the LU
!              decomposition of P if MITER is 1, 2 , 4, or 5.
!              Storage of matrix elements starts at WM(3).
!              Storage of the saved Jacobian starts at WM(LOCJS).
!              WM also contains the following matrix-related data:
!              WM(1) = SQRT(UROUND), used in numerical Jacobian step.
!              WM(2) = H*RL1, saved for later use if MITER = 3.
! IWM        = Integer work space containing pivot information,
!              starting at IWM(31), if MITER is 1, 2, 4, or 5.
!              IWM also contains band parameters ML = IWM(1) and
!              MU = IWM(2) if MITER is 4 or 5.
! F          = Dummy name for the user supplied subroutine for f.
! JAC        = Dummy name for the user supplied Jacobian subroutine.
! RPAR, IPAR = Dummy names for user's real and integer work arrays.
! RL1        = 1/EL(2) (input).
! IERPJ      = Output error flag,  = 0 if no trouble, 1 if the P
!              matrix is found to be singular.
! JCUR       = Output flag to indicate whether the Jacobian matrix
!              (or approximation) is now current.
!              JCUR = 0 means J is not current.
!              JCUR = 1 means J is current.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for labeled COMMON block DVOD02 --------------------
!
      DOUBLEPRECISION HU
      INTEGER NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
! Type declarations for local variables --------------------------------
!
      DOUBLEPRECISION CON, DI, FAC, HRL1, ONE, PT1, R, R0, SRUR, THOU,  &
      YI, YJ, YJJ, ZERO
      INTEGER I, I1, I2, IER, II, J, J1, JJ, JOK, LENP, MBA, MBAND,     &
      MEB1, MEBAND, ML, ML3, MU, NP1
!
! Type declaration for function subroutines called ---------------------
!
      DOUBLEPRECISION DVNORM
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this subroutine.
!-----------------------------------------------------------------------
      SAVE ONE, PT1, THOU, ZERO
!-----------------------------------------------------------------------
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
      COMMON / DVOD02 / HU, NCFN, NETF, NFE, NJE, NLU, NNI, NQU, NST
!
      DATA ONE / 1.0D0 /, THOU / 1000.0D0 /, ZERO / 0.0D0 /, PT1 /      &
      0.1D0 /
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,One,PT1,THOU,Zero)
!
      IERPJ = 0
      HRL1 = H * RL1
! See whether J should be evaluated (JOK = -1) or not (JOK = 1). -------
      JOK = JSV
      IF (JSV.EQ.1) THEN
         IF (NST.EQ.0.OR.NST.GT.NSLJ + MSBJ) JOK = - 1
         IF (ICF.EQ.1.AND.DRC.LT.CCMXJ) JOK = - 1
         IF (ICF.EQ.2) JOK = - 1
      ENDIF
! End of setting JOK. --------------------------------------------------
!
      IF (JOK.EQ. - 1.AND.MITER.EQ.1) THEN
! If JOK = -1 and MITER = 1, call JAC to evaluate Jacobian. ------------
         NJE = NJE+1
         NSLJ = NST
         JCUR = 1
         LENP = N * N
         DO 110 I = 1, LENP
  110    WM (I + 2) = ZERO
         CALL JAC (N, TN, Y, 0, 0, WM (3), N, RPAR, IPAR)
         IF (JSV.EQ.1) CALL DCOPY (LENP, WM (3), 1, WM (LOCJS), 1)
      ENDIF
!
      IF (JOK.EQ. - 1.AND.MITER.EQ.2) THEN
! If MITER = 2, make N calls to F to approximate the Jacobian. ---------
         NJE = NJE+1
         NSLJ = NST
         JCUR = 1
         FAC = DVNORM (N, SAVF, EWT)
         R0 = THOU * ABS (H) * UROUND * REAL (N) * FAC
         IF (R0.EQ.ZERO) R0 = ONE
         SRUR = WM (1)
         J1 = 2
         DO 230 J = 1, N
            YJ = Y (J)
            R = MAX (SRUR * ABS (YJ), R0 / EWT (J) )
            Y (J) = Y (J) + R
            FAC = ONE / R
            CALL F (N, TN, Y, FTEM, RPAR, IPAR)
            DO 220 I = 1, N
  220       WM (I + J1) = (FTEM (I) - SAVF (I) ) * FAC
            Y (J) = YJ
            J1 = J1 + N
  230    END DO
         NFE = NFE+N
         LENP = N * N
         IF (JSV.EQ.1) CALL DCOPY (LENP, WM (3), 1, WM (LOCJS), 1)
      ENDIF
!
      IF (JOK.EQ.1.AND. (MITER.EQ.1.OR.MITER.EQ.2) ) THEN
         JCUR = 0
         LENP = N * N
         CALL DCOPY (LENP, WM (LOCJS), 1, WM (3), 1)
      ENDIF
!
      IF (MITER.EQ.1.OR.MITER.EQ.2) THEN
! Multiply Jacobian by scalar, add identity, and do LU decomposition. --
         CON = - HRL1
         CALL DSCAL (LENP, CON, WM (3), 1)
         J = 3
         NP1 = N + 1
         DO 250 I = 1, N
            WM (J) = WM (J) + ONE
  250    J = J + NP1
         NLU = NLU + 1
         CALL DGEFA (WM (3), N, N, IWM (31), IER)
         IF (IER.NE.0) IERPJ = 1
         RETURN
      ENDIF
! End of code block for MITER = 1 or 2. --------------------------------
!
      IF (MITER.EQ.3) THEN
! If MITER = 3, construct a diagonal approximation to J and P. ---------
         NJE = NJE+1
         JCUR = 1
         WM (2) = HRL1
         R = RL1 * PT1
         DO 310 I = 1, N
  310    Y (I) = Y (I) + R * (H * SAVF (I) - YH (I, 2) )
         CALL F (N, TN, Y, WM (3), RPAR, IPAR)
         NFE = NFE+1
         DO 320 I = 1, N
            R0 = H * SAVF (I) - YH (I, 2)
            DI = PT1 * R0 - H * (WM (I + 2) - SAVF (I) )
            WM (I + 2) = ONE
            IF (ABS (R0) .LT.UROUND / EWT (I) ) GOTO 320
            IF (ABS (DI) .EQ.ZERO) GOTO 330
            WM (I + 2) = PT1 * R0 / DI
  320    END DO
         RETURN
  330    IERPJ = 1
         RETURN
      ENDIF
! End of code block for MITER = 3. -------------------------------------
!
! Set constants for MITER = 4 or 5. ------------------------------------
      ML = IWM (1)
      MU = IWM (2)
      ML3 = ML + 3
      MBAND = ML + MU + 1
      MEBAND = MBAND+ML
      LENP = MEBAND * N
!
      IF (JOK.EQ. - 1.AND.MITER.EQ.4) THEN
! If JOK = -1 and MITER = 4, call JAC to evaluate Jacobian. ------------
         NJE = NJE+1
         NSLJ = NST
         JCUR = 1
         DO 410 I = 1, LENP
  410    WM (I + 2) = ZERO
         CALL JAC (N, TN, Y, ML, MU, WM (ML3), MEBAND, RPAR, IPAR)
         IF (JSV.EQ.1) CALL DACOPY (MBAND, N, WM (ML3), MEBAND, WM (    &
         LOCJS), MBAND)
      ENDIF
!
      IF (JOK.EQ. - 1.AND.MITER.EQ.5) THEN
! If MITER = 5, make ML+MU+1 calls to F to approximate the Jacobian. ---
         NJE = NJE+1
         NSLJ = NST
         JCUR = 1
         MBA = MIN (MBAND, N)
         MEB1 = MEBAND-1
         SRUR = WM (1)
         FAC = DVNORM (N, SAVF, EWT)
         R0 = THOU * ABS (H) * UROUND * REAL (N) * FAC
         IF (R0.EQ.ZERO) R0 = ONE
         DO 560 J = 1, MBA
            DO 530 I = J, N, MBAND
               YI = Y (I)
               R = MAX (SRUR * ABS (YI), R0 / EWT (I) )
  530       Y (I) = Y (I) + R
            CALL F (N, TN, Y, FTEM, RPAR, IPAR)
            DO 550 JJ = J, N, MBAND
               Y (JJ) = YH (JJ, 1)
               YJJ = Y (JJ)
               R = MAX (SRUR * ABS (YJJ), R0 / EWT (JJ) )
               FAC = ONE / R
               I1 = MAX (JJ - MU, 1)
               I2 = MIN (JJ + ML, N)
               II = JJ * MEB1 - ML + 2
               DO 540 I = I1, I2
  540          WM (II + I) = (FTEM (I) - SAVF (I) ) * FAC
  550       END DO
  560    END DO
         NFE = NFE+MBA
         IF (JSV.EQ.1) CALL DACOPY (MBAND, N, WM (ML3), MEBAND, WM (    &
         LOCJS), MBAND)
      ENDIF
!
      IF (JOK.EQ.1) THEN
         JCUR = 0
         CALL DACOPY (MBAND, N, WM (LOCJS), MBAND, WM (ML3), MEBAND)
      ENDIF
!
! Multiply Jacobian by scalar, add identity, and do LU decomposition.
      CON = - HRL1
      CALL DSCAL (LENP, CON, WM (3), 1)
      II = MBAND+2
      DO 580 I = 1, N
         WM (II) = WM (II) + ONE
  580 II = II + MEBAND
      NLU = NLU + 1
      CALL DGBFA (WM (3), MEBAND, N, ML, MU, IWM (31), IER)
      IF (IER.NE.0) IERPJ = 1
      RETURN
! End of code block for MITER = 4 or 5. --------------------------------
!
!----------------------- End of Subroutine DVJAC -----------------------
      END SUBROUTINE DVJAC


!*DECK DACOPY
      SUBROUTINE DACOPY (NROW, NCOL, A, NROWA, B, NROWB)
      DOUBLEPRECISION A, B
      INTEGER NROW, NCOL, NROWA, NROWB
      DIMENSION A (NROWA, NCOL), B (NROWB, NCOL)
!-----------------------------------------------------------------------
! Call sequence input -- NROW, NCOL, A, NROWA, NROWB
! Call sequence output -- B
! COMMON block variables accessed -- None
!
! Subroutines called by DACOPY: DCOPY
! Function routines called by DACOPY: None
!-----------------------------------------------------------------------
! This routine copies one rectangular array, A, to another, B,
! where A and B may have different row dimensions, NROWA and NROWB.
! The data copied consists of NROW rows and NCOL columns.
!-----------------------------------------------------------------------
      INTEGER IC
!
      DO 20 IC = 1, NCOL
         CALL DCOPY (NROW, A (1, IC), 1, B (1, IC), 1)
   20 END DO
!
      RETURN
!----------------------- End of Subroutine DACOPY ----------------------
      END SUBROUTINE DACOPY


!*DECK DVSOL
      SUBROUTINE DVSOL (WM, IWM, X, IERSL)
      DOUBLEPRECISION WM, X
      INTEGER IWM, IERSL
      DIMENSION WM ( * ), IWM ( * ), X ( * )
!-----------------------------------------------------------------------
! Call sequence input -- WM, IWM, X
! Call sequence output -- X, IERSL
! COMMON block variables accessed:
!     /DVOD01/ -- H, RL1, MITER, N
!
! Subroutines called by DVSOL: DGESL, DGBSL
! Function routines called by DVSOL: None
!-----------------------------------------------------------------------
! This routine manages the solution of the linear system arising from
! a chord iteration.  It is called if MITER .ne. 0.
! If MITER is 1 or 2, it calls DGESL to accomplish this.
! If MITER = 3 it updates the coefficient H*RL1 in the diagonal
! matrix, and then computes the solution.
! If MITER is 4 or 5, it calls DGBSL.
! Communication with DVSOL uses the following variables:
! WM    = Real work space containing the inverse diagonal matrix if
!         MITER = 3 and the LU decomposition of the matrix otherwise.
!         Storage of matrix elements starts at WM(3).
!         WM also contains the following matrix-related data:
!         WM(1) = SQRT(UROUND) (not used here),
!         WM(2) = HRL1, the previous value of H*RL1, used if MITER = 3.
! IWM   = Integer work space containing pivot information, starting at
!         IWM(31), if MITER is 1, 2, 4, or 5.  IWM also contains band
!         parameters ML = IWM(1) and MU = IWM(2) if MITER is 4 or 5.
! X     = The right-hand side vector on input, and the solution vector
!         on output, of length N.
! IERSL = Output flag.  IERSL = 0 if no trouble occurred.
!         IERSL = 1 if a singular matrix arose with MITER = 3.
!-----------------------------------------------------------------------
!
! Type declarations for labeled COMMON block DVOD01 --------------------
!
      DOUBLEPRECISION ACNRM, CCMXJ, CONP, CRATE, DRC, EL, ETA, ETAMAX,  &
      H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU, TQ, TN, UROUND
      INTEGER ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG, KUTH, L, LMAX, &
      LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, METH, MITER,   &
      MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ, NQNYH, NQWAIT,    &
      NSLJ, NSLP, NYH
!
! Type declarations for local variables --------------------------------
!
      INTEGER I, MEBAND, ML, MU
      DOUBLEPRECISION DI, HRL1, ONE, PHRL1, R, ZERO
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE ONE, ZERO
!
      COMMON / DVOD01 / ACNRM, CCMXJ, CONP, CRATE, DRC, EL (13),        &
      ETA, ETAMAX, H, HMIN, HMXI, HNEW, HSCAL, PRL1, RC, RL1, TAU (13), &
      TQ (5), TN, UROUND, ICF, INIT, IPUP, JCUR, JSTART, JSV, KFLAG,    &
      KUTH, L, LMAX, LYH, LEWT, LACOR, LSAVF, LWM, LIWM, LOCJS, MAXORD, &
      METH, MITER, MSBJ, MXHNIL, MXSTEP, N, NEWH, NEWQ, NHNIL, NQ,      &
      NQNYH, NQWAIT, NSLJ, NSLP, NYH
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,One,Zero)
!
      DATA ONE / 1.0D0 /, ZERO / 0.0D0 /
!
      IERSL = 0
      GOTO (100, 100, 300, 400, 400), MITER
  100 CALL DGESL (WM (3), N, N, IWM (31), X, 0)
      RETURN
!
  300 PHRL1 = WM (2)
      HRL1 = H * RL1
      WM (2) = HRL1
      IF (HRL1.EQ.PHRL1) GOTO 330
      R = HRL1 / PHRL1
      DO 320 I = 1, N
         DI = ONE-R * (ONE-ONE / WM (I + 2) )
         IF (ABS (DI) .EQ.ZERO) GOTO 390
  320 WM (I + 2) = ONE / DI
!
  330 DO 340 I = 1, N
  340 X (I) = WM (I + 2) * X (I)
      RETURN
  390 IERSL = 1
      RETURN
!
  400 ML = IWM (1)
      MU = IWM (2)
      MEBAND = 2 * ML + MU + 1
      CALL DGBSL (WM (3), MEBAND, N, ML, MU, IWM (31), X, 0)
      RETURN
!----------------------- End of Subroutine DVSOL -----------------------
      END SUBROUTINE DVSOL


!*DECK DVSRCO
      SUBROUTINE DVSRCO (RSAV, ISAV, JOB)
      DOUBLEPRECISION RSAV
      INTEGER ISAV, JOB
      DIMENSION RSAV ( * ), ISAV ( * )
!-----------------------------------------------------------------------
! Call sequence input -- RSAV, ISAV, JOB
! Call sequence output -- RSAV, ISAV
! COMMON block variables accessed -- All of /DVOD01/ and /DVOD02/
!
! Subroutines/functions called by DVSRCO: None
!-----------------------------------------------------------------------
! This routine saves or restores (depending on JOB) the contents of the
! COMMON blocks DVOD01 and DVOD02, which are used internally by DVODE.
!
! RSAV = real array of length 49 or more.
! ISAV = integer array of length 41 or more.
! JOB  = flag indicating to save or restore the COMMON blocks:
!        JOB  = 1 if COMMON is to be saved (written to RSAV/ISAV).
!        JOB  = 2 if COMMON is to be restored (read from RSAV/ISAV).
!        A call with JOB = 2 presumes a prior call with JOB = 1.
!-----------------------------------------------------------------------
      DOUBLEPRECISION RVOD1, RVOD2
      INTEGER IVOD1, IVOD2
      INTEGER I, LENIV1, LENIV2, LENRV1, LENRV2
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this integrator.
!-----------------------------------------------------------------------
      SAVE LENRV1, LENIV1, LENRV2, LENIV2
!
      COMMON / DVOD01 / RVOD1 (48), IVOD1 (33)
      COMMON / DVOD02 / RVOD2 (1), IVOD2 (8)
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(/DVOD01/,/DVOD02/,LENRV1,LENIV1,LENRV2,LENIV2)
!

      DATA LENRV1 / 48 /, LENIV1 / 33 /, LENRV2 / 1 /, LENIV2 / 8 /
!
      IF (JOB.EQ.2) GOTO 100
      DO 10 I = 1, LENRV1
   10 RSAV (I) = RVOD1 (I)
      DO 15 I = 1, LENRV2
   15 RSAV (LENRV1 + I) = RVOD2 (I)
!
      DO 20 I = 1, LENIV1
   20 ISAV (I) = IVOD1 (I)
      DO 25 I = 1, LENIV2
   25 ISAV (LENIV1 + I) = IVOD2 (I)
!
      RETURN
!
  100 CONTINUE
      DO 110 I = 1, LENRV1
  110 RVOD1 (I) = RSAV (I)
      DO 115 I = 1, LENRV2
  115 RVOD2 (I) = RSAV (LENRV1 + I)
!
      DO 120 I = 1, LENIV1
  120 IVOD1 (I) = ISAV (I)
      DO 125 I = 1, LENIV2
  125 IVOD2 (I) = ISAV (LENIV1 + I)
!
      RETURN
!----------------------- End of Subroutine DVSRCO ----------------------
      END SUBROUTINE DVSRCO
!*DECK DEWSET
      SUBROUTINE DEWSET (N, ITOL, RTOL, ATOL, YCUR, EWT)
!***BEGIN PROLOGUE  DEWSET
!***SUBSIDIARY
!***PURPOSE  Set error weight vector.
!***TYPE      DOUBLE PRECISION (SEWSET-S, DEWSET-D)
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
!
!  This subroutine sets the error weight vector EWT according to
!      EWT(i) = RTOL(i)*ABS(YCUR(i)) + ATOL(i),  i = 1,...,N,
!  with the subscript on RTOL and/or ATOL possibly replaced by 1 above,
!  depending on the value of ITOL.
!
!***SEE ALSO  DLSODE
!***ROUTINES CALLED  (NONE)
!***REVISION HISTORY  (YYMMDD)
!   791129  DATE WRITTEN
!   890501  Modified prologue to SLATEC/LDOC format.  (FNF)
!   890503  Minor cosmetic changes.  (FNF)
!   930809  Renamed to allow single/double precision versions. (ACH)
!***END PROLOGUE  DEWSET
!**End
      INTEGER N, ITOL
      INTEGER I
      DOUBLEPRECISION RTOL, ATOL, YCUR, EWT
      DIMENSION ATOL ( * ), YCUR (N), EWT (N)
!
!***FIRST EXECUTABLE STATEMENT  DEWSET
      GOTO (10, 20, 30, 40), ITOL
   10 CONTINUE
      DO 15 I = 1, N
   15 EWT (I) = RTOL * ABS (YCUR (I) ) + ATOL (1)
      RETURN
   20 CONTINUE
      DO 25 I = 1, N
   25 EWT (I) = RTOL * ABS (YCUR (I) ) + ATOL (I)
      RETURN
   30 CONTINUE
      DO 35 I = 1, N
   35 EWT (I) = RTOL * ABS (YCUR (I) ) + ATOL (1)
      RETURN
   40 CONTINUE
      DO 45 I = 1, N
   45 EWT (I) = RTOL * ABS (YCUR (I) ) + ATOL (I)
      RETURN
!----------------------- END OF SUBROUTINE DEWSET ----------------------
      END SUBROUTINE DEWSET


!*DECK DVNORM
      DOUBLEPRECISION FUNCTION DVNORM (N, V, W)
!***BEGIN PROLOGUE  DVNORM
!***SUBSIDIARY
!***PURPOSE  Weighted root-mean-square vector norm.
!***TYPE      DOUBLE PRECISION (SVNORM-S, DVNORM-D)
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
!
!  This function routine computes the weighted root-mean-square norm
!  of the vector of length N contained in the array V, with weights
!  contained in the array W of length N:
!    DVNORM = SQRT( (1/N) * SUM( V(i)*W(i) )**2 )
!
!***SEE ALSO  DLSODE
!***ROUTINES CALLED  (NONE)
!***REVISION HISTORY  (YYMMDD)
!   791129  DATE WRITTEN
!   890501  Modified prologue to SLATEC/LDOC format.  (FNF)
!   890503  Minor cosmetic changes.  (FNF)
!   930809  Renamed to allow single/double precision versions. (ACH)
!***END PROLOGUE  DVNORM
!**End
      INTEGER N, I
      DOUBLEPRECISION V, W, SUM
      DIMENSION V (N), W (N)
!
!***FIRST EXECUTABLE STATEMENT  DVNORM
      SUM = 0.0D0
      DO 10 I = 1, N
   10 SUM = SUM + (V (I) * W (I) ) **2
      DVNORM = SQRT (SUM / N)
      RETURN
!----------------------- END OF FUNCTION DVNORM ------------------------
      END FUNCTION DVNORM


!*DECK XERRWD
      SUBROUTINE XERRWD (MSG, NMES, NERR, LEVEL, NI, I1, I2, NR, R1, R2)
!***BEGIN PROLOGUE  XERRWD
!***SUBSIDIARY
!***PURPOSE  Write error message with values.
!***CATEGORY  R3C
!***TYPE      DOUBLE PRECISION (XERRWV-S, XERRWD-D)
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
!
!  Subroutines XERRWD, XSETF, XSETUN, and the function routine IXSAV,
!  as given here, constitute a simplified version of the SLATEC error
!  handling package.
!
!  All arguments are input arguments.
!
!  MSG    = The message (character array).
!  NMES   = The length of MSG (number of characters).
!  NERR   = The error number (not used).
!  LEVEL  = The error level..
!           0 or 1 means recoverable (control returns to caller).
!           2 means fatal (run is aborted--see note below).
!  NI     = Number of integers (0, 1, or 2) to be printed with message.
!  I1,I2  = Integers to be printed, depending on NI.
!  NR     = Number of reals (0, 1, or 2) to be printed with message.
!  R1,R2  = Reals to be printed, depending on NR.
!
!  Note..  this routine is machine-dependent and specialized for use
!  in limited context, in the following ways..
!  1. The argument MSG is assumed to be of type CHARACTER, and
!     the message is printed with a format of (1X,A).
!  2. The message is assumed to take only one line.
!     Multi-line messages are generated by repeated calls.
!  3. If LEVEL = 2, control passes to the statement   STOP
!     to abort the run.  This statement may be machine-dependent.
!  4. R1 and R2 are assumed to be in double precision and are printed
!     in D21.13 format.
!
!***ROUTINES CALLED  IXSAV
!***REVISION HISTORY  (YYMMDD)
!   920831  DATE WRITTEN
!   921118  Replaced MFLGSV/LUNSAV by IXSAV. (ACH)
!   930329  Modified prologue to SLATEC format. (FNF)
!   930407  Changed MSG from CHARACTER*1 array to variable. (FNF)
!   930922  Minor cosmetic change. (FNF)
!***END PROLOGUE  XERRWD
!
!*Internal Notes:
!
! For a different default logical unit number, IXSAV (or a subsidiary
! routine that it calls) will need to be modified.
! For a different run-abort command, change the statement following
! statement 100 at the end.
!-----------------------------------------------------------------------
! Subroutines called by XERRWD.. None
! Function routine called by XERRWD.. IXSAV
!-----------------------------------------------------------------------
!**End
!
!  Declare arguments.
!
      DOUBLEPRECISION R1, R2
      INTEGER NMES, NERR, LEVEL, NI, I1, I2, NR
      CHARACTER ( * ) MSG
!
!  Declare local variables.
!
      INTEGER LUNIT, IXSAV, MESFLG
!
!  Get logical unit number and message print flag.
!
!***FIRST EXECUTABLE STATEMENT  XERRWD
      LUNIT = IXSAV (1, 0, .FALSE.)
      MESFLG = IXSAV (2, 0, .FALSE.)
      IF (MESFLG.EQ.0) GOTO 100
!
!  Write the message.
!
! 20190711 -- wmy removed all the write errors b/c there are
! too many in most complex NPAG runs. Just rely on the 
! number of support points skipped vs passed.
!
!
!      WRITE (LUNIT, 10) MSG
!   10 FORMAT(1X,A)
!      IF (NI.EQ.1) WRITE (LUNIT, 20) I1
!   20 FORMAT(6X,'In above message,  I1 =',I10)
!      IF (NI.EQ.2) WRITE (LUNIT, 30) I1, I2
!   30 FORMAT(6X,'In above message,  I1 =',I10,3X,'I2 =',I10)
!      IF (NR.EQ.1) WRITE (LUNIT, 40) R1
!   40 FORMAT(6X,'In above message,  R1 =',D21.13)
!      IF (NR.EQ.2) WRITE (LUNIT, 50) R1, R2
!   50 FORMAT(6X,'In above,  R1 =',D21.13,3X,'R2 =',D21.13)
!
!  Abort the run if LEVEL = 2.
!
  100 IF (LEVEL.NE.2) RETURN
      STOP
!----------------------- End of Subroutine XERRWD ----------------------
      END SUBROUTINE XERRWD


!*DECK XSETF
      SUBROUTINE XSETF (MFLAG)
!***BEGIN PROLOGUE  XSETF
!***PURPOSE  Reset the error print control flag.
!***CATEGORY  R3A
!***TYPE      ALL (XSETF-A)
!***KEYWORDS  ERROR CONTROL
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
!
!   XSETF sets the error print control flag to MFLAG:
!      MFLAG=1 means print all messages (the default).
!      MFLAG=0 means no printing.
!
!***SEE ALSO  XERRWD, XERRWV
!***REFERENCES  (NONE)
!***ROUTINES CALLED  IXSAV
!***REVISION HISTORY  (YYMMDD)
!   921118  DATE WRITTEN
!   930329  Added SLATEC format prologue. (FNF)
!   930407  Corrected SEE ALSO section. (FNF)
!   930922  Made user-callable, and other cosmetic changes. (FNF)
!***END PROLOGUE  XSETF
!
! Subroutines called by XSETF.. None
! Function routine called by XSETF.. IXSAV
!-----------------------------------------------------------------------
!**End
      INTEGER MFLAG, JUNK, IXSAV
!
!***FIRST EXECUTABLE STATEMENT  XSETF
      IF (MFLAG.EQ.0.OR.MFLAG.EQ.1) JUNK = IXSAV (2, MFLAG, .TRUE.)
      RETURN
!----------------------- End of Subroutine XSETF -----------------------
      END SUBROUTINE XSETF


!*DECK XSETUN
      SUBROUTINE XSETUN (LUN)
!***BEGIN PROLOGUE  XSETUN
!***PURPOSE  Reset the logical unit number for error messages.
!***CATEGORY  R3B
!***TYPE      ALL (XSETUN-A)
!***KEYWORDS  ERROR CONTROL
!***DESCRIPTION
!
!   XSETUN sets the logical unit number for error messages to LUN.
!
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***SEE ALSO  XERRWD, XERRWV
!***REFERENCES  (NONE)
!***ROUTINES CALLED  IXSAV
!***REVISION HISTORY  (YYMMDD)
!   921118  DATE WRITTEN
!   930329  Added SLATEC format prologue. (FNF)
!   930407  Corrected SEE ALSO section. (FNF)
!   930922  Made user-callable, and other cosmetic changes. (FNF)
!***END PROLOGUE  XSETUN
!
! Subroutines called by XSETUN.. None
! Function routine called by XSETUN.. IXSAV
!-----------------------------------------------------------------------
!**End
      INTEGER LUN, JUNK, IXSAV
!
!***FIRST EXECUTABLE STATEMENT  XSETUN
      IF (LUN.GT.0) JUNK = IXSAV (1, LUN, .TRUE.)
      RETURN
!----------------------- End of Subroutine XSETUN ----------------------
      END SUBROUTINE XSETUN



!*DECK IXSAV
      INTEGER FUNCTION IXSAV (IPAR, IVALUE, ISET)
!***BEGIN PROLOGUE  IXSAV
!***SUBSIDIARY
!***PURPOSE  Save and recall error message control parameters.
!***CATEGORY  R3C
!***TYPE      ALL (IXSAV-A)
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
!
!  IXSAV saves and recalls one of two error message parameters:
!    LUNIT, the logical unit number to which messages are printed, and
!    MESFLG, the message print flag.
!  This is a modification of the SLATEC library routine J4SAVE.
!
!  Saved local variables..
!   LUNIT  = Logical unit number for messages.  The default is obtained
!            by a call to IUMACH (may be machine-dependent).
!   MESFLG = Print control flag..
!            1 means print all messages (the default).
!            0 means no printing.
!
!  On input..
!    IPAR   = Parameter indicator (1 for LUNIT, 2 for MESFLG).
!    IVALUE = The value to be set for the parameter, if ISET = .TRUE.
!    ISET   = Logical flag to indicate whether to read or write.
!             If ISET = .TRUE., the parameter will be given
!             the value IVALUE.  If ISET = .FALSE., the parameter
!             will be unchanged, and IVALUE is a dummy argument.
!
!  On return..
!    IXSAV = The (old) value of the parameter.
!
!***SEE ALSO  XERRWD, XERRWV
!***ROUTINES CALLED  IUMACH
!***REVISION HISTORY  (YYMMDD)
!   921118  DATE WRITTEN
!   930329  Modified prologue to SLATEC format. (FNF)
!   930915  Added IUMACH call to get default output unit.  (ACH)
!   930922  Minor cosmetic changes. (FNF)
!   010425  Type declaration for IUMACH added. (ACH)
!***END PROLOGUE  IXSAV
!
! Subroutines called by IXSAV.. None
! Function routine called by IXSAV.. IUMACH
!-----------------------------------------------------------------------
!**End
      LOGICAL ISET
      INTEGER IPAR, IVALUE
!-----------------------------------------------------------------------
      INTEGER IUMACH, LUNIT, MESFLG
!-----------------------------------------------------------------------
! The following Fortran-77 declaration is to cause the values of the
! listed (local) variables to be saved between calls to this routine.
!-----------------------------------------------------------------------
      SAVE LUNIT, MESFLG
!
! NEW PARALLEL CODE BELOW AS OF npageng28.f.
!$omp Threadprivate(Mesflg,LUNIT)
! 
      DATA LUNIT / - 1 /, MESFLG / 1 /
!
!***FIRST EXECUTABLE STATEMENT  IXSAV
      IF (IPAR.EQ.1) THEN
         IF (LUNIT.EQ. - 1) LUNIT = IUMACH ()
         IXSAV = LUNIT
         IF (ISET) LUNIT = IVALUE
      ENDIF
!
      IF (IPAR.EQ.2) THEN
         IXSAV = MESFLG
         IF (ISET) MESFLG = IVALUE
      ENDIF
!
      RETURN
!----------------------- End of Function IXSAV -------------------------
      END FUNCTION IXSAV
!*DECK IUMACH
      INTEGER FUNCTION IUMACH ()
!***BEGIN PROLOGUE  IUMACH
!***PURPOSE  Provide standard output unit number.
!***CATEGORY  R1
!***TYPE      INTEGER (IUMACH-I)
!***KEYWORDS  MACHINE CONSTANTS
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
! *Usage:
!        INTEGER  LOUT, IUMACH
!        LOUT = IUMACH()
!
! *Function Return Values:
!     LOUT : the standard logical unit for Fortran output.
!
!***REFERENCES  (NONE)
!***ROUTINES CALLED  (NONE)
!***REVISION HISTORY  (YYMMDD)
!   930915  DATE WRITTEN
!   930922  Made user-callable, and other cosmetic changes. (FNF)
!***END PROLOGUE  IUMACH
!
!*Internal Notes:
!  The built-in value of 6 is standard on a wide range of Fortran
!  systems.  This may be machine-dependent.
!**End
!***FIRST EXECUTABLE STATEMENT  IUMACH
      IUMACH = 6
!
      RETURN
!----------------------- End of Function IUMACH ------------------------
      END FUNCTION IUMACH
!*DECK DUMACH
      DOUBLEPRECISION FUNCTION DUMACH ()
!***BEGIN PROLOGUE  DUMACH
!***PURPOSE  Compute the unit roundoff of the machine.
!***CATEGORY  R1
!***TYPE      DOUBLE PRECISION (RUMACH-S, DUMACH-D)
!***KEYWORDS  MACHINE CONSTANTS
!***AUTHOR  Hindmarsh, Alan C., (LLNL)
!***DESCRIPTION
! *Usage:
!        DOUBLE PRECISION  A, DUMACH
!        A = DUMACH()
!
! *Function Return Values:
!     A : the unit roundoff of the machine.
!
! *Description:
!     The unit roundoff is defined as the smallest positive machine
!     number u such that  1.0 + u .ne. 1.0.  This is computed by DUMACH
!     in a machine-independent manner.
!
!***REFERENCES  (NONE)
!***ROUTINES CALLED  DUMSUM
!***REVISION HISTORY  (YYYYMMDD)
!   19930216  DATE WRITTEN
!   19930818  Added SLATEC-format prologue.  (FNF)
!   20030707  Added DUMSUM to force normal storage of COMP.  (ACH)
!***END PROLOGUE  DUMACH
!
      DOUBLEPRECISION U, COMP
!***FIRST EXECUTABLE STATEMENT  DUMACH
      U = 1.0D0
   10 U = U * 0.5D0
      CALL DUMSUM (1.0D0, U, COMP)
      IF (COMP.NE.1.0D0) GOTO 10
      DUMACH = U * 2.0D0
      RETURN
!----------------------- End of Function DUMACH ------------------------
      END FUNCTION DUMACH

!-----------------------------------------------------------------------
      SUBROUTINE DUMSUM (A, B, C)
!     Routine to force normal storing of A + B, for DUMACH.
      DOUBLEPRECISION A, B, C
      C = A + B
      RETURN
      END SUBROUTINE DUMSUM


!-----------------------------------------------------------------------
!*DECK DGEFA
      SUBROUTINE DGEFA (A, LDA, N, IPVT, INFO)
!***BEGIN PROLOGUE  DGEFA
!***PURPOSE  Factor a matrix using Gaussian elimination.
!***CATEGORY  D2A1
!***TYPE      DOUBLE PRECISION (SGEFA-S, DGEFA-D, CGEFA-C)
!***KEYWORDS  GENERAL MATRIX, LINEAR ALGEBRA, LINPACK,
!             MATRIX FACTORIZATION
!***AUTHOR  Moler, C. B., (U. of New Mexico)
!***DESCRIPTION
!
!     DGEFA factors a double precision matrix by Gaussian elimination.
!
!     DGEFA is usually called by DGECO, but it can be called
!     directly with a saving in time if  RCOND  is not needed.
!     (Time for DGECO) = (1 + 9/N)*(Time for DGEFA) .
!
!     On Entry
!
!        A       DOUBLE PRECISION(LDA, N)
!                the matrix to be factored.
!
!        LDA     INTEGER
!                the leading dimension of the array  A .
!
!        N       INTEGER
!                the order of the matrix  A .
!
!     On Return
!
!        A       an upper triangular matrix and the multipliers
!                which were used to obtain it.
!                The factorization can be written  A = L*U  where
!                L  is a product of permutation and unit lower
!                triangular matrices and  U  is upper triangular.
!
!        IPVT    INTEGER(N)
!                an integer vector of pivot indices.
!
!        INFO    INTEGER
!                = 0  normal value.
!                = K  if  U(K,K) .EQ. 0.0 .  This is not an error
!                     condition for this subroutine, but it does
!                     indicate that DGESL or DGEDI will divide by zero
!                     if called.  Use  RCOND  in DGECO for a reliable
!                     indication of singularity.
!
!***REFERENCES  J. J. Dongarra, J. R. Bunch, C. B. Moler, and G. W.
!                 Stewart, LINPACK Users' Guide, SIAM, 1979.
!***ROUTINES CALLED  DAXPY, DSCAL, IDAMAX
!***REVISION HISTORY  (YYMMDD)
!   780814  DATE WRITTEN
!   890831  Modified array declarations.  (WRB)
!   890831  REVISION DATE from Version 3.2
!   891214  Prologue converted to Version 4.0 format.  (BAB)
!   900326  Removed duplicate information from DESCRIPTION section.
!           (WRB)
!   920501  Reformatted the REFERENCES section.  (WRB)
!***END PROLOGUE  DGEFA
      INTEGER LDA, N, IPVT ( * ), INFO
      DOUBLEPRECISION A (LDA, * )
!
      DOUBLEPRECISION T
      INTEGER IDAMAX, J, K, KP1, L, NM1
!
!     GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
!
!***FIRST EXECUTABLE STATEMENT  DGEFA
      INFO = 0
      NM1 = N - 1
      IF (NM1.LT.1) GOTO 70
      DO 60 K = 1, NM1
         KP1 = K + 1
!
!        FIND L = PIVOT INDEX
!
         L = IDAMAX (N - K + 1, A (K, K), 1) + K - 1
         IPVT (K) = L
!
!        ZERO PIVOT IMPLIES THIS COLUMN ALREADY TRIANGULARIZED
!
         IF (A (L, K) .EQ.0.0D0) GOTO 40
!
!           INTERCHANGE IF NECESSARY
!
         IF (L.EQ.K) GOTO 10
         T = A (L, K)
         A (L, K) = A (K, K)
         A (K, K) = T
   10    CONTINUE
!
!           COMPUTE MULTIPLIERS
!
         T = - 1.0D0 / A (K, K)
         CALL DSCAL (N - K, T, A (K + 1, K), 1)
!
!           ROW ELIMINATION WITH COLUMN INDEXING
!
         DO 30 J = KP1, N
            T = A (L, J)
            IF (L.EQ.K) GOTO 20
            A (L, J) = A (K, J)
            A (K, J) = T
   20       CONTINUE
            CALL DAXPY (N - K, T, A (K + 1, K), 1, A (K + 1, J),        &
            1)
   30    END DO
         GOTO 50
   40    CONTINUE
         INFO = K
   50    CONTINUE
   60 END DO
   70 CONTINUE
      IPVT (N) = N
      IF (A (N, N) .EQ.0.0D0) INFO = N
      RETURN
      END SUBROUTINE DGEFA

!-----------------------------------------------------------------------
!*DECK DGESL
      SUBROUTINE DGESL (A, LDA, N, IPVT, B, JOB)
!***BEGIN PROLOGUE  DGESL
!***PURPOSE  Solve the real system A*X=B or TRANS(A)*X=B using the
!            factors computed by DGECO or DGEFA.
!***CATEGORY  D2A1
!***TYPE      DOUBLE PRECISION (SGESL-S, DGESL-D, CGESL-C)
!***KEYWORDS  LINEAR ALGEBRA, LINPACK, MATRIX, SOLVE
!***AUTHOR  Moler, C. B., (U. of New Mexico)
!***DESCRIPTION
!
!     DGESL solves the double precision system
!     A * X = B  or  TRANS(A) * X = B
!     using the factors computed by DGECO or DGEFA.
!
!     On Entry
!
!        A       DOUBLE PRECISION(LDA, N)
!                the output from DGECO or DGEFA.
!
!        LDA     INTEGER
!                the leading dimension of the array  A .
!
!        N       INTEGER
!                the order of the matrix  A .
!
!        IPVT    INTEGER(N)
!                the pivot vector from DGECO or DGEFA.
!
!        B       DOUBLE PRECISION(N)
!                the right hand side vector.
!
!        JOB     INTEGER
!                = 0         to solve  A*X = B ,
!                = nonzero   to solve  TRANS(A)*X = B  where
!                            TRANS(A)  is the transpose.
!
!     On Return
!
!        B       the solution vector  X .
!
!     Error Condition
!
!        A division by zero will occur if the input factor contains a
!        zero on the diagonal.  Technically this indicates singularity
!        but it is often caused by improper arguments or improper
!        setting of LDA .  It will not occur if the subroutines are
!        called correctly and if DGECO has set RCOND .GT. 0.0
!        or DGEFA has set INFO .EQ. 0 .
!
!     To compute  INVERSE(A) * C  where  C  is a matrix
!     with  P  columns
!           CALL DGECO(A,LDA,N,IPVT,RCOND,Z)
!           IF (RCOND is too small) GO TO ...
!           DO 10 J = 1, P
!              CALL DGESL(A,LDA,N,IPVT,C(1,J),0)
!        10 CONTINUE
!
!***REFERENCES  J. J. Dongarra, J. R. Bunch, C. B. Moler, and G. W.
!                 Stewart, LINPACK Users' Guide, SIAM, 1979.
!***ROUTINES CALLED  DAXPY, DDOT
!***REVISION HISTORY  (YYMMDD)
!   780814  DATE WRITTEN
!   890831  Modified array declarations.  (WRB)
!   890831  REVISION DATE from Version 3.2
!   891214  Prologue converted to Version 4.0 format.  (BAB)
!   900326  Removed duplicate information from DESCRIPTION section.
!           (WRB)
!   920501  Reformatted the REFERENCES section.  (WRB)
!***END PROLOGUE  DGESL
      INTEGER LDA, N, IPVT ( * ), JOB
      DOUBLEPRECISION A (LDA, * ), B ( * )
!
      DOUBLEPRECISION DDOT, T
      INTEGER K, KB, L, NM1
!***FIRST EXECUTABLE STATEMENT  DGESL
      NM1 = N - 1
      IF (JOB.NE.0) GOTO 50
!
!        JOB = 0 , SOLVE  A * X = B
!        FIRST SOLVE  L*Y = B
!
      IF (NM1.LT.1) GOTO 30
      DO 20 K = 1, NM1
         L = IPVT (K)
         T = B (L)
         IF (L.EQ.K) GOTO 10
         B (L) = B (K)
         B (K) = T
   10    CONTINUE
         CALL DAXPY (N - K, T, A (K + 1, K), 1, B (K + 1), 1)
   20 END DO
   30 CONTINUE
!
!        NOW SOLVE  U*X = Y
!
      DO 40 KB = 1, N
         K = N + 1 - KB
         B (K) = B (K) / A (K, K)
         T = - B (K)
         CALL DAXPY (K - 1, T, A (1, K), 1, B (1), 1)
   40 END DO
      GOTO 100
   50 CONTINUE
!
!        JOB = NONZERO, SOLVE  TRANS(A) * X = B
!        FIRST SOLVE  TRANS(U)*Y = B
!
      DO 60 K = 1, N
         T = DDOT (K - 1, A (1, K), 1, B (1), 1)
         B (K) = (B (K) - T) / A (K, K)
   60 END DO
!
!        NOW SOLVE TRANS(L)*X = Y
!
      IF (NM1.LT.1) GOTO 90
      DO 80 KB = 1, NM1
         K = N - KB
         B (K) = B (K) + DDOT (N - K, A (K + 1, K), 1, B (K + 1),       &
         1)
         L = IPVT (K)
         IF (L.EQ.K) GOTO 70
         T = B (L)
         B (L) = B (K)
         B (K) = T
   70    CONTINUE
   80 END DO
   90 CONTINUE
  100 CONTINUE
      RETURN
      END SUBROUTINE DGESL


!-----------------------------------------------------------------------
!*DECK DGBFA
      SUBROUTINE DGBFA (ABD, LDA, N, ML, MU, IPVT, INFO)
!***BEGIN PROLOGUE  DGBFA
!***PURPOSE  Factor a band matrix using Gaussian elimination.
!***CATEGORY  D2A2
!***TYPE      DOUBLE PRECISION (SGBFA-S, DGBFA-D, CGBFA-C)
!***KEYWORDS  BANDED, LINEAR ALGEBRA, LINPACK, MATRIX FACTORIZATION
!***AUTHOR  Moler, C. B., (U. of New Mexico)
!***DESCRIPTION
!
!     DGBFA factors a double precision band matrix by elimination.
!
!     DGBFA is usually called by DGBCO, but it can be called
!     directly with a saving in time if  RCOND  is not needed.
!
!     On Entry
!
!        ABD     DOUBLE PRECISION(LDA, N)
!                contains the matrix in band storage.  The columns
!                of the matrix are stored in the columns of  ABD  and
!                the diagonals of the matrix are stored in rows
!                ML+1 through 2*ML+MU+1 of  ABD .
!                See the comments below for details.
!
!        LDA     INTEGER
!                the leading dimension of the array  ABD .
!                LDA must be .GE. 2*ML + MU + 1 .
!
!        N       INTEGER
!                the order of the original matrix.
!
!        ML      INTEGER
!                number of diagonals below the main diagonal.
!                0 .LE. ML .LT.  N .
!
!        MU      INTEGER
!                number of diagonals above the main diagonal.
!                0 .LE. MU .LT.  N .
!                More efficient if  ML .LE. MU .
!     On Return
!
!        ABD     an upper triangular matrix in band storage and
!                the multipliers which were used to obtain it.
!                The factorization can be written  A = L*U  where
!                L  is a product of permutation and unit lower
!                triangular matrices and  U  is upper triangular.
!
!        IPVT    INTEGER(N)
!                an integer vector of pivot indices.
!
!        INFO    INTEGER
!                = 0  normal value.
!                = K  if  U(K,K) .EQ. 0.0 .  This is not an error
!                     condition for this subroutine, but it does
!                     indicate that DGBSL will divide by zero if
!                     called.  Use  RCOND  in DGBCO for a reliable
!                     indication of singularity.
!
!     Band Storage
!
!           If  A  is a band matrix, the following program segment
!           will set up the input.
!
!                   ML = (band width below the diagonal)
!                   MU = (band width above the diagonal)
!                   M = ML + MU + 1
!                   DO 20 J = 1, N
!                      I1 = MAX(1, J-MU)
!                      I2 = MIN(N, J+ML)
!                      DO 10 I = I1, I2
!                         K = I - J + M
!                         ABD(K,J) = A(I,J)
!                10    CONTINUE
!                20 CONTINUE
!
!           This uses rows  ML+1  through  2*ML+MU+1  of  ABD .
!           In addition, the first  ML  rows in  ABD  are used for
!           elements generated during the triangularization.
!           The total number of rows needed in  ABD  is  2*ML+MU+1 .
!           The  ML+MU by ML+MU  upper left triangle and the
!           ML by ML  lower right triangle are not referenced.
!
!***REFERENCES  J. J. Dongarra, J. R. Bunch, C. B. Moler, and G. W.
!                 Stewart, LINPACK Users' Guide, SIAM, 1979.
!***ROUTINES CALLED  DAXPY, DSCAL, IDAMAX
!***REVISION HISTORY  (YYMMDD)
!   780814  DATE WRITTEN
!   890531  Changed all specific intrinsics to generic.  (WRB)
!   890831  Modified array declarations.  (WRB)
!   890831  REVISION DATE from Version 3.2
!   891214  Prologue converted to Version 4.0 format.  (BAB)
!   900326  Removed duplicate information from DESCRIPTION section.
!           (WRB)
!   920501  Reformatted the REFERENCES section.  (WRB)
!***END PROLOGUE  DGBFA
      INTEGER LDA, N, ML, MU, IPVT ( * ), INFO
      DOUBLEPRECISION ABD (LDA, * )
!
      DOUBLEPRECISION T
      INTEGER I, IDAMAX, I0, J, JU, JZ, J0, J1, K, KP1, L, LM, M, MM,   &
      NM1
!
!***FIRST EXECUTABLE STATEMENT  DGBFA
      M = ML + MU + 1
      INFO = 0
!
!     ZERO INITIAL FILL-IN COLUMNS
!
      J0 = MU + 2
      J1 = MIN (N, M) - 1
      IF (J1.LT.J0) GOTO 30
      DO 20 JZ = J0, J1
         I0 = M + 1 - JZ
         DO 10 I = I0, ML
            ABD (I, JZ) = 0.0D0
   10    END DO
   20 END DO
   30 CONTINUE
      JZ = J1
      JU = 0
!
!     GAUSSIAN ELIMINATION WITH PARTIAL PIVOTING
!
      NM1 = N - 1
      IF (NM1.LT.1) GOTO 130
      DO 120 K = 1, NM1
         KP1 = K + 1
!
!        ZERO NEXT FILL-IN COLUMN
!
         JZ = JZ + 1
         IF (JZ.GT.N) GOTO 50
         IF (ML.LT.1) GOTO 50
         DO 40 I = 1, ML
            ABD (I, JZ) = 0.0D0
   40    END DO
   50    CONTINUE
!
!        FIND L = PIVOT INDEX
!
         LM = MIN (ML, N - K)
         L = IDAMAX (LM + 1, ABD (M, K), 1) + M - 1
         IPVT (K) = L + K - M
!
!        ZERO PIVOT IMPLIES THIS COLUMN ALREADY TRIANGULARIZED
!
         IF (ABD (L, K) .EQ.0.0D0) GOTO 100
!
!           INTERCHANGE IF NECESSARY
!
         IF (L.EQ.M) GOTO 60
         T = ABD (L, K)
         ABD (L, K) = ABD (M, K)
         ABD (M, K) = T
   60    CONTINUE
!
!           COMPUTE MULTIPLIERS
!
         T = - 1.0D0 / ABD (M, K)
         CALL DSCAL (LM, T, ABD (M + 1, K), 1)
!
!           ROW ELIMINATION WITH COLUMN INDEXING
!
         JU = MIN (MAX (JU, MU + IPVT (K) ), N)
         MM = M
         IF (JU.LT.KP1) GOTO 90
         DO 80 J = KP1, JU
            L = L - 1
            MM = MM - 1
            T = ABD (L, J)
            IF (L.EQ.MM) GOTO 70
            ABD (L, J) = ABD (MM, J)
            ABD (MM, J) = T
   70       CONTINUE
            CALL DAXPY (LM, T, ABD (M + 1, K), 1, ABD (MM + 1, J),      &
            1)
   80    END DO
   90    CONTINUE
         GOTO 110
  100    CONTINUE
         INFO = K
  110    CONTINUE
  120 END DO
  130 CONTINUE
      IPVT (N) = N
      IF (ABD (M, N) .EQ.0.0D0) INFO = N
      RETURN
      END SUBROUTINE DGBFA

!-----------------------------------------------------------------------
!*DECK DGBSL
      SUBROUTINE DGBSL (ABD, LDA, N, ML, MU, IPVT, B, JOB)
!***BEGIN PROLOGUE  DGBSL
!***PURPOSE  Solve the real band system A*X=B or TRANS(A)*X=B using
!            the factors computed by DGBCO or DGBFA.
!***CATEGORY  D2A2
!***TYPE      DOUBLE PRECISION (SGBSL-S, DGBSL-D, CGBSL-C)
!***KEYWORDS  BANDED, LINEAR ALGEBRA, LINPACK, MATRIX, SOLVE
!***AUTHOR  Moler, C. B., (U. of New Mexico)
!***DESCRIPTION
!
!     DGBSL solves the double precision band system
!     A * X = B  or  TRANS(A) * X = B
!     using the factors computed by DGBCO or DGBFA.
!
!     On Entry
!
!        ABD     DOUBLE PRECISION(LDA, N)
!                the output from DGBCO or DGBFA.
!
!        LDA     INTEGER
!                the leading dimension of the array  ABD .
!
!        N       INTEGER
!                the order of the original matrix.
!
!        ML      INTEGER
!                number of diagonals below the main diagonal.
!
!        MU      INTEGER
!                number of diagonals above the main diagonal.
!
!        IPVT    INTEGER(N)
!                the pivot vector from DGBCO or DGBFA.
!
!        B       DOUBLE PRECISION(N)
!                the right hand side vector.
!
!        JOB     INTEGER
!                = 0         to solve  A*X = B ,
!                = nonzero   to solve  TRANS(A)*X = B , where
!                            TRANS(A)  is the transpose.
!
!     On Return
!
!        B       the solution vector  X .
!
!     Error Condition
!
!        A division by zero will occur if the input factor contains a
!        zero on the diagonal.  Technically this indicates singularity
!        but it is often caused by improper arguments or improper
!        setting of LDA .  It will not occur if the subroutines are
!        called correctly and if DGBCO has set RCOND .GT. 0.0
!        or DGBFA has set INFO .EQ. 0 .
!
!     To compute  INVERSE(A) * C  where  C  is a matrix
!     with  P  columns
!           CALL DGBCO(ABD,LDA,N,ML,MU,IPVT,RCOND,Z)
!           IF (RCOND is too small) GO TO ...
!           DO 10 J = 1, P
!              CALL DGBSL(ABD,LDA,N,ML,MU,IPVT,C(1,J),0)
!        10 CONTINUE
!
!***REFERENCES  J. J. Dongarra, J. R. Bunch, C. B. Moler, and G. W.
!                 Stewart, LINPACK Users' Guide, SIAM, 1979.
!***ROUTINES CALLED  DAXPY, DDOT
!***REVISION HISTORY  (YYMMDD)
!   780814  DATE WRITTEN
!   890531  Changed all specific intrinsics to generic.  (WRB)
!   890831  Modified array declarations.  (WRB)
!   890831  REVISION DATE from Version 3.2
!   891214  Prologue converted to Version 4.0 format.  (BAB)
!   900326  Removed duplicate information from DESCRIPTION section.
!           (WRB)
!   920501  Reformatted the REFERENCES section.  (WRB)
!***END PROLOGUE  DGBSL
      INTEGER LDA, N, ML, MU, IPVT ( * ), JOB
      DOUBLEPRECISION ABD (LDA, * ), B ( * )
!
      DOUBLEPRECISION DDOT, T
      INTEGER K, KB, L, LA, LB, LM, M, NM1
!***FIRST EXECUTABLE STATEMENT  DGBSL
      M = MU + ML + 1
      NM1 = N - 1
      IF (JOB.NE.0) GOTO 50
!
!        JOB = 0 , SOLVE  A * X = B
!        FIRST SOLVE L*Y = B
!
      IF (ML.EQ.0) GOTO 30
      IF (NM1.LT.1) GOTO 30
      DO 20 K = 1, NM1
         LM = MIN (ML, N - K)
         L = IPVT (K)
         T = B (L)
         IF (L.EQ.K) GOTO 10
         B (L) = B (K)
         B (K) = T
   10    CONTINUE
         CALL DAXPY (LM, T, ABD (M + 1, K), 1, B (K + 1), 1)
   20 END DO
   30 CONTINUE
!
!        NOW SOLVE  U*X = Y
!
      DO 40 KB = 1, N
         K = N + 1 - KB
         B (K) = B (K) / ABD (M, K)
         LM = MIN (K, M) - 1
         LA = M - LM
         LB = K - LM
         T = - B (K)
         CALL DAXPY (LM, T, ABD (LA, K), 1, B (LB), 1)
   40 END DO
      GOTO 100
   50 CONTINUE
!
!        JOB = NONZERO, SOLVE  TRANS(A) * X = B
!        FIRST SOLVE  TRANS(U)*Y = B
!
      DO 60 K = 1, N
         LM = MIN (K, M) - 1
         LA = M - LM
         LB = K - LM
         T = DDOT (LM, ABD (LA, K), 1, B (LB), 1)
         B (K) = (B (K) - T) / ABD (M, K)
   60 END DO
!
!        NOW SOLVE TRANS(L)*X = Y
!
      IF (ML.EQ.0) GOTO 90
      IF (NM1.LT.1) GOTO 90
      DO 80 KB = 1, NM1
         K = N - KB
         LM = MIN (ML, N - K)
         B (K) = B (K) + DDOT (LM, ABD (M + 1, K), 1, B (K + 1),        &
         1)
         L = IPVT (K)
         IF (L.EQ.K) GOTO 70
         T = B (L)
         B (L) = B (K)
         B (K) = T
   70    CONTINUE
   80 END DO
   90 CONTINUE
  100 CONTINUE
      RETURN
      END SUBROUTINE DGBSL
