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

// - Program Parameters

// - Memory Management

#ifndef BUFFLEN
#define BUFFLEN 512
#endif

#ifndef N_DATAPTR
#define N_DATAPTR 1
#endif

#ifndef N_TFRAME
#define N_TFRAME 1
#endif

#ifndef BUFF_T
#define BUFF_T double
#endif

#ifndef EMPTY 
#define EMPTY -1
#endif

#define STACKBUFF

// - Data Structures

class SimpleStackBuffer { // n.b "simple" as in that an object of this class contains exactly one data buffer, of one element type BUFF_T

// stack type data buffer class - NB no access locking for parallel access to the data[][][] buffer

   private:
   // - private data fields
      BUFF_T data[N_TFRAME][N_DATAPTR][BUFFLEN]; // assuming C++ order for array domains
      bool asTimeSeries; // applied in a functional inverse of MQL ArraySetAsSeries - may only be bound in constructor
      int fill; // primary data fill pointer. must be < BUFFLEN. applied uniformly across N_TFRAME, N_DATAPTR
      int datumidx; // last configured datum kind identifier
      int tframeidx; // last configured timeframe index identifier

  public:
  // - public construtor methods
      SimpleStackBuffer(const bool asTSeries) {
         this.asTimeSeries = asTSeries;
         this.fill = 0;
         this.datumidx = 0;
         this.tframeidx = 0;
         // this.data = data[N_TFRAME][N_DATAPTR][BUFFLEN]; // data buffer is automatically initialized ?
      };

  // - destrutor methods
      ~SimpleStackBuffer() {
         ArrayFree(data);
      }

  // - public data access methods - method parameters
      bool getAsTimeSeries() {
         // NB: This value is applied in a functional, logical inverse of MQL ArraySetAsSeries
         // for sake of disambiguation of the meaning and application of this property of the StackBuffer
         return this.asTimeSeries;
      }
      
      int getIndex() {
         return this.fill;
      };
      void setIndex(const int n) {
         // DEBUG: validate idx < BUFFLEN
         this.fill=n;
      };
      
      int getDatumIdx() {
         return this.datumidx;
      };
      void setDatumIdx(const int idx) {
         // DEBUG: validate idx < N_DATAPTR
         this.datumidx = idx;
      };
      
      int getTframeIdx() {
         return this.tframeidx;
      };
      void setTframeIdx(const int idx) {
         // DEBUG: validate idx < N_TFRAME
         this.tframeidx = idx;
      };
      
      BUFF_T getData(int n=EMPTY, int idx=EMPTY, int tframe=EMPTY) {
      // return one datum at the specified array coordinates
         // DEBUG: validate n < BUFFLEN, idx < N_DATAPTR, tframe < N_TFRAME
         if(n == EMPTY) {
            n = this.fill;
         };
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // logMessage(LOG_CALC,__FUNCTION__ + StringFormat(" n %d, datum idx %d, tframe %d", n, idx, tframe));
         return this.data[tframe][idx][n]; // assuming C++ order for array domains
      }; 
      
      void setData(BUFF_T datum, int n=EMPTY, int idx=EMPTY, int tframe=EMPTY) {
      // set one datum at the specified array coordinates
         if(n == EMPTY) {
            n = this.fill;
         };
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // logMessage(LOG_CALC,__FUNCTION__ + StringFormat(" datum %f, n %d, datum idx %d, tframe %d", datum, n, idx, tframe));
         this.data[tframe][idx][n]=datum; // assuming C++ order for array domains
      };
      
      // NOTE - Beyond the naive initial design sketch, the practical application of this buffer class becomes
      // in ways more tedious. For instance, when the buffer fill pointer is updated, this interface will
      // require that data will be provided for adding the "new" data for every configured timeframe and
      // every configured datum, so as to minimize ambiguity in how the data may be updated at the 
      // resulting, new fill pointer. This may result in some complexity in applications.
      //
      // Correspondingly, for accessing data from the buffer, an array of type BUFF_T[][] may be returned,
      // except in the instance of any function providing access only at the last configured this.datumidx
      // and last configured this.tfidx
      void pushData(/*&const BUFF_T &dbuff[N_TFRAME][N_DATAPTR]*/) {
      /* UPDATE : shift stacked buffer data, but do not add "New data" */
      // add data at fill, for the specified datum kind 'idx' and timeframe 'tframe' 
      //
      // if the stack buffer is 'full' this function will shift the buffer contents 
      // for all buffer timeframes and buffered data kinds before transferring the dbuff[][] data points
      //
         // logMessage(LOG_CALC,__FUNCTION__);
         if (this.fill == BUFFLEN) {
            for (int tf = 0; tf < N_TFRAME; tf++) {
               for (int dptr = 0; dptr < N_DATAPTR; dptr++) {
                  for (int n = 0; n < (BUFFLEN - 1); n++){
                     // shift elements in data stack, effectively overwriting the last data element
                     this.data[tf][dptr][n+1] = this.data[tf][dptr][n]; // assuming C++ order for array domains
                  };
               };
           };
         } else {
            this.fill++;
         };
         
         /* 
         for (int tf = 0; tf < N_TFRAME; tf++) {
            for (int dptr = 0; dptr < N_DATAPTR; dptr++) {
               this.data[tf][dptr][this.fill] = dbuff[tf][dptr];
            };       
         };
         */
      };
      
      
      BUFF_T getNewest(const int n=0, int idx=EMPTY, int tframe=EMPTY) {
      // read the nth chronologically newest dataum
      //
      // apply default datumidx, trameidx as last configured values
         // logMessage(LOG_CALC,__FUNCTION__);
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // assuming C++ order for array domains
         if(this.asTimeSeries) {
            return this.data[tframe][idx][fill-n];         
         } else {
            return this.data[tframe][idx][n];
         };
      }; 
      void setNewest(const BUFF_T datum, const int n=0, int idx=EMPTY, int tframe=EMPTY) {
      // update the nth chronologically newest dataum
      //
      // apply default datumidx, trameidx as last configured values
      //
      // note that this method does not shift data values an deeper into the stack - see also pushData(...)
         // logMessage(LOG_CALC,__FUNCTION__);
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // assuming C++ order for array domains
         if(this.asTimeSeries) {
            this.data[tframe][idx][fill-n] = datum;
         } else {
            this.data[tframe][idx][n]  = datum;
         };
      };


      BUFF_T getOldest(int n=0, int idx=EMPTY, int tframe=EMPTY) {
      // read one element of the nth chronologically oldest dataum
      //
      // apply default datumidx, trameidx as last configured values
         // logMessage(LOG_CALC,__FUNCTION__);
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // assuming C++ order for array domains
         if(this.asTimeSeries) {
            return this.data[tframe][idx][n];
         } else {
            return this.data[tframe][idx][fill-n];
         };
      }; 
      void setOldest(const BUFF_T datum, const int n=0, int idx=EMPTY, int tframe=EMPTY) {
      // update one element of the nth chronologically oldest dataum
      //
      // apply default datumidx, trameidx as last configured values
      //
      // note that this method does not shift data values an deeper into the stack - see also pushData(...)
         if (idx == EMPTY) {
            idx = this.datumidx;
         };
         if (tframe == EMPTY) {
            tframe = this.tframeidx;
         };
         // assuming C++ order for array domains
         if(this.asTimeSeries) {
            this.data[tframe][idx][n] = datum;
         } else {
            this.data[tframe][idx][fill-n] = datum;
         };
      };

};
