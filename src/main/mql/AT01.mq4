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

/* Documntation Notes

Rationale - Synopsis

Among the primary goals in developing AT01:
 * to develop a logically unambiguous mechanical trading methodolgy applying a function onto linear weighted moving average calculations of realtime market rate data
 * to apply that methodology in calculations onto realtime market rate data - towards applications in trading on Forex ECN
 * to develop this application in a manner as to limit risk to the trader, namely as juxtaposed to the potential for steep, disfavorable "spike" events in time-series evolution of market rate data



*/

// - Metadata
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property description "AT01 - Mechanical Trading Prototype. OTLIB"
#property version   "1.00"
#property strict
// #property script_show_inputs
// #property indicator_chart_window
// #property indicator_buffers 3 // number of drawn buffers ?

/* NO DRAWING IN EA ?
#property indicator_color1 clrYellow
#property indicator_width1 2
#property indicator_color2 clrLime
#property indicator_width2 2
#property indicator_color3 clrSilver
#property indicator_width3 2
*/

#include "stdlib.mqh" // FIXME: INCLUDE PATHS
#include "libea.mqh"
#include "libat.mqh"


// NOTE: This proram, though originally designed onto a set of graphical 
// indicators, must be installed as an Expert Advisor. No OnCalculate() 
// function is provided in this EA. Instead, the indicator data is 
// initialized via the function atInitData(), and subsequently updated via
// the function atUpdateData()
// 
// This EA does not draw any chart data. Chart data may be drawn by the
// platform user as in a manner corresonding to this EA, using MA indiators
// similar to those configured in any single running instance of this EA.
//
// FIXME: Define a combined three-MA graphical indicator and call iCustom 
// from this program to launch the same indicator, such as to provide
// a visual indication accurate to the internal chart data of this EA.

// FIXME: THE WHOLE THING IS UPDATED TO NO WAY DOCUMENTED, WHEN CHART TIMEFRAME IS CHANGED

// - EA Custom Data Types

enum ENUM_AT_CMD {
   OP_AT_SELL, // Sell
   OP_AT_BUY,  // Buy
   OP_AT_ANY   // Sell Or Buy
};

enum ENUM_LOG_LEVEL {
   // Event Categories - AT01
   LOG_PROGRAM = 1,
   LOG_CALC = 2,
   LOG_ORDER = 4,
   LOG_DRAW = 8
};

enum ENUM_LOG_OPTIONS {
   OPT_LOG_NONE = 0,      // Log No Events
   OPT_LOG_PROGRAM = 1,   // Log Program Events
   OPT_LOG_CALC = 3,      // Log Calc and Program Events
   OPT_LOG_ORDER = 7,     // Log Order, Calc, Program Events
   OPT_LOG_DRAW = 15      // Log Draw, Order Calc, Program Events
};

#ifndef HA_OPEN_DATUM
#define HA_OPEN_DATUM 3
#endif

#ifndef HA_HIGH_DATUM
#define HA_HIGH_DATUM 4
#endif

#ifndef HA_LOW_DATUM
#define HA_LOW_DATUM 5
#endif


#ifndef HA_CLOSE_DATUM
#define HA_CLOSE_DATUM 6
#endif


enum ENUM_DATA {
   DATA_MDATA=0, // main chart MA data, at each configured timeframe
   DATA_SDATA=1, // signal chart MA data, at each configured timeframe
   DATA_TDATA=2, // trend chart MA data, at each configured timeframe
   DATA_HA_OPEN=HA_OPEN_DATUM, // Heikin Ashi open rate, at each configured timeframe
   DATA_HA_HIGH=HA_HIGH_DATUM, // Heikin Ashi high rate, at each configured timeframe
   DATA_HA_LOW=HA_LOW_DATUM, // Heikin Ashi low rate, at each configured timeframe
   DATA_HA_CLOSE=HA_CLOSE_DATUM // Heikin Ashi close rate, at each configured timeframe
};

enum ENUM_TF_PERIOD {
   // Timeframe period as configured in input - see also ptf(..)
   TF_PERIOD_1 = 0,
   TF_PERIOD_2 = 1,
   TF_PERIOD_3 = 2
};

