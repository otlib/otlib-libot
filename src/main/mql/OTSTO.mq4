/*-                                                     -*- c++ -*-
 * Copyright (c) 2016
 * Sean Champ. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met: 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials provided
 *    with the distribution. 
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.  
 *
 */

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "OTLIB Stochastic Oscillator"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_maximum    100
#property indicator_minimum    0
#property indicator_separate_window
#property indicator_buffers    2
#property indicator_color1     SpringGreen
#property indicator_color2     Gold


input int PeriodD=5;  // Signal Period
input int PeriodS=5;  // Slowing Period

#include "libea.mqh"

double StoMain[];
double StoSignal[];
const string label="OTSTO";

int calcStoHistory(const int nticks,
                   const int prev_calc,
                   const double &high[],
                   const double &low[],
                   const double &close[]) {
//   if (nticks > prev_calc) {
      const int toCount = nticks - prev_calc;
      const int nmin = PeriodD + PeriodS;
      double cl, hl, stmp;
      int n, m;
      for (n = toCount-1; n >= nmin; n--) {
         cl = dblz;
         hl = dblz;
         // FIXME: PeriodK not used here - no scanning for high-minimum/low-maximum in period K
         for(m = (n- PeriodS); m <= n; m++) {
            cl = cl + close[m] - low[m];
            hl = hl + high[m] - low[m];
         }
         if (hl != dblz) { StoMain[n] = cl/hl * 100.0; }
      }
      for (n = toCount-1; n >= nmin; n--) {
         stmp = dblz;
         for(m = (n - PeriodD); m <= n; m++) {
            stmp = stmp + StoMain[m];
         }
         StoSignal[n] = stmp/PeriodD;
         // FIXME: also record StoSignal[n] - StoMain[n]
      }
      return toCount;
//   } else {
      // FIXME: Realtime OnCalculate here
//      return prev_calc;
//   }
}

void OnInit() {
   IndicatorBuffers(2);
   const int bufflen = iBars(NULL, 0);
   initDrawBuffer(StoMain,0,bufflen,"Main",DRAW_LINE,0,false);
   initDrawBuffer(StoSignal,1,bufflen,"Signal",DRAW_LINE,0,false);
}

int OnCalculate(const int ntick,
                const int prev_calc,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   return calcStoHistory(ntick,prev_calc,high,low,close);
}