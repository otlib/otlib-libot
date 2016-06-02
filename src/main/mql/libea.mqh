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

// #property library
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property version   "1.00"
#property strict

// - Input Parameters
input bool log_debug = false; // Log Runtime Information
// ^ FIXME: Rexpress debug info fn w/ a preprocessor macro

// - Program Parameters
const double dblz   = 0.0; // use one 0.0 value for zero of type 'double'

// - Memory Management
const int rsvbars = 512;

int pushAt (const int idx,
            const double value, 
            double &buffer[]) {
 const int len = ArraySize(buffer);
 int n;
 for(n = len-1; n > idx; n--) {
   buffer[n] = buffer[n - 1];
 }
 buffer[idx] = value;
 return n;
}

int push (const double value, 
          double &buffer[]) {
 return pushAt(0,value,buffer);
}

int pushAt (const int idx,
            const int value, 
            int &buffer[]) {
 const int len = ArraySize(buffer);
 int n;
 for(n = len-1; n > idx; n--) {
   buffer[n] = buffer[n - 1];
 }
 buffer[idx] = value;
 return n;
}

int push (const int value, 
          int &buffer[]) {
 return pushAt(0,value,buffer);
}


int pushAt (const int idx,
            const long value, 
            long &buffer[]) {
 const int len = ArraySize(buffer);
 int n;
 for(n = len-1; n > idx; n--) {
   buffer[n] = buffer[n - 1];
 }
 buffer[idx] = value;
 return n;
}

int push (const long value, 
          long &buffer[]) {
 return pushAt(0,value,buffer);
}


int pushAt (const int idx,
            const datetime value, 
            datetime &buffer[]) {
 const int len = ArraySize(buffer);
 int n;
 for(n = len-1; n > idx; n--) {
   buffer[n] = buffer[n - 1];
 }
 buffer[idx] = value;
 return n;
}

int push (const datetime value, 
          datetime &buffer[]) {
 return pushAt(0,value,buffer);
}



// functions also defined in libot.mq4 library
// 
// subset: functions applied in EA0 prototypes


// - Utility Functions - Curency Pairs

string getCurrentSymbol() {
   return ChartSymbol(0);
}


// - Utility Functions - Time

int dayStartOffT(const datetime dt) {
// return iBarShift for datetime dt
// using current chart and curren timeframe
   return iBarShift(NULL, 0, dt, false);
}

int dayStartOffL() export {
// return iBarShift for datetime at start of day, local time
// using current chart and curren timeframe
   MqlDateTime st;
   st.year = Year();
   st.mon = Month();
   st.day = Day();
   st.day_of_week = DayOfWeek();
   st.day_of_year = DayOfYear();
   st.hour = 0;
   st.min = 0;
   st.sec = 0;
   st.day_of_week = 1;
   datetime dt = StructToTime(st);
   // FIXME: Compute offset btw server local time and dt as provided here
   return dayStartOffT(dt);
}

// - Utiliy Functions - Market Data

double getAskPrice(const string symbol) {
   return MarketInfo(symbol,MODE_ASK);
}

double getAskPrice() {
   return getAskPrice(NULL);
}

double getOfferPrice(const string symbol) {
   return MarketInfo(symbol,MODE_BID);
}

double getOfferPrice() {
   return getOfferPrice(NULL);
}

double getSpread(const string symbol) {
   double ask = getAskPrice(symbol);
   double offer = getOfferPrice(symbol);
   return ask - offer;
}

double getSpread() {
   return getSpread(NULL);
}

double getStoplevel(const string symbol) {
   return MarketInfo(symbol, MODE_STOPLEVEL);
}

double getStoplevel() {
   return getStoplevel(NULL);
}

bool bearTick(const int index=0, const string symbol=NULL, const int tframe=0) {
   // NB This function DOES NOT check for time-series array order
   const double open = iOpen(symbol,tframe,index);
   const double close = iClose(symbol,tframe,index);
   return (open > close);
}