enum AT_TIME { // extends ENUM_TIMEFRAME with additional AT_TIME_NONE element
   AT_TIME_NONE = -1, // Not Configured
   AT_TIME_M1 = PERIOD_M1,    // 1 Minute
   AT_TIME_M5 = PERIOD_M5,    // 5 Minutes
   AT_TIME_M15 = PERIOD_M15,  // 15 Minutes
   AT_TIME_M30 = PERIOD_M30,  // 30 Minutes
   AT_TIME_H1 = PERIOD_H1,    // 1 Hour
   AT_TIME_H4 = PERIOD_H4,    // 4 Hours
   AT_TIME_D1 = PERIOD_D1,    // 1 Day
   AT_TIME_W1 = PERIOD_W1,    // 1 Week
   AT_TIME_MN = PERIOD_MN1    // 1 Month
};



// - EA Input Parameters

input bool AT_ALWAYS=false; // Open order on EA activation
input double AT_VOLUME=0.02;   // Volume for mechanically opened orders
// input ENUM_AT_CMD AT_CMD_OP = OP_AT_SELL; // Activate autotrading for Sell, Buy, or Any // unused
input int AT_M_PERIOD = 5;  // Period for MA of Main Indicator Graph
input int AT_S_PERIOD = 10; // Period for MA of Signal Indicator Graph
input int AT_O_PERIOD = 5;  // Offset for MA of Signal Indicator Graph
input int AT_T_PERIOD = 20; // Period for MA of Trend Indicator Graph
input ENUM_MA_METHOD       AT_MA_METHOD = MODE_LWMA; // MA method for Indicator Graphs
input ENUM_APPLIED_PRICE   AT_P_METHOD = PRICE_TYPICAL; // Rate Calculation method for Indicator Graphs
input bool AST_REV_ENAB = true; // Enable algorithmic reversal stop
input bool AST_XOV_ENAB = true; // Enable algorithmic crossover stop
input int C_TIME   = 200;  // Duration (milliseconds) for calculation timer
input AT_TIME AT_PERIOD1 = PERIOD_M1;   // Primary Period for Event Calculations
input AT_TIME AT_PERIOD2 = PERIOD_M5;   // Secondary Period for Event Calculations
input AT_TIME AT_PERIOD3 = PERIOD_M15;  // Tertiary Period for Event Calculations
input int CALC_DEPTH = 3; // Depth for market history calculation
input int ORDER_ST_PERIOD = 2; // Minimum period (seconds) between order close, order open
input ENUM_LOG_OPTIONS AT_LOGLEVEL = OPT_LOG_DRAW; // Log Level

// FIXME: ENSURE DATA REINITIALIZED AFTER CHANGE IN AT_PERIOD1, AT_PERIOD2, AT_PERIOD3
// I.E WHEN EA RESTARTED AFTER PREVIOUS DEINIT DUE TO REASON_PARAMETERS

// NB: INTERPRET AT_PERIOD1 .. AT_PERIOD3 == AT_TIME_NONE as meaning "UNDEFINED" - alternate to defining another enum type
// NB: At least one of AT_PERIOD1, AT_PERIOD2, AT_PERIOD3  must be != AT_TIME_NONE

// NB: If both AST_REV_ENAB and AST_XOV_ENAB = false, orders will not be mechanically closed with this program



// - configure and activate the SimpleStackBuffer implementation
#ifndef BUFFLEN
#define BUFFLEN 512
#endif

#ifndef N_DATAPTR
#define N_DATAPTR HA_CLOSE_DATUM + 1
#endif

#ifndef N_TFRAME
#define N_TFRAME 3
#endif

#ifndef BUFF_T
#define BUFF_T double
#endif


// NB UNDOCUMENTED FEATURE? - DATETIME CLOK OPERATING AT A SCALE OF MILLISECONDS (AFTER EventSetMillisecondTimer) ??
#ifndef TFRAME_SCALE
#define TFRAME_SCALE 60 // datetime timer functioning in unit of seconds?
#endif

#include "libbuffer.mqh"
#include "libha.mqh"

SimpleStackBuffer* sbuff=NULL;

// buffer for converting from timeframe index to timeframe period
// utilized in calculations applying SimpleStackBuffer
int timeframes[3]; 
datetime chart_last[N_TFRAME]; // Applied onto sbuff for sbuff chart data push function

// - EA Program Parameters

const string label = "AT01";
// - order_main 

// if (order_main > 0), records the ticket number for the main order 
// else indicates that no main order is open

int order_main = -1; // Record of one active order, or none if -1
datetime order_main_last; // datetime of last event onto order_main - FIXME: REMOVE
datetime ontick_last = 0; // Applied in a finite state machine for slowing OnTick updates


