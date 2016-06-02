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

enum ENUM_TF_PERIOD {
   // Timeframe period as configured in input - see also ptf(..)
   TF_PERIOD_1 = 0,
   TF_PERIOD_2 = 1,
   TF_PERIOD_3 = 2
};

enum AT_TIME {
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


// - EA Program Parameters

const string label = "AT01";
// - order_main 
// if (order_main > 0), records the ticket number for the main order 
// else indicates that no main order is open
int order_main = -1;
datetime order_main_last; // datetime of last event onto order_main
int calc_period;
string EA_SYMBOL;
int AT_ONCE = false; // applied when AT_ALWAYS

/* // unused - metadata value
datetime dtzero_p1;
datetime dtzero_p2;
datetime dtzero_p3;
*/

#define BUFFLEN 1024
double MA_MDATA[BUFFLEN][3]; // main chart data - time frames 0, 1, 2
double MA_SDATA[BUFFLEN][3]; // signal chart data - time frames 0, 1, 2
double MA_TDATA[BUFFLEN][3]; // trend chart data - time frames 0, 1, 2



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

int ptf(const ENUM_TF_PERIOD tfidx) {
   // return timeframe for chart-local period record
   //
   // implicitly coerces return value to int type
   switch(tfidx) {
      case TF_PERIOD_1:
         return AT_PERIOD1;
      case TF_PERIOD_2:
         return AT_PERIOD2;
      case TF_PERIOD_3:
         return AT_PERIOD3;
      default:
         return -1;
   }
}

void atInitData() {
   // called again after EA change

   // initialize main, signal, and trend data buffers (drawn)
     
   // NB: SetIndexBuffer() not applicable for double[][]

   // NB: SetIndexBuffer N/A in EA type programs
   //
   // FIXME: Try out the simple array-as-stack implementation in libea.mqh ?
   // update for each MA data buffer
   logMessage(LOG_PROGRAM,__FUNCTION__);
   IndicatorDigits(Digits+2);
   // ArraySetAsSeries(MA_MDATA,true);
   // ArraySetAsSeries(MA_SDATA,true);
   // ArraySetAsSeries(MA_TDATA,true);
   // ArrayFill(MA_MDATA,0,BUFFLEN,dblz);
   // ArrayFill(MA_SDATA,0,BUFFLEN,dblz);
   // ArrayFill(MA_TDATA,0,BUFFLEN,dblz);
   
   /*
   const int ptf1 = AT_PERIOD1;
   const int ptf2 = AT_PERIOD2;
   const int ptf3 = AT_PERIOD3;
   */
   
   // populate MA_MDATA, MA_SDATA, MA_TDATA up to BUFFLEN
   atUpdateData(calc_period); // update only at n = 0 - may be all it needs in the program itself   
}

void atDeinitData() {
   // free data of main, signal, and trend chart lines
   
   // FIXME: FREE BUFERS N/A for double[][]
   // assume that the platform will free memory otherwise, after program exit
   logMessage(LOG_PROGRAM,__FUNCTION__);
   
   // NB: This function was originally called from OnDeinit() in all instances.
   // OnDeinit() may be called after an EA is updated, or after the active
   // char window's timeframe is changed - evets at which it would not be
   // advisable to ArrayFree these values.
   ArrayFree(MA_MDATA);
   ArrayFree(MA_SDATA);
   ArrayFree(MA_TDATA);
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
   // FIXME: Should update buffer to a stop period configured with an input value e.g 5
   for(int n = 0; n < period; n++) { // 2 because 2 points in analysis
      // FIXME: This program-historic data buffering not very well needed in a non-visualized EA
      MA_MDATA[n][0] = iMA(EA_SYMBOL,ptf1,AT_M_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n); // X array out of bounds ? after chart timeframe change ?
      MA_MDATA[n][1] = iMA(EA_SYMBOL,ptf2,AT_M_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n);
      MA_MDATA[n][2] = iMA(EA_SYMBOL,ptf3,AT_M_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n);
      
      MA_SDATA[n][0] = iMA(EA_SYMBOL,ptf1,AT_S_PERIOD,AT_O_PERIOD,AT_MA_METHOD,AT_P_METHOD,n);
      MA_SDATA[n][1] = iMA(EA_SYMBOL,ptf2,AT_S_PERIOD,AT_O_PERIOD,AT_MA_METHOD,AT_P_METHOD,n);
      MA_SDATA[n][2] = iMA(EA_SYMBOL,ptf3,AT_S_PERIOD,AT_O_PERIOD,AT_MA_METHOD,AT_P_METHOD,n);
      
      MA_TDATA[n][0] = iMA(EA_SYMBOL,ptf1,AT_T_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n);
      MA_TDATA[n][1] = iMA(EA_SYMBOL,ptf2,AT_T_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n);
      MA_TDATA[n][2] = iMA(EA_SYMBOL,ptf3,AT_T_PERIOD,0,AT_MA_METHOD,AT_P_METHOD,n);
   }
   // logMessage(LOG_PROGRAM,__FUNCTION__ + " END");
   return 2;
}

void atInitTimer() {
   logMessage(LOG_PROGRAM,__FUNCTION__);
   EventSetMillisecondTimer(C_TIME);
}

void atDeinitTimer() {
   logMessage(LOG_PROGRAM,__FUNCTION__);
   // NB: DOES NOT modify any open orders
   EventKillTimer();
}

/* // unused utility
void updDTZero() {
   if (AT_PERIOD1 != AT_TIME_NONE) { dtzero_p1 = iTime(EA_SYMBOL, AT_PERIOD1, 0); }
   if (AT_PERIOD2 != AT_TIME_NONE) { dtzero_p2 = iTime(EA_SYMBOL, AT_PERIOD2, 0); }
   if (AT_PERIOD3 != AT_TIME_NONE) { dtzero_p3 = iTime(EA_SYMBOL, AT_PERIOD3, 0); }
}
*/


// - Order Orchestration

bool calcMSXover(const ENUM_TF_PERIOD tfidx, const int start=0, const int period=1) { 
   // logMessage(LOG_CALC,__FUNCTION__);
   const double mst = MA_MDATA[start][tfidx];
   const double mend = MA_MDATA[start+period][tfidx];
   
   const double sst = MA_SDATA[start][tfidx];
   const double send = MA_SDATA[start+period][tfidx];
   
   const double dst = mst - sst;
   const double dend = mend - send;
   
   // FIXME: log call at level LOG_CALC
   
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz));
}

