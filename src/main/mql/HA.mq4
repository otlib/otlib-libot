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
#property description "Heikin Ashi Indicator, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_chart_window
#property indicator_buffers 4 // number of drawn buffers

// HA0 indicator buffers (drawn)
//
// EA0 buffer 0 (1) : HA low=>high   - bear tick trace - HABearTrc
// EA0 buffer 1 (2) : HA high=>low   - bull tick trace - HABullTrc
// EA0 buffer 2 (3) : HA ..open..    - bear tick body - HAOpen 
// EA0 buffer 3 (4) : HA ..close..   - bull tick body - HAClose

#property indicator_color1 clrTomato
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID

#property indicator_color2 clrKhaki
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

#property indicator_color3 clrTomato
#property indicator_width3 3
#property indicator_style3 STYLE_SOLID

#property indicator_color4 clrKhaki
#property indicator_width4 3
#property indicator_style4 STYLE_SOLID


// - Line Properties as Input Parameters
// input color haBearTraceColor = clrTomato;    // bare tick trace
// input color haBullTraceColor = clrKhaki; // bull tick trace
// input color haBearBodyColor = clrTomato;     // bear tick body
// input color haBullBodyColor = clrKhaki;  // bull tick body

// - Program Parameters
const string label   = "HA";

const double dblz   = 0.0; // use one 0.0 value for zero of type 'double'

// - Code

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) {
   // calculate rate in a manner of Heikin Ashi Close
   const double value = ( open + high + low + close ) / 4;
   return value;
}

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

// memory management
const int rsvbars = 8;
int bufflen;

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

void OnInit() {
   IndicatorShortName(label);
   IndicatorDigits(Digits);
   IndicatorBuffers(7); 
   // 4 drawn buffers, 3 undrawn
   // 2 of the drawn bufers contain possible indicator data
   // 1 of the undrawn buffers is not fundamentally needed
   
   bufflen = iBars(NULL, 0);

   // NB: SetIndexBuffer may <not> accept a buffer of class type elements

   SetIndexBuffer(0, HABearTrc); // not needed outside of visuals
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexLabel(0,"Bear Tick Trace"); 
   SetIndexDrawBegin(0,2);
   
   SetIndexBuffer(1, HABullTrc); // not needed outside of visuals
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexLabel(1,"Bull Tick Trace");
   SetIndexDrawBegin(1,2);

   SetIndexBuffer(2, HAOpen);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexLabel(2,"Bear Tick Body"); 
   SetIndexDrawBegin(2,2);
   
   SetIndexBuffer(3, HAClose);
   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexLabel(3,"Bull Tick Body");
   SetIndexDrawBegin(3,2);
   
   // FIXME: Delete HATick
   SetIndexBuffer(4,HATick); // puts it under platform memory management ?
   SetIndexBuffer(5,HAHigh); // puts it under platform memory management ?
   SetIndexBuffer(6,HALow); // puts it under platform memory management ?
   
   resizeBuffs(bufflen);
 
   ArrayInitialize(HAOpen, dblz);
   ArrayInitialize(HABearTrc, dblz);
   ArrayInitialize(HABullTrc, dblz);
   ArrayInitialize(HAClose, dblz);
   ArrayInitialize(HAHigh, dblz);
   ArrayInitialize(HALow, dblz);
   ArrayInitialize(HATick, 0);
   
   // DO THIS AFTER OTHER CALLS ... (FIXME: DOCUMENTATION)
   ArraySetAsSeries(HAOpen, false);
   ArraySetAsSeries(HABearTrc, false);
   ArraySetAsSeries(HABullTrc, false);
   ArraySetAsSeries(HAClose, false);
   ArraySetAsSeries(HATick, false);
   ArraySetAsSeries(HAHigh, false);
   ArraySetAsSeries(HALow, false);

}


int OnCalculate(const int nticks,
                const int counted,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   int haCount;

   if (nticks >= (bufflen + rsvbars)) {
      resizeBuffs(nticks + rsvbars);
   }

   haCount = calcHA(nticks,0,open,high,low,close);
   return haCount;
}
