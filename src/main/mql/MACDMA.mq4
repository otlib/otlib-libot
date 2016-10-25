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
 
// Synopsis: The MACDMA "Moving Average" may serve as an indicator of 
//           overall "Market rate trend"

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "MACD Moving Average Indicator, OTLIB"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1 // number of drawn buffers

#property indicator_color1 clrSilver // Moving Average of MACD
#property indicator_width1 3

// 'input' parameters


#include "libea.mqh"

input ENUM_TIMEFRAMES      MACDMA_TF = PERIOD_CURRENT; // Timeframe for analysis
input int                  MACDMA_EMAFP = 15; // Fast EMA Period
input int                  MACDMA_EMASP = 30; // Slow EMA Period
input int                  MACDMA_PMA = 5;   // Period for moving average
input ENUM_APPLIED_PRICE   METHOD_PRICE = PRICE_TYPICAL; // Price Computation Method


// - Program Parameters
const string               label   = "MACDMA"; // FIXME: Update label in OnInit, illustrating EMAFP, EMASP parameters
const int                  MACDMA_SIGP = 5; // MACDMA SMA i.e signal period 
// Note: MACDMA signal line is unused in this indicator

const string               MACDMA_SYMBOL = getCurrentSymbol();


// - Code


double MMain[]; // iMACD term
double MMavg[]; // moving average - sum of iMACD terms over nterms
double sumCurrent = dblz; // sum for updating tick 0
datetime newestTick; // TBD: Tick-DT conversion

int bufflen;

int macdmaPadBuffers(const int len) {
   // Memory Management
   if(len > bufflen) {
      // FIXME: rename 'rsvbars' (defined in libea.mqh)
      ArrayResize(MMain,len,rsvbars);
      ArrayResize(MMavg,len,rsvbars);
      PrintFormat("MACDMA::Pad Buffers %d => %d ",bufflen, len); // DEBUG
      bufflen = len;
   } 
   return bufflen;
}

void OnInit() {   
   const string labelf = StringFormat("%s(%d,%d,%d)",label,MACDMA_EMAFP,MACDMA_EMASP,MACDMA_PMA);
   IndicatorShortName(labelf);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(2); // one drawn buffer, one data buffer
   bufflen = iBars(NULL, MACDMA_TF);
   initDrawBuffer(MMavg,0,bufflen,"MACD Moving Average",DRAW_LINE,0,true);
   initDataBufferDbl(MMain,1,bufflen,true);
}

double calcMACD(const int backshift) {
   // iMACD computation is orchestrated witih greater shift => older 'tick'
   const double m = iMACD(MACDMA_SYMBOL,MACDMA_TF,MACDMA_EMAFP,MACDMA_EMASP,MACDMA_SIGP,METHOD_PRICE,MODE_MAIN,backshift);
   return m;
}

void calcMACDMAHistoric(const int backshift) {
   // iMACD calculation is conducted witih greater shift -> older 'tick'
   double sumHistoric = dblz;
   double m = dblz;
   for(int n = MACDMA_PMA - 1; n>=0; n--) {
      m = calcMACD(backshift + n);
      sumHistoric += m;
   }
   // FIXME: MMain retained for informative purposes, otherwise unused
   MMain[backshift]= m; // last m at n = 0

   MMavg[backshift]= sumHistoric / MACDMA_PMA;
}


void calcMACDMACurrent() {
   calcMACDMAHistoric(0);
}

// void pushMACDMACurent() { // UNUSED
//   newestTick = TimeCurrent();
// }

int getNTOffset() {
   const int tidx = iBarShift(MACDMA_SYMBOL,MACDMA_TF,newestTick,false);
   return tidx;
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
      const int lim = ncount - MACDMA_PMA;
      for(int n = 0; n <=lim; n++) {
         calcMACDMAHistoric(n);
      }
   } else {
      // if(getNTOffset() != 0) {
      //   pushMACDMACurrent(); // UNUSED
      //   // PrintFormat("MACDMA: PUSH CURRENT"); // DEBUG
      // }
      calcMACDMACurrent();
   }
   // PrintFormat("MACDMA::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
