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


input int PeriodK=15; // K Period
input int PeriodD=5;  // Signal Period
input int PeriodS=5;  // Slowing Period
input ENUM_MA_METHOD MethodMA=MODE_LWMA; // Moving Average Method
input bool PrcFldLH=false; // Use Low/High Price Fields

#include "libea.mqh"

double StoMain[];
double StoSignal[];
const string label="OTSTO";

void OnInit() {
   IndicatorBuffers(2);
   const int bufflen = iBars(NULL, 0);
   initDrawBuffer(StoMain,0,bufflen,"Main",DRAW_LINE,0,true);
   initDrawBuffer(StoSignal,1,bufflen,"Signal",DRAW_LINE,0,true);
}

double calcStoMain(const int idx) {
   const static int pf = PrcFldLH ? 0 : 1;
   return iStochastic(NULL,0,PeriodK,PeriodD,PeriodS,MethodMA,pf,0,idx);
}


double calcStoSignal(const int idx) {
   const static int pf = PrcFldLH ? 0 : 1;
   return iStochastic(NULL,0,PeriodK,PeriodD,PeriodS,MethodMA,pf,1,idx);
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
                
   
   // PrintFormat("NTICK %d, PREV %d", ntick, prev_calc);
   if(ntick > prev_calc) {
      for(int n = prev_calc; n<ntick; n++) {
         StoMain[n] = calcStoMain(n);
         StoSignal[n] = calcStoSignal(n);
      } 
   } else {
      // update zeroth data bar in realtime
      const int n = 0;
      StoMain[n] = calcStoMain(n);
      StoSignal[n] = calcStoSignal(n);
   }
   return ntick;
}