bool calcMTXover(const ENUM_TF_PERIOD tfidx, const int start=0, const int period=1) { 
   // logMessage(LOG_CALC,__FUNCTION__);

   /* e.g
   MST = 5
   MEND = 6
   
   TST = 6
   TEND = 5
   
   DST = 5 - 6 = -2
   DEND = 6 - 5 = 1
   
   */
   
   const double mst = MA_MDATA[start][tfidx];
   const double mend = MA_MDATA[start+period][tfidx];
   
   const double tst = MA_TDATA[start][tfidx];
   const double tend = MA_TDATA[start+period][tfidx];
   
   const double dst = mst - tst; // difference at start
   const double dend = mend - tend; // diference at end
   
   // FIXME: log call at level LOG_CALC
   
   // calculating crossover by difference of difference ?
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz));
}

bool calcXoverX(const int start=0, const int period=1) {
   // DATA
   // {main,signal} xover
   // and {main,trend} xover
   // in no specific order of events
   // witin duration of one chart tick
   // starting at position 0
   //
   // EVENT CALC
   
   logMessage(LOG_CALC,__FUNCTION__);
   if((AT_PERIOD1 != AT_TIME_NONE) 
       && !(calcMSXover(TF_PERIOD_1,start,period))
       && !(calcMTXover(TF_PERIOD_1,start,period))) {
       return false;
   } // else log ?
   if((AT_PERIOD2 != AT_TIME_NONE) 
       && !(calcMSXover(TF_PERIOD_2,start,period))
       && !(calcMTXover(TF_PERIOD_2,start,period))) {
       return false;
   } // else log ?
   if((AT_PERIOD3 != AT_TIME_NONE) 
       && !(calcMSXover(TF_PERIOD_3,start,period))
       && !(calcMTXover(TF_PERIOD_3,start,period))) {
       return false;
   } else {
      // FIXME: Log
      return true;
   }
}

int calcReversal(const ENUM_TF_PERIOD tfidx, const int start=0, const int duration=1) {
   // logMessage(LOG_CALC,__FUNCTION__);
   
   // FIXME: Define ocReversalHA and apply here - use HA derived open/close, bear/bull data 
   return ocReversal(start,duration,EA_SYMBOL,ptf(tfidx));
}

