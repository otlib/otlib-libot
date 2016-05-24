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

 
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "Script SCR0, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs

input bool  log_debug = true; // print initial runtime information to Experts log
input bool  chart_draw_times = false; // draw additional indicators of trend duration

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



// NB: see also SymbolInfoTick()

// FIXME: Cannot define calcTrends in a library and import it?
// Compiler emits a message, "Constant variable cannot be passed 
// as reference" when function is defined in a library then 
// called as across an 'import' definition.

int calcTrends(const int count, 
                  const int start, 
                  Trend* &trends[], // FIXME: define as a four-slot indicator buffer arrangement
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
      // rate = calcMax ? calcRateHHL(high[n], low[n]) : calcRateHLL(high[n], low[n]);
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
   
         //
         // FIXME: Logic for calculations following event of reversal detection
         // also, whether or not to set pRate, pTick in the previous two program branches
         //
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
      // pRate = calcMax ? high[n] : low[n];
      sTrend = new Trend(time[n], pRate, time[sTick], sRate);
      trends[nrTrends++] = sTrend;
   }

   return nrTrends;
}

void drawTrendsForS(const long id, const Trend* &trends[], const int count) {
   // FIXME: Cleanups - function name
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

void OnStart() {
   // run program in script mode (DEBUG)
   
   
   // DEBUG
   // logDebug("Clear Objects");
   // ObjectsDeleteAll(0,-1);
   
   // const string symbol = getCurrentSymbol();
   
   // for the script implementation of this EA, calculate bars from bar 0
   // to the first visible bar in the chart
   int count = WindowFirstVisibleBar();
   int first = 0;
   // int maxTrends = MathCeil(count / min_trend_period); // FIXME: maxTrends calculation
   int maxTrends = count / 2;
   // FIXME: Log messages not printed ??
   logDebug(StringFormat("First %d, Count: %d, Maximum nr. trends: %d", first, count, maxTrends));
   logDebug(StringFormat("Duration: [%s]..[%s}", TimeToString(Time[count]), TimeToString(Time[first])));
   
   Trend *trends[];
   ArrayResize(trends, maxTrends, 0);
   ArraySetAsSeries(trends, true); // NB: MUST call this - it has odd worse effects to not

   // This script will use buffered Open, High, Low, Close, Time instead of CopyRates(...)
   // see also: OnCalculate(), RefreshRates()
   const int nrTrends = calcTrends(count, first, trends, Open, High, Low, Close, Time); // 15 instead of rates_total
   
   drawTrendsForS(ChartID(), trends, nrTrends); // DEBUG INFO
   
   ExpertRemove(); // DEBUG
   
}
