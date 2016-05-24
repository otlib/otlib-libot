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
input bool  chart_draw_times = false; // draw additional indicators of trend duration

// - Buffers
double TrendStrR[]; // Trend Start Rate
double TrendStrT[]; // Trend Start Time
double TrendEndR[]; // Trend End Rate
double TrendEndT[]; // Trend End Time
// SigStoK[]; // Data similar to Stochastic Oscillator K
// SigStoM[]; // Data similar to Stochastic Oscillator Main
// SigAD[];   // Data similar to Accmulation/Ditribution Indicator
// SigCCI[];  // Data similar to Commodity Channel Index Indicator

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

class Trend { // FIXME: separate this into four buffers, two of datetime[] and two of double[]
public:
   datetime startTime;
   datetime endTime;
   double startRate;
   double endRate;
      Trend() ;
      Trend(datetime time, double rate);
      Trend(datetime t1, double r1, datetime t2, double r2);
};

Trend::Trend() {
  startTime = 0;
  startRate = 0;
  endTime = 0;
  endRate = 0; 
}

Trend::Trend(const datetime time,const double rate) {
  startRate = 0;
  startTime = 0;
  endTime = time;
  endRate = rate; 
}

Trend::Trend(const datetime t1, const double r1, const datetime t2, const double r2) {
   startRate = r1;
   startTime = t1;
   endRate = r2;
   endTime = t2;
}

double getChange(const Trend &trend) {
   return (trend.endRate - trend.startRate);
}

Trend *trends[]; // FIXME: Remove

// NB: see also SymbolInfoTick()

// FIXME: Cannot define calcTrends in a library and import it?
// Compiler emits a message, "Constant variable cannot be passed 
// as reference" when function is defined in a library then 
// called as across an 'import' definition.

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
   // the `trends` array and returning the number of trends calculated.
   //
   // `trends` should be of a length no greater than the length of each
   // of the {open, high, low, close, time} arrays

   int sTick, pTick, nrTrends;
   double rate, sRate, pRate;
   bool updsTrend = false;
   
   Trend* sTrend = NULL;

   nrTrends = 0;

   sRate = calcRateHAC(open[start], high[start], low[start], close[start]);
   pRate = sRate;
   sTick = start;
   pTick = start;

   bool calcMax = (sRate < calcRateHAC(open[start+1], high[start+1], low[start+1], close[start+1]));  

   int n;
   
   for(n=start+1; n < count; n++) {
      // apply a simple high/low calculation for logical dispatch to trend filtering
      rate = calcMax ? high[n] : low[n];
      if (calcMax && (rate >= pRate)) {
      // continuing trend rate > pRate - simple calc
         logDebug(StringFormat("Simple calcMax %f [%d]", rate, n));
         if(updsTrend) {
            sRate = rate;
            sTick = n;
            sTrend.startRate = rate;
            sTrend.startTime = time[n];
         }
         pRate = rate;
         pTick = n;
      } else if (!calcMax && (rate <= pRate)) {
      // continuing trend rate <= pRate - simple calc
         logDebug(StringFormat("Simple !calcMax %f [%d]", rate, n));
         if(updsTrend) {
            sRate = rate;
            sTick = n;
            sTrend.startRate = rate;
            sTrend.startTime = time[n];
         }
         pRate = rate;
         pTick = n;
      } else if (!calcMax && !updsTrend &&
                  (sTrend != NULL) && 
                  (high[n] >= sTrend.startRate) &&
                  (sTrend.startRate > sTrend.endRate)) {
      // high.n >= sTrend.startRate > sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = high[n];
         calcMax = true;
         sRate = pRate;
         sTrend.startRate = sRate;
         sTrend.startTime=time[n];
         sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert !calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         updsTrend = true;
      } else if (calcMax && !updsTrend &&
                  (sTrend != NULL) && 
                  (low[n] <= sTrend.startRate) &&
                  (sTrend.startRate <= sTrend.endRate)) {
      // low.n <= sTrend.startRate <= sTrend.endRate
      // i.e trend now develops in parallel with sStrend - no longer traversing a reversal.
      // do not log as reversal. invert the traversal logic. udpate pRate, sRate, sTrend
         pRate = low[n];
         calcMax = false;
         sRate = pRate;
         sTrend.startRate = sRate;
         sTrend.startTime=time[n];
         sTick = n;
         pTick = n;
         logDebug(StringFormat("Invert calcMax rate %f => %f [%d] %s", rate, pRate, n, TimeToString(time[n])));
         // FIXME: sTrend will not be further updated, past this branch of exec
         updsTrend = true;
      } else { 
      // trend interrupted
         if(!updsTrend) {
          // do not create new sTrend for intemediate log data
            logDebug(StringFormat("Record Trend (%f @ %s) => (%f @ %s) [%d]", pRate, TimeToString(time[pTick]), sRate, TimeToString(time[sTick]), n));
            sTrend = new Trend(time[pTick], pRate, time[sTick], sRate);
            trends[nrTrends++] = sTrend;
            logDebug(StringFormat("New number of trends: %d", nrTrends));
         }  else {
          // defer trend initializtion, previous sTrend updated
            logDebug(StringFormat("End sTrend update (%f @ %s)[%d]", sTrend.startRate, TimeToString(sTrend.startTime), n));
            updsTrend = false;
         }
   
         calcMax = (sTrend.startRate <= sTrend.endRate); // set for traversing reversal of previous trend
         sRate = calcMax ? low[pTick] : high[pTick];
         pRate = calcMax ? high[n] : low[n];
         sTick = pTick;
         pTick = n;
         logDebug(StringFormat("New calcMax %s, pRate %f, sRate %f [%d:%d]", (calcMax? "true" : "false"), pRate, sRate, sTick, pTick));
      } 
   }  
   
   if (sTrend != NULL) { // nrTrends != 0
      // final (series-first) trend
      logDebug(StringFormat("Last Trend (%f @ %s) => (%f @ %s)", sRate, TimeToString(time[sTick]), pRate, TimeToString(time[n])));
      pRate = calcMax ? high[n]: low[n];
      sTrend = new Trend(time[n], pRate, time[sTick], sRate);
      trends[nrTrends++] = sTrend;
   }

   return nrTrends;
}

