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

double FirstMin = dblz;
double FirstMax = dblz;
int FirstMinTk = -1;
int FirstMaxTk = -1;
datetime FirstMinDT = 0;
datetime FirstMaxDT = 0;

const string label = "MinMax";

// -

void mmResizeBuffers(const int newsz) {
   ArrayResize(MMMinTk, newsz, rsvbars); // not platform managed
   ArrayResize(MMMaxTk, newsz, rsvbars); // not platform managed
   haResizeBuffers(newsz);
}

int mmInitBuffers(int start) {
   const int mmnrbuffs = start + 5;   
   IndicatorBuffers(mmnrbuffs);    
   bufflen = iBars(NULL, 0);
   PrintFormat("MM Init Buffers %d (%d)", start, bufflen);
   
   initDrawBuffer(MMDraw,start++,bufflen,"MinMax Change",DRAW_SECTION,0,true);
   SetIndexEmptyValue(0,dblz);
   
   initDataBufferDbl(MMMinRt,start++,bufflen);
   initDataBufferInt(MMMinTk,start++,bufflen);
   initDataBufferDbl(MMMaxRt,start++,bufflen);
   initDataBufferInt(MMMaxTk,start++,bufflen);
   mmResizeBuffers(bufflen);
   mmZeroizeBuffers();
   const int nrHA = haInitBuffersUndrawn(start,bufflen);
   haResizeBuffers(bufflen);
   return nrHA;
}

void mmZeroizeBuffers() {
   MMMinCount = 0;
   MMMaxCount = 0;
   FirstMin = dblz;
   FirstMax = dblz;
   FirstMinTk = -1;
   FirstMaxTk = -1;
   FirstMinDT = 0;
   FirstMaxDT = 0;
   ArrayInitialize(MMDraw,dblz);
   ArrayInitialize(MMMinRt,dblz);
   ArrayInitialize(MMMaxRt,dblz);
   ArrayInitialize(MMMinTk,-1);
   ArrayInitialize(MMMaxTk,-1);
}


int mmPadBuffers(const int count) {
  // PrintFormat("Pad %d", count);
  if (count > bufflen) {
      const int newct = count + rsvbars; // X
      PrintFormat("MM Pad - Resize Buffers [MM] %d => %d", bufflen, newct); // DEBUG
      mmResizeBuffers(newct);
      bufflen = newct;
      return newct;
   } else {
      return bufflen;
   }
}
// -

double getOldestTrend() {
   if(MMMinCount > MMMaxCount) {
      return MMMinRt[MMMinCount] - MMMaxRt[MMMaxCount];
   } else {
      return MMMaxRt[MMMaxCount] - MMMinRt[MMMinCount];
   }
}

void setDraw(const int idx, const double rate) {
   // mmPadBuffers(idx + 1);
   MMDraw[idx] = rate;
}

/*
void pushDraw(const int idx, const double rate) {
   push(rate,MMDraw); // ??? NOPE
}
*/


void setMax(const int maxidx, const int idx, const double rate) {
   PrintFormat("SetMax(%d, %d, %f) [%d]", maxidx, idx, rate, MMMaxCount);
   setDraw(idx, rate);
   MMMaxRt[maxidx] = rate;
   MMMaxTk[maxidx] = idx;
   if(maxidx == 0) { 
      FirstMax = rate;
      FirstMaxTk = idx;
      FirstMaxDT = iTime(NULL,0,idx);
   }

}


void setMax(const int idx, const double rate) {
   setMax(MMMaxCount, idx, rate);
}


void pushMax(const int idx, const double rate) {
   PrintFormat("PushMax(%d, %f)", idx, rate);
   push(rate, MMMaxRt);
   push(idx, MMMaxTk);
   // pushDraw(idx,rate);
   setDraw(idx,rate);
   FirstMax = rate;
   FirstMaxTk = idx;
   FirstMaxDT = iTime(NULL,0,idx);
}


void setMin(const int minidx, const int idx, const double rate) {
   PrintFormat("SetMin(%d, %d, %f) [%d]", minidx, idx, rate, MMMinCount);
   setDraw(idx, rate);
   MMMinRt[minidx] = rate;
   MMMinTk[minidx] = idx;
   if(minidx == 0) { 
      FirstMin = rate;
      FirstMinTk = idx;
      FirstMinDT = iTime(NULL,0,idx);
   }
}

void setMin(const int idx, const double rate) {
   setMin(MMMinCount, idx, rate);
}


void pushMin(const int idx, const double rate) {
   PrintFormat("PushMin(%d, %f)", idx, rate);
   push(rate, MMMinRt);
   push(idx, MMMinTk);
   // pushDraw(idx,rate);
   setDraw(idx,rate);
   FirstMin = rate;
   FirstMinTk = idx;
   FirstMinDT = iTime(NULL,0,idx);
}



