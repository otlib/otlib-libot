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
int TickHA[];
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
// The third data buffer (TickHA) is avaiable for synch onto series-format chart buffers


// - memory management

// const int rsvbars = 8; // defined in libea.mqh
int bufflen;

int haInitBuffers(int start, const int len) {
   // return number (count) of buffers (one indexed)
   // PrintFormat("haInitBuffers (%d .. %d)", start, len); // DEBUG
   initDrawBuffer(HABearTrc,start++,len,"Bear Tick Trace",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HABullTrc,start++,len,"Bull Tick Trace",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HAOpen,start++,len,"Bear Tick Body",DRAW_HISTOGRAM,2,false);
   initDrawBuffer(HAClose,start++,len,"Bull Tick Body",DRAW_HISTOGRAM,2,false);
   initDataBufferInt(TickHA,len,true,-1);
   initDataBufferDbl(HAHigh,start++,len,false);
   initDataBufferDbl(HALow,start++,len,false);
   return start;
}


int haInitBuffersUndrawn(int start, const int len) {
   // Initialize all buffers as data buffers, without drawing configuration
   // return number (count) of buffers (one indexed)
   // PrintFormat("haInitBuffersUndrawn (%d .. %d)", start, len); // DEBUG
   initDataBufferDbl(HABearTrc,start++,len,false);
   initDataBufferDbl(HABullTrc,start++,len,false);
   initDataBufferDbl(HAOpen,start++,len,false);
   initDataBufferDbl(HAClose,start++,len,false);
   initDataBufferInt(TickHA,len,true,-1);
   initDataBufferDbl(HAHigh,start++,len,false);
   initDataBufferDbl(HALow,start++,len,false);
   return start;
}


void haResizeBuffers(const int newsz) {
   ArrayResize(TickHA, newsz, rsvbars); // not platform managed
}

int haPadBuffers(const int count) {
  if (count > bufflen) {
      const int newct = count + rsvbars; // X
      // PrintFormat("Resize Buffers [HA] %d => %d", bufflen, newct); // DEBUG
      haResizeBuffers(newct);
      bufflen = newct;
      return newct;
   } else {
      return bufflen;
   }
}

// - accessors

int getTickHA(const int idx) {
   // PrintFormat("getTickHA(%d)", idx); // DEBUG
   const int htk = TickHA[idx];
   return htk;
}

double getTickHAOpen(const int idx) {
   const int htk = getTickHA(idx);
   return HAOpen[htk];
}

double getTickHAHigh(const int idx) {
   const int htk = getTickHA(idx);
   return HAHigh[htk];
}


double getTickHALow(const int idx) {
   const int htk = getTickHA(idx);
   return HALow[htk];
}

double getTickHAClose(const int idx) {
   const int htk = getTickHA(idx);
   return HAClose[htk];
}



// - calcuations

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
         TickHA[tickidx] = 0;
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
         // Print(StringFormat("HA Calc (%d => %d) O %f H %f L %f C %f", hidx, tickidx, hopen, hhigh, hlow, hclose)); // DEBUG
         HAOpen[hidx] = hopen;
         haoprev = hopen;
         HAClose[hidx] = hclose;
         hacprev = hclose;
         TickHA[tickidx] = hidx;
      }
      HAStart = start;
      HACount = hidx - start;
      return HACount;
   } else {
      // Print(StringFormat("HA INDICATOR ABORT %d %d", count, start)); // DEBUG
      return 0;
   }    
}
