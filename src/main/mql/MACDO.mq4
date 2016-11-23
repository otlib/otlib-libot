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
 

// Synopsis: The Moving Average Convergence/Divergence Oscillation indoator (MACDO) ...


// Maintainer Note: This source file was derived originally from DMACD.mq4 (OTLIB)

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "MACD - OsMA Difference, OTLIB"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_separate_window
#property indicator_buffers 1

#property indicator_color1 clrSilver 
#property indicator_width1 2

// 'input' parameters


#include "libea.mqh"

input ENUM_TIMEFRAMES      MACDO_TF = PERIOD_CURRENT; // Timeframe for analysis
input int                  MACDO_EMAFP = 15; // Fast EMA Period
input int                  MACDO_EMASP = 30; // Slow EMA Period
input ENUM_APPLIED_PRICE   METHOD_PRICE = PRICE_TYPICAL; // Price Computation Method


// - Program Parameters
const string               label   = "MACDO";
const int                  MACDO_SIGP = 5; // OsMA SMA i.e signal period 
const string               MACDO_SYMBOL = getCurrentSymbol();

// - Code

double MACDODiff[]; // moving percentage  - sum of iOsMA terms over nterms

int bufflen;

int OsMAmaPadBuffers(const int len) {
   // Memory Management
   if(len > bufflen) {
      // FIXME: rename 'rsvbars' (defined in libea.mqh)
      ArrayResize(MACDODiff,len,rsvbars);
      // PrintFormat("OsMAMA::Pad Buffers %d => %d ",bufflen, len); // DEBUG
      bufflen = len;
   } 
   return bufflen;
}

void OnInit() {   
   const string labelf = StringFormat("%s(%d,%d)",label,MACDO_EMAFP,MACDO_EMASP);
   IndicatorShortName(labelf);
   IndicatorDigits(Digits+2);
   IndicatorBuffers(1); // one drawn buffer, no additional data buffers
   bufflen = iBars(NULL, MACDO_TF);
   initDrawBuffer(MACDODiff,0,bufflen,"MACDO Difference",DRAW_LINE,0,true);
}

double calcOsMA(const int backshift) {
   // iOsMA computation is orchestrated witih greater shift => older 'tick'
   const double macd = iMACD(MACDO_SYMBOL,MACDO_TF,MACDO_EMAFP,MACDO_EMASP,MACDO_SIGP,METHOD_PRICE,MODE_MAIN,backshift);
   const double osma = iOsMA(MACDO_SYMBOL,MACDO_TF,MACDO_EMAFP,MACDO_EMASP,MACDO_SIGP,METHOD_PRICE,backshift);
   return macd - osma;
}

void calcMACDOHistoric(const int backshift) {
   // iOsMA calculation is conducted witih greater shift -> older 'tick'
   
   const double prev = calcOsMA(backshift + 1);
   const double curr = calcOsMA(backshift);
   const double diff = curr - prev;
   MACDODiff[backshift]= diff;
   
}


void calcMACDOCurrent() {
   calcMACDOHistoric(0);
}

// void pushOsMAMACurent() { // UNUSED
//   newestTick = TimeCurrent();
// }

// int getNTOffset() { // UNUSED
//   const int tidx = iBarShift(MACDO_SYMBOL,MACDO_TF,newestTick,false);
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
         calcMACDOHistoric(n);
      }
   } else {
      // if(getNTOffset() != 0) {
      //   pushOsMAMACurrent(); // UNUSED
      //   // PrintFormat("OsMAMA: PUSH CURRENT"); // DEBUG
      // }
      calcMACDOCurrent();
   }
   // PrintFormat("OsMAMA::Current %f, %d ", sumCurrent, nterms ); // DEBUG
   return ntick;
 }
