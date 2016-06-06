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


#ifdef STACKBUFF
#ifndef HA_OPEN_DATUM
#define HA_OPEN_DATUM 0
#endif

#ifndef HA_HIGH_DATUM
#define HA_HIGH_DATUM 1
#endif

#ifndef HA_LOW_DATUM
#define HA_LOW_DATUM 2
#endif


#ifndef HA_CLOSE_DATUM
#define HA_CLOSE_DATUM 3
#endif
#endif


#include "libea.mqh"

// - Heikin Ashi chart records

// - Buffers - HA // FIXME: Not same in EA impl
// TO DO: Modular Components model for OTLIB MQL4 header-libs, Indicator Programs, and EA Programs
#ifndef STACKBUFF
double HAOpen[];  // Draw Buffer (Drawn Indicator Impl) - FIXME reimpl w/ a colors buffer
double HABearTrc[]; // Draw Buffer (Drawn Indicator Impl)- FIXME reimpl w/ a colors buffer
double HABullTrc[]; // Draw Buffer (Drawn Indicator Impl)- FIXME reimpl w/ a colors buffer
double HAClose[]; // Draw Buffer (Drawn Indicator Impl) - FIXME reimpl w/ a colors buffer
// Revised HA Indicator impl TO DO
// #ifndef BUFFLEN #define BUFFLEN=...? #endif // Maximum buffer length - see also: Memory Management (MQL Platforms)
// #ifndef NR_DATA_POINTS #define NR_DATA_POINTS=4 #endif
// #ifndef NR_TIMEFRAMES #define NR_TIMEFRAMES=1 #endif // X!
// double HAData[NR_TIMEFRAMES][NR_DATA_POINTS][BUFFLEN] // indexed in the time series mode, not the 0(newest)->N(oldest) reverse time series mode
// // NOTE: Same as impl for original HADataEA design, with NR_TIMEFRAMES=1 (!)
//
// Accompany with additional ENUM_HA_DATA_POINT type
/* enum HA_DATA_POINT { // when cast as int, provides an index onto {HAData dimension 1|HADataEA Dimension 2}, i.e "NR_DATA_POINTS" dim
   HA_DP_OPEN = 0,
   HA_DP_HIGH = 1,
   HA_DP_LOW = 2,
   HA_DP_CLOSE = 3
} */
// Also accompany with careful prototyping for the datapoint stack model cf. libeah.mqh 
// ...juxtaposed to MQL's strictly single-dimensional draw buffers
//
// Additional HA EA impl TO DO
// #ifndef BUFFLEN #define BUFFLEN=1024 #endif
// #ifndef NR_DATA_POINTS #define NR_DATA_POINTS=4 #endif
// #ifndef NR_TIMEFRAMES #define NR_TIMEFRAMES=3 #endif
// double HAData[NR_TIMEFRAMES][NR_DATA_POINTS][BUFFLEN]
int TickHA[];
double HAHigh[]; // Data Buffer - Storage for HA High rate data, independent of "drawn buffers" i.e visualized buffers HABearTrc, HABullTrc
double HALow[]; // Data Buffer - Storage for HA Low rate data, independent of "drawn buffers" HABearTrc, HABullTrc
int HACount = 0; // App Impl Convenience/Kludge
int HAStart = 0; // App Impl Convenience/Kludge
#endif

// FIXME documentation 
// 4 drawn buffers, 3 data buffers (not drawn)
//
// Two of the drawn bufers contain possible indicator data - HAOpen, HAClose
//
// The other two drawn buffers are applied for chart visuals,
// may be used for indicator data but see also: Data buffers HAHigh, HALow
//
// The third data buffer (TickHA) is avaiable for synch onto series-format chart buffers


// - memory management

// const int rsvbars = 8; // defined in libea.mqh
#ifndef STACKBUFF
int bufflen; // App Impl Convenience/Kludge - TO DO, REIMPL with #ifn... #define BUFFLEN=... #endif

int haInitBuffers(int start, const int len) {
   // return number (count) of buffers (one indexed)
   // PrintFormat("haInitBuffers (%d .. %d)", start, len); // DEBUG
   IndicatorBuffers(start + 7);
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
   IndicatorBuffers(start + 7);
   initDataBufferDbl(HABearTrc,start++,len,false);
   initDataBufferDbl(HABullTrc,start++,len,false);
   initDataBufferDbl(HAOpen,start++,len,false);
   initDataBufferDbl(HAClose,start++,len,false);
   initDataBufferInt(TickHA,len,true,-1);
   initDataBufferDbl(HAHigh,start++,len,false);
   initDataBufferDbl(HALow,start++,len,false);
   return start;
}