int calc_period;
string EA_SYMBOL;
int AT_ONCE = false; // applied when AT_ALWAYS

// - individual data buffers applied before implementing SimpleStackBuffer
// double MA_MDATA[BUFFLEN][3]; // main chart data - time frames 0, 1, 2
// double MA_SDATA[BUFFLEN][3]; // signal chart data - time frames 0, 1, 2
// double MA_TDATA[BUFFLEN][3]; // trend chart data - time frames 0, 1, 2



// - Utility

void logMessage(const ENUM_LOG_LEVEL llevel, const string message) {
   if(AT_LOGLEVEL != 0) {
   // if(( AT_LOGLEVEL & llevel) != 0) {
      Print(message);
   // }
   }
}

int atHandleError() {
   const int code = GetLastError();
   PrintFormat("Error [%d] : %s ",code , ErrorDescription(code));
   //   _StopFlag = true; // NB: CANNOT SET _StopFlag. MQL4 Documentation suggest otherwise ?
   ExpertRemove();
   return code;
}

void atValidateInputs() {
   logMessage(LOG_PROGRAM,__FUNCTION__);
   if( (AT_PERIOD1 == AT_TIME_NONE) 
        && (AT_PERIOD2 == AT_TIME_NONE) 
        && (AT_PERIOD3 == AT_TIME_NONE)) {
      Print("Invalid Inputs - AT01 periods 1, 2, 3 are set to AT_TIME_NONE");
      ExpertRemove();
   }
   if(calc_period > BUFFLEN) {
      PrintFormat("Error - calc_period %d greater than BUFFLEN %d. Consider adjusting EA period, depth parameters", calc_period, BUFFLEN);
      ExpertRemove();
   }
}


void atInitData(const int depth) {
   // called again after EA change

   // initialize main, signal, and trend data buffers (drawn)
     
   // NB: SetIndexBuffer() not applicable for double[][]

   // NB: SetIndexBuffer N/A in EA type programs
   //
   // FIXME: Try out the simple array-as-stack implementation in libea.mqh ?
   // update for each MA data buffer
   logMessage(LOG_PROGRAM,__FUNCTION__);
   IndicatorDigits(Digits+2);

   if(sbuff == NULL) {
      sbuff = new SimpleStackBuffer(false); 
      // SSBuf init with asTSeries false => use conventional reverse-time-series order, similar to iOpen and others
   }
   
   // - initialize timeframes[0..2]
   timeframes[0] = AT_PERIOD1;
   timeframes[1] = AT_PERIOD2;
   timeframes[2] = AT_PERIOD3;

   // haInitBuffers(calc_period); // unused when STACKBUFF
   // FIXME - Open, High, Low, Close no longer used when STACKBUFF
   ArraySetAsSeries(Open,true); // disambiguate Open element order
   ArraySetAsSeries(High,true); // disambiguate High element order
   ArraySetAsSeries(Low,true); // disambiguate Low element order
   ArraySetAsSeries(Close,true); // disambiguate Close element order
      
   // populate MA_MDATA, MA_SDATA, MA_TDATA up to BUFFLEN - also populate HA data
   atUpdateData(depth);
}


void atDeinitData() {
   // free data of main, signal, and trend chart lines
   logMessage(LOG_PROGRAM,__FUNCTION__);
   delete sbuff;
}