int calcMinMax(const int ntick,
               const int prev_count,
               const datetime &time[]) {

   int tick, prevTick;
   double rate, prevRate;
   
   double rtOpen, rtClose;
   double lastMin, lastMax;
   int lastMinTk, lastMaxTk;
   
   const int toCount = ntick - prev_count;

   if (ntick <= 1) { 
      return 0;
   } else if(toCount > 1) { // when prev_count = 0 & when to record more data bars than in previous iteration
   
      // traverse market rate history from prev_count (probably 0, i.e current tick) to ntick (oldest)
      
      tick = 0;
      prevTick = 1;
      rate = getTickHAClose(tick);
      prevRate = getTickHAOpen(prevTick);
      lastMin = rate;
      lastMax = rate;
      lastMinTk = 0;
      lastMaxTk = 0;
      
      // FIXME: also initialize draw[0] rate, tick ? it should be later updated ...
      // KLUDGE:
      if(rate > prevRate) {
         setMin(0,prevRate);
         FirstMin = prevRate;
         FirstMinTk = 0;
      } else {
         setMax(0,prevRate);
         FirstMax = prevRate;
         FirstMaxTk = 0;
      }
      
      // FIXME: Consider reimplementing as to precede from oldest tick to newest tick
      
      for(int n = prev_count; n < (ntick - 1); n++) {
         tick = n;
         rtOpen = getTickHAOpen(n);
         rtClose = getTickHAClose(n);
         // select rate based on whether tick is a bear or a bull tick
         rate = (rtOpen < rtClose) ? getTickHALow(n) : getTickHAHigh(n);
         
         if(rate > prevRate) {  // FIXME: Rate for current tick not set 
            lastMax = rate;
            lastMaxTk = tick;

            // if(lastMinTk == prevTick) {
               // assume this begins a new, possibly short duration trend.
               //
               // No comparison is made, here, to HA Low at lastMinTik
               // MMMinCount ...; // Last Min is already recorded
               
               // set trend-open data for last min
               setMin(lastMinTk, lastMin);                              

               // advance ...
               MMMinCount++; // current rate is already set as the last max
            // } // else no further update (?)

         } else { // rate <= prevRate
            lastMin = rate;
            lastMinTk = tick;
         
            // if(lastMaxTk == prevTick) {
               // assume this begins a new, possibly short duration trend
               //
               // No comparison is made, here, to HA High at lastMinTik
               // MMMaxCount ...; // Last Max is already recorded
               
               // set trend-open data for last max
               setMax(lastMaxTk, lastMax);
               
               // advance ...
               MMMaxCount++; // current rate is already set as the last min
            // } // else no further update (?)
         }
         prevTick = n;
         prevRate = rate;
      }
      
      // PrintFormat("CALC toCount %d RET %d (%d : %d)", toCount, ntick - 1, MMMinCount, MMMaxCount);
      
      // cleanup after last trend recorded - set the fist time-series trend open rate
      // return ntick - index-of-time-series-first-trend-open
      if (MMMinTk[0] < MMMaxTk[0]) { // minimum trend at newer index
         setMin(0, prev_count, getTickHAHigh(0));
         return ntick - FirstMinTk;
      } else {
         setMax(0, prev_count, getTickHALow(0));
         return ntick - FirstMaxTk;
      }

      /// return ntick - 1; 
   } else {
      // typically called when prev_count = ntick, thus toCount = 0
      // sometimes called when ntick = prev_count + 1
      //      
      // role: update zeroth data bar and any additional data bars up to toCount
      // notes: 
      //  * typically called in realtime market chart upadates
      //  * may be called across timer durations shorter than market tick duration
      
       // MMMinCount, MMMaxCount ...?
      
      PrintFormat("Forward calc %d, %d", ntick, prev_count);
      
      // FIXME: MMMaxRT, MMMinRT no longer to be applied here
      // Instead, dispatch on FirstMax... , FirstMin...
      
      bool forwardMin = (FirstMaxTk < FirstMinTk);

      prevRate = forwardMin ? FirstMax : FirstMin;
      prevTick = forwardMin ? FirstMaxTk : FirstMinTk;
      
      lastMin = FirstMin;
      lastMax = FirstMax; 
      lastMinTk = FirstMinTk;
      lastMaxTk = FirstMaxTk;
      int n;
      
      for(n = toCount; n >= 0; n--) {
         rate = forwardMin ? getTickHALow(n) : getTickHAHigh(n);
         if(forwardMin && (rate <= lastMin)) {
            lastMin = rate;
            lastMinTk = n;
            setMin(0,n,rate); // X 0 ?? // SET[0] => UPDATE[0]
         } else if (!forwardMin && (rate >= lastMax)) {
            lastMax = rate;
            lastMaxTk = n;
            setMax(0,n,rate); // X 0 ?? // SET[0] => UPDATE[0]
         } else {
            // X ! immediate rate reversal (?!...) - update buffers, dispatching on forwardMin
            if(forwardMin && rate > lastMin) { // => rate !< lastMin
               if (FirstMinDT == time[0]) { // NOT ENOUGH A CHECK
                  setMin(0,lastMinTk,lastMin); // SET[0] => UPDATE[0]
               } else { // CALLED WAY TOO OFTEN
                  pushMin(lastMinTk,lastMin); // PUSH[0] => ADD NEW MIN
               }
               // RESET FOR !forwardMin (THIS CALL)
               lastMax = rate;
               lastMaxTk = n;
               forwardMin = !forwardMin;
            } else if (!forwardMin && rate < lastMax) { // => rate !> lastMax
               if (FirstMaxDT == time[0]) { // NOT ENOUGH A CHECK
                  setMax(0,lastMaxTk,lastMax); // SET[0] => UPDATE[0]
               } else { // CALLED WAY TOO OFTEN
                  pushMax(lastMaxTk,lastMax); // PUSH[0] => ADDD NEW MAX
               }
               // RESET FOR !forwardMin (THIS CALL)
               lastMin = rate;
               lastMinTk = n;
               forwardMin = !forwardMin;
            } else {
               PrintFormat("?????");
            }
            
         }
         prevRate = rate;
         prevTick = n;
      }

      // return prev_count + n;
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

//   mmPadBuffers(ntick);
 
   calcHA(ntick,prev_count,open,high,low,close);

   if(prev_count == 0) {
      mmZeroizeBuffers();
   }     
   return calcMinMax(ntick, prev_count, time);
   
}