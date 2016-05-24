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

// - Input Parameters
input bool  log_debug = true; // print initial runtime information to Experts log

// - Buffers
double TrendStrR[]; // Trend Start Rate - calcTrends()
double TrendStrT[]; // Trend Start Time - calcTrends()
double TrendEndR[]; // Trend End Rate   - calcTrends()
double TrendEndT[]; // Trend End Time   - calcTrends()
// SigStoK[]; // Calculation similar to Stochastic Oscillator K data. TBD
// SigStoM[]; // Calculation similar to Stochastic Oscillator Main data. TBD
// SigAD[];   // Calculation similar to Accmulation/Ditribution Indicator data. TBD
// SigCCI[];  // Calculation similar to Commodity Channel Index Indicator data. TBD

// - Code

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) export {
   // calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
   return value;
}


void logDebug(const string message) export { 
   // FIXME: Reimplement w/ a reusable preprocessor macro, optimizing the call pattern for this fn
   if (log_debug) {
      Print(message);
   }
}

// NB: see also SymbolInfoTick()

// FIXME: Cannot define calcTrends in a library and import it?
// Compiler emits a message, "Constant variable cannot be passed 
// as reference" when function is defined in a library then 
// called as across an 'import' definition.


void setTrend(const int idx, 
              const datetime strT, // trend start time
              const double strR,   // trend start rate
              const datetime endT, 
              const double endR) {
   TrendStrT[idx] = strT;
   TrendStrR[idx] = strR;
   TrendEndT[idx] = endT;
   TrendEndR[idx] = endR;
}

void setTrendStart(const int idx,
                   const datetime time,
                   const double rate) {
// NB: This function is applied in historic data analysis
   TrendStrT[idx] = time;
   TrendStrR[idx] = rate;
}


void setTrendEnd(const int idx,
                 const datetime time,
                 const double rate) {
// NB: This function may be applied in calculation and update of realtime indicators
   TrendEndT[idx] = time;
   TrendEndR[idx] = rate;
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

   int sTick, pTick, nrTrends;
   double rate, sRate, pRate;
   bool updsTrend = false;

   nrTrends = 0;

   sRate = calcRateHAC(open[start], high[start], low[start], close[start]);
   pRate = sRate;
   sTick = start;
   pTick = start+1;

   bool calcMax = (sRate < calcRateHAC(open[pTick], high[pTick], low[pTick], close[pTick]));  

   int n;
   
   // NB: In application for Indicator calculation, the 'start' parameter may 
   // be considered as a pointer to the last calculated element of the trend 
   // data buffers {TrendStrT, TrendStrR, TrendEndT, TrendEndR}
   
   for(n=start+1; n < count; n++) {
      // apply a simple high/low calculation for logical dispatch to trend filtering
      rate = calcMax ? high[n] : low[n];
      if (calcMax && (rate >= pRate)) {
      // continuing trend rate > pRate - simple calc
         logDebug(StringFormat("Simple calcMax %f [%d]", rate, n));
         if(updsTrend) {
            sRate = rate;
            sTick = n;
            setTrendStart(nrTrends, time[n], rate);
         }
         pRate = rate;
         pTick = n;
      } else if (!calcMax && (rate <= pRate)) {
      // continuing trend rate <= pRate - simple calc
         logDebug(StringFormat("Simple !calcMax %f [%d]", rate, n));
         if(updsTrend) {
            sRate = rate;
            sTick = n;
            setTrendStart(nrTrends, time[n], rate);
         }
         pRate = rate;
         pTick = n;
      } else if (!calcMax && !updsTrend &&
                  (nrTrends > 0) && 
                  (high[n] >= TrendStrR[nrTrends]) &&
                  (TrendStrR[nrTrends] > TrendEndR[nrTrends])) {
      // high.n >= sTrend.startRate > sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = high[n];
         calcMax = true;
         sRate = pRate;
         setTrendStart(nrTrends, time[n], sRate);
         sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert !calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         updsTrend = true;
      } else if (calcMax && !updsTrend &&
                  (nrTrends > 0) && 
                  (low[n] <= TrendStrR[nrTrends]) &&
                  (TrendStrR[nrTrends] <= TrendEndR[nrTrends])) {
      // low.n <= sTrend.startRate <= sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = low[n];
         calcMax = false;
         sRate = pRate;
         setTrendStart(nrTrends, time[n], sRate);
         sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         updsTrend = true;
      } else { 
      // trend interrupted
         if(!updsTrend) {
          // do not create new sTrend for intemediate log data
            logDebug(StringFormat("Record Trend (%f @ %s) => (%f @ %s) [%d]", pRate, TimeToString(time[pTick]), sRate, TimeToString(time[sTick]), n));
            setTrend(nrTrends, time[pTick], pRate, time[sTick], sRate);
            // sTrend = new Trend(time[pTick], pRate, time[sTick], sRate);
            // trends[nrTrends++] = sTrend;
            logDebug(StringFormat("New number of trends: %d", nrTrends));
         }  else {
          // defer trend initializtion, previous sTrend updated
            logDebug(StringFormat("End sTrend update (%f @ %s)[%d]", TrendStrR[nrTrends], TimeToString(TrendStrT[nrTrends]), n));
            updsTrend = false;
         }
   
         calcMax = (TrendStrR[nrTrends] <= TrendEndR[nrTrends]); // set for traversing reversal of previous trend
         sRate = calcMax ? low[pTick] : high[pTick];
         pRate = calcMax ? high[n] : low[n];
         sTick = pTick;
         pTick = n;
         logDebug(StringFormat("New calcMax %s, pRate %f, sRate %f [%d:%d]", (calcMax? "true" : "false"), pRate, sRate, sTick, pTick));
      } 
   }  
   
   if (nrTrends > 0) {
      // update last (chronologically first) trend record
      logDebug(StringFormat("Last Trend (%f @ %s) => (%f @ %s)", sRate, TimeToString(time[sTick]), pRate, TimeToString(time[n])));
      pRate = calcMax ? high[n]: low[n];
      // sTrend = new Trend(time[n], pRate, time[sTick], sRate);
      // trends[nrTrends++] = sTrend;
      setTrend(nrTrends++, time[n], pRate, time[sTick], sRate);
   }

   return nrTrends;
}