int atUpdateData(const int period) {
   // UPDATE ALL TIMEFRAME 0..3 BUFFERS
   //
   // ALSO UPDATE DRAWN BUFFERS FOR CURRENT TIMEFRAME
   
   // return -1 on error
   
   // logMessage(LOG_PROGRAM,__FUNCTION__);
   
   // FIXME: TIME/TICK SYNC BTW OnTick EVENTS ?
   // NOTE: This does not presently update any values beyond those at index 0
   const int ptf1 = AT_PERIOD1;
   const int ptf2 = AT_PERIOD2;
   const int ptf3 = AT_PERIOD3;
   
   double datum;
   int idx, tframe;

   datetime last, next, ctime;
   bool pushed = false;
   
   // NB: Called from atInitData(), OnTick(), OnTimer()
   
   for(int n = 0; n < period; n++) {
      // assume at least one tframe != AT_TIME_NONE
      for(int tf = 0; tf < N_TFRAME; tf++) {
         tframe=timeframes[tf];
         if (tframe != AT_TIME_NONE) {
            idx = n;
            
            // - time/chart synch maintenance
            last = chart_last[tf];
            next = last + (tframe * TFRAME_SCALE); // tframe is measued in units of minutes
            ctime = iTime(EA_SYMBOL,tframe,n);
            if (next < ctime) {
               // Do not exit iteration - Ensure last index is updated - FIXME despite previous sbuff.pushData()
               if(n > 0) {
                  idx = n-1;   
               } // else idx = 0
            }  else {
               // last >= ctime
               if (!pushed) {
                  sbuff.pushData();
                  pushed = true;
                  logMessage(LOG_PROGRAM, __FUNCTION__ + " push stack");
               }
            }
            chart_last[tf] = ctime;
            
            // - calculations

            // logMessage(LOG_PROGRAM, StringFormat(__FUNCTION__ + " - tframe %d: %d - index %d", tf, tframe, n ));
            // cache DATA_MDATA - moving average onto M data graph
            datum = iMA(EA_SYMBOL,tframe,AT_M_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,idx);
            sbuff.setData(datum,idx,DATA_MDATA,tf);
            
            // cache DATA_SDATA - - moving average onto S data graph
            datum = iMA(EA_SYMBOL,tframe,AT_S_PERIOD,AT_O_PERIOD,AT_MA_METHOD,AT_P_METHOD,idx);
            sbuff.setData(datum,idx,DATA_SDATA,tf);
            
            // cache DATA_TDATA - - moving average onto T data graph
            datum = iMA(EA_SYMBOL,tframe,AT_T_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,idx);
            sbuff.setData(datum,idx,DATA_TDATA,tf);

            // cache Heikin Ashi indicator data - FIXME for duration ... !
            // FIXME : redundant tf, tframe in function call to calcHA
            calcHA(sbuff,tf,period,idx,EA_SYMBOL,tframe); // FIXME: period, n - OPTIMIZE CALC; tf, timeframes[tf] - OPTIMIZE CALL

         }; // tframe != AT_TIME_NONE
      }; // tf iterator
   }; // idx iteraror n
   // logMessage(LOG_PROGRAM,__FUNCTION__ + " END");
   return 2;
}


void atInitTimer() {
   logMessage(LOG_PROGRAM,__FUNCTION__ + " - minutes calc scale " + (string) TFRAME_SCALE);
   EventSetMillisecondTimer(C_TIME);
}


void atDeinitTimer() {
   logMessage(LOG_PROGRAM,__FUNCTION__);
   // NB: DOES NOT modify any open orders
   EventKillTimer();
}


// - Utility - HA buffer impl w/ SimpleStackBuffer


double openRate(const int tfidx, const int idx=0) {
   return sbuff.getData(idx, DATA_HA_OPEN, tfidx);   
}


double closeRate(const int tfidx, const int idx=0) {
   return sbuff.getData(idx, DATA_HA_CLOSE, tfidx);
}



// - Order Orchestration

bool calcMSXover(const int tfidx=0, const int start=0, const int depth=1) { 
   // logMessage(LOG_CALC,__FUNCTION__);
   const double mst = sbuff.getData(start,DATA_MDATA,tfidx); // MA_MDATA[start][tfidx];
   const double mend = sbuff.getData(start+depth,DATA_MDATA,tfidx); // MA_MDATA[start+period][tfidx];
   
   const double sst = sbuff.getData(start,DATA_SDATA,tfidx); // MA_SDATA[start][tfidx];
   const double send = sbuff.getData(start+depth,DATA_SDATA,tfidx); // MA_SDATA[start+period][tfidx];
   
   const double dst = mst - sst;
   const double dend = mend - send;
   
   // FIXME: log call at level LOG_CALC
   
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz));
}


bool calcMTXover(const int tfidx=0, const int start=0, const int depth=1) { 
   // logMessage(LOG_CALC,__FUNCTION__);

   /* e.g
   MST = 5
   MEND = 6
   
   TST = 6
   TEND = 5
   
   DST = 5 - 6 = -2
   DEND = 6 - 5 = 1
   
   */

   const double mst = sbuff.getData(start,DATA_MDATA,tfidx); // MA_MDATA[start][tfidx];
   const double mend = sbuff.getData(start+depth,DATA_MDATA,tfidx); // MA_MDATA[start+period][tfidx];
   
   const double tst = sbuff.getData(start,DATA_TDATA,tfidx); // MA_TDATA[start][tfidx];
   const double tend = sbuff.getData(start+depth,DATA_TDATA,tfidx); // MA_TDATA[start+period][tfidx];
      
   const double dst = mst - tst; // difference at start
   const double dend = mend - tend; // diference at end
   
   // FIXME: log call at level LOG_CALC
   
   // calculating crossover by difference of difference ?
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz));
}


