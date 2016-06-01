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

#include "libea.mqh"
#include "libat.mqh"

// - EA Program Parameters

const string label = "AT01";
// - order_main 
// if (order_main > 0), records the ticket number for the main order 
// else indicates that no main order is open
int order_main = -1;

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
input ENUM_MA_METHOD       AT_MA_METHOD = MODE_LWMA; // Moving Average method for Indicator Graphs
input ENUM_APPLIED_PRICE   AT_P_METHOD = PRICE_TYPICAL; // Rate Calculation method for Indicator Graphs
input bool AST_REV_ENAB = true; // Enable algorithmic reversal stop-loss
input bool AST_XOV_ENAB = true; // Enable algorithmic crossover stop-loss
input int C_TIME   = 200;  // Duration (milliseconds) for calculation timer



// - Utility

void atHandleError() {
   // FIXME: NAIVE IMPLEMENTATION
   ExpertRemove();
}

void atInitData() {
   // initialize main, signal, and trend chart lines
   
   // FIXME: TRANSPOSE INPUT VALUES
   
   // FIXME: INITIALIZE BUFERS
   // FIXME: POPULATE BUFFERS (MA x 3)
}

void atDeinitData() {
   // free data of main, signal, and trend chart lines
   
   // FIXME: FREE BUFERS
}

void atInitTimer() {
   EventSetMillisecondTimer(C_TIME);
}

void atDeinitTimer() {
   // NB: DOES NOT modify any open orders
   EventKillTimer();
}

// - Data


// - Order Orchestration

int calcXover() {
   // DATA
   // {main,signal} xover
   // and {main,trend} xover
   // in no specific order of events
   // witin duration of one chart tick
   // starting at position 0
   //
   // EVENT
   // ...
   
   // FIXME: TRANSPOSE INPUT VALUES
}

int calcReversal(const int start=0, const int period=0) {
   // DATA
   bool rev = ocReversal(start,period); 
   // EVENT ...
   
   // FIXME: TRANSPOSE INPUT VALUES
}

int calcOrderOpen() {
   // if XOVER, SPREAD, TRENDX => openOrder(...)
   
   // FIXME: TRANSPOSE INPUT VALUES
}

int calcOrderClose() {
   // if AST..REV and calcReversal => closeOrder
   
   // FIXME: TRANSPOSE INPUT VALUES
   
   // if AST..XOVER an calcXover => closeOrder

   // FIXME: TRANSPOSE INPUT VALUES
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

int OntInit() {
   // Init Visual Properties
   IndicatorShortName(label);
   // Init Data
   IndicatorDigits(Digits+2);
   atInitData();
   // Init Timer
   atInitTimer();
}

int OnDeinit() {
   // Free Data
   atDeinitData();
   // Close Timer
   atDeinitTimer();
}

int OnTimer() {
   int retv;
   if(order_main > 0) {
      retv = calcOrderClose();
   } else {
      retv = calcOrderOpen();
   }
   if(retv < 0) { 
      atHandleError(); 
   } else { 
      return retv; 
   }
}