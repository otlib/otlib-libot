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
 
 // NOTE: This indicator develops a concept of "Gross moving average," 
 // in which the moving average is calculated across the entire historic
 // data set. Contrast to a concept of "Net moving average," in which
 // the moving average would be caulculated across an interval p = 5.
 
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
input ENUM_APPLIED_PRICE   METHOD_PRICE = PRICE_TYPICAL; // Price Computation Method


// - Program Parameters
const string               label   = "MACDMA";
const int                  MACDMA_SIGP = 5; // MACDMA SMA i.e signal period 
// Note: MACDMA signal line is unused in this indicator

const string               MACDMA_SYMBOL = getCurrentSymbol();


// - Code


double MMain[]; // iMACD term
double MMavg[]; // moving average - sum of iMACD terms over nterms
double sumHistoric; // sum for moving average
double sumCurrent; // sum for updating tick 0
int nterms; // number of terms in moving average
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
   IndicatorShortName(label);
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
   const double m = calcMACD(backshift);
   MMain[backshift]= m;
   sumHistoric += m;
   MMavg[backshift]= sumHistoric / ++nterms;
}


void calcMACDMACurrent() {
   const double m = calcMACD(0);
   MMain[0]= m;
   sumCurrent = sumHistoric + m;
   MMavg[0]= sumCurrent / nterms;
}

void pushMACDMACurrent() {
   sumHistoric = sumCurrent;
   ++nterms;
   newestTick = TimeCurrent();
}

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

   // fooPadBuffers(ntick);
   PrintFormat("MACDMA::OnCalculate(%d, %d, ...)", ntick, prev_count); // DEBUG
   
   // NB: market spread (ask, offer difference) not automatically recorded in market history
   // double sp = getSpread();
   
   
   if(ncount  > 0) {
      if (prev_count == 0) {
         // reset
         sumCurrent = 0.0;
         nterms = 0;
      }
      macdmaPadBuffers(ncount); // Memory Management
      for(int n = ncount-1; n >=0; n--) {
         calcMACDMAHistoric(n);
      }
   } else {
      if(getNTOffset() != 0) {
         pushMACDMACurrent();
         PrintFormat("MACDMA: PUSH CURRENT"); // DEBUG
      }
      calcMACDMACurrent();
   }
   PrintFormat("MACDMA::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
