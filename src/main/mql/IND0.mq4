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
#property description "Indicator IND0, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_chart_window
#property indicator_buffers 5 // number of drawn buffers (?)

// FIXME: message "libot is not loaded" ??
// #import "libot"
//   int dayStartOffL();
// #import


// EA0 indicator buffers
//
// EA0 buffer 0 (1) : market trends (drawn)
// EA0 buffer 1 (2) : HA low=>high   - bear tick trace - HABearTrc (drawn?) [REMOVE?]
// EA0 buffer 2 (3) : HA high=>low   - bull tick trace - HABullTrc (drawn?) [REMOVE?]
// EA0 buffer 3 (4) : HA ..open..    - bear tick body - HAOpen     (drawn?)
// EA0 buffer 4 (5) : HA ..close..   - bull tick body - HAClose    (drawn?)
// EA0 buffer 5 (6) : HATick
// EA0 buffer 6 (7) : HAHigh
// EA0 buffer 7 (8) : HALow
// ... 
// TrendDraw   : Drawn buffer - calcTrends(), updTrends()
// - NB: TrendDraw contents are synched to clock ticks 
// - NB: TrendDraw values: either 0.0 or Trend Start Rate at tick
// - NB: The following bufers are not synched to clock ticks
// TrendDrSTk  : Trend Start Clock Tick Synch for TrendDraw, ...
// TrendDrETk  : Trend End Clock Tick Synch for TrendDraw, ..
// TrendStrR   : Trend Start Rate - calcTrends(), updTrends()
// TrendStrT   : Trend Start Time - calcTrends(), updTrends()
// TrendEndR   : Trend End Rate   - calcTrends(), updTrends()
// TrendEndT   : Trend End Time   - calcTrends(), updTrends()
// 
// TBD
// dataStoK
// dataStoM
// diffSto (DRAW - histogram - develop w/ an independent indicator prototype)
//
// dataAD ?
// 
// dataCCI ?


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


// - Buffers - Trends
//
// NB: It appears that when a variable sized array buffer is registered 
// with the MetaTrader platform, as via SetIndexBuffer(), then it may
// be a function such that places the respective buffer under memory
// management in MetaTrader. Without registering the buffer via 
// SetIndexBuffer(), the buffer may not be resized appropriately across
// subsequent calls to OnCalculate and other MQL functions.
//
// FIXME: These buffers could be registered via SetIndexBuffer() ??
// even those that are not synchronized to individual chart ticks - but SetIndexBuffer()
// does not accept an array of dateime element type. So, manage these manually - resizeBuffs()
//
double TrendDraw[]; // Drawn buffer - calcTrends(), updTrends()
// NB: TrendDraw contents are synched to clock ticks 
// NB: TrendDraw values: either 0.0 or Trend Start Rate at tick
int TrendDrSTk[]; // Synch for Trend start=>TrendDraw (TBD)
int TrendDrETk[]; // Synch for Trend end=>TrendDraw (TBD)
double TrendStrR[]; // Trend Start Rate - calcTrends(), updTrends()
datetime TrendStrT[]; // Trend Start Time - calcTrends(), updTrends()
double TrendEndR[]; // Trend End Rate   - calcTrends(), updTrends()
datetime TrendEndT[]; // Trend End Time   - calcTrends(), updTrends()

// TO DO:
// SigStoK[]; // Calculation similar to Stochastic Oscillator K data. TBD
// SigStoM[]; // Calculation similar to Stochastic Oscillator Main data. TBD
// SigStoDiff[]; // Ratio of STO K and M across previous ticks
// SigAD[];   // Calculation similar to Accmulation/Ditribution Indicator data. TBD
// SigCCI[];  // Calculation similar to Commodity Channel Index Indicator data. TBD


//
// NB: MQL4 allows a maximum of eight drawn buffers (zero indexed)
//     so far as accessed via SetIndexStyle()

#property indicator_color1 clrLimeGreen
#property indicator_width1 3
#property indicator_style1 STYLE_SOLID

#property indicator_color2 clrTomato
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

