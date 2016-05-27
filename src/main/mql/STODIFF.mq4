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
#property indicator_maximum    2
#property indicator_minimum    -2
#property indicator_separate_window
#property indicator_buffers    1 // drawn buffers
#property indicator_color1     Gold

#include "libsto.mqh"

input int stoPeriodK=15; // K Period
input int stoPeriodD=5;  // Signal Period
input int stoPeriodS=5;  // Slowing Period
input ENUM_MA_METHOD stoMethodMA=MODE_LWMA; // Moving Average Method
input bool stoPrcFldLH=false; // Use Low/High Fields
// FIXME: Document stoPrcFldLH

double StoVel[]; // metaphor: velocity of STO [UNUSED]
double StoAcc[]; // metaphor: acceleration of STO

const string stodfLabel="STODF";

int initStoDF(int idx) {
   const int bufflen = iBars(NULL, 0);
   // returns total number of buffers
   initDrawBuffer(StoAcc,idx++,bufflen,"Difference",DRAW_HISTOGRAM,0,true);
   initDataBufferDbl(StoVel,idx++,bufflen,true);
   const int nrbuffs = initStoUndrawn(idx, bufflen);
   return nrbuffs;
}

void OnInit() {
   initStoDF(0);
   IndicatorDigits(Digits+4);
   IndicatorShortName(stodfLabel);
}

double calcVel(const int n) {
   // const double pdiff = StoMain[n+1] - StoSignal[n+1];
   const double mdiff = StoMain[n] - StoMain[n+1];
   // const double cdiff = StoMain[n] - StoSignal[n];
   const double sdiff = StoSignal[n] - StoSignal[n+1];
   if (sdiff == dblz) {
      return dblz;
   } else {
      const double data = mdiff/sdiff;
      if (mdiff < 0) {
         return dblz - data;
      } else {
         return data;
      } 
   }
}

double calcAcc(const int n) {
   const double vcur = calcVel(n);
   const double vprev = calcVel(n+1);
   if (vprev == dblz ) {   
      return dblz;
   } else {
      const double data = vcur/vprev;
      return (vcur < 0) ? -data : data;
   }
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
   calcSto(ntick,prev_calc);
   if(ntick > prev_calc) {
      for(int n = prev_calc; n<ntick - 2; n++) {
         // FIXME: StoVel[] unused
         StoAcc[n] = calcAcc(n);
      }
      return ntick;
   } else if (ntick > 0) {
      // update zeroth data bar in realtime
      StoAcc[0] = calcAcc(0);
      return ntick;
   } else {
      return 0;
   }
}