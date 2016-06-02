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
#property script_show_inputs
#property indicator_chart_window
#property indicator_buffers 3 // number of drawn buffers ?

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

// - EA Custom Data Types

enum ENUM_AT_CMD {
   OP_AT_SELL, // Sell
   OP_AT_BUY,  // Buy
   OP_AT_ANY   // Sell Or Buy
};


// - EA Input Parameters

input double AT_VOLUME=0.02;   // Volume for mechanically opened orders
input ENUM_AT_CMD AT_CMD_OP = OP_AT_SELL; // Activate autotrading for Sell, Buy, or Any
input int AT_M_PERIOD = 5;  // Period for MA of Main Indicator Graph
input int AT_S_PERIOD = 10; // Period for MA of Signal Indicator Graph
input int AT_O_PERIOD = 5;  // Offset for MA of Signal Indicator Graph
input int AT_T_PERIOD = 20; // Period for MA of Trend Indicator Graph
input ENUM_MA_METHOD       AT_MA_METHOD = MODE_LWMA; // MA method for Indicator Graphs
input ENUM_APPLIED_PRICE   AT_P_METHOD = PRICE_TYPICAL; // Rate Calculation method for Indicator Graphs
input bool AST_REV_ENAB = true; // Enable algorithmic reversal stop
input bool AST_XOV_ENAB = true; // Enable algorithmic crossover stop
input int C_TIME   = 200;  // Duration (milliseconds) for calculation timer
input ENUM_TIMEFRAMES AT_PERIOD1 = PERIOD_M1;   // Primary Period for Event Calculations
input ENUM_TIMEFRAMES AT_PERIOD2 = PERIOD_M5;   // Secondary Period for Event Calculations
input ENUM_TIMEFRAMES AT_PERIOD3 = PERIOD_M15;  // Tertiary Period for Event Calculations

// FIXME: ENSURE DATA REINITIALIZED AFTER CHANGE IN AT_PERIOD1, AT_PERIOD2, AT_PERIOD3
// I.E WHEN EA RESTARTED AFTER PREVIOUS DEINIT DUE TO REASON_PARAMETERS

// NB: INTERPRET AT_PERIOD1 .. AT_PERIOD3 == PERIOD_CURRENT as meaning "UNDEFINED" - alternate to defining another enum type
// NB: At least one of AT_PERIOD1, AT_PERIOD2, AT_PERIOD3  must be != PERIOD_CURRENT

// NB: If both AST_REV_ENAB and AST_XOV_ENAB = false, orders will not be mechanically closed with this program


// - EA Program Parameters

const string label = "AT01";
// - order_main 
// if (order_main > 0), records the ticket number for the main order 
// else indicates that no main order is open
int order_main = -1;


double MA_MDATA[2][]; // main chart data at time frames 0, 1, 2
double MA_SDATA[2][]; // signal chart data at time frames 0, 1, 2
double MA_TDATA[2][]; // trend chart data at time frames 0, 1, 2

// - Utility

int atHandleError() {
   // FIXME: NAIVE IMPLEMENTATION
   const int code = GetLastError();
   PrintFormat("Error [%d] : %s ",code , ErrorDescription(code));
   //   _StopFlag = true; // NB: CANNOT SET _StopFlag. MQL4 Documentation suggest otherwise ?
   ExpertRemove();
   return code;
}

void atValidateInputs() {
   if( (AT_PERIOD1 == PERIOD_CURRENT) 
        && (AT_PERIOD2 == PERIOD_CURRENT) 
        && (AT_PERIOD3 == PERIOD_CURRENT)) {
      Print("Invalid Inputs - AT01 periods 1, 2, 3 are set to PERIOD_CURRENT");
      ExpertRemove();
   }
}

void atInitData() {
   // initialize main, signal, and trend data buffers (drawn)
     
   // NB: SetIndexBuffer() not applicable for double[][]

   // FIXME: SetIndexBuffer N/A in EA type programs
   // initDrawBuffer(MA_MDATA0,0,bufflen);
   // initDrawBuffer(MA_SDATA0,1,bufflen);
   // initDrawBuffer(MA_TDATA0,2,bufflen);
   // initDrawBuffer(MA_MDATA1,0,bufflen);
   // initDrawBuffer(MA_SDATA1,1,bufflen);
   // initDrawBuffer(MA_TDATA1,2,bufflen);
   // initDrawBuffer(MA_MDATA2,0,bufflen);
   // initDrawBuffer(MA_SDATA2,1,bufflen);
   // initDrawBuffer(MA_TDATA2,2,bufflen);
   
   // FIXME: Try out the simple array-as-stack implementation in libea.mqh ?
}