#property indicator_color3 clrKhaki
#property indicator_width3 1
#property indicator_style3 STYLE_SOLID

#property indicator_color4 clrTomato
#property indicator_width4 3
#property indicator_style4 STYLE_SOLID

#property indicator_color5 clrKhaki
#property indicator_width5 3
#property indicator_style5 STYLE_SOLID

// - Input Parameters
input bool log_debug = false; // Log Runtime Information


// - Program Parameters
// convenience
const string label   = "IND0";
const double dblz   = 0.0; // use one 0.0 value for zero of type 'double'
// memory management
const int rsvbars = 8;
int bufflen;
// application logic
int nrTrends = 0;

// - Utility Functions

// - Utility Functions - Memory Management

void resizeBuffs(const int newsz) {
   // buffers applied for HA tick calculation
   ArrayResize(HAOpen, newsz, rsvbars);
   ArrayResize(HABearTrc, newsz, rsvbars);
   ArrayResize(HABullTrc, newsz, rsvbars);
   ArrayResize(HAClose, newsz, rsvbars);
   ArrayResize(HATick, newsz, rsvbars);
   ArrayResize(HAHigh, newsz, rsvbars);
   ArrayResize(HALow, newsz, rsvbars);

   // buffers applied for trend calculation
   ArrayResize(TrendDraw, newsz, rsvbars);
   ArrayResize(TrendDrSTk, newsz, rsvbars);
   ArrayResize(TrendDrETk, newsz, rsvbars);
   ArrayResize(TrendStrR, newsz, rsvbars);
   ArrayResize(TrendStrT, newsz, rsvbars);
   ArrayResize(TrendEndR, newsz, rsvbars);
   ArrayResize(TrendEndT , newsz, rsvbars);
   
   bufflen = newsz;
}

// - Utility Functions - Time

int dayStartOffT(const datetime dt) export {
// return iBarShift for datetime dt
// using current chart and curren timeframe
   return iBarShift(NULL, 0, dt, false);
}

int dayStartOffL() export {
// return iBarShift for datetime at start of day, local time
// using current chart and current timeframe
   MqlDateTime st;
   st.year = Year();
   st.mon = Month();
   st.day = Day();
   st.day_of_week = DayOfWeek();
   st.day_of_year = DayOfYear();
   st.hour = 0;
   st.min = 0;
   st.sec = 0;
   st.day_of_week = 1;
   datetime dt = StructToTime(st);
   // FIXME: Compute offset btw server local time and dt as provided here
   return dayStartOffT(dt);
}

// - Utility Functions - Rate Calculation

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) {
// calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
   return value;
}

// - Utility Functions - Program Utility

void logDebug(const string message) { 
   // FIXME: Reimplement w/ a reusable preprocessor macro, optimizing the call pattern for this fn
   if (log_debug) {
      Print(message);
   }
}


// - Code - OTLIB HA Indicator

// NB: See also ./HA.mq4 - ostensibly, keep it synchronized with this source file

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


// - Code - OTLIB Trend Calculation


// FIXME: Cannot define calcTrends in a library and import it?
// Compiler emits a message, "Constant variable cannot be passed 
// as reference" when function is defined in a library then 
// called as across an 'import' definition.

void setDrawZero(const int cidx) {
   TrendDraw[cidx] = dblz;
}

void setDrawRate(const int cidx, const double rate) {
   TrendDraw[cidx] = rate;
}

void setTrend(const int tidx, // trend number
              const int stridx, // chart tick index for trend start
              const int endidx, // chart tick index for trend en
              const double strR,   // trend start rate
              const double endR) {
   TrendDraw[stridx] = strR;
   TrendDrSTk[tidx] = stridx;
   TrendDraw[endidx] = endR;
   TrendDrETk[tidx] = endidx;
   
   TrendStrT[tidx] = Time[stridx];
   TrendStrR[tidx] = strR;
   TrendEndT[tidx] = Time[endidx];
   TrendEndR[tidx] = endR;
}

