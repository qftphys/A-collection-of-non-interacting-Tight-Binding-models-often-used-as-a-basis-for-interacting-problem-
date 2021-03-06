      program provau0

c     +--------------------------------------------------------------------+
c     PROGRAM  : u0.f
c     VERSION  : 20-03-2008
c     AUTHOR   : Adriano Amaricci (amaricci@lps.u-psud.fr)
c     Giovanni Sordi (sordi@lps.u-psud.fr)
c     PORPOSE  : solve the PAM for U=0, using the BL
c     
c     OUTPUT   : dos, Green's functions, p-selfenergy, etc
c     (input are in fort.99) 
c     +--------------------------------------------------------------------+

      implicit none
c     ---------------------------------------------------------------------
c     variables used
      integer L,Lepsi,k,M,j,L2,Nfreq
      parameter(L=2*4096,Lepsi=1000,M=16*4096)
      real*8 pi,U,D,V,ep0,ed0,dosminus,dospd,dosd,dosp0,dosd0,temp0
      real*8 omega,omega_zero,omega_max,omega_step,ome(-L:L),mues
      real*8 sign,alpha,gamma,delta,xmu,xmu0,dmu,dome,om(M),tau,dtau
      real*8 ome1,ome2,ome3,ome4,gzeropa,gzeropb,beta,gzerop,gzerom
      real*8 ome1apx,ome2apx,ome3apx,ome4apx,sigmapp,xxx,Eplus(Lepsi),
     *     Eminus(Lepsi),xxmu,tr(Lepsi),radice(Lepsi),poles,
     *     omestep,omemax,omemin,nu(-L:L),sig,sig0,beta0,isq0
      real*8 epsilon,epsimin,epsimax,depsi,zeta,pinzeta,epsi(Lepsi)
      real*8 dband,pband,mass,Va,Vb,w,isig,isq,xref,isig0
      complex*16 xi,Gppdd,Gminus,root,Gd,zi,zr,one,iGd,iroot0,gfbethe
      complex*16 dispersionroot,iome,pinroot,d2,iw,gpd(4*L)
      real*8 gtpd(-2*L:2*L),At(-2*L:2*L),kplus,kk

      complex*16 izeta,pinningp,xgd(M),xgp(M),pinningd,izeta0
      complex*16 ialpha,igamma,iroot,isigmapp,iGminus,iGminus0,iGppdd
      integer i,imax,nmu,imu,n
      integer ll,lmax
      
      real*8 ndelta,ndelta1,nepserr,nread,znd,znp,zntot,znpp,zndd,znpd
      integer nindex,nindex1,niter,iteration,muflag,multi

      real*8 fermi,ddens,dfermi,xfermi,dens,free,emin,emax,e,temp

      double precision muesgp,muesgd,imues,rmues,imuesd,rmuesd
      double precision kag0,kag,kas,code,coda1,coda2,zsig
      
      complex*16 greenp0,greenp,greenpd,sqroot,sqroot0,zero
      complex*16 tail,tail0,tails,selfpR,greenpR,greenp0R
      complex*16 gptail,gp0tail,sig1,sig2,wm1,wm2
      complex*16 selfp,selfd,zita,zita0,npcomp,fgpd(4*L)
      complex*16 Etot,Ekin,Epot,Ehyb,Emu,Eepsi,Ec,Ect
      complex*16 Etot1,Ekin1,Epot1,Ehyb1,EkinA,EkinB,EkinC
      
      character*1 itu,todo
