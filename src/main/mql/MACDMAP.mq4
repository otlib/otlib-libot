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
 

// Synopsis: The MACD "Moving Percentage" indicator (MACDMAP) may serve 
//           in illustrating any transitional reversals of the MACD rate, 
//           as calculated principally onto the going market rate. During 
//           an event of MACD crossover, the MACDMAP term may illustrate a
//           pronounced "Spike" in the value of the term's functional ratio. 

// Description: Methodologically, this indicator calculates the MACDMAP term
//              for any "chart tick" as the quotient (or ratio) of the current 
//              MACD for the given "chart tick", over the MACD for the "chart 
//              tick" previous to the curent. 
//
//              Of course, the MetaTrader 4 platform may interpolate values
//              intermediate to indivdual chart ticks, as in order to trace a
//              continuous graph line across the individual data points, in each
//              individual chart window. Principally, the data is calculated at
//              a scale of individual "Chart ticks".


// Maintainer Note: This source file was derived originally from MACDMA.mq4 (OTLIB)

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "MACD Moving Percentage Indicator, OTLIB"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1 // number of drawn buffers

#property indicator_color1 clrSilver // Moving Percentage of MACD
#property indicator_width1 3

// 'input' parameters


#include "libea.mqh"

input ENUM_TIMEFRAMES      MACDMAP_TF = PERIOD_CURRENT; // Timeframe for analysis
input int                  MACDMAP_EMAFP = 15; // Fast EMA Period
input int                  MACDMAP_EMASP = 30; // Slow EMA Period
input ENUM_APPLIED_PRICE   METHOD_PRICE = PRICE_TYPICAL; // Price Computation Method


// - Program Parameters
const string               label   = "MACDMAP"; // FIXME: Update label in OnInit, illustrating EMAFP, EMASP parameters
const int                  MACDMAP_SIGP = 5; // MACDMA SMA i.e signal period 
const string               MACDMAP_SYMBOL = getCurrentSymbol();

// - Code

double MPerc[]; // moving percentage  - sum of iMACD terms over nterms
// datetime newestTick; // UNUSED

int bufflen;

int macdmaPadBuffers(const int len) {
   // Memory Management
   if(len > bufflen) {
      // FIXME: rename 'rsvbars' (defined in libea.mqh)
      ArrayResize(MPerc,len,rsvbars);
      // PrintFormat("MACDMA::Pad Buffers %d => %d ",bufflen, len); // DEBUG
      bufflen = len;
   } 
   return bufflen;
}

void OnInit() {   
   const string labelf = StringFormat("%s(%d,%d)",label,MACDMAP_EMAFP,MACDMAP_EMASP);
   IndicatorShortName(labelf);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(1); // one drawn buffer, no additional data buffers
   bufflen = iBars(NULL, MACDMAP_TF);
   initDrawBuffer(MPerc,0,bufflen,"MACD Moving Percentage",DRAW_LINE,0,true);
}

double calcMACD(const int backshift) {
   // iMACD computation is orchestrated witih greater shift => older 'tick'
   const double m = iMACD(MACDMAP_SYMBOL,MACDMAP_TF,MACDMAP_EMAFP,MACDMAP_EMASP,MACDMAP_SIGP,METHOD_PRICE,MODE_MAIN,backshift);
   return m;
}

void calcMACDMAPHistoric(const int backshift) {
   // iMACD calculation is conducted witih greater shift -> older 'tick'
   
   const double prev = MathAbs(calcMACD(backshift + 1));
   const double cur = MathAbs(calcMACD(backshift));
   double percentage;

   if(prev == 0) {
      // PrintFormat("Note: Calculated zero MACD for shift %d", backshift + 1); // DEBUG
      percentage = 0;
   } else {
      percentage = cur/prev;
   }
   MPerc[backshift]= percentage;
}


void calcMACDMAPCurrent() {
   calcMACDMAPHistoric(0);
}

// void pushMACDMACurent() { // UNUSED
//   newestTick = TimeCurrent();
// }

// int getNTOffset() { // UNUSED
//   const int tidx = iBarShift(MACDMAP_SYMBOL,MACDMAP_TF,newestTick,false);
//   return tidx;
// }


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
   // ^ FIXME: Document calculation behavior when changing timeframes in current chart

   // fooPadBuffers(ntick);
   // PrintFormat("MACDMA::OnCalculate(%d, %d, ...)", ntick, prev_count); // DEBUG
   
   // NB: market spread (ask, offer difference) not automatically recorded in market history
   // double sp = getSpread();
   
   
   if(ncount  > 0) {
//      if (prev_count == 0) {
         // reset - unused
//      }
      macdmaPadBuffers(ncount); // Memory Management
      const int lim = ncount - 2;
      for(int n = 0; n <=lim; n++) {
         calcMACDMAPHistoric(n);
      }
   } else {
      // if(getNTOffset() != 0) {
      //   pushMACDMACurrent(); // UNUSED
      //   // PrintFormat("MACDMA: PUSH CURRENT"); // DEBUG
      // }
      calcMACDMAPCurrent();
   }
   // PrintFormat("MACDMA::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