void atDeinitData() {
   // free data of main, signal, and trend chart lines
   
   // FIXME: FREE BUFERS
}

int atUpdateData() {
   // UPDATE ALL TIMEFRAME 0..3 BUFFERS
   //
   // ALSO UPDATE DRAWN BUFFERS FOR CURRENT TIMEFRAME
}

void atInitTimer() {
   EventSetMillisecondTimer(C_TIME);
}

void atDeinitTimer() {
   // NB: DOES NOT modify any open orders
   EventKillTimer();
}

// - Order Orchestration

bool calcMSXover(const int tfidx, const int start=0, const int period=1) { 
   const double mst = MA_MDATA[tfidx][start];
   const double mend = MA_MDATA[tfidx][start+period];
   
   const double sst = MA_SDATA[tfidx][start+period];
   const double send = MA_SDATA[tfidx][start+period];
   
   const double dst = mst - sst;
   const double dend = mend - send;
   
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz);
}

bool calcMTXover(const int tfidx, const int start=0, const int period=1) { 
   const double mst = MA_MDATA[tfidx][start];
   const double mend = MA_MDATA[tfidx][start+period];
   
   const double tst = MA_TDATA[tfidx][start+period];
   const double tend = MA_TDATA[tfidx][start+period];
   
   const double dst = mst - tst;
   const double dend = mend - tend;
   
   return ((dst <= dblz && dend > dblz) || (dst > dblz && dend <= dblz);
}

bool calcXover(const int tfidx, const int start=0, const int period=1) {
   // DATA
   // {main,signal} xover
   // and {main,trend} xover
   // in no specific order of events
   // witin duration of one chart tick
   // starting at position 0
   //
   // EVENT
   // ...
   return ( calcMSXover(tframe,start,period) && calcMTXover(tframe,start,period) ); 
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != PERIOD_CURRENT
}

int calcReversal(const int tfidx, const int start=0, const int period=1) {
   // DATA
   bool rev = ocReversal(start,period); 
   // EVENT ...
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != PERIOD_CURRENT
}

bool calcSpreadX(const int tfidx) {
   // getSpread() <= previous OC diff ?
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != PERIOD_CURRENT ??
}

bool calcTrendX(const int tfidx) {
   // dispatch on AT_CMD_OP, analyzing MA_TDATA[tfidx][0]
   // CALL FOR any tfidx 0,1,2 for which the corresponding AT_PERIOD1..AT_PERIOD3 != PERIOD_CURRENT ??
}

int calcOrderOpen() {
   // if XOVER, SPREAD, TRENDX ... for all configured time frames ... => openOrder(...)
   
}

int calcOrderClose() {
   // if  AST_REV_ENAB and calcReversal ... for all configured time frames ... => closeOrder
   
   // if  AST_XOV_ENAB and calcXover ... for all configured time frames ... => closeOrder

}

int atOpenOrder(const bool buy) {
   // FIXME: VOLUME INTERPRETED IN UNIT OF LOTS - SEE ALSO libat.mqh
   const double volume = pipsToLots(AT_VOLUME); // FIME: TO DO
   const string comment=label + " Mechanicaly Opened Order";
   // const double rate = ... // calculated in placeOrder
   const int order = placeOrder(buy,volume,comment,0); // FIXME: "Magic" number as static program identifier
   if (order > 0) {
      order_main = order;
   } 
   return order;
}

int atCloseOrder() {
   if (order_main > 0) {
      // CLOSE ORDER AT CURRENT MARKET PRICE, INITIAL NUMBER OF LOTS, 0 SLIPPAGE
      closeOrder(order_main); // FIXME: UNIT TEST FOR ORDER CLOSE PRICE SELECTION
   } else {
      return -1;
   }
}

// - Event Handling Functions, MQL

void OntInit() {
   atValidateInputs();
   // Init Visual Properties
   IndicatorShortName(label);
   // Init Data
   IndicatorDigits(Digits+2);
   atInitData();
   // Init Timer
   atInitTimer();
}

void OnDeinit(const int reason) {
   // see also: "Uninitialization Reason Codes" MQL4 ref

   // Free Data
   atDeinitData();
   // Close Timer
   atDeinitTimer();
}

void OnTimer() {
   // NB: This must ensure the graph data is already avaialble - return if OnCalculate not called yet
   int retv;
   retv = atUpdateData();
   if(retv < 0) { 
      atHandleError(); 
      return;
   }
   if(order_main > 0) {
      retv = calcOrderClose();      
   } else {
      retv = calcOrderOpen();
   }
   if(retv < 0) { 
      atHandleError(); 
   }
}
