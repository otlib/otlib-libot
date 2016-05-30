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
#property description "Heikin Ashi Difference Indicator, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 2 // number of drawn buffers

#property indicator_color1 clrDarkOrange
#property indicator_width1 3 // Change in HA Close-Open Difference
#property indicator_color2 clrForestGreen
#property indicator_width2 2 // Heikin Ashi Close-Open Difference


// - Program Parameters
const string label   = "HADiff";

// - Code

#include "libea.mqh"
#include "libha.mqh"

double HAOCDiff[];
double HAOCDChg[];

void OnInit() {
   IndicatorShortName(label);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(8);    
   bufflen = iBars(NULL, 0);
   // NB: SetIndexBuffer may <not> accept a buffer of class type elements, e.g. Trend
   initDrawBuffer(HAOCDChg,0,bufflen,"HA CO Diff Change",DRAW_HISTOGRAM,0,true);
   initDrawBuffer(HAOCDiff,1,bufflen,"HA CO Diff",DRAW_HISTOGRAM,0,true);
   haInitBuffers(2, bufflen);
}


double calcOCDiff(const int n) {
   // const double pdiff = StoMain[n+1] - StoSignal[n+1];
   // Incorporate A/D as to represent a character of market trend
   return (getTickHAOpen(n) - getTickHAClose(n)) * iAD(NULL, 0, n);
}

double calcOCDiffChg(const int n) {
   const double curDiff = calcOCDiff(n);
   const double prevDiff = calcOCDiff(n+1);
   return calcGeoSum(curDiff, prevDiff);
}


int OnCalculate(const int ntick,
                const int prev_count,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   int haCount;
   // NB: The spread buffer may be empty.
   haPadBuffers(ntick);
   
   double sp = getSpread(NULL);

   haCount = calcHA(ntick,0,open,high,low,close);
   if(ntick > prev_count) {
      for(int n = prev_count; n < (ntick - 2); n++) {
         HAOCDiff[n] = calcOCDiff(n);
         HAOCDChg[n] = calcOCDiffChg(n) - sp; // FIXME KLUDGE
      }
      return ntick;
   } else if (ntick > 0) {
      // update zeroth data bar in realtime
      HAOCDiff[0] = calcOCDiff(0);
      HAOCDChg[0] = calcOCDiffChg(0) - sp;
      return ntick;
   } else {
      return 0;
   }
}

// FIXME: Consider making all of the HA data available across MLQL4 'import' semnatics, however tedious.
// 1) define 'export' for trivial functions - move shared functions into otlib.mq4
// 2) ensure compiled forms are avaialble in appropriate directory - see MQL4 Reference  /  MQL4 programs / Call of Imported Functions 
//    ... noting TERMINAL_DATA_PATH 
// 3) define initialization routines that may be called from external program, for initializing this indicator
//     e.c. extHaInit => OnCalculate() in this file (???)
// 4) define runtime routines that may be called from external programs, for updating the indicator's record data
//     e.g extCalcHA => calcHA in this file? or OnCalculate() in this file (???)
// 5) define accessors encapsulating the array access - e.g getHAClose(...) getHACloseAS(...) latter cf. ArraySetAsSeries, TickHA
// 6) DOCUMENT HOWTO if the MT4 and MQL4 docs aren't sufficient in that regards
//