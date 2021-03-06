module m_mksummary
contains
subroutine mksummary(ave,af,cnum,cvar)
! writes an Eclipse type summary file based on information in an ensemble restart file
   use mod_dimensions
   use mod_states
   use mod_wellnames
   use  m_eclipse_write
   implicit none
   type (states),    intent(in) :: ave
   character(len=4), intent(in) :: cnum
   character(len=1), intent(in) :: af
   character(len=*), intent(in) :: cvar

   integer ird,i,j
   real days
   logical ex
   integer iday,yyyy,mm,dd,irep

   character(len=80) fname
   character(len=80) command

! FSMSPEC file variables
   integer,           allocatable ::  DIMENS(:)
   character(len=10), allocatable ::  KEYWORDS(:)
   integer,           allocatable ::  NUMS(:)
   character(len=10), allocatable ::  RESTART(:)
   integer,           allocatable ::  STARTDAT(:)
   character(len=10), allocatable ::  UNITS(:)
   character(len=10), allocatable ::  WGNAMES(:)

! Summary file
   integer,           allocatable ::  MINISTEP(:)
   real*4,            allocatable ::  PARAMS(:)
   integer,           allocatable ::  SEQHDR(:)

   read(cnum,'(i4)')irep

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Generation of header file cvar.FSMSPEC
   allocate(RESTART(9)); RESTART='''        '''

   call wellnames()

   allocate(DIMENS(6))
   DIMENS(1)=2+nrwells*10 ! number of output fields
   DIMENS(2)=nx
   DIMENS(3)=ny
   DIMENS(4)=nz
   DIMENS(5)=0
   DIMENS(6)=-1

   allocate(KEYWORDS(DIMENS(1)))
   KEYWORDS(1)='''TIME    '''
   KEYWORDS(2)='''YEARS   '''
   i=1; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WTHP    '''
   i=2; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WBHP    '''
   i=3; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WOPR    '''
   i=4; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WGPR    '''
   i=5; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WWPR    '''
   i=6; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WWCT    '''
   i=7; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WGOR    '''
   i=8; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WOPT    '''
   i=9; KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WGPT    '''
   i=10;KEYWORDS(2+(i-1)*nrwells+1:2+i*nrwells)='''WWPT    '''

   allocate(WGNAMES(DIMENS(1)))
   WGNAMES(1)=''':+:+:+:+'''
   WGNAMES(2)=''':+:+:+:+'''
   allocate(NUMS(DIMENS(1)))
   NUMS(1)=-32767
   NUMS(2)=-32767
   do i=1,10
      do j=1,nrwells
         WGNAMES(2+(i-1)*nrwells+j)(1:1)=''''
         WGNAMES(2+(i-1)*nrwells+j)(2:9)=wells(j)(1:8)
         WGNAMES(2+(i-1)*nrwells+j)(10:10)=''''
         NUMS(2+(i-1)*nrwells+j)=j
      enddo
   enddo

   allocate(UNITS(DIMENS(1)))
   UNITS(1)='''DAYS    '''
   UNITS(2)='''YEARS   '''
   i=1; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''  BARSA '''
   i=2; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''  BARSA '''
   i=3; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''SM3/DAY '''
   i=4; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''SM3/DAY '''
   i=5; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''SM3/DAY '''
   i=6; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''        '''
   i=7; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''SM3/SM3 '''
   i=8; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''    SM3 '''
   i=9; UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''    SM3 '''
   i=10;UNITS(2+(i-1)*nrwells+1:2+i*nrwells)='''    SM3 '''

   allocate(STARTDAT(3))
   open(10,file='days.dat')
      read(10,'(tr15,i4,i3,i3)')STARTDAT(3),STARTDAT(2),STARTDAT(1)
   close(10)


   fname(:)=' '
   fname='Diag/'//cvar//'.FSMSPEC'
!   print *,'fname=',trim(fname)
   open(10,file=trim(fname))
   ird=write_char('RESTART ',9,'CHAR',RESTART)
   ird=write_integer('DIMENS  ',6        ,'INTE',DIMENS)
   ird=write_char   ('KEYWORDS',DIMENS(1),'CHAR',KEYWORDS)
   ird=write_char   ('WGNAMES ',DIMENS(1),'CHAR',WGNAMES)
   ird=write_integer('NUMS    ',DIMENS(1),'INTE',NUMS)
   ird=write_char   ('UNITS   ',DIMENS(1),'CHAR',UNITS)
   ird=write_integer('STARTDAT',3        ,'INTE',STARTDAT)
   close(10)
   print *,'mksummary: wrote AVE.FSMSPEC'


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Saving summary file
   allocate( SEQHDR(1)         ); SEQHDR(1)=-1390577905
   allocate( MINISTEP(1)       ); MINISTEP(1)=irep
   allocate( PARAMS(DIMENS(1)) )
   open(10,file='days.dat')
      i=0
      do
         i=i+1
         read(10,'(i4,f10.2,i5,i3,i3)',end=100)iday,days,yyyy,mm,dd
         if (iday == irep) then
            exit
         else
            cycle
         endif
         100 stop 'Reached end of days.dat: Please re-post-process reference run'
      enddo
   close(10)

   PARAMS(1)=days
   PARAMS(2)=0.0
   i=1
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%THP(j)
   enddo
   
   i=2
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%BHP(j)
   enddo
   
   i=3
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%OPR(j)
   enddo
   
   i=4
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%GPR(j)
   enddo
   
   i=5
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%WPR(j)
   enddo
   
   i=6
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%WCT(j)
   enddo
   
   i=7
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%GOR(j)
   enddo

   i=8
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%OPT(j)
   enddo

   i=9
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%GPT(j)
   enddo

   i=10
   do j=1,nrwells
      PARAMS(2+(i-1)*nrwells+j)=ave%WPT(j)
   enddo

   fname(:)=' '
   fname='Diag/'//cvar//'.A'//cnum(1:4)
!   print *,'fname=',trim(fname),'+++'
   if (af=='F') then
      open(10,file=trim(fname))
      ird=write_integer('SEQHDR  ',1        ,'INTE',SEQHDR  )
      ird=write_integer('MINISTEP',1        ,'INTE',MINISTEP)
      ird=write_real   ('PARAMS  ',DIMENS(1),'REAL',PARAMS  )
      close(10)
   elseif (af=='A') then
      inquire(file=trim(fname),exist=ex)
      if (ex) then
         open(10,file=trim(fname),position='append')
         ird=write_integer('MINISTEP',1        ,'INTE',MINISTEP)
         ird=write_real   ('PARAMS  ',DIMENS(1),'REAL',PARAMS  )
         close(10)
      else
         open(10,file=trim(fname))
         ird=write_integer('SEQHDR  ',1        ,'INTE',SEQHDR  )
         ird=write_integer('MINISTEP',1        ,'INTE',MINISTEP)
         ird=write_real   ('PARAMS  ',DIMENS(1),'REAL',PARAMS  )
         close(10)
      endif
   endif


   command(:)=' '
   command='cat '//trim(fname)//' | sed -e "/^$/d" > tmp.file ; mv tmp.file '//trim(fname)
   print *,'executes +++',trim(command),'+++'
   call system(trim(command))
   print *,'mksummary: wrote ',trim(fname)

end subroutine
end module