int haInitBuffersEA(/* &int start, */ const int len) {
   // Initialize all buffers as data buffers, without drawing configuration
   // return number (count) of buffers (one indexed)
   // PrintFormat("haInitBuffersUndrawn (%d .. %d)", start, len); // DEBUG
   
   // NB: SetIndexBuffer not avaialble in EA programs
   
   // IndicatorBuffers(start + 7); // N/A in EA programs
   initDataBufferDblEA(HABearTrc,len,false);
   initDataBufferDblEA(HABullTrc,len,false);
   initDataBufferDblEA(HAOpen,len,false);
   initDataBufferDblEA(HAClose,len,false);
   initDataBufferInt(TickHA,len,true,-1);
   initDataBufferDblEA(HAHigh,len,false);
   initDataBufferDblEA(HALow,len,false);
   return len;
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
#endif

// - accessors

#ifndef STACKBUFF
int getTickHA(const int idx) {
   // PrintFormat("getTickHA(%d)", idx); // DEBUG
   const int htk = TickHA[idx];
   return htk;
}
#endif
// TO DO
/* #ifdef STACKBUFF
int getTickHA(SimpleStackBuffer* &buffer,const int idx, const int tfidx) {
   // PrintFormat("getTickHA(%d)", idx); // DEBUG
   const int htk = TickHA[idx]; // not stored in an array, when STACKBUFF
   return htk;
}
#endif
*/

#ifndef STACKBUFF
double getTickHAOpen(const int idx) {
   const int htk = getTickHA(idx);
   return HAOpen[htk];
}
#endif
#ifdef STACKBUFF
double getTickHAOpen(SimpleStackBuffer* &buffer, const int idx, const int tfidx) {
   return buffer.getData(idx,HA_OPEN_DATUM,tfidx);
}
#endif

#ifndef STACKBUFF
double getTickHAHigh(const int idx) {
   const int htk = getTickHA(idx);
   return HAHigh[htk];
}
#endif
#ifdef STACKBUFF
double getTickHAHigh(SimpleStackBuffer* &buffer, const int idx, const int tfidx) {
   return buffer.getData(idx,HA_HIGH_DATUM,tfidx);
}
#endif

#ifndef STACKBUFF
double getTickHALow(const int idx) {
   const int htk = getTickHA(idx);
   return HALow[htk];
}
#endif
#ifdef STACKBUFF
double getTickHALow(SimpleStackBuffer* &buffer, const int idx, const int tfidx) {
   return buffer.getData(idx,HA_LOW_DATUM,tfidx);
}
#endif

#ifndef STACKBUFF
double getTickHAClose(const int idx) {
   const int htk = getTickHA(idx);
   return HAClose[htk];
}
#endif
#ifdef STACKBUFF
double getTickHAClose(SimpleStackBuffer* &buffer, const int idx, const int tfidx) {
   return buffer.getData(idx,HA_CLOSE_DATUM,tfidx);
}
#endif




// - calcuations

#ifdef STACKBUFF
int calcHA(SimpleStackBuffer* &buffer,
           const int tfidx, // FIXME: Awkwardly redundant onto 'timeframe'
           const int count, 
           const int start, 
           const string symbol=NULL,
           const int timeframe = PERIOD_CURRENT) {
           
           // FIXME: Generalize timeframe recording
           // - tfidx, timeframe -- redundant, with both as parameters to this function

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
         mopen = iOpen(symbol, timeframe,tickidx);   // market rate open
         mhigh = iHigh(symbol, timeframe,tickidx);   // market rate high
         mlow = iLow(symbol, timeframe,tickidx);     // market rate low
         mclose = iClose(symbol, timeframe,tickidx); // market rate close
         haoprev = mopen;
         
         buffer.pushData();
         buffer.setData(haoprev,start,HA_OPEN_DATUM,tfidx);
         hacprev = calcRateHAC(mopen, mhigh, mlow, mclose);
         buffer.setData(hacprev,start,HA_CLOSE_DATUM,tfidx);
         // TickHA[tickidx] = 0;
      } else {
        // assume previous HA Open, High, Low, Close records exist
        buffer.pushData();
        haoprev = buffer.getData(start,HA_OPEN_DATUM,tfidx);
        hacprev = buffer.getData(start,HA_CLOSE_DATUM,tfidx);
      }
      // calculate subsequent HA tick records
      for(hidx = start+1, tickidx = (count - start - 2); hidx < count; hidx++, tickidx--) {
         buffer.pushData();
         mopen = iOpen(symbol, timeframe,tickidx);
         mhigh = iHigh(symbol, timeframe,tickidx);
         mlow = iLow(symbol, timeframe,tickidx);
         mclose =  iClose(symbol, timeframe,tickidx);

         hopen = (haoprev + hacprev) / 2;
         buffer.setData(hopen,start,HA_OPEN_DATUM,tfidx); // HAOpen[hidx] = hopen;
         
         hclose = calcRateHAC(mopen, mhigh, mlow, mclose);
         buffer.setData(hclose,start,HA_CLOSE_DATUM,tfidx); // HAHClose[hidx]
         
         hhigh = MathMax(mhigh, MathMax(hopen, hclose));
         buffer.setData(hhigh,start,HA_HIGH_DATUM,tfidx); // HAHigh[hidx]
         
         hlow = MathMin(mlow, MathMin(hopen, hclose));
         buffer.setData(hlow,start,HA_LOW_DATUM,tfidx); // HALow[hidx]
         // Store data for visuals - HABearTrc, HABullTrc
         // Print(StringFormat("HA Calc (%d => %d) O %f H %f L %f C %f", hidx, tickidx, hopen, hhigh, hlow, hclose)); // DEBUG
         haoprev = hopen;
         hacprev = hclose;
         // TickHA[tickidx] = hidx;
      }
      return hidx - start;
   } else {
      // Print(StringFormat("HA INDICATOR ABORT %d %d", count, start)); // DEBUG
      return 0;
   }    
}
#endif

#ifndef STACKBUFF
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
#endif