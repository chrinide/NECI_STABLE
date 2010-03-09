Program ModelFCIQMC
    IMPLICIT NONE
    INTEGER , PARAMETER :: NDet=100
    INTEGER , PARAMETER :: LScr=4*NDet
    REAL*8 , PARAMETER :: Tau=0.05
    REAL*8 , PARAMETER :: SftDamp=0.05
    INTEGER , PARAMETER :: StepsSft=25
    INTEGER , PARAMETER :: NMCyc=1000000
    INTEGER , PARAMETER :: InitialWalk=1 
    INTEGER , PARAMETER :: TargetWalk=1000
    REAL*8 , PARAMETER :: InitialShift=0.D0
    REAL*8 :: KMat(NDet,NDet),Norm,GrowRate,GroundShift,rat,r,Norm1
    INTEGER :: GroundTotParts,Iter,OldGroundTotParts
    REAL*8 :: EigenVec(NDet,NDet),EValues(NDet),Scr(LScr),Check
    INTEGER :: ierr,i,j,Die,Create,k
    INTEGER :: WalkListGround(NDet),WalkListGroundSpawn(NDet)
    INTEGER*8 :: SumWalkListGround(NDet)
    LOGICAL :: tFixedShift


!Initialise rand
    call random_seed()

!Set up KMat
    CALL SetUpKMat(KMat,NDet)
    WRITE(6,*) "Setting up K-Matrix..."

!Diagonalise KMat
    EigenVec(:,:)=KMat(:,:)
    WRITE(6,*) "Diagonalising K-Matrix..."
    CALL DSYEV('V','U',NDet,EigenVec,NDet,Evalues,Scr,LScr,ierr)
    IF(ierr.ne.0) THEN
        STOP 'Error diagonalising matrix'
    ENDIF
    OPEN(9,FILE="Eigenvectors",STATUS='UNKNOWN')
    do i=1,NDet
        WRITE(9,"(I5)",advance='no') i
        do j=1,9
            WRITE(9,"(F20.12)",advance='no') EigenVec(i,j)
        enddo
        WRITE(9,"(F20.12)") EigenVec(i,10)
    enddo
    CLOSE(9)

!    Norm=0.D0
!    Norm1=0.D0
    do i=1,NDet
!        Norm=Norm+abs(EigenVec(i,1))
        Norm1=Norm1+(EigenVec(i,1))**2
    enddo
!    WRITE(6,*) "Norm = ",Norm
!    WRITE(6,*) "Norm for sq = ",Norm1

    WRITE(6,*) "Lowest eigenvalues: "
    OPEN(9,FILE="Eigenvalues",STATUS='UNKNOWN')
    do i=1,10
        WRITE(9,*) i,EValues(i)
        WRITE(6,*) i,EValues(i)
    enddo
    CLOSE(9)

    WRITE(6,*) "Performing Spawning..."

!Setup spawning
    WalkListGround(:)=0
    GroundShift=InitialShift
!    WalkListExcit(:)=0
    SumWalkListGround(:)=0
    OPEN(12,FILE='ModelFCIMCStats',STATUS='unknown')

    WalkListGround(1)=InitialWalk
!    WalkListExcit(1)=-1     !Start off orthogonal
    tFixedShift=.true.
    OldGroundTotParts=InitialWalk
    
    do Iter=1,NMCyc

!Every so often, update the shift
        IF((mod(Iter,StepsSft).eq.0).and.(Iter.ne.1)) THEN

            GrowRate=REAL(GroundTotParts,8)/REAL(OldGroundTotParts,8)
            IF(.not.tFixedShift) THEN
                GroundShift=GroundShift-(log(GrowRate)*SftDamp)/(Tau*(StepsSft+0.D0))
            ELSE
                IF(GroundTotParts.ge.TargetWalk) THEN
                    tFixedShift=.false.
                ENDIF
            ENDIF
            OldGroundTotParts=GroundTotParts

            !Write out stats
            WRITE(6,"(I8,F25.12,I15,I7)") Iter,GroundShift,GroundTotParts,WalkListGround(1)
            WRITE(12,"(I8,F25.12,I15,I7)") Iter,GroundShift,GroundTotParts,WalkListGround(1)

            Norm=0.D0
            Norm1=0.D0
            do i=1,NDet
                Norm=Norm+REAL(WalkListGround(i),8)**2
                Norm1=Norm1+REAL(SumWalkListGround(i),8)**2
            enddo
            Norm=SQRT(Norm)
            Norm1=SQRT(Norm1)
            OPEN(13,FILE='GroundWavevec',STATUS='unknown')
!            Check=0.D0
            do i=1,NDet
!                Check=Check+(REAL(SumWalkListGround(i),8)/Norm1)**2
                WRITE(13,*) i,REAL(WalkListGround(i),8)/Norm,REAL(SumWalkListGround(i),8)/Norm1
            enddo
!            WRITE(6,*) "Check = ",Check
            CLOSE(13)
        ENDIF

!Rezero spawning arrays    
!        WalkListExcitSpawn(:)=0
        WalkListGroundSpawn(:)=0

!Simulate dynamic for calculation of GS
        do i=1,NDet     !Run through all determinants
