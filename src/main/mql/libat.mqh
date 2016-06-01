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

// - Utility Functions - Order Orchestration

int orderTick(const int tkt, const int tframe=0, const bool exact=false) {
  const bool selp = OrderSelect(tkt,SELECT_BY_TICKET);
  if (selp) {
   // NB: Following functions use the currently selected ticket, "current thread"
   const datetime dt = OrderOpenTime(); 
   const string sym = OrderSymbol();
   return iBarShift(sym,tframe,dt,exact); // may return -1
  } else {
   return -1;
  }
}


int cmdFor(const bool buy, const double rate) {
   // FIXME: Documentation
   
   // Logic:
   //
   // "Buy" executes at "Ask" price
   // "Sell" executes at "Offer" price
   //
   // Buy @ higher than market price + mkt stoplevel = Buy Stop
   // Sell @ lower than market price - mkt stoplevel = Sell Stop
   // Buy @ lower than market price + mkt stoplevel = Buy Limit
   // Sell @ highter than market price - mkt pad = Sell Limit
   
   
   // const double sl = getStoplevel();
   // FIXME: adjust stop/limit order calc for market stop level, returning -1 if INVALID
   if(buy) {
      const double mkt = getAskPrice();
      const double mktst = mkt + getStoplevel();
      if(rate > mktst) {
         return OP_BUYSTOP;
      } else if (rate < mktst) {
         return OP_BUYLIMIT;
      } else {
         // if (mkt > rate < mktst) ... TBD
         return OP_BUY;
      }
   } else {
      const double mkt = getOfferPrice();
      const double mktst = mkt - getStoplevel();
      if(rate < mktst) {
         return OP_SELLSTOP;
      } else if (rate > mktst) {
         return OP_SELLLIMIT;
      } else {
      // if (mkt > rate < mktst) ... TBD
         return OP_SELL;
      }
   }
   return -1; // FIXME tmp
}

int placeOrder(const bool buy, const double volume, const string comment=NULL, const int idx=0) {
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
   const int orderNr = OrderSend(symbol,cmd,volume,mkt,0,0,0,comment,idx);
   // NB: orderNr < 0 on failed call to OrderSend
   return orderNr;
}

int placeOrder(const bool buy, const double rate, const double volume, const string comment=NULL, const int idx=0) {
// place a forward order to open at 'rate', on current currency symbol
// NB: getStopLevel()
   const string symbol = getCurrentSymbol();
   const int cmd = cmdFor(buy,rate);
   if (cmd > 0) {
      // NB: no slippage rate, SL, TP, timed expiration
      return OrderSend(symbol,cmd,volume,rate,0,0,0,comment,idx);
   } else {
      return cmd;
   }
}

bool orderKindBuy(const int kind) {
   if((kind == OP_BUY) || (kind == OP_BUYLIMIT) || (kind == OP_BUYSTOP)) {
      return true;
   } else {
      // NB: Does not exhaustively validate the provided 'kind' value
      return false;
   }
}

int closeOrder(const int tkt) {
   const bool selok = OrderSelect(tkt,SELECT_BY_TICKET);
   if (selok) {
      const double initvol = OrderLots();
      const int kind = OrderType();
      const bool closeBuy = orderKindBuy(kind);
      const double closep = closeBuy ? getOfferPrice() : getAskPrice(); // ?
   // CLOSE ORDER AT CURRENT MARKET PRICE (Ask or Offer, depending on order kind), INITIAL NUMBER OF LOTS, 0 SLIPPAGE
      return OrderClose(tkt, initvol, closep, 0, CLR_NONE);      
   } else { 
      return -1;
   }
}