int calcReversalX(const int start=0, const int period=1) {
   // DATA
   // e.g bool rev = 
   // EVENT CALC
   
   logMessage(LOG_CALC,__FUNCTION__);
   
   if((AT_PERIOD1 != AT_TIME_NONE) 
       && !(calcReversal(TF_PERIOD_1,start,period))) {
       return false;
   } 
   if((AT_PERIOD2 != AT_TIME_NONE) 
       && !(calcReversal(TF_PERIOD_2,start,period))) {
       return false;
   } 
   if((AT_PERIOD3 != AT_TIME_NONE) 
       && !(calcReversal(TF_PERIOD_3,start,period))) {
       return false;
   } else {
   // FIXME: Log
      return true;
   }
}

double calcOCDiff(const ENUM_TF_PERIOD tfidx, const int idx=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   
   const double open = iOpen(EA_SYMBOL, ptf(tfidx), idx);
   const double close = iClose(EA_SYMBOL, ptf(tfidx), idx);
   return MathAbs(open - close);
}


bool calcSpread(const ENUM_TF_PERIOD tfidx, const int idx=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   
   const double spread = getSpread(EA_SYMBOL);
   const double ocdiff = calcOCDiff(tfidx,idx);
   return (spread <= ocdiff);
}


bool calcSpreadX(const int idx=0) {
   // getSpread() <= previous OC diff ?
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != AT_TIME_NONE ??
   
   logMessage(LOG_CALC,__FUNCTION__);
   
   if((AT_PERIOD1 != AT_TIME_NONE) 
       && !(calcSpread(TF_PERIOD_1, idx))) {
       return false;
   } 
   if((AT_PERIOD2 != AT_TIME_NONE) 
       && !(calcSpread(TF_PERIOD_2, idx))) {
       return false;
   } 
   if((AT_PERIOD3 != AT_TIME_NONE) 
       && !(calcSpread(TF_PERIOD_3, idx))) {
       return false;
   } else {
   // FIXME: Log
      return true;
   }
}

bool calcTrend(const bool isSell, const ENUM_TF_PERIOD tfidx, const int idx=0, const int duration=1) {
   double trInitial = MA_TDATA[idx + duration][tfidx];
   double trFinal = MA_TDATA[idx][tfidx];
   
   // logMessage(LOG_CALC,__FUNCTION__);
   
   if (isSell) {
      return (trInitial >= trFinal);
   } else {
      return (trInitial < trFinal);
   }
}

bool calcTrendX(const bool isSell, const int idx=0, const int duration=1) {
   // dispatch on AT_CMD_OP, analyzing MA_TDATA[tfidx][0]
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != AT_TIME_NONE ??
   
   logMessage(LOG_CALC,__FUNCTION__);
   if((AT_PERIOD1 != AT_TIME_NONE) 
       && !(calcTrend(isSell, TF_PERIOD_1, idx, duration))) {
       return false;
   } 
   if((AT_PERIOD2 != AT_TIME_NONE) 
       && !(calcTrend(isSell, TF_PERIOD_2, idx, duration))) {
       return false;
   } 
   if((AT_PERIOD3 != AT_TIME_NONE) 
       && !(calcTrend(isSell, TF_PERIOD_3, idx, duration))) {
       return false;
   } else {
   // FIXME: Log
      return true;
   }
}

int calcBuySell(const ENUM_TF_PERIOD tfidx, const int idx=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   const int tframe = ptf(tfidx);
   const bool isBear = bearTick(idx,EA_SYMBOL,tframe);
   return isBear ? OP_SELL : OP_BUY;
}


int calcBuySell(const int idx=0) {
   // logMessage(LOG_CALC,__FUNCTION__);
   const int tframe = PERIOD_CURRENT;
   const bool isBear = bearTick(idx,EA_SYMBOL,tframe);
   return isBear ? OP_SELL : OP_BUY;
}


int calcBuySellX(const int idx=0) {
   logMessage(LOG_CALC,__FUNCTION__);
   int cmd1 = -1;
   int cmd2 = -1;
   int cmd3 = -1;
    if(AT_PERIOD1 != AT_TIME_NONE) {
       cmd1 = calcBuySell(TF_PERIOD_1,idx);
   } 
   if(AT_PERIOD2 != AT_TIME_NONE) {
       cmd2 = calcBuySell(TF_PERIOD_2,idx);
   } 
   if(AT_PERIOD3 != AT_TIME_NONE) {
       cmd3 = calcBuySell(TF_PERIOD_3,idx);
   } 

   if((cmd2 != -1) && (cmd1 != -1) && (cmd2 != cmd1)) {
         return -1;
    } else if((cmd2 != -1) && (cmd3 != -1) && (cmd2 != cmd3)) {
         return -1;
    } else if((cmd3 != -1) && (cmd1 != -1) && (cmd3 != cmd1)) {
         return -1;
    } else {
       // COMPARE TO AT_CMD_OP - REDUNDANT considering platform EA configuration options
/*       if(((cmd1 == OP_BUY)
            && ((AT_CMD_OP == OP_AT_BUY) || (AT_CMD_OP == OP_AT_ANY)))
           ||  ((cmd1 == OP_SELL)
                  && ((AT_CMD_OP == OP_AT_SELL) || (AT_CMD_OP == OP_AT_ANY)))) {
*/
         return cmd1; 
/*       } else {
         return -1;
       }
*/      
    }
}