bool calcXoverX(const int start=0, const int depth=1) {
   // DATA
   // {main,signal} xover
   // and {main,trend} xover
   // in no specific order of events
   // witin duration of one chart tick
   // starting at position 0
   //
   // EVENT CALC
   
   // logMessage(LOG_CALC,__FUNCTION__);
   // -iterate across timeframes
   for(int tf = 0; tf < N_TFRAME; tf++) {
      int tframe = timeframes[tf];
      if ((tframe != AT_TIME_NONE)
            && !(calcMSXover(tf,start,depth))
            && !(calcMTXover(tf,start,depth))) {
        return false;
      };
   };
   return true;
}


bool bearTickHA(const int tfidx=0, const int index=0, const int depth=0) {
   // NB This function DOES NOT check for time-series array order
   
   // FIXME: update default HA to use data bufers double[N][4] -- HA_OPEN HA_HIGH HA_LOW HA_CLOSE enum indexes onto dimension [4]
   //
   // FIXME: deine EA HA for this AT using data buffer double[N][4][3] - similar enum onto dimension [4], and timeframes onto dimension [3]
   //
   // NB: IN BOTH IMPLEMENTATIONS, MQL'S SPECIAL DYNAMIC ARRAYS SHOULD NOT BE USED.
   // Rationale:
   // At least in MQL's specialized Dynamic Arrays implementation, it seems MQL inverts the row-major ordering for C++ multidimensional arrays 
   // contrary to what one may presume useful for application prorgrams - as with a dynamic array foo[][1024] in which presumably, MQL would 
   // append "Rows" (e.g additional lists) to the dynamic array, rather than "Columns" (e.g additional list elements)
   // in a sense of an albeit non-canonical contextual reference about C++ i.e http://www.tutorialspoint.com/cplusplus/cpp_multi_dimensional_arrays.htm
   //
   // Considering the pecularity of MQL's Dynamic Arrays implementation if applied to multidimensional arrays, thus - candidly - one might not trust 
   // any of MQL's specialized functions if applied onto multidimensional arrays - assuming the MQL compiler would respect ANSI standard conventions 
   // for C++ at least in regards to generic multidimensional arrays, however oddly it may be interfaced if C++ multdimensional arrays are applied 
   // with MQL's speialized multidimensional arrays. 
   //
   // In short, candid synopsis: MQL's Dynamic Array concept may not be in any ways notably useful for application programs utilizing multidimensional
   // array data. The MQL Dynamic Array concept has a definite novelty for single-dimensional arrays, but should not be relied on as if like a crutch
   // in application design and development.

   
   // so NB: This EA must calculate HA ticks onto all configured timeframes.
   
   const double open = openRate(index+depth,tfidx);
   const double close = closeRate(index,tfidx);
   return (open > close);
}


bool ocReversalHA(const int tfidx=0, const int start=0, const int depth=1) {
   // calculate whether market performs a market trend reversal
   // bear=>bull or bull=>bear starting at index START
   // then to end of PERIOD duration in chart ticks
   //
   // this calculation is performed onto chart tick {open, close} data 
   // at the indicated timeframe, onto the data record for the specified symbol
   // (current chart symbol if NULL)
   
   
   // MAINT NOTE: calcReveral when applied onto conventional candlestick chart data was frequently returning
   // spurious values, as calculated with regards to whether a chart candlestick represented a 'bull' or 'bear' tick,
   // as would then be according to conventional logic for candlestick open/close calculation.
   //
   // The HA indicator, alternately, applies a logical methodology for computation of candlestick open, high, low, and close
   // data in manner uilizing immediate market data for high,low values but using a sequential chart analsis for calculating
   // tick open, close values. The HA indicator may be more typically representative of market trends.
   
   if(depth <= 0) {
      PrintFormat("Program Warning - calcReversal with depth %d", depth); // DEBUG_WARN
      return false;
   } else {
      int tframe = timeframes[tfidx];
      bool btStart = bearTickHA(tfidx, start, depth); // ?
      bool btEnd = bearTickHA(tfidx, start + depth, depth); // ?
      return (btStart != btEnd);
   }
}

