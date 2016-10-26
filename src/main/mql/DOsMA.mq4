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
 

// Synopsis: The OsMA "Difference" indicator (DOsMA) ...


// Maintainer Note: This source file was derived originally from DMACD.mq4 (OTLIB)

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "OsMA Difference Indicator, OTLIB"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 2 // number of drawn buffers

#property indicator_color1 clrSilver // Moving Difference of OsMA
#property indicator_width1 2


#property indicator_color2 clrMidnightBlue // DOsMA / Price
#property indicator_width2 2

// 'input' parameters


#include "libea.mqh"

input ENUM_TIMEFRAMES      DOsMA_TF = PERIOD_CURRENT; // Timeframe for analysis
input int                  DOsMA_EMAFP = 15; // Fast EMA Period
input int                  DOsMA_EMASP = 30; // Slow EMA Period
input ENUM_APPLIED_PRICE   METHOD_PRICE = PRICE_TYPICAL; // Price Computation Method


// - Program Parameters
const string               label   = "DOsMA"; // FIXME: Update label in OnInit, illustrating EMAFP, EMASP parameters
const int                  DOsMA_SIGP = 5; // OsMA SMA i.e signal period 
const string               DOsMA_SYMBOL = getCurrentSymbol();

// - Code

double OsDiff[]; // moving percentage  - sum of iOsMA terms over nterms
double OsRatio[]; // ratio - OsDiff / Price

int bufflen;

int OsMAmaPadBuffers(const int len) {
   // Memory Management
   if(len > bufflen) {
      // FIXME: rename 'rsvbars' (defined in libea.mqh)
      ArrayResize(OsDiff,len,rsvbars);
      // PrintFormat("OsMAMA::Pad Buffers %d => %d ",bufflen, len); // DEBUG
      bufflen = len;
   } 
   return bufflen;
}

void OnInit() {   
   const string labelf = StringFormat("%s(%d,%d)",label,DOsMA_EMAFP,DOsMA_EMASP);
   IndicatorShortName(labelf);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(2); // two drawn buffers, no additional data buffers
   bufflen = iBars(NULL, DOsMA_TF);
   initDrawBuffer(OsDiff,0,bufflen,"OsMA Difference",DRAW_LINE,0,true);
   initDrawBuffer(OsRatio,1,bufflen,"OsMA Price Ratio",DRAW_LINE,0,true);
}

double calcOsMA(const int backshift) {
   // iOsMA computation is orchestrated witih greater shift => older 'tick'
   const double m = iOsMA(DOsMA_SYMBOL,DOsMA_TF,DOsMA_EMAFP,DOsMA_EMASP,DOsMA_SIGP,METHOD_PRICE,backshift);
   return m;
}

void calcDOsMAHistoric(const int backshift) {
   // iOsMA calculation is conducted witih greater shift -> older 'tick'
   
   const double prev = calcOsMA(backshift + 1);
   const double curr = calcOsMA(backshift);
   const double diff = curr - prev;
   OsDiff[backshift]= diff;
   
   const double price = calcPrice(backshift,DOsMA_TF,DOsMA_SYMBOL,METHOD_PRICE);
   OsRatio[backshift] = curr / price;
}


void calcDOsMACurrent() {
   calcDOsMAHistoric(0);
}

// void pushOsMAMACurent() { // UNUSED
//   newestTick = TimeCurrent();
// }

// int getNTOffset() { // UNUSED
//   const int tidx = iBarShift(DOsMA_SYMBOL,DOsMA_TF,newestTick,false);
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
   // PrintFormat("OsMAMA::OnCalculate(%d, %d, ...)", ntick, prev_count); // DEBUG
   
   // NB: market spread (ask, offer difference) not automatically recorded in market history
   // double sp = getSpread();
   
   
   if(ncount  > 0) {
//      if (prev_count == 0) {
         // reset - unused
//      }
      OsMAmaPadBuffers(ncount); // Memory Management
      const int lim = ncount - 2;
      for(int n = 0; n <=lim; n++) {
         calcDOsMAHistoric(n);
      }
   } else {
      // if(getNTOffset() != 0) {
      //   pushOsMAMACurrent(); // UNUSED
      //   // PrintFormat("OsMAMA: PUSH CURRENT"); // DEBUG
      // }
      calcDOsMACurrent();
   }
   // PrintFormat("OsMAMA::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