bool calcTimeOk() {
   const datetime dt_off = (int) order_main_last + ORDER_ST_PERIOD;
   const datetime dt_now = TimeCurrent();
   return (dt_now > dt_off);
}

int atOpenOrder(const int cmd) {

   logMessage(LOG_ORDER,__FUNCTION__);

   // FIXME: VOLUME INTERPRETED IN UNIT OF LOTS - SEE ALSO libat.mqh
   const string comment=label + " Mechanicaly Opened Order";
   // const double rate = ... // calculated in placeOrder
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

int calcOrderOpen() {
   // if BUYSELLL, SPREAD, TRENDX, XOVER ... for all configured time frames ... => openOrder(...)
   
   // called from OnTimer()
   
   // logMessage(LOG_ORDER,__FUNCTION__);
   
   if(calcTimeOk()) {
      const int cmd = calcBuySellX(0); // market bear/bull tick state must correspond across all configured time frames
      if (cmd == -1) {
         return -1; // not cmd
      } else {
         const bool spreadx = calcSpreadX(0);
         if (spreadx) {
            const bool xoverx = calcXoverX(0,CALC_DEPTH);
            if(xoverx) {
               int order = atOpenOrder(cmd);
               return order;
            } else {
               return -1; // not xoverx
            }
         } else {
            return -1; // not spreadx
         } 
      } // cmd ok
   } else {
      return -1; // not calcTimeOk()
   }
}

int atCloseOrder() {
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
   logMessage(LOG_ORDER,__FUNCTION__);
   
   // NB: This does not check to ensure whether {order,market} is or is not at a rate providing an ROI
   if(AST_REV_ENAB && calcReversalX(0,1)) {
      return atCloseOrder();
   } else if (AST_XOV_ENAB && calcXoverX(0,1)) {
      return atCloseOrder();
   } else {
      return 0;
   }
}

// - Event Handling Functions, MQL

void OnInit() {
   logMessage(LOG_PROGRAM,__FUNCTION__);

   EA_SYMBOL = ChartSymbol();
      
   calc_period = CALC_DEPTH * MathMax(AT_M_PERIOD,MathMax(AT_S_PERIOD + AT_O_PERIOD, AT_T_PERIOD));

   atValidateInputs();
   // - Init Visual Properties (NA for this EA?)
   IndicatorShortName(StringFormat("%s(%s)", label, EA_SYMBOL));
   // - Init Data
   atInitData();
   // Init Timer
   atInitTimer();
}

void OnDeinit(const int reason) {
   logMessage(LOG_PROGRAM, __FUNCTION__ + " " + (string) reason);

   // see also: "Uninitialization Reason Codes" MQL4 ref

   // Free Data - ONLY IF PROGRAM IS COMPLETELY EXITING
   // atDeinitData();
   // Close Timer
   atDeinitTimer();
}

void OnTick() {
   atUpdateData(calc_period);
}

void OnTimer() {
// FIXME: log with level LOG_PROGRAM
   // logMessage(LOG_PROGRAM, __FUNCTION__);

   // NB: This must ensure the graph data is already avaialble - return if OnCalculate not called yet
   int retv;
   retv = atUpdateData(0);
   
   if(retv < 0) { 
      atHandleError(); 
      return;
   }
   // Not being called : calcOrderOpen ?
   if(order_main > 0) {
      retv = calcOrderClose(); // CONDITIONALLY CLOSES ORDER 
   } else if (AT_ALWAYS && !AT_ONCE) {
      const int cmd = calcBuySell();
      retv = atOpenOrder(cmd);
      AT_ONCE = true;
   } else {
      retv = calcOrderOpen(); // CONDITIONALLY CALCULATES ORDER OPEN CMD, -1 IF NO OPEN
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