bool ocReversal(const int start=0, const int period=1, const string symbol=NULL, const ENUM_TIMEFRAMES tframe=PERIOD_CURRENT) {
   // calculate whether market performs a market trend reversal
   // bear=>bull or bull=>bear starting at index START
   // then to end of PERIOD duration in chart ticks
   //
   // this calculation is performed onto chart tick {open, close} data 
   // at the indicated timeframe, onto the data record for the specified symbol
   // (current chart symbol if NULL)
   if(period <= 0) {
      PrintFormat("Program Warning - calcReversal with period %d", period); // DEBUG_WARN
      return false;
   } else {
      bool btStart = bearTick(start, symbol, tframe);
      bool btEnd = bearTick(start + period, symbol, tframe);
      return (btStart != btEnd);
   }
}


// - Utility Functions - Rate Calculation

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) export {
// calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
   return value;
}

double calcGeoSum(const double a, const double b) {
   // calculate geometric sum of a and b
   double value = MathSqrt(MathPow(a,2) + MathPow(b,2));
   return value;
}

// - Utility Functions - Program Utility

void logDebug(const string message) { 
   // FIXME: Reimplement w/ a reusable preprocessor macro, optimizing the call pattern for this fn
   if (log_debug) {
      Print(message);
   }
}

// datetime dtbuff[][512]; // ? pointers & references in MQL4 ?
// const MqlDateTime dtzs;
// const datetime dtz = StructToTime(dtzs); 

// datetime dtz; // heap allocated (FIXME)
MqlDateTime dtzs; // heap allocated (FIXME)
datetime dtz; // heap allocated (FIXME)
bool dtzok = false;

void initDataBufferDT(datetime &ptr[], int len, bool asSeries = true) {
   // FIXME: ENUM_INDEXBUFFER_TYPE NOT DOCUMENTED (MQL4 REF) - DOCUMENTED (MQL5 REF)
   if(!dtzok) {   
      dtzs.year = 0;
      dtzs.mon = 0;
      dtzs.day = 0;
      dtzs.hour = 0;
      dtzs.min = 0;
      dtzs.sec = 0;
      dtzs.day_of_week = 0;
      dtzs.day_of_year = 0;
      dtz = StructToTime(dtzs); 
      dtzok = true;
   }

   ArrayResize(ptr,len,rsvbars);
   ArrayInitialize(ptr,dtz);
   // DO LAST:
   ArraySetAsSeries(ptr,asSeries);
   // FIXME: buffer must be manually resized
}

void initDataBufferInt(int &ptr[], int len, bool asSeries = true, int initValue = 0) {
   ArrayResize(ptr,len,rsvbars);
   ArrayInitialize(ptr, initValue);
   // DO LAST:
   ArraySetAsSeries(ptr,asSeries);
   // FIXME: buffer must be manually resized
}

void initDataBufferDbl(double &ptr[], int nr, int len, bool asSeries = true) {
   // FIXME: rename => initCalcBufferDbl
   ArrayResize(ptr,len,rsvbars); // DO BEFORE SetIndexBuffer - see ArrayResize docu
   SetIndexBuffer(nr,ptr,INDICATOR_CALCULATIONS); // FIXME: INDICATOR_DATA not documented
   ArrayInitialize(ptr,dblz); // cannot pass interpreted value as default value. MQL is not Lisp
   // DO LAST:
   ArraySetAsSeries(ptr,asSeries);
}

void initDrawBuffer(double &ptr[], int nr, int len, string lbl, int style=DRAW_LINE, int draw_begin=0, bool asSeries=true) {
   ArrayResize(ptr,len,rsvbars); // DO BEFORE SetIndexBuffer - see ArrayResize docu
   SetIndexBuffer(nr,ptr,INDICATOR_DATA);
   ArrayInitialize(ptr,dblz);
   // DO LAST in array modification forms
   ArraySetAsSeries(ptr,asSeries);
   SetIndexStyle(nr,style);
   SetIndexLabel(nr,lbl); 
   SetIndexDrawBegin(nr,draw_begin);
}