c--------------------
c     set some parameters

      one=(1.d0,0.d0)
      pi=3.141592653589793238d0
      xi=(0.d0,1.d0)
      zero=(0.d0,0.d0)

      nindex=0                  !the test variable (0,1,-1)
      ndelta=0.1d0              !mu-step
      nepserr=1.e-12            !Tolerance in mu (should be ~ 1.e-1*delta)


      
      open(99,file='inputU0.in')
      read(99,*)V,ep0,ed0,D,itu
      read(99,*)xmu0,nmu,dmu,temp0
      read(99,*)omemin,omemax   
      read(99,*)muflag,nread
      read(99,*)Nfreq
      close(99)

      temp=temp0
      beta=1.d0/temp
      d2=D*(1.d0,0.d0)
      d2=d2**2
      U=0.0d0
      delta=ed0-ep0
      omestep=(omemax-omemin)/dfloat(2*L+1)
      do i=-L,L
         nu(i)=omemin+omestep*dfloat(L+i)
      enddo
      do i=-L,L
         ome(i) = dfloat(2*i-1)
         ome(i) = (pi/beta)*ome(i) !the positive freq.(n:1-->L-1)
      enddo
      dome=ome(2)-ome(1)

      gzerop=0.5*(ep0+ed0+sqrt((ep0-ed0)**2 + 4*V**2))
      gzerom=0.5*(ep0+ed0-sqrt((ep0-ed0)**2 + 4*V**2))
      xmu0=xmu0
      if(delta.gt.0.d0)xmu0=xmu0+gzerop
      if(delta.lt.0.d0)xmu0=xmu0+gzerom
      xmu=xmu0

      print*,'Delta_eff [|gammap-gammam|]',gzerop-gzerom
      print*,gzerop,gzerom

      open(21,file='DOSpp.analytic')
      open(22,file='Sigmapp_realw.analytic')
      open(23,file='Gpp_iw.analytic')
      open(24,file='Sigmapp_iw.analytic')

      open(25,file='DOSdd.analytic')
      open(26,file='Gdd_iw.analytic')
      
      open(27,file='Bandpoles.analytic')
      open(28,file='Gpd_iw.analytic')
      open(29,file='DOSpd.analytic')
      
c     -----------------
c     compute the DOS
      
      do imu=1,nmu         
         if(itu.eq.'t')then
            todo='n'
            temp=temp0+dmu*(imu-1)
            beta=1.d0/temp
            print*,''
            print*,imu,'/',nmu,'',beta    
            do i=-L,L
               ome(i) = dfloat(2*i-1)
               ome(i) = (pi/beta)*ome(i) !the positive freq.(n:1-->L-1)
            enddo
            dome=ome(2)-ome(1)
         elseif(itu.eq.'m')then
            todo='y'
            xmu=xmu0+dmu*(imu-1)
            print*,''
            print*,imu,'/',nmu,'',xmu    
         endif

c======================================================
*     Fix chemical potential, get density.
         if(muflag.eq.0)then
!     if(nmu.eq.1)then
            do i=-L,L
               omega=ome(i)
               zi=xi*omega
               zr=nu(i)+xi*0.01d0
               
               alpha=zr+xmu-ed0
               ialpha=zi+xmu-ed0
               zeta=zr+xmu-ep0-(V**2/(alpha))
               izeta0=zi+xmu-ep0
               izeta=zi+xmu-ep0-(V**2/(ialpha))
               
               sigmapp=V**2/(alpha)
               isigmapp=V**2/(ialpha)

               root = cdsqrt((zeta)**2-d2) !cmplx(gamma**2 -D**2)
               iroot0= cdsqrt((izeta0)**2-d2) !cmplx(igamma**2 -D**2)
               iroot= cdsqrt((izeta)**2-d2) !cmplx(igamma**2 -D**2)

               isq=dimag(iroot)
               isq0=dimag(iroot0)

               w=dimag(zi)
               isig=w*isq/dabs(w*isq)
               isig0=w*isq0/dabs(w*isq0)

c     get the p -DOS
               iGminus=2.d0*one/(izeta+isig*iroot)
               iGminus0=2.d0*one/(izeta0+isig0*iroot0)
               Gminus=2.d0*one/(zeta-root) !cmplx((2.d0/(D**2))*(gamma - root))
               dosminus=-dimag(Gminus)/pi
               if(i.eq.0)dosp0=dosminus

c     get the d-DOS
               Gd =one/(alpha) + (V**2/alpha**2)*Gminus
               iGd=one/(ialpha) + (V**2/ialpha**2)*iGminus
               dosd=-dimag(Gd)/pi
               if(i.eq.0)dosd0=dosd

               Gppdd=V/alpha*Gminus
               if(dimag(Gppdd).gt.0.d0)Gppdd=-Gppdd
               iGppdd=V/ialpha*iGminus
               dospd=-dimag(Gppdd)/pi

