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
 
// Synopsis: Simple Volume Indicator

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "Volume Indicator"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1 // number of drawn buffers

#property indicator_color1 clrSilver // Inline Volume Metric
#property indicator_width1 2

#include "libea.mqh"


// - Program Parameters
const string               label   = "VOL"; // FIXME: Update label in OnInit, illustrating EMAFP, EMASP parameters
const int                  VOL_TF = PERIOD_CURRENT; // Timeframe for analysis
const string               VOL_SYMBOL = getCurrentSymbol();


// - Code


double RVol[]; // Rate of Volume

int bufflen;

int VolPadBuffers(const int len) {
   // Memory Management
   if(len > bufflen) {
      // FIXME: rename 'rsvbars' (defined in libea.mqh)
      ArrayResize(RVol,len,rsvbars);
      // PrintFormat("Vol::Pad Buffers %d => %d ",bufflen, len); // DEBUG
      bufflen = len;
   } 
   return bufflen;
}

void OnInit() {   
   IndicatorShortName(label);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(1); // one drawn buffer, no additional data buffers
   bufflen = iBars(NULL, VOL_TF);
   initDrawBuffer(RVol,0,bufflen,"Volume (Vol)",DRAW_LINE,0,true);
}


void calcVol(const int backshift) {
 RVol[backshift]=iVolume(VOL_SYMBOL,VOL_TF,backshift);
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
   
   const int ncount = ntick - prev_count;   
   
   if(ncount  > 0) {
      VolPadBuffers(ncount); // Memory Management
      const int lim = ncount - 1;
      for(int n = 0; n < lim; n++) {
         calcVol(n);
      }
   } else {
      calcVol(0);
   }
   // PrintFormat("Vol::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
