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
const int rsvbars = 8;

// functions also defined in libot.mq4 library
// 
// subset: functions applied in EA0 prototypes

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


// - Utility Functions - Rate Calculation

double calcRateHAC(const double open, 
                   const double high, 
                   const double low, 
                   const double close) export {
// calculate rate in a manner of Heikin Ashi Close
   double value = ( open + high + low + close ) / 4;
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

void initDataBufferInt(int &ptr[], int len, bool asSeries = true) {
   ArrayResize(ptr,len,rsvbars);
   ArrayInitialize(ptr,dtz); // FIXME: Define a DT alternative
   // DO LAST:
   ArraySetAsSeries(ptr,asSeries);
   // FIXME: buffer must be manually resized
}

void initDataBufferDbl(double &ptr[], int nr, int len, bool asSeries = true) {
   // SetIndexBuffer(nr,ptr,INDICATOR_DATA); // FIXME: INDICATOR_DATA, ... not documented
   SetIndexBuffer(nr,ptr); // FIXME: INDICATOR_DATA not documented
   ArrayResize(ptr,len,rsvbars);
   ArrayInitialize(ptr,dblz);
   // DO LAST:
   ArraySetAsSeries(ptr,asSeries);
}

void initDrawBuffer(double &ptr[], int nr, int len, string lbl, int style=DRAW_LINE, int draw_begin=0, bool asSeries=true) {
   SetIndexBuffer(nr,ptr);
   ArrayResize(ptr,len,rsvbars);
   ArrayInitialize(ptr,dblz);
   // DO LAST in array modification forms
   ArraySetAsSeries(ptr,asSeries);
   SetIndexStyle(nr,style);
   SetIndexLabel(nr,lbl); 
   SetIndexDrawBegin(nr,draw_begin);
}