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
#property description "Indicator MinMax, Open Trading Toolkit"
#property version   "1.00"
#property strict
#property script_show_inputs
#property indicator_chart_window
#property indicator_buffers 1 // number of drawn buffers

#property indicator_color1 clrLime
#property indicator_width1 3

#include "libea.mqh"
#include "libha.mqh"

double   MMDraw[];
double   MMMinRt[];
int      MMMinTk[];
double   MMMaxRt[];
int      MMMaxTk[];

int MMMinCount = 0;
int MMMaxCount = 0;

const string label = "MinMax";

// -

int mmInitBuffers(int start) {
   const int mmnrbuffs = start + 5;   
   IndicatorBuffers(mmnrbuffs);    
   bufflen = iBars(NULL, 0);
   
   initDrawBuffer(MMDraw,start++,bufflen,"MinMax Change",DRAW_SECTION,0,true);
   SetIndexEmptyValue(0,dblz);
   
   initDataBufferDbl(MMMinRt,start++,bufflen);
   initDataBufferInt(MMMinTk,start++,bufflen);
   initDataBufferDbl(MMMaxRt,start++,bufflen);
   initDataBufferInt(MMMaxTk,start++,bufflen);
   return haInitBuffers(start,bufflen);
}

void mmZeroizeBuffers() {
   MMMinCount = 0;
   MMMaxCount = 0;
   ArrayInitialize(MMDraw,dblz);
   ArrayInitialize(MMMinRt,dblz);
   ArrayInitialize(MMMaxRt,dblz);
   ArrayInitialize(MMMinTk,-1);
   ArrayInitialize(MMMaxTk,-1);
}


void mmResizeBuffers(const int newsz) {
   ArrayResize(MMMinTk, newsz, rsvbars); // not platform managed
   ArrayResize(MMMaxTk, newsz, rsvbars); // not platform managed
   haResizeBuffers(newsz);
}

int mmPadBuffers(const int count) {
  if (count > bufflen) {
      const int newct = count + rsvbars; // X
      // PrintFormat("Resize Buffers [MM] %d => %d", bufflen, newct); // DEBUG
      mmResizeBuffers(newct);
      bufflen = newct;
      return newct;
   } else {
      return bufflen;
   }
}
// -

double getLastTrend() {
   if(MMMinCount > MMMaxCount) {
      return MMMinRt[MMMinCount] - MMMaxRt[MMMaxCount];
   } else {
      return MMMaxRt[MMMaxCount] - MMMinRt[MMMinCount];
   }
}

void setDraw(const int idx, const double rate) {
   MMDraw[idx] = rate;
}

int calcMinMax(const int ntick,
               const int prev_count) {

   int tick = 0;
   int prevTick = 1;
   double rate = getTickHAOpen(tick);
   double prevRate = getTickHAOpen(prevTick);
   
   double rtOpen, rtClose;
   double lastMin = rate;
   double lastMax = rate;
   int lastMinTk = 0;
   int lastMaxTk = 0;
   
   const double toCount = ntick - prev_count;
   
   if(prev_count == 0) {
      mmZeroizeBuffers();
   }

   if (ntick <= prevTick) { 
      return 0;
   } else if(toCount > 0) { // when prev_count = 0 & when to record more data bars than in previous iteration
      for(int n = prev_count; n < (ntick - 1); n++) {
         tick = n;
         rtOpen = getTickHAOpen(n);
         rtClose = getTickHAClose(n);
         // select rate based on whether tick is a bear or a bull tick
         rate = (rtOpen < rtClose) ? getTickHAHigh(n) : getTickHALow(n);
         
         if(rate > prevRate) {  // FIXME: Rate for current tick not set 
            lastMax = rate;
            lastMaxTk = tick;

            if(lastMinTk == prevTick) {
               // assume this begins a new, possibly short duration trend.
               //
               // No comparison is made, here, to HA Low at lastMinTik
               // MMMinCount ...; // Last Min is already recorded
               
               setDraw(lastMinTk, lastMin);
               MMMaxCount ++; // current rate is already set as the last max
            }

         } else { // rate < prevRate
            lastMin = rate;
            lastMinTk = tick;
         
            if(lastMaxTk == prevTick) {
               // assume this begins a new, possibly short duration trend
               //
               // No comparison is made, here, to HA High at lastMinTik
               // MMMaxCount ...; // Last Max is already recorded
               
               setDraw(lastMaxTk, lastMax);
               MMMinCount++; // current rate is already set as the last min
            }
         }
         prevTick = n;
         prevRate = rate;
      }
      return ntick; 
   } else {
      // typically called when prev_count = ntick, thus toCount = 0
      // sometimes called when ntick = prev_count + 1
      //      
      // role: update up to zeroth data bar
      // notes: typically called in realtime upadates, across timer durations shorter than market tick duration
      for(int n = 0; n <= toCount; n++) {
         if(rate > prevRate) {
         
         } else {
         
         }      
      }
      return ntick;
   }
}
   

// -

void OnInit() {
   IndicatorShortName(label);
   IndicatorDigits(Digits+2);
   mmInitBuffers(0);
}


int OnCalculate(const int ntick,
                const int prev_count,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   mmPadBuffers(ntick);
 
   calcHA(ntick,prev_count,open,high,low,close);
     
   return calcMinMax(ntick, prev_count);
   
}