void setTrendStart(const int tidx, // trend number
                   const int cidx, // new chart tick for trend start
                   const datetime time,
                   const double rate) {
// NB: This function is applied in historic data analysis
// NB: This function does not update TrendDraw for any previously specified cidx
   setDrawRate(cidx, rate);
   TrendDrSTk[tidx] = cidx;
   TrendStrT[tidx] = time;
   TrendStrR[tidx] = rate;
}

void moveTrendStart(const int tidx, // trend number
                    const int cidx, // new chart tick for trend start
                    const datetime time,
                    const double rate,
                    const bool movePrev=true) {
   const int obsTick = TrendDrSTk[tidx]; // ensure previous slot zeroed
   if(obsTick != cidx) { setDrawZero(obsTick); } // ?
   setTrendStart(tidx, cidx, time, rate);
   if (movePrev && (tidx > 0)) {
   //  Also adjust end rate, time of previous trend when tidx > 0 ?
      moveTrendEnd(tidx-1, cidx, time, rate, false);
   }
}

void setTrendEnd(const int tidx, // trend number
                 const int cidx,
                 const datetime time,
                 const double rate) {
// NB: This function may be applied in calculation and update of realtime indicators

// NB: TrendDraw is not modified here, as TrendDraw is being applied such as to record 
// trend start rates at individual chart ticks coinciding with a trend start

   setDrawRate(cidx,rate);
   TrendEndT[tidx] = time;
   TrendEndR[tidx] = rate;
   TrendDrETk[tidx] = cidx;
   // NB: this function does not update for tidx+1
   // see also: moveTrendENd
}

void moveTrendEnd(const int tidx, // trend number
                  const int cidx, // chart bar index of end 'time'
                  const datetime time,
                  const double rate,
                  const bool moveNext=true) {
   const int obsTick = TrendDrETk[tidx];
   if(obsTick != cidx) { setDrawZero(obsTick); } // ?
   setTrendEnd(tidx, cidx, time, rate);
   if(moveNext && (tidx+1 < nrTrends)) {
      moveTrendStart(tidx+1, cidx, time, rate, false);
   }

}

double trendStartRate(const int tidx) {
   // Print(StringFormat("trendStartRate(%d) @ %d, %d", tidx, nrTrends, iBars(NULL, 0))); // DEBUG
   return TrendStrR[tidx];
}

datetime trendStartTime(const int tidx) {
   return TrendStrT[tidx];
}

int trendStartIndex(const int tidx) {
   return TrendDrSTk[tidx];
}

double trendEndRate(const int tidx) {
   return TrendEndR[tidx];
}

datetime trendEndTime(const int tidx) {
   return TrendEndT[tidx];
}

int trendEndIndex(const int tidx) {
   return TrendDrETk[tidx];
}


