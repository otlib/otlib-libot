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

#property library
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property version   "1.00"
#property strict


// - curency pairs

string getCurrentSymbol() {
   return ChartSymbol(0);
}

// - interactive messaging 

int errorNotify(const string message) {
   Print(message);
   return MessageBox(message,"Error",MB_OKCANCEL);
}

void logDebug(const string message) { 
   // FIXME: Reimplement w/ a reusable preprocessor macro, optimizing the call pattern for this fn
   if (log_debug) {
      Print(message);
   }
}

// - charts

// - market information

// See also: SymbolInfoDouble(Symbol(),SYMBOL_{ASK|BID});


double getAskP(){ // market ask price, current chart and symbol
   string symbol = getCurrentSymbol();
   return getAskPForS(symbol);
}


double getAskPForC(const long id){ 
   // return ask price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getAskPForS(symbol);
}


double getAskPForS(const string symbol){
   return MarketInfo(symbol,MODE_ASK);
}


double getOfferP(){ // market offer price, i.e bid price
   string symbol = getCurrentSymbol();
   return getOfferPForS(symbol);
}


double getOfferPForC(const long id){ 
   // return offer price for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getOfferPForS(symbol);
}


double getOfferPForS(const string symbol){
   return MarketInfo(symbol,MODE_BID);
}


double getSpread() { // diference of ask and offer price
   string symbol = getCurrentSymbol();
   return getSpreadForS(symbol);
}


double getSpreadForC(const long id){ 
   // return market spread for chart with specified chart ID. 
   // ID 0 indicates current chart
   string symbol = ChartSymbol(id);
   return getSpreadForS(symbol);
}

double getSpreadForS(const string symbol) {
   double ask = getAskPForS(symbol);
   double offer = getOfferPForS(symbol);
   return ask - offer;
}


double calcRateHAC(const double open, const double high, const double low, const double close) {
   // calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
   return value;
}