c     get poles
               poles=nu(i)-ep0+xmu-real(sigmapp)
               
               if(i.eq.1)then
                  sig1=isigmapp
                  wm1=omega
               endif
               if(i.eq.2)then
                  sig2=isigmapp
                  wm2=omega
               endif
               if(i.ge.1)then
                  write(23,*) omega,dimag(iGminus),real(iGminus)
                  write(24,*) omega,dimag(isigmapp),real(isigmapp)
                  write(26,*) omega,dimag(iGd),real(iGd)
                  write(28,*) omega,dimag(iGppdd),real(iGppdd)
               endif
               write(21,*) nu(i),dosminus !  p-DOS
               write(22,*) nu(i),sigmapp
               write(29,*) nu(i),dospd !  pd-DOS
               write(25,*) nu(i),dosd !  d-DOS
               if(abs(poles).le.1.d0)then
                  write(27,*)nu(i),poles
               endif
            enddo
!     endif
            zsig   = dimag(sig1)-wm1*(dimag(sig2)-dimag(sig1))/(wm2-wm1)



            zntot=0.d0
            znd=0.d0
            znp=0.d0
            znpd=0.d0
            do i=-L,L
               omega=nu(i)
               zr=omega+xi*0.05d0
               alpha=zr+xmu-ed0
               zeta=zr+xmu-ep0-(V**2/(alpha))
               root = cdsqrt((zeta)**2-d2)
               Gminus=2.d0*one/(zeta-root)
               dosminus=-dimag(Gminus)/pi
               Gd =(one+V**2/alpha*Gminus)/alpha
               dosd=-dimag(Gd)/pi
               xfermi=fermi(omega,0.d0,beta)

               znp=znp+2.d0*dosminus*omestep*xfermi
               znd=znd+2.d0*dosd*omestep*xfermi
               zntot=znd+znp
            enddo
            if(itu.eq.'m')then
               open(60,file='npVSmu.analytic',access='append')
               open(61,file='ndVSmu.analytic',access='append')
               open(62,file='ntotVSmu.analytic',access='append')
               write(60,*)xmu,znp
               write(61,*)xmu,znd
               write(62,*)xmu,zntot
               do i=60,62
                  close(i)
               enddo
            endif
            if(nmu.ne.1.and.itu.eq.'t')then
               open(60,file='npVStemp.analytic',access='append')
               open(61,file='ndVStemp.analytic',access='append')
               open(62,file='ntotVStemp.analytic',access='append')
               write(60,*)temp,znp
               write(61,*)temp,znd
               write(62,*)temp,zntot
               write(63,*)temp,zsig
               do i=60,62
                  close(i)
               enddo
            endif
            print*,'nd     =',znd
            print*,'np     =',znp
            print*,'ntot   =',zntot
            print*,'xmu    =',xmu
            print*,'shift  =',gzerop
            if(itu.eq.'t')then
               include 'getener.f'
            endif
            if(nmu.eq.1)then
               include 'arpes0.f'
            endif
c======================================================
*     Fix density get chemical potential
         elseif(muflag.eq.1)then
            include 'searchmu0.f'
         endif

c============================================================
c     End get solution
c============================================================

         pinroot=cdsqrt((xmu-ep0-(V**2/(xmu-ed0)))**2-d2)
         pinningp=2.d0*one/(xmu-ep0-(V**2/(xmu-ed0))-pinroot)
         pinningd=one/(xmu-ed0)+(V**2/(xmu-ed0)**2)*pinningp
         
         xref=xmu-ep0-(V**2/(xmu-ed0))

         open(60,file='nepsiOUT.analytic')
         write(60,*)'Gpp(w-->0)',dimag(pinningp)/pi
         write(60,*)'DOSpp(0)',dosp0
         write(60,*)'Gdd(w-->0)',dimag(pinningd)/pi
         write(60,*)'DOSdd(0)',dosd0
         close(60)
         
         if(1.eq.1)then
            print*,'Gpp(w-->0)',dimag(pinningp)/pi
            print*,'DOSpp(0)',dosp0
            print*,'Gdd(w-->0)',dimag(pinningd)/pi
            print*,'DOSdd(0)',dosd0
            pinningp=pinningp+pinningd
            dosp0=dosp0+dosd0
            print*,'Gtotal(w-->0)',dimag(pinningp)/pi
            print*,'DOStotal(0)',dosp0
            print*,'-------------------'
            print*,'FermiLevel',xref
         endif

         open(50,file='FermiLevelVSmu.analytic')
         write(50,*)beta,xref
         close(50)

         
c------------------------------------------------------------
         if(1.eq.2)then
            include 'arpes0.f'
         endif

c------------------------------------------------c
c     compute the width of the two bands
         include 'width.f'

         do i=21,26
            write(i,*) ''
         enddo
      enddo

      END
      include 'subroutines.f'