!            WRITE(6,*) "Determinant: ",i

            do j=1,abs(WalkListGround(i))  !Run through all walkers

!Simulate full spawning by running through all connections.
                do k=1,NDet

                    IF(KMat(i,k).eq.0.D0) CYCLE
                    IF(i.eq.k) CYCLE

                    rat=abs(Tau*KMat(i,k))
!                    WRITE(6,*) rat
                    Create=INT(rat)
                    rat=rat-REAL(Create)
                    call random_number(r)
                    IF(rat.gt.r) THEN
!                        WRITE(6,*) "CREATED PARTICLE"
                        Create=Create+1
                    ENDIF

                    !create particles.
                    IF(KMat(i,k).gt.0.D0) THEN
                        !Flip child sign
                        IF(WalkListGround(i).lt.0) THEN
                            !Positive children
                            WalkListGroundSpawn(k)=WalkListGroundSpawn(k)+Create
                        ELSE
                            WalkListGroundSpawn(k)=WalkListGroundSpawn(k)-Create
                        ENDIF
                    ELSE
                        !Same sign as parent
                        IF(WalkListGround(i).gt.0) THEN
                            !Positive children
                            WalkListGroundSpawn(k)=WalkListGroundSpawn(k)+Create
                        ELSE
                            WalkListGroundSpawn(k)=WalkListGroundSpawn(k)-Create
                        ENDIF
                    ENDIF

                enddo

            enddo

!            do j=1,abs(WalkListGround(i))   
!!Each walker has unique probability to die
!                rat=Tau*(KMat(i,i)-GroundShift)
!                Die=INT(abs(rat))
!                IF(rat.lt.0.D0) THEN
!                    Die=-Die
!                    rat=rat+REAL(Die)
!                ELSE
!                    rat=rat-REAL(Die)
!                ENDIF
!                call random_number(r)
!                IF(abs(rat).gt.r) THEN
!                    IF(rat.gt.0.D0) THEN
!                        Die=Die+1
!                    ELSE
!                        Die=Die-1
!                    ENDIF
!                ENDIF
!                IF(WalkListGround(i).gt.0) THEN
!                    WalkListGround(i)=WalkListGround(i)-Die
!                ELSE
!                    WalkListGround(i)=WalkListGround(i)+Die
!                ENDIF
!            enddo

!Attempt to die simultaneously to all particles
            rat=REAL(abs(WalkListGround(i)),8)*Tau*(KMat(i,i)-GroundShift)
            Die=INT(rat)
            rat=rat-REAL(Die)
            call random_number(r)
            IF(abs(rat).gt.r) THEN
                IF(rat.gt.0.D0) THEN
                    Die=Die+1
                ELSE
                    Die=Die-1
                ENDIF
            ENDIF
            IF(Die.gt.abs(WalkListGround(i))) STOP 'Trying to create anti-particles'
            IF(WalkListGround(i).gt.0) THEN
                WalkListGround(i)=WalkListGround(i)-Die
            ELSE
                WalkListGround(i)=WalkListGround(i)+Die
            ENDIF

        enddo

!Combine lists (annihilation)
        GroundTotParts=0
        do i=1,NDet
            WalkListGround(i)=WalkListGround(i)+WalkListGroundSpawn(i)
            SumWalkListGround(i)=SumWalkListGround(i)+WalkListGround(i)
            GroundTotParts=GroundTotParts+abs(WalkListGround(i))
        enddo
        IF(GroundTotParts.eq.0) THEN
            WRITE(6,*) "ALL WALKERS DIED - RESTARTING"
            GroundShift=InitialShift
            WalkListGround(1)=InitialWalk
            tFixedShift=.true.
            OldGroundTotParts=InitialWalk
        ENDIF

    enddo
    CLOSE(12)
        


End Program ModelFCIQMC


SUBROUTINE SetUpKMat(KMat,NDet)
    IMPLICIT NONE
    INTEGER :: NDet,i,j
    REAL*8 :: KMat(NDet,NDet),StartEl,EndEl,Step,ProbNonZero,OffDiagEl
    REAL*8 :: r

    KMat(:,:)=0.D0

    StartEl=0.5
    EndEl=10.D0
    Step=(EndEl-StartEl)/REAL(NDet-1,8)
    KMat(2,2)=StartEl
    do i=3,NDet
        KMat(i,i)=KMat(i-1,i-1)+Step
    enddo

    WRITE(6,*) "RefDet = ", KMat(1,1)
    WRITE(6,*) "MaxDet = ", KMat(NDet,NDet)

    ProbNonZero=0.2     !This is probability that off-diagonal matrix elements are non-zero
    OffDiagEl=5.D-2     !This is the magnitude of the off-diagonal matrix elements.
    do i=1,NDet
        do j=1,i-1
            call random_number(r)
            IF(r.gt.ProbNonZero) THEN

                IF(r.gt.0.51) THEN
                    !Matrix element is negative with probability 0.49
                    KMat(i,j)=-OffDiagEl
                    KMat(j,i)=-OffDiagEl
                ELSE
                    !Matrix element is positive with probability 0.49
                    KMat(i,j)=OffDiagEl
                    KMat(j,i)=OffDiagEl
                ENDIF
            ENDIF
        enddo
    enddo

END SUBROUTINE SetUpKMat
