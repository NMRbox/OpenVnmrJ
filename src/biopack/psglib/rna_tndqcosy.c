/*
 * Copyright (C) 2015  University of Oregon
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Apache License, as specified in the LICENSE file.
 *
 * For more information, see the LICENSE file.
 */
#ifndef LINT
#endif
/* 
 */

/* tndqcosy - double quantum filtered cosy experiment
               using obs xmtr for presaturation during presat period
               and d2, if desired 
              TRANSMITTER MUST BY AT SOLVENT FREQUENCY

  Parameters:

         pw = 90 excitation pulse (at power level tpwr)
      phase =   0: P-type non-phase-sensitive experiment
              1,2: hypercomplex phase-sensitive experiment
                3: TPPI phase-sensitive experiment
   satmode  = 'yn' for saturation during relaxation period
              'ny' for saturation during d2
              'yy' for both
     satdly = presaturation period -uses obs xmtr at tof with satpwr; 
      sspul = 'y': selects for Trim(x)-Trim(y)
               sequence at start of pulse sequence
             (highly recommended to eliminate "long T1" artifacts)
 

  revised from dqcosy.c       Sept 1991  g.gray
	P.A.Keifer 940916 - modified d2 and rlpower 
  */


#include <standard.h>

void pulsesequence()
{
   char            sspul[MAXSTR];


/* LOAD VARIABLES AND CHECK CONDITIONS */
   getstr("sspul", sspul);

   if (satpwr > 40)
   {
      printf("satpwr too large  - acquisition aborted.\n");
      psg_abort(1);
   }
   if ((rof1 < 9.9e-6) && (ix== 1))
      fprintf(stdout,"Warning:  ROF1 is less than 10 us\n");

/* STEADY-STATE PHASECYCLING */
/* This section determines if the phase calculations trigger off of (SS - SSCTR)
   or off of CT */

   ifzero(ssctr);
      hlv(ct, v4);
      mod4(ct, v3);
   elsenz(ssctr);
      sub(ssval, ssctr, v12);	/* v12 = 0,...,ss-1 */
      hlv(v12, v4);
      mod4(v12, v3);
   endif(ssctr);


/* CALCULATE PHASECYCLE */
/* The phasecycle first performs a 4-step cycle on the third pulse in order
   to select for DQC.  Second, the 2-step QIS cycle is added in.  Third, a
   2-step cycle for axial peak suppression is performed on the second pulse.
   Fourth, a 2-step cycle for axial peak suppression is performed on the
   first pulse.  If P-type peaks only are being selected, the 2-step cycle
   for P-type peak selection is performed on the first pulse immediately
   after the 4-step cycle on the third pulse. */

   hlv(v4, v4);
   if (phase1 == 0)
   {
      assign(v4, v6);
      hlv(v4, v4);
      mod2(v6, v6);		/* v6 = P-type peak selection in w1 */
   }
   hlv(v4, v2);
   mod4(v4, v4);		/* v4 = quadrature image suppression */
   hlv(v2, v1);
   mod2(v1, v1);
   dbl(v1, v1);
   mod2(v2, v2);
   dbl(v2, v2);
   dbl(v3, v5);
   add(v3, v5, v5);
   add(v1, v5, v5);
   add(v2, v5, v5);
   add(v4, v5, v5);
   add(v4, v1, v1);
   add(v4, v2, v2);
   add(v4, v3, v3);
   if (phase1 == 0)
   {
      add(v6, v1, v1);
      add(v6, v5, v5);
   }
   if (phase1 == 2)
      incr(v1);
   if (phase1 == 3)
      add(id2, v1, v1);		/* adds TPPI increment to the phase of the
				 * first pulse */
   assign(v5, oph);

  /* FOR HYPERCOMPLEX, USE REDFIED TRICK TO MOVE AXIALS TO EDGE */  
   if ((phase1==2)||(phase1==1))
   {
      initval(2.0*(double)(d2_index%2),v9);  /* moves axials */
      add(v1,v9,v1); add(oph,v9,oph);
   }

/* BEGIN ACTUAL PULSE SEQUENCE CODE */
   status(A);
   if (sspul[0] == 'y')
   {
      obspower(tpwr-12);
      rgpulse(200*pw, one, 10.0e-6, 0.0e-6);
      rgpulse(200*pw, zero, 0.0e-6, 1.0e-6);
      obspower(tpwr);
   }
   hsdelay(d1);
   if (satmode[A] == 'y')
   {
      obspower(satpwr); 
      rgpulse(satdly,zero,rof1,rof1);
      obspower(tpwr);
   }
   status(B);
   rgpulse(pw, v1, rof1, 1.0e-6);
   if (satmode[B] == 'y')
   {
      obspower(satpwr);
      if (d2>100.0e-6)
         rgpulse(d2-(2*POWER_DELAY)-1.0e-6-rof1-(4*pw)/3.14159,zero,0.0,0.0);
      obspower(tpwr);
   }
   else if (d2>0.0)
   {
      delay(d2 - rof1 - 1.0e-6 -(4*pw)/3.1416);
   }
   rgpulse(pw, v2, rof1, 0.0);
   rgpulse(pw, v3, 1.0e-6, rof2);
   status(C);
}
