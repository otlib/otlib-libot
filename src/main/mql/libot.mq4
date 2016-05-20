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
input int   b_period_init=a_period_int * 3; // e.g STO//K, CCI PERIOD, FISHER PERIOD
input int   c_period_init=b_period_init * 2; // e.g LWMA period
input int   min_reversal_period = 4 // minimum number of clock ticks for reversal calculation
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

// - market information

// FIXME: See also double SymbolInfoDouble(Symbol(),SYMBOL_{ASK|BID});


double getAskP(){ // market ask price, current chart and symbol
   string symbol = getCurrentSymbol();
   return getAskPriceFor(symbol);
}


double getAskPForC(long id){ 
   // return ask price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getAskPForS(symbol);
}


double getAskPForS(string symbol){
   return MarketInfo(sybol,MODE_ASK);
}


double getOfferP(){ // market offer price, i.e bid price
   string symbol = getCurrentSymbol();
   return getOfferPriceFor(symbol);
}


double getOfferPForC(long id){ 
   // return offer price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getOfferPForS(symbol);
}


double getOfferPForS(string symbol){
   return MarketInfo(sybol,MODE_BID);
}


double getSpread() { // diference of ask and offer price
   string symbol = getCurrentSymbol();
   return getSpreadFor(symbol);
}


double getSpreadForC(long id){ 
   // return market spread for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getSpreadForS(symbol);
}


dougle getSpreadForS(string symbol) {
   double ask = getAskPriceFor(symbol);
   double offer = getOfferPriceFor(symbol);
   return ask - offer;
}

// -- market performance data

/* see instead: MqlTick, MqlRates 
struct rateTick {
   // see also: MqlTick, SymbolInfoTick()
   double rate;
   datetime time;
}
*/


/* see instead: MqlTick, MqlRates 

struct OHLCTick {
   // assumption: market symbol and timeframe stored external to this data object
   double open; // iOpen
   double high; // iHigh
   double low; // iLow
   double close; // iClose
   // int timeframe; // see Period(); must be consistent across iOpen, iHigh, iLow, iClose calls
   datetime time; // iTime - converted from 'shift' as applied in iHigh, ...
}


*/

// struct HATick - TO DO, HA Indicator Calculation (series-based)


double calcAvgRate(MqlRates rate) {
   // calculation is similar to HA-close for Heikin Ashi indicators
   // cf. http://stockcharts.com/school/doku.php?id=chart_school:chart_analysis:heikin_ashi
   double rt = ( rate.open + rate.high + rate.low + rate.close ) / 4;
   return rt;
}



// FIXME: Use SymbolInfoTick(...) ?

rateTick getHighest(int period, int count, int start) {
   // period 0 indicates current timeframe of active chart
  string symbol = getCurrentSymbol();
  return getHighestForS(symbol, period, count, start);
}


rateTick getHighestForC(int id, int count, int start) {
   string symbol = ChartSymbol(id);
   int period = ChartPeriod(id);
   return getHighestForS(symbol, period, count, start);
} 


rateTick getHighestForS(string symbol, int period, int count, int start) {
   int offset = iHighest(symbol,period,MODE_HIGH,count,start);
   double rate = iHigh(symbol, period, offset);
   datetime time = iTime(symbol, period, offset);
   rateTick tick = {rate, time};
   return tick;
}


rateTick getLowest(int period, int count, int start) {
   // period 0 indicates current timeframe of active chart
  string symbol = getCurrentSymbol();
  return getLowestForS(symbol, period, count, start);
}


rateTick getLowestForC(int id, int count, int start) {
   string symbol = ChartSymbol(id);
   int period = ChartPeriod(id);
   return getLowestForS(symbol, period, count, start);
} 


rateTick getLowestForS(string symbol, int period, int count, int start) {
   int offset = iLowest(symbol,period,MODE_LOW,count,start);
   double rate = iLow(symbol, period, offset);
   datetime time = iTime(symbol, period, offset);
   rateTick tick = {rate, time};
   return tick;
}


// -- 

struct MinMax {
   int minOffset;
   double minRate;
   int maxOffset;
   double maxRate;
   // MinMax prev;
   MinMax *next;
}


struct Trend {
   int startOffset;
   double startrate;
   int endOffset;
   double endRate;
}



Reversal[] plotReversals(int period, int count, int start) {
  // ...
}