int calcReversalX(const int start=0, const int period=1) {
   // calculate whether the market rate has developed to a bear/bull reversal
   //
   // this function applies Heikin Ashi indicator data, for the calculation
   // logMessage(LOG_CALC,__FUNCTION__);
   for(int tf = 0; tf < N_TFRAME; tf++) {
      int tframe = timeframes[tf];
      if ((tframe != AT_TIME_NONE) &&
            !(ocReversalHA(tf,start,period))) {
               return false;
      };
   }; 
   logMessage(LOG_CALC,__FUNCTION__ + " true");
   return true;
}


double calcOCDiff(const int tfidx=0, const int idx=0, const int depth=0) {
   // logMessage(LOG_CALC,__FUNCTION__);

   // FIXME: VERIFY CONSISTENCY OF HA INDICATOR DATA
   
   const double open = sbuff.getData(idx+depth,DATA_HA_OPEN,tfidx);
   const double close = sbuff.getData(idx,DATA_HA_CLOSE,tfidx);
   return MathAbs(open - close);
}


bool calcSpreadX(const int idx=0, const int depth=0) {
   // calculate whether getSpread() <= current diff of market open and close rates (HA)
   // rationale: limit risk before event of open order

   // logMessage(LOG_CALC,__FUNCTION__);
   const double spread = getSpread(EA_SYMBOL); // xglobal EA_SYMBOL scope
   for(int tf = 0; tf < N_TFRAME; tf++) {
      int tframe = timeframes[tf];
      const double diff = calcOCDiff(tf, idx, depth);
      if ((tframe != AT_TIME_NONE) &&
            !(spread <= diff)) {
            // NB: Spread data is not updated to a very fine resolution of time
            logMessage(LOG_CALC,__FUNCTION__ + StringFormat(" false - ! spread %f < diff %f - tframe %d", spread, diff, tframe));
         return false;            
      };
   };
   return true;
   logMessage(LOG_CALC,__FUNCTION__ + " true");
}


bool calcTrend(const bool isSell, const int tfidx, const int idx=0, const int depth=1) {
   // calculate whether the market trend graph - at depth `depth` to index idx for timeframe (tfidx) - is favorable to a buy or sell order
   // logMessage(LOG_CALC,__FUNCTION__);
   double trInitial = sbuff.getData((idx + depth),DATA_TDATA,tfidx);  // was: MA_TDATA[idx + duration][tfidx];
   double trFinal = sbuff.getData(idx,DATA_TDATA,tfidx);  // was: MA_TDATA[idx][tfidx];
   if (isSell) {
      return (trInitial >= trFinal);
   } else {
      return (trInitial < trFinal);
   }
}


bool calcTrendX(const bool isSell, const int idx=0, const int depth=1) {
   // dispatch on AT_CMD_OP, analyzing MA_TDATA[tfidx][0]
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != AT_TIME_NONE ??
   for(int tf = 0; tf < N_TFRAME; tf++) {
      int tframe = timeframes[tf];
      if ((tframe != AT_TIME_NONE)
            && !(calcTrend(isSell, tf, idx, depth))) {
         return false;     
      };
   };
   return true;
}


int calcBuySell(const int tfidx, const int idx=0, const int depth=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   // const int tframe = timerames[tfidx]; // ptf(tfidx);
   // const bool isBear = bearTickHA(tfidx,idx);
   const bool isBear = (openRate(tfidx, idx+depth) > closeRate(tfidx, idx));
   return isBear ? OP_SELL : OP_BUY;
}


bool calcCmdSame(const int cmd1, const int cmd2) {
   if ((cmd1 != -1) && (cmd2 != -1) && (cmd1 != cmd2)) {
      return false;
   } else {
      return true;
   }
}


int calcBuySellX(const int idx=0, const int depth=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   int cmd1 = -1;
   int cmd2 = -1;
   int cmd3 = -1;
    if(AT_PERIOD1 != AT_TIME_NONE) {
       cmd1 = calcBuySell(TF_PERIOD_1, idx, depth);
   } 
   if(AT_PERIOD2 != AT_TIME_NONE) {
       cmd2 = calcBuySell(TF_PERIOD_2, idx, depth);
   } 
   if(AT_PERIOD3 != AT_TIME_NONE) {
       cmd3 = calcBuySell(TF_PERIOD_3, idx, depth);
   } 

   if(!(calcCmdSame(cmd1, cmd2))) {
         return -1;
    } else if (!(calcCmdSame(cmd2, cmd3))) {
         return -1;
    } else if (!(calcCmdSame(cmd1, cmd3))) {
         return -1;
    } else {
         return cmd1; 
    };
}


