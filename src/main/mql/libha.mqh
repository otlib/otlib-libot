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

// #property library
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property version   "1.00"
#property strict

#include "libea.mqh"

// - Heikin Ashi chart records

// - Buffers - HA
double HAOpen[];
double HABearTrc[];
double HABullTrc[];
double HAClose[];
double HATick[];
double HAHigh[];
double HALow[];
int HACount = 0;
int HAStart = 0;

// FIXME documentation 
// 4 drawn buffers, 3 data buffers (not drawn)
//
// Two of the drawn bufers contain possible indicator data - HAOpen, HAClose
//
// The other two drawn buffesr are applied for chart visuals,
// may be used for indicator data but see also: Data buffers HAHigh, HALow
//
// The third data buffer (HATick) is avaiable for synch onto series-format chart buffers


// memory management
// const int rsvbars = 8; // defined in libea.mqh
int bufflen;

void haInitBuffers(int start, int len) {
   initDrawBuffer(HABearTrc,0,len,"Bear Tick Trace",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HABullTrc,1,len,"Bull Tick Trace",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HAOpen,2,len,"Bear Tick Body",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HAClose,3,len,"Bull Tick Body",DRAW_HISTOGRAM,2,false);
   
   initDataBufferDbl(HATick,4,len,false);
   initDataBufferDbl(HAHigh,5,len,false);
   initDataBufferDbl(HALow,6,len,false);
}

void resizeBuffs(const int newsz) {
   ArrayResize(HAOpen, newsz, rsvbars);
   ArrayResize(HABearTrc, newsz, rsvbars);
   ArrayResize(HABullTrc, newsz, rsvbars);
   ArrayResize(HAClose, newsz, rsvbars);
   ArrayResize(HATick, newsz, rsvbars);
   ArrayResize(HAHigh, newsz, rsvbars);
   ArrayResize(HALow, newsz, rsvbars);
   bufflen = newsz;
}

int calcHA(const int count, 
           const int start, 
           const double &open[],
           const double &high[],
           const double &low[],
           const double &close[]) {
// Optimized Heikin Ashi calculator

// NB: this HA implementation will not invert the indexing of the open, high, low, close time buffers.
// Those buffers will use an inverse indexing sequence - similar to other indicators in this program
// contrasted to HAOpen, HABearTrc, HABullTrc, HAClose, which will use indexes approaching "0" at "oldest" tick.

   double mopen, mhigh, mlow, mclose, hopen, hhigh, hlow, hclose, haoprev, hacprev;
   int hidx, tickidx;
   
   // Print(StringFormat("HA Indicator %d, %d", count, start)); // DEBUG
   
   if(count > start+2) {
      if(start == 0) {
      // calculate initial HA tick from market rate data
         tickidx = count-1;
         mopen = open[tickidx];   // market rate open
         mhigh = high[tickidx];   // market rate high
         mlow = low[tickidx];     // market rate low
         mclose = close[tickidx]; // market rate close
         if(mopen < mclose) {
            HABearTrc[0] = mlow; 
            HABullTrc[0] = mhigh;
         } else {
            HABearTrc[0] = mhigh;
            HABullTrc[0] = mlow;
         }
         haoprev = mopen;
         HAOpen[0] = haoprev;
         hacprev = calcRateHAC(mopen, mhigh, mlow, mclose);
         HAClose[0] = hacprev;
         HATick[0] = tickidx;
      } else {
        // assume previous HA Open, High, Low, Close records exist
        haoprev = HAOpen[start];
        hacprev = HAClose[start];
      }
      // calculate subsequent HA tick records
      for(hidx = start+1, tickidx = (count - start - 2); hidx < count; hidx++, tickidx--) {
         mopen = open[tickidx];
         mhigh = high[tickidx];
         mlow = low[tickidx];
         mclose = close[tickidx];

         hopen = (haoprev + hacprev) / 2;
         hclose = calcRateHAC(mopen, mhigh, mlow, mclose);
         hhigh = MathMax(mhigh, MathMax(hopen, hclose));
         HAHigh[hidx] = hhigh;
         hlow = MathMin(mlow, MathMin(hopen, hclose));
         HALow[hidx] = hlow;
         // Store data for visuals - HABearTrc, HABullTrc
         if(hopen < hclose) {
            HABearTrc[hidx] = hlow;
            HABullTrc[hidx] = hhigh;
         } else {
            HABearTrc[hidx] = hhigh;
            HABullTrc[hidx] = hlow;
         }
         HAOpen[hidx] = hopen;
         haoprev = hopen;
         HAClose[hidx] = hclose;
         hacprev = hclose;
         HATick[hidx] = tickidx; // FIXME: Delete HATick
         // Print(StringFormat("HA Calc (%d => %d) O %f H %f L %f C %f", hidx, tickidx, hopen, hhigh, hlow, hclose)); // DEBUG
      }
      HAStart = start;
      HACount = hidx - start;
      return HACount;
   } else {
      // Print(StringFormat("HA INDICATOR ABORT %d %d", count, start)); // DEBUG
      return 0;
   }    
}
