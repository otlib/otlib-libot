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
#property description "OTLIB"
#property version   "1.00"
#property strict
#property script_show_inputs



//--- input parameters
input int   a_period_init=5; // e.g STO//D, STO//SLOWING
input int   b_period_init=15; // e.g STO//K, CCI PERIOD, FISHER PERIOD
input int   c_period_init=10; // e.g LWMA period
input int   min_trend_period = 4; // minimum number of clock ticks for trend calculation

// OTLIB

// - curency pairs

string getCurrentSymbol() {
   return ChartSymbol(0);
}

// - interactive messaging 

int errorNotify(string message) {
   Print(message);
   return MessageBox(message,"Error",MB_OKCANCEL);
}

int msgOkAbort(string message) {
   int retv = MessageBox(message, "Notifiation", MB_OKCANCEL);
   if (retv == IDCANCEL) {
      ExpertRemove();
   }
   return retv;
}

// - market information

// See also: SymbolInfoDouble(Symbol(),SYMBOL_{ASK|BID});


double getAskP(){ // market ask price, current chart and symbol
   string symbol = getCurrentSymbol();
   return getAskPForS(symbol);
}


double getAskPForC(long id){ 
   // return ask price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getAskPForS(symbol);
}


double getAskPForS(string symbol){
   return MarketInfo(symbol,MODE_ASK);
}


double getOfferP(){ // market offer price, i.e bid price
   string symbol = getCurrentSymbol();
   return getOfferPForS(symbol);
}


double getOfferPForC(long id){ 
   // return offer price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getOfferPForS(symbol);
}


double getOfferPForS(string symbol){
   return MarketInfo(symbol,MODE_BID);
}


double getSpread() { // diference of ask and offer price
   string symbol = getCurrentSymbol();
   return getSpreadForS(symbol);
}


double getSpreadForC(long id){ 
   // return market spread for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getSpreadForS(symbol);
}


double getSpreadForS(string symbol) {
   double ask = getAskPForS(symbol);
   double offer = getOfferPForS(symbol);
   return ask - offer;
}

// -- market performance data


class Trend {
public:
   datetime startTime;
   datetime endTime;
   double startRate;
   double endRate;
   Trend* next;
   Trend* previous;
          Trend(void) { next = NULL; previous = NULL; };
          Trend(datetime end, double rate, Trend* &trend){ endTime = end; endRate = rate; next = trend; previous = NULL; };
   double getChange(); 
};


double Trend::getChange(void) {
   if (this.previous != NULL) {
      return this.previous.endRate - this.endRate;
   } else {
      return 0;
   }
}


// NB: see also SymbolInfoTick()


Trend *plotTrendsForS(string symbol, int timeframe, int count, int start) {

   MqlRates rates[];
   // ArraySetAsSeries(rates, true);
   
   Trend *lastTrend = new Trend;
   Trend *trend =    lastTrend;
      
   int retv = CopyRates(symbol, timeframe, start, count, rates);
   if (retv > 0) {
      double min, max, rate;
      int minTick, maxTick, tick, nextStart, nextCount;
      datetime time;
      
      min = getOfferPForS(symbol);
      max = 0;
      nextStart = start;
      nextCount = retv;

      bool minFound, complete;
      minFound = false;
      complete = false;

      while(!complete && nextCount > min_trend_period) {
         msgOkAbort("Start, Count " + nextStart + ", " + nextCount);
         
         for (int n = nextStart; n <= nextCount; n++) {
            // rate calculation is similar to HA-close for Heikin Ashi indicators
            // cf. http://stockcharts.com/school/doku.php?id=chart_school:chart_analysis:heikin_ashi
            rate = ( rates[n].open + rates[n].high + rates[n].low + rates[n].close ) / 4;
            msgOkAbort("Average Rate: " + rate);
            if (rate >= max && ! minFound) {
               maxTick = n;
               max = rate;
               msgOkAbort("Set new max: " + rate + " at " + n);
            } else if (rate <= min) {
               minTick = n;
               min = rate;
               minFound = true;
               msgOkAbort("Set new min: " + rate + " at " + n);
            } else { // ?? if ( (nextCount - n) > min_trend_period ) ??
               // minFound = rate > min;
               msgOkAbort("Exiting for n = " + n);
               break;
            }
         }

         if ( minFound ) {
            rate = min;
            tick = minTick;
            max = min; // reset for next iteration
            minFound = false; // reset for next iteration
         } else {
            rate = max;
            tick = maxTick;
            min = max; // reset for next iteration
            minFound = true; // reset for next iteration
         }
         time = iTime(symbol, timeframe, tick);

         msgOkAbort("Intermediate Rate, Tick, Time: " + rate + ", " + tick + ", " + time);
         
         trend.startRate = rate;
         trend.startTime = time;
         
         nextStart = tick;
         nextCount = nextCount - tick;
         // TO DO : reset 'rate'  !!!!!!!!!
         
         complete = (nextCount <= min_trend_period); // ???

         if (!complete) {
           trend = new Trend(time, rate, trend);
           trend.next.previous = trend;
         } // if !complete
      } // while !complete
   } else {
      retv = errorNotify("Error " + IntegerToString(GetLastError()) + " [CopyRates] when copying history data for symbol " + symbol + ". Cancel to remove EA");
      if (retv == IDCANCEL) {
         ExpertRemove(); // !
      }
   }
   return lastTrend;
}


void OnStart() {

   MessageBox("Visible : " + CHART_VISIBLE_BARS, "Notification", MB_OK);
   Trend *last = plotTrendsForS(getCurrentSymbol(),PERIOD_M1, CHART_VISIBLE_BARS, 0);
   // MessageBox("Rate: " + DoubleToString(last.startRate),"Notification",MB_OK);
   
}

