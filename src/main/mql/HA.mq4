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
#property description "Heikin Ashi Indicator, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_chart_window
#property indicator_buffers 4 // number of drawn buffers

// OTLIB HA indicator buffers (drawn)
//
// HA buffer 0 (1) : HA low=>high   - bear tick trace - HABearTrc
// HA buffer 1 (2) : HA high=>low   - bull tick trace - HABullTrc
// HA buffer 2 (3) : HA ..open..    - bear tick body - HAOpen 
// HA buffer 3 (4) : HA ..close..   - bull tick body - HAClose

#property indicator_color1 clrTomato
#property indicator_width1 1
#property indicator_style1 STYLE_SOLID

#property indicator_color2 clrKhaki
#property indicator_width2 1
#property indicator_style2 STYLE_SOLID

#property indicator_color3 clrTomato
#property indicator_width3 3
#property indicator_style3 STYLE_SOLID

#property indicator_color4 clrKhaki
#property indicator_width4 3
#property indicator_style4 STYLE_SOLID


// - Line Properties as Input Parameters
// input color haBearTraceColor = clrTomato;    // bare tick trace
// input color haBullTraceColor = clrKhaki; // bull tick trace
// input color haBearBodyColor = clrTomato;     // bear tick body
// input color haBullBodyColor = clrKhaki;  // bull tick body

// - Program Parameters
const string label   = "HA";
const double dblz   = 0.0; // use one 0.0 value for zero of type 'double'

// - Code

#include "libha.mqh"

void OnInit() {
   // FIXME: Revise to define void haInit(int bufferStartIdx)
   // FIXME: Also define initDrawBuffer(&... *ptr, int nr, style, label, draw_begin=0)
   // FIXME: Also define initDataBuffer(&... *ptr, int nr)
   // FIXME: Also define classes DataBuffer, DrawBuffer ???
   
   IndicatorShortName(label);
   IndicatorDigits(Digits);
   IndicatorBuffers(7); 
   // 4 drawn buffers, 3 undrawn
   // 2 of the drawn bufers contain possible indicator data
   // 1 of the undrawn buffers is not fundamentally needed
   
   bufflen = iBars(NULL, 0);

   // NB: SetIndexBuffer may <not> accept a buffer of class type elements

   SetIndexBuffer(0, HABearTrc); // not needed outside of visuals
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexLabel(0,"Bear Tick Trace"); 
   SetIndexDrawBegin(0,2);
   
   SetIndexBuffer(1, HABullTrc); // not needed outside of visuals
   SetIndexStyle(1,DRAW_HISTOGRAM);
   SetIndexLabel(1,"Bull Tick Trace");
   SetIndexDrawBegin(1,2);

   SetIndexBuffer(2, HAOpen);
   SetIndexStyle(2,DRAW_HISTOGRAM);
   SetIndexLabel(2,"Bear Tick Body"); 
   SetIndexDrawBegin(2,2);
   
   SetIndexBuffer(3, HAClose);
   SetIndexStyle(3,DRAW_HISTOGRAM);
   SetIndexLabel(3,"Bull Tick Body");
   SetIndexDrawBegin(3,2);
   
   // FIXME: Delete HATick (?)
   SetIndexBuffer(4,HATick); // puts it under platform memory management ?
   SetIndexBuffer(5,HAHigh); // puts it under platform memory management ?
   SetIndexBuffer(6,HALow); // puts it under platform memory management ?
   
   resizeBuffs(bufflen);
 
   ArrayInitialize(HAOpen, dblz);
   ArrayInitialize(HABearTrc, dblz);
   ArrayInitialize(HABullTrc, dblz);
   ArrayInitialize(HAClose, dblz);
   ArrayInitialize(HAHigh, dblz);
   ArrayInitialize(HALow, dblz);
   ArrayInitialize(HATick, 0);
   
   // DO THIS AFTER OTHER CALLS ... (FIXME: DOCUMENTATION)
   ArraySetAsSeries(HAOpen, false);
   ArraySetAsSeries(HABearTrc, false);
   ArraySetAsSeries(HABullTrc, false);
   ArraySetAsSeries(HAClose, false);
   ArraySetAsSeries(HATick, false);
   ArraySetAsSeries(HAHigh, false);
   ArraySetAsSeries(HALow, false);

}


int OnCalculate(const int nticks,
                const int counted,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   int haCount;

   if (nticks >= (bufflen + rsvbars)) {
      resizeBuffs(nticks + rsvbars);
   }

   haCount = calcHA(nticks,0,open,high,low,close);
   return haCount;
}

// FIXME: Consider making all of the HA data available across MLQL4 'import' semnatics, however tedious.
// 1) define 'export' for trivial functions - move shared functions into otlib.mq4
// 2) ensure compiled forms are avaialble in appropriate directory - see MQL4 Reference  /  MQL4 programs / Call of Imported Functions 
//    ... noting TERMINAL_DATA_PATH 
// 3) define initialization routines that may be called from external program, for initializing this indicator
//     e.c. extHaInit => OnCalculate() in this file (???)
// 4) define runtime routines that may be called from external programs, for updating the indicator's record data
//     e.g extCalcHA => calcHA in this file? or OnCalculate() in this file (???)
// 5) define accessors encapsulating the array access - e.g getHAClose(...) getHACloseAS(...) latter cf. ArraySetAsSeries, HATick
// 6) DOCUMENT HOWTO if the MT4 and MQL4 docs aren't sufficient in that regards
//