int calcTrends(const int count, 
               const int start, 
               const double &open[],
               const double &high[],
               const double &low[],
               const double &close[],
               const datetime &time[]) {
   // traverse {open, high, low, close, time} arrays for a duration 
   // of `count` beginning at `start`. Calculate time and rate of 
   // beginnings of market trend reversals, storing that data in 
   // the `trends` arrays and returning the number of trends calculated.

   if((count < 1)) {
      return 0;
   }
   
   nrTrends = start; // ...
   
   int sTick, pTick;
   double rate, sRate, pRate, curLow, curHigh;
   bool updsTrend = false;

   sRate = calcRateHAC(open[start], high[start], low[start], close[start]);
   sTick = start;
   pTick = start+1;
   pRate = calcRateHAC(open[pTick], high[pTick], low[pTick], close[pTick]);

   bool calcMax = (pRate > sRate);  

   int n;
   
   // NB: In application for Indicator calculation, the 'start' parameter may 
   // be considered as a pointer to the last calculated element of the trend 
   // data buffers {TrendStrT, TrendStrR, TrendEndT, TrendEndR}
   
   for(n=start+1; n < count; n++) {
      // apply a simple high/low calculation for logical dispatch to trend filtering
      curLow = low[n];
      // curLow = calcRateHLL(high[n], low[n]);
      curHigh = high[n];
      // curHigh = calcRateHHL(high[n], low[n]);
      //  rate = calcMax ? calcRateHHL(curHigh, curLow) : calcRateHLL(curHigh, curLow);
      rate = calcMax ? curHigh : curLow;

      if (calcMax && (rate >= pRate)) {
      // continuing trend rate > pRate - simple calc
         logDebug(StringFormat("Simple calcMax %f [%d]", rate, n));
         if(updsTrend) {
            moveTrendStart(nrTrends, n, time[n], rate);
         } else {
            pRate = rate;
            pTick = n;
         }
      } else if (!calcMax && (rate <= pRate)) {
      // continuing trend rate <= pRate - simple calc
         logDebug(StringFormat("Simple !calcMax %f [%d]", rate, n));
         if(updsTrend) {
            moveTrendStart(nrTrends, n, time[n], rate);
         } else {
            pRate = rate;
            pTick = n;
         }
      } else if (!calcMax && !updsTrend &&
                  (nrTrends > 0) && 
                  (trendStartRate(nrTrends) < trendEndRate(nrTrends)) &&
                  ((curHigh > trendEndRate(nrTrends)) || (curLow > trendEndRate(nrTrends))) &&
                  (trendStartRate(nrTrends-1) > trendEndRate(nrTrends-1))) {
      // [high|low].n >= sTrend.startRate > sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = (curHigh > trendEndRate(nrTrends)) ? curHigh : curLow;
         calcMax = true;
         // sRate = pRate;
         
         moveTrendStart(nrTrends, n, time[n], pRate); // NB: Updates TrendDraw[n], TrendDrSTk[nrTrends]
         // sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert !calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         updsTrend = true;
      } else if (calcMax && !updsTrend &&
                  (nrTrends > 0) && 
                  (trendStartRate(nrTrends) > trendEndRate(nrTrends)) &&
                  ((curLow < trendEndRate(nrTrends)) || (curHigh < trendEndRate(nrTrends))) &&
                  (trendStartRate(nrTrends-1) < trendEndRate(nrTrends-1))) {
      // [low|high].n <= sTrend.startRate <= sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = (curLow < trendEndRate(nrTrends)) ? curLow : curHigh;
         calcMax = false;
         // sRate = pRate;
         
         moveTrendStart(nrTrends, n, time[n], pRate); // NB: Updates TrendDraw[n], TrendDrSTk[nrTrends]
         // sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         updsTrend = true;
      } else { 
      // trend interrupted
         if(!updsTrend) {
            logDebug(StringFormat("Record Trend (%f @ %s) => (%f @ %s) [%d]", pRate, TimeToString(time[pTick]), sRate, TimeToString(time[sTick]), n));
            setTrend(nrTrends, pTick, sTick, pRate, sRate); // NB: Updates TrendDraw[pTick], TrendDrSTk[nrTrends]
            // sTrend = new Trend(time[pTick], pRate, time[sTick], sRate);
            // trends[nrTrends++] = sTrend;
            logDebug(StringFormat("New number of trends: %d", nrTrends));
            // TrendDraw[pTick] = pRate; // explicit TrendDraw data spec
            // TrendDraw[sTick] = sRate; // explicit TrendDraw data spec
         }  else {
          // defer trend initializtion, previous sTrend updated
            logDebug(StringFormat("End sTrend %d update (%f @ %s)[%d]", nrTrends, TrendStrR[nrTrends], TimeToString(TrendStrT[nrTrends]), n));
            updsTrend = false;
            setDrawZero(n);
         }
   
         calcMax = (trendStartRate(nrTrends) <= trendEndRate(nrTrends)); // set for traversing reversal of previous trend
         nrTrends++;
         sRate = calcMax ? low[pTick] : high[pTick];
         pRate = calcMax ? curHigh : curLow;
         sTick = pTick;
         pTick = n;
         logDebug(StringFormat("New calcMax %s, pRate %f, sRate %f [%d:%d]", (calcMax? "true" : "false"), pRate, sRate, sTick, pTick));
      } 
   }  
   
   if (nrTrends > 0) {
      n--;
      // update last (chronologically first) trend record
      logDebug(StringFormat("Last Trend (%f @ %s) => (%f @ %s)", sRate, TimeToString(time[sTick]), pRate, TimeToString(time[n])));
      pRate = calcMax ? high[n]: low[n];
      // sTrend = new Trend(time[n], pRate, time[sTick], sRate);
      // trends[nrTrends++] = sTrend;
      setTrend(nrTrends++, n, sTick, pRate, sRate); // NB: Updates TrendDraw[n]
   }

   // set draw rate for end rate of zeroth trend 
   setDrawRate(start, trendEndRate(0));

   return nrTrends; // NB: Not same as number of ticks
}

