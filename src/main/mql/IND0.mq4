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
#property indicator_buffers 1 // number of drawn buffers
#property indicator_color1 clrLimeGreen  // EA0 buffer 0 (1)
#property indicator_width1 3;
#property indicator_style1 STYLE_SOLID;

// FIXME: message "libot is not loaded" ??
// #import "libot"
//   int dayStartOffL();
// #import

int dayStartOffT(const datetime dt) export {
// return iBarShift for datetime dt
// using current chart and curren timeframe
   return iBarShift(NULL, 0, dt, false);
}

int dayStartOffL() export {
// return iBarShift for datetime at start of day, local time
// using current chart and curren timeframe
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



// NB: On estimation, the EA configuration wizard may 
// automaticallly present line width and line style options 
// for each drawn buffer (??)

// - Input Parameters
input bool log_debug = false; // print initial runtime information to Experts log

// - Program Parameters
const string label   = "IND0";

const double dblz   = 0.0; // use one 0.0 value for zero of type 'double'

int nrTrends = 0;


// - Buffers
double TrendDraw[]; // Drawn buffer - calcTrends(), updTrends()
// NB: TrendDraw contents are synched to clock ticks 
// NB: TrendDraw values: either 0.0 or Trend Start Rate at tick
int TrendDrSTk[]; // Synch for Trend start=>TrendDraw (TBD)
int TrendDrETk[]; // Synch for Trend end=>TrendDraw (TBD)
double TrendStrR[]; // Trend Start Rate - calcTrends(), updTrends()
datetime TrendStrT[]; // Trend Start Time - calcTrends(), updTrends()
double TrendEndR[]; // Trend End Rate   - calcTrends(), updTrends()
datetime TrendEndT[]; // Trend End Time   - calcTrends(), updTrends()

// NOTE: SetIndexBufer() not applicable for datetime[]

// TO DO:
// SigStoK[]; // Calculation similar to Stochastic Oscillator K data. TBD
// SigStoM[]; // Calculation similar to Stochastic Oscillator Main data. TBD
// SigAD[];   // Calculation similar to Accmulation/Ditribution Indicator data. TBD
// SigCCI[];  // Calculation similar to Commodity Channel Index Indicator data. TBD

// - Code

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) {
   // calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
   return value;
}

/* // unused
double calcRateHHL(const double high, 
                   const double low) {
   // calculate rate in a manner of Heikin Ashi Close
   double value = ((high * 2) + low) / 3;
   return value;
}


double calcRateHLL(const double high, 
                   const double low) {
   // calculate rate in a manner of Heikin Ashi Close
   double value = (high + (low * 2)) / 3;
   return value;
}
*/



void logDebug(const string message) { 
   // FIXME: Reimplement w/ a reusable preprocessor macro, optimizing the call pattern for this fn
   if (log_debug) {
      Print(message);
   }
}

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
      // rate = calcMax ? calcRateHHL(curHigh, curLow) : calcRateHLL(curHigh, curLow);
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

// see also: Heikin Ashi.mq4 src - "Existing work" in MQL4 indicator development

void OnInit() {
   IndicatorShortName(label);
   
   ArraySetAsSeries(TrendDraw, true);
   ArraySetAsSeries(TrendDrSTk, true);
   ArraySetAsSeries(TrendDrETk, true);
   ArraySetAsSeries(TrendStrR, true);
   ArraySetAsSeries(TrendStrT, true);
   ArraySetAsSeries(TrendEndR, true);
   ArraySetAsSeries(TrendEndT, true);
   
   IndicatorBuffers(4); // Prototype 1: No separate buffer for indicator lines
   // NB: SetIndexBuffer may <not> accept a buffer of class type elements
   SetIndexBuffer(0, TrendDraw); // NB: Stored for every chart tick
   SetIndexEmptyValue(0, dblz);

   // NB: This indicator also uses TrendDrSTk, TrendStrT, TrendEndT.
   // However, SetIndexBuffer is not applicable for
   // arrays of datetime[] or int[] type
   SetIndexBuffer(1, TrendStrR); // NB: Not stored for every chart tick
   SetIndexBuffer(2, TrendEndR); // NB: Not stored for every chart tick
   // SetIndexBuffer(4, SigStoK[]); // TBD - calcSto
   // SetIndexBuffer(5, SigStoM[]); // TBD - calcSto
   // SetIndexBuffer(6, SigAD[]);   // TBD - calcAD
   // SetIndexBuffer(7, SigCCI[]);  // TBD - calcCCI

   SetIndexStyle(0, DRAW_SECTION); // FIXME: How are the line's style and width made avaialble for configuration?
   // FIXME: How are DRAW_SECTION indicator lines matched to chart tick indexes?
   SetIndexDrawBegin(0, 0); // Indicator line drawn for TrendStrR, starting at index 0 (?)
   
   const int nbars = iBars(NULL, 0);
   const int maxTrends = nbars;
   
   ArrayResize(TrendDraw, nbars, 0);
   ArrayResize(TrendDrSTk, maxTrends, 0);
   ArrayResize(TrendDrETk, maxTrends, 0);
   ArrayResize(TrendStrR, maxTrends, 0);
   ArrayResize(TrendStrT, maxTrends, 0);
   ArrayResize(TrendEndR, maxTrends, 0);
   ArrayResize(TrendEndT, maxTrends, 0);
   
   ArrayInitialize(TrendDraw, dblz);
   ArrayInitialize(TrendStrR, dblz);
   ArrayInitialize(TrendEndR, dblz);
   ArrayInitialize(TrendDrSTk, 0);
   ArrayInitialize(TrendDrETk, 0);
   ArrayInitialize(TrendStrT, 0);
   ArrayInitialize(TrendEndT, 0);

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
   int toCount;
   
   logDebug("OnCalculate called");

   if(counted == 0) {
      toCount = nticks;
      nrTrends = calcTrends(nticks, counted, open, high, low, close, time);
      Print(StringFormat("calcTrends nrTrends %d (count, toCount %d counted %d)", nrTrends, nticks, counted)); // DEBUG
      return toCount;
   } else {
      // note that this branch of program exec may be arrived at repeatedly,
      // at a duration less than the minimum possible chart resolution
     toCount = nticks - counted; // FIXME: Parametrs named like a minomer
     Print(StringFormat("calcTrends for count %d ticks != 0 (to count %d) (counted %d trends)", nticks, toCount, counted)); // DEBUG
     
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
            const double rate = (cstart > low[n]) ? high[n] : low[n];
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
