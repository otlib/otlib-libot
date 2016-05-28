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
#property description "Autotrader Utility Header"
#property version   "1.00"
#property strict
#property library // FIXME TMP

#include "libea.mqh"

// FIXME: Test in realtime paper trading (markets closed on weekends)

int cmdFor(const bool buy, const double rate) {
   // FIXME: Documentation
   // "Buy" executes at "Ask" price
   // "Sell" executes at "Offer" price
   
   // const double sl = getStoplevel();
   // FIXME: adjust stop/limit order calc for market stop level, returning -1 if INVALID
   if(buy) {
      const double mkt = getAskPrice();
      // FIXME: Expand on OTLIB documentation
      if(rate > mkt) {
         // FIXME implement
      } else {
         // FIXME implement
      } 
   } else {
      const double mkt = getOfferPrice();
      // FIXME: Expand on OTLIB documentation
      if(rate > mkt) {
         // FIXME implement
      } else {
         // FIXME implement
      }
   }
   return -1; // FIXME tmp
}

double placeOrder(const bool buy, const double volume, const string comment=NULL, const int idx=0) {
// place an order to open at current market rate, on current currency symbol
   // FIXME struct MqlTradeRequest not documented (MQL4)
   const string symbol = getCurrentSymbol();
   double mkt;
   int cmd;
   if(buy) {
      mkt = getAskPrice();
      cmd = OP_BUY;
   } else {
      mkt = getOfferPrice();
      cmd = OP_SELL;
   }
   // NB: no slippage rate, SL, TP, timed expiration
   const double orderNr = OrderSend(symbol,cmd,volume,mkt,0,0,0,comment,idx);
   // NB: orderNr < 0 on failed call to OrderSend
   return orderNr;
}

double placeOrder(const bool buy, const double rate, const double volume, const string comment=NULL, const int idx=0) {
// place a forward order to open at 'rate', on current currency symbol
// NB: getStopLevel()
   const string symbol = getCurrentSymbol();
   const int cmd = cmdFor(buy,rate);
   // NB: no slippage rate, SL, TP, timed expiration
   const double orderNr = OrderSend(symbol,cmd,volume,rate,0,0,0,comment,idx);
   // NB: orderNr < 0 on failed call to OrderSend
   return orderNr;
}