Reversal[] plotReversalsForS(string symbol, int period, int count, int start) { 
 // ...
} 

Reversal[] plotLimits(string symbol, int period, int count, int start, bool calcMin, bool calcMax) {
   if(count >= min_reversal_period) {
      int n = 0; // number of indexed min,max tries
      MinMax *m = plotMinMax(symbol, period, count, start, calcMin, calcMax);
      if (m != NULL){
         
      int nextCount = count, nextStart = start, offt, difft;
      bool calcMin, calcMax;
      
         // iterate (to limtis of stack)
         
      do{ // first subregion
         calcMin = (m.minOffset - start) > min_reversal_period; // ?
         calcMax = (m.maxOffset - start) > min_reversal_period; // ?
         offt = m.minOffset < m.maxOffset ? m.minOffset : m.maxOffset; // ?
         nextCount = offt - start; // X
         nextStart = start; // X
         if (calcMin || calcMax && nextCount > min_reversal_period) {
            // (start ...  nextStart]
            m.next = plotMinMax(symbol, period, nextCount, nextStart, calcMin, calcMax);
            m = m.next
            n++;
            } else {
               calcMin = FALSE;
               calcMax = FALSE;
            }
         } while (calcMin || calcMax);
         

      do{ // second subregion
         calcMin = (m.minOffset - start) > min_reversal_period; // ?
         calcMax = (m.maxOffset - start) > min_reversal_period; // ?
         offt = m.minOffset < m.maxOffset ? m.minOffset : m.maxOffset; // ?
         netCount = count - offt; // X
         nextStart = offt; // X
         if (calcMin || calcMax && nextCount > min_reversal_period) {
            // (start ...  nextStart]
            m.next = plotMinMax(symbol, period, nextCount, nextStart, calcMin, calcMax);
            m = m.next
            n++;
            } else {
               calcMin = FALSE;
               calcMax = FALSE;
            }
         } while (calcMin || calcMax);

         
         // TO DO: 'expand' M to individual min, max rates, sorting results by offset; calculate reversal offsets, magnitudes
         // then graph min->max->min... lines for debug + indicator [XXXX]
         
         return expandMinMax(MinMax, n); 
       }
       }
    else { // if error occurred - handled elsewhere
      return NULL;
    }
}

MinMax[] simplifyMinMax(MinMax &value, count) {
   MinMax[count] *mm; // * & ??
   MinMax *cur = value;
   for(int n = 0; n < count; n++) {
      mm[n] = cur;
      cur = cur.next;
   }
   return mm;
}

Reversal[] expandMinMax(MinMax &value, int count) {
   MinMax *cur = value;
   MinMax[] *mm = simplifyMinMax(value, count);
   Trend[count] trend = NULL;
   for (int a = 0; a < count; a++) {
      // ...
      trend[a] = { startOff, startRate, endOff, endRate}
      
      mm = mm.next;
   }
   return rev;

}

MinMax plotMinMax(string symbol, int period, int count, int start, bool calcMin, bool CalcMax ) {
   
   MqlRates[] rates;
   ArraySetAsSeries(rates, true);
   int retv = CopyRates(symbol, period, start, count, &rates);
   if (retv > 0) {
      int minOffset = 0, maxOffset = 0;
      double min, max, cur;
      rt MqlRates;
      
      if(calcMin) { 
         min = getLowestForS(symbol, period, count, start); 
      } else {
         min = NULL;  
      }
      if(calcMax){ 
          max = getHighestForS(symbol, period, count, start);
      } else {
         max = NULL;
      }   

      // FIXME: Also copy a reference to rt.time for each of min, max ?
      for(int a = 0; a < count; a++) {
         rt = rates[a];
         cur = calcAvgRate(rt);
         if (calcMax && cur >= max) {
            max = cur; 
            maxOffset = a;
         } else if (calcMin && cur <= min) {
            min = cur;
            minOffset = a;
         }
      }
      MinMax m = {minOfset, min, maxOffset, max};
      return m;
      }
      
   }
   else  { 
      retv = errorNotify("Error " + GetLastError() + " [CopyRates] when copying history data for symbol " + symbol + ". Cancel to remove EA");
      if (retv = IDCANCEL) {
         ExpertRemove(); // !
         return NULL;
      }
   } 

}


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//void OnStart()
//  {
//---
   
//  }
//+------------------------------------------------------------------+