// - Code - Event Handling

void OnInit() {
   IndicatorShortName(label);
   IndicatorDigits(Digits);
   IndicatorBuffers(8);

   // FIXME: "Weirdness" in integrated HA draw - so, do not draw the HA in IND0

   // Trend Data Buffers - Drawn Bufer Init

   SetIndexBuffer(0, TrendDraw);
   SetIndexEmptyValue(0, dblz); // ?!...
   SetIndexStyle(0, DRAW_SECTION);
   SetIndexLabel(0, "Reversals");
   SetIndexDrawBegin(0, 0);

   // HA Data Buffers - Drawn, Undrawn Buffer Init
   
   SetIndexBuffer(1, HABearTrc); // not needed outside of visuals
   SetIndexEmptyValue(1, EMPTY_VALUE); // ?!...
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexLabel(1,"Bear Tick Trace"); 
   SetIndexDrawBegin(1,2);
   
   SetIndexBuffer(2, HABullTrc); // not needed outside of visuals
   SetIndexEmptyValue(2, EMPTY_VALUE); // ?!...
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexLabel(2,"Bull Tick Trace");
   SetIndexDrawBegin(2,2);

   SetIndexBuffer(3, HAOpen);
   SetIndexEmptyValue(3, EMPTY_VALUE); // ?!...
   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexLabel(3,"Bear Tick Body"); 
   SetIndexDrawBegin(3,2);
   
   SetIndexBuffer(4, HAClose);
   SetIndexEmptyValue(4, EMPTY_VALUE); // ?!...
   SetIndexStyle(4,DRAW_HISTOGRAM);
   SetIndexLabel(4,"Bull Tick Body");
   SetIndexDrawBegin(4,2);
   
   // Undrawn HA bufers
   SetIndexBuffer(5,HATick); // puts it under platform memory management ?
   SetIndexBuffer(6,HAHigh); // puts it under platform memory management ?
   SetIndexBuffer(7,HALow); // puts it under platform memory management ?

   // Memory Management
   bufflen = iBars(NULL, 0);
   int maxTrends = bufflen; // FIXME : REMOVE ?
   resizeBuffs(bufflen);
   // ^ DO BEFORE ArrayInitialize(), ArraySetAsSeries()

   // Array Initialization
   
   ArrayInitialize(TrendDraw, dblz);
   ArrayInitialize(HABearTrc, dblz);
   ArrayInitialize(HABullTrc, dblz);
   ArrayInitialize(HAOpen, dblz);
   ArrayInitialize(HAHigh, dblz);
   ArrayInitialize(HALow, dblz);
   ArrayInitialize(HAClose, dblz);
   ArrayInitialize(HATick, 0);
   ArrayInitialize(TrendStrR, dblz);
   ArrayInitialize(TrendEndR, dblz);
   ArrayInitialize(TrendDrSTk, 0);
   ArrayInitialize(TrendDrETk, 0);
   ArrayInitialize(TrendStrT, 0);
   ArrayInitialize(TrendEndT, 0);

   // NB: Call ArraySetAsSeries after previous
   ArraySetAsSeries(TrendDraw, true);
   ArraySetAsSeries(HABearTrc, false);
   ArraySetAsSeries(HABullTrc, false);
   ArraySetAsSeries(HAOpen, false);
   ArraySetAsSeries(HAHigh, false);
   ArraySetAsSeries(HALow, false);
   ArraySetAsSeries(HAClose, false);
   ArraySetAsSeries(HATick, false);
   ArraySetAsSeries(TrendDrSTk, true);
   ArraySetAsSeries(TrendDrETk, true);
   ArraySetAsSeries(TrendStrR, true);
   ArraySetAsSeries(TrendStrT, true);
   ArraySetAsSeries(TrendEndR, true);
   ArraySetAsSeries(TrendEndT, true);
 
   logDebug("OnInit complete");
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
   logDebug("OnCalculate called");
   if (nticks >= (bufflen + rsvbars)) {
      // PrintFormat("Resize Buffs: ~D", nticks + rsvbars); // DEBUG
      resizeBuffs(nticks + rsvbars);
   }
   
   // FIRST, call calcHA() to populate the HA data buffers
   int haCount;
   haCount = calcHA(nticks,counted,open,high,low,close);

   return haCount;
   // FIXME: HA integration not "Working Out" !
   
   // NEXT, call calcTrends() for ...
   int toCount;
   if(counted == 0) {
      toCount = nticks;
      nrTrends = calcTrends(nticks, counted, open, high, low, close, time);
      // Print(StringFormat("calcTrends nrTrends %d (count, toCount %d counted %d)", nrTrends, nticks, counted)); // DEBUG
      return toCount;
   } else {
     // note that this branch of program exec may be arrived at repeatedly,
     // at a duration less than the minimum possible chart resolution
     toCount = nticks - counted; // FIXME: Parametrs named like a minomer
     // Print(StringFormat("calcTrends for count %d ticks != 0 (to count %d) (counted %d trends)", nticks, toCount, counted)); // DEBUG
     
     // TO DO : Define a forwardBuff not assigned to tick rates,
     // as for purpose of recording rate changes at durations 
     // less than minimum chart period.
     
     if((toCount > 0) && (nrTrends > 0)) {
        // const double pstart = trendStartRate(nrTrends-1);
        // const double pend = trendEndRate(nrTrends-1);
        const double cstart = trendStartRate(nrTrends);
        const double cend = trendEndRate(nrTrends);
        double curHigh, curLow, rate;
        
        for(int n=toCount; n >= 0; n--) {
         curHigh = high[n];
         curLow = low[n];
         if((cstart > cend) && ((cstart > curLow) || (cstart > curHigh))) {
         // simple continuing trend, market rate numerically decreasing
         
            // rate = (start > curLow) ? curLow : curHigh;
            // dispatch on low, record high (?) FIXME: use HA high/low values
            rate = curHigh;
            // NB: current trend may evolve as to parallel previous trend.
            // FIXME: on parallel trend, fold current trend into previous trend
            moveTrendEnd(nrTrends,n,time[n],rate, false);            
         } else if ((cstart < cend) && ((cstart < curHigh) || (cstart < curLow))) {
         // simple continuing trend, market rate numerically increasing
            // rate = (start < curHigh) ? curHigh : curLow;
            // dispatch on high, record low (?) FIXME: use HA high/low values
            rate = curLow;
            // NB: current trend may evolve as to parallel previous trend.
            // FIXME: on parallel trend, fold current trend into previous trend
            moveTrendEnd(nrTrends,n,time[n],rate, false);            
         } else {
         // immediate reversal on Trend[nrTrends]
         // new trend start is determinable at index of previous trend end.
         // new trend end is the immediate n
         
            const int cendx = trendEndIndex(nrTrends);
            // const double rate = (start > low[n]) ? low[n] : high[n];
            // similar dispatch/record semantics as in previous branches (?)
            // FIXME: use HA high/low values
            rate = (cstart > low[n]) ? high[n] : low[n];
            setTrend(nrTrends++,cendx,n,cend,rate);
   
         }
       }
       return counted + toCount;
     } else {
      // FIMXME
      return counted;
     }
   }
   // logDebug(StringFormat("Count %d, Counted %d", nticks, counted));

   
   // FIXME: calcTrends is applied only for historic analysis. 
   //
   // The first trend calculated by calcTernds - i.e. trends[0] - should be updated
   // subsequent to incoming market data, when the function is applied in a realtime
   // indicator.
   // TO DO: define updTrends(const int countDif, const int counted, ...)
   
   // return counted;
}