// see also: Heikin Ashi.mq4 src - "Existing work" in MQL4 indicator development

void OnInit() {
   IndicatorShortName("IND0");
   
   ArraySetAsSeries(TrendStrR, true);
   ArraySetAsSeries(TrendStrT, true);
   ArraySetAsSeries(TrendEndR, true);
   ArraySetAsSeries(TrendEndT, true);
   
   IndicatorBuffers(4);
   // NB: SetIndexBuffer may not accept a buffer of class type elements
   SetIndexBuffer(0, TrendStrR);
   SetIndexBuffer(1, TrendStrT);
   SetIndexBuffer(2, TrendEndR);
   SetIndexBuffer(3, TrendEndT);
   // SetIndexBuffer(4, SigStoK[]); // TBD - calcSto
   // SetIndexBuffer(5, SigStoM[]); // TBD - calcSto
   // SetIndexBuffer(6, SigAD[]);   // TBD - calcAD
   // SetIndexBuffer(7, SigCCI[]);  // TBD - calcCCI
}


int OnCalculate(const int count,
                const int counted,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
                
   const int first = 0;
   const int maxTrends = (count - first) / 2;
   ArrayResize(TrendStrR, maxTrends, 0);
   ArrayResize(TrendStrT, maxTrends, 0);
   ArrayResize(TrendEndR, maxTrends, 0);
   ArrayResize(TrendEndT, maxTrends, 0);
   logDebug(StringFormat("Count %d, Counted %d, maxTrends %d", count, counted, maxTrends));

   const int nrTrends = calcTrends(count, counted, open, high, low, close, time);
   logDebug(StringFormat("calcTrends nrTrends %d", nrTrends));
   
   // drawTrends(...)
   
   // FIXME: calcTrends is applied only for historic analysis. 
   //
   // The first trend calculated by calcTernds - i.e. trends[0] - should be updated
   // subsequent to incoming market data, when the function is applied in a realtime
   // indicator.
   
   return nrTrends;
}