bool calcTimeOk() { // ?
   const datetime dt_off = order_main_last + (datetime) ORDER_ST_PERIOD;
   const datetime dt_now = TimeCurrent();
   return (dt_now >= dt_off);
}


int atOpenOrder(const int cmd) {
   logMessage(LOG_ORDER,__FUNCTION__);
   // NOTE: VOLUME INTERPRETED IN MEASURE OF LOTS - SEE ALSO libat.mqh
   const string comment=label + " Mechanicaly Opened Order";
   double rate;
   switch(cmd) {
      case OP_BUY: 
         rate = getAskPrice();
         break;
      case OP_SELL:
         rate = getOfferPrice();
         break;
      default:
         rate = -1;
         break;
      }
   const int order = placeOrder(cmd,rate,AT_VOLUME,comment,0); // FIXME: "Magic" number as static program identifier
   if (order > 0) {
      order_main = order;
      order_main_last = TimeCurrent();
   } 
   return order;
}


int calcOrderOpen(const int depth) {
   // if BUYSELLL, SPREAD, TRENDX, and XOVER signals ... for all configured time frames ... => openOrder(...)
   
   // called from OnTimer()
   
   // logMessage(LOG_ORDER,__FUNCTION__);
   
   if(calcTimeOk()) { // NOTE: calcTimeOk() - simple time-rate slowing for order open/close cycles
      // FIXME : calcTimeOk => market rate can still spike sharply & adversely within that duration
      const int cmd = calcBuySellX(0,depth); // market bear/bull tick state must correspond across all configured time frames
      if (cmd == -1) {
         logMessage(LOG_ORDER,__FUNCTION__ + " exit - no consistent buy/sell");
         return -1; // not cmd
      } else {
         const bool spreadx = calcSpreadX(0,depth);
         if (spreadx) {
            const bool xoverx = calcXoverX(0,depth);
            if(xoverx) {
               int order = atOpenOrder(cmd);
               return order;
            } else {
                        logMessage(LOG_ORDER,__FUNCTION__ + " exit - no xover calc");
               return -1; // not xoverx
            }
         } else {
            logMessage(LOG_ORDER,__FUNCTION__ + " exit - spread/OC");
            return -1; // not spreadx
         } 
      } // cmd ok
   } else {
      return -1; // not calcTimeOk()
   }
}


int atCloseOrder() {
   // FIXME: {trend,xover}=>open and {trend,xover}=>close signals beign applied to same market rate tick

   logMessage(LOG_ORDER,__FUNCTION__);
   if (order_main > 0) {
      // CLOSE ORDER AT CURRENT MARKET PRICE, INITIAL NUMBER OF LOTS, 0 SLIPPAGE
      const int retv = closeOrder(order_main); // FIXME: UNIT TEST FOR ORDER CLOSE PRICE SELECTION
      if (retv == 0) {
         order_main = -1;
         order_main_last = TimeCurrent();
         return 0;
      } else {
         return -127;
      }
   } else {
      return -1;
   }
}


int calcOrderClose() {
   // if  AST_REV_ENAB and calcReversal ... for all configured time frames ... => closeOrder
   // if  AST_XOV_ENAB and calcXover ... for all configured time frames ... => closeOrder
   //   
   // called from OnTimer()
   //
   // logMessage(LOG_ORDER,__FUNCTION__);
   
   // NB: This does not check to ensure whether {order,market} is or is not at a rate to an ROI
   
   // FIXME : calcTimeOk => market rate can still spike sharply & adversely within that duration
   
   // FIXME : calcTimeOk not applied in this function

   // Novel Idea for updating order close logic:
   // * if market rate is spiking adversely, close order
   // * else leave order open until next && REV_ENAB REVERSAL , && XOV_ENAB XOVER
   if(AST_REV_ENAB && calcReversalX(0,1)) { // FIXME: calc-close calc depth always 1
      // FIXME: update calcReversal => calcOpenReversal, calcCloseReversal
      logMessage(LOG_ORDER,__FUNCTION__ + " close - reversal");
      return atCloseOrder();
   } else if (AST_XOV_ENAB && calcXoverX(0,1)) { // FIXME: calc-close calc depth always 1
      // FIXME: update calcXover => calcOpenXover, calcCloseXover ?
      // or calcOpenXover, calcStoplossXover, calcROIXover ?
      logMessage(LOG_ORDER,__FUNCTION__ + " close - xover");
      return atCloseOrder();
   } else {
      return 0;
   }
}