void drawTrendsForS(const long id, const Trend* &trends[], const int count) { 
   // FIXME: Revise for indicator line semanatics & remove

   datetime startT, endT;
   double startP, endP;
   bool start, end;
   string name;

   for (int n = 0; n < count; n++) {
      startT = trends[n].startTime;
      startP = trends[n].startRate;
      if (startT != 0 && startP != 0) {
         start = true;
         if (chart_draw_times) {
            name = StringFormat("TREND %d START %s", n, TimeToString(startT)); // FIXME use formatted strings
            ObjectCreate(id,name, OBJ_VLINE, 0, startT, 0);
         }
      }
      
      endT = trends[n].endTime;
      endP = trends[n].endRate;
      if (endT != 0 && endP != 0) {
         end = true;
      //// redundant
      // name = StringFormat("TREND %d END %s", n, TimeToString(endT));
      // ObjectCreate(id,name, OBJ_VLINE, 0, endT, 0);
      }
      
      if(start && end) {
         name = StringFormat("TREND %d LINE [%s .. %s ]", n, TimeToString(startT), TimeToString(endT));
         ObjectCreate(id, name, OBJ_TREND, 0, startT, startP, endT, endP);
         ObjectSetInteger(id,name,OBJPROP_RAY_RIGHT,false);
         ObjectSetInteger(id,name,OBJPROP_COLOR,clrLime); // FIME: MAKE PROPERTY
         ObjectSetInteger(id,name,OBJPROP_WIDTH,3); // FIME: MAKE PROPERTY
      } /* else { // DEBUG
         Print("Trend not complete : [" + startT + " ... " + endT + "]");
      } */
   }
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
   ArrayResize(trends, maxTrends, 0); // FIXME remove
   ArrayResize(TrendStrR, maxTrends, 0);
   ArrayResize(TrendStrT, maxTrends, 0);
   ArrayResize(TrendEndR, maxTrends, 0);
   ArrayResize(TrendEndT, maxTrends, 0);
   
   const int nrTrends = 0;
   
   // nrTrends = calcTrends(count, first, trends, open, high, low, close, time);
   // ^ FIXME: redefine calcTrends for Trend{Str|End}{R|T} and apply here
   
   // drawTrends(...)
   
   // FIXME: calcTrends is applied only for historic analysis. 
   //
   // The first trend calculated by calcTernds - i.e. trends[0] - should be updated
   // subsequent to incoming market data, when the function is applied in a realtime
   // indicator.
   
   return nrTrends;
}