// - Event Handling Functions, MQL

void OnInit() {
   logMessage(LOG_PROGRAM,__FUNCTION__);

   EA_SYMBOL = ChartSymbol();
      
   // NB: global calc_period (FIXME)
   calc_period = CALC_DEPTH;
   const int init_depth = CALC_DEPTH * MathMax(AT_M_PERIOD,MathMax(AT_S_PERIOD + AT_O_PERIOD, AT_T_PERIOD));

   atValidateInputs();
   // - Init Visual Properties (NA for this EA?)
   IndicatorShortName(StringFormat("%s(%s)", label, EA_SYMBOL));
   // - Init Data
   // HERE: Initialize to depth of calc_period
   atInitData(init_depth); 
   // Init Timer
   atInitTimer();
   
   // FIXME: return nonzero if any of the previous functions failed
   // thus allowing failover to OnDeinit
}


void OnDeinit(const int reason) {
   // logMessage(LOG_PROGRAM, __FUNCTION__ + " " + (string) reason);

   // see also: "Uninitialization Reason Codes" MQL4 ref

   // Free Data - ONLY IF PROGRAM IS COMPLETELY EXITING
   if(deinitClose(reason)) {
      logMessage(LOG_PROGRAM, __FUNCTION__ + " " + (string) reason + " close");
      atDeinitData();
   } else {
      logMessage(LOG_PROGRAM, __FUNCTION__ + " " + (string) reason + " reinit");
   }
   atDeinitTimer();
}


// NB - WHACKY PLATFORM - OnTick is being called WAY TOO OFTEN, before the chart has even advanced

void OnTick() {
   // calcHA(calc_period,0,Open,High,Low,Close); // original logic
   // - logic as applied with STACKBUFF - calcHA handled in atUpdateData
   
   // HERE, push one new tick of data
   // atUpdateData(calc_period);
   
   const datetime dt_now = TimeCurrent();
   datetime dt_next;
   bool update = false;
   for(int tf = 0; tf < N_TFRAME; tf++) {
      int tframe = timeframes[tf];
      if ((tframe != AT_TIME_NONE) && !update) {
         dt_next = ontick_last + (tframe * TFRAME_SCALE); // NB: tframe is defined in units of minutes
         update = dt_now >= dt_next; // FIXME: Fold this into the timeOk calculation         
         // FIXME: also record a dt_last field for each timeframe? - so as to push data on timeframe advance, or update current data when not on timeframe advance
      };
   };
   if(update) {
      // logMessage(LOG_PROGRAM, __FUNCTION__ + " advance");
      // FIXME: only advance for specific timeframes in which dt_next >= dt_now
      atUpdateData(calc_period); // NB: depth 1 may not apply for every configured timeframe
      ontick_last = dt_now;
   }
}


void OnTimer() {
   // logMessage(LOG_PROGRAM, __FUNCTION__);

   // This must ensure the graph data is already avaialble - FIXME return if OnCalculate not called yet ?
   int retv;
   // HERE, only update the latest data tick
   retv = atUpdateData(0);
   
   if(retv < 0) { 
      atHandleError(); 
      return;
   }

   if(order_main > 0) {
      retv = calcOrderClose(); // CONDITIONALLY CLOSES ORDER 
   } else if (AT_ALWAYS && !AT_ONCE) {
      const int cmd = calcBuySell(0,0,calc_period); // FIXME: Timeframe 0 must be configured
      retv = atOpenOrder(cmd);
      AT_ONCE = true;
   } else {
      retv = calcOrderOpen(calc_period); // CONDITIONALLY CALCULATES ORDER OPEN CMD, -1 IF NO OPEN
      if(retv < 0) {
         return; // no cmd - FIXME: and no error ?
      } else {
         atOpenOrder(retv);
      }
   }
   if(retv < 0) { 
      atHandleError(); 
      return;
   }
}
