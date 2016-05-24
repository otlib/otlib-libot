[[otlib-libot][libot]] libot - Open Trading Toolkit 
===================================================

# Description

**Project Status:** Development

**Project Resources**

* `src/main/mql/libot.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:**
    * History
        * Initial Prototype for otlib EA0
        * Later renamed to SCR0.mq4
        * Reusable functions from SCR0 subsequently reproduced in
          file libot.mq4
        * File subsequently updated with additional functions that may
          be reusable in individual MQL4 prorams
    * **Description**
        * Goal (EA0): Market Trend Detection and Trend Reversal Detection
            * Analysis onto _affine space_ of market {time, rate} data
              for an individual market exchange chart
            * `calcTrends` funtion conducts variable high/low rate
              selection in a manner of the _Heikin Ashi_ indicator,
              applied in a manner of stochastic differential analysis
              accross an individual series of sequential market chart
              _ticks_, proceeding in a _reverse chronological_
              analysis
        * Initial prototype begins from `OnStart`.
        * Designed to be run as a MetaTrader 4 _Script_ program
        * Provides visual indicator of analysis
        * Program parameter `log_debug` provides control over printing
          of program debug messages to MetaTrader _Experts_ log

* `src/main/mql/SCR0.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Initial prototype of EA0 concept in application as
      a Metatrader 4 Script type program
    * **Description**: This program represents the canonical prototype
      of the EA0 concept, at this time.

* `src/main/mql/IND0.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Initial prototype of EA0 concept in application as
      a Metatrader 4 Indicator type program
    * **Description:**

      This program is representative of an adaptation of the SCR0
      program onto the semantics of MetaTrader 4 Inicator types
      programs. In adapting the SCR0 program for application as a
      MetaTrader 4 Indicator type program, a number of revisions have
      been produced onto the original SCR0 prototype. Mainly, data
      buffering in IND0 is produced onto a series of _time_ and _rate_
      buffers, rather than a single buffer of _Trend_ classes.

      In order to provide data values for application with the
      indicator's `DRAW_SECTION` buffer style, an additional buffer
      has been defined for maintaining synchronization between the
      respective _data buffers_ and the indicator's single _drawn
      buffer_.

    * **Known Issues**
        * **SCR0_INDO_DIVERGE**
            * **Synopsis:** Market rate trend calculation diverges
              between calculations produced with `calcTrends` in SCR0
              and `calcTrends` in IND0. The mechanical logic
              implemeted of the respective functions is not
              substantially different, at this time.  

            * **Description:** This indicator, in its present version,
              is producing data values that are numerically divergent
              from data values produced in the original SCR0
              prototype. This issue is documented, albeit
              rudimentarily, in the filesystem directory 
              `assets/isstrk/SCRO_IND0_DIVERGE/` in which the _lime
              green_ indicator lines are produced with the SCR0
              implementation and the _aqua_ hued indicator lines are
              produced with the IND0 implementation. Notably, the IND0
              implementation is producing _drawn indicator_ data of a
              character _less than ideal_, contrasted to the indicator
              data produced of the SCR0 implementation.

* `src/main/mql/clearObj.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Script utility for MetaTrader chart management
    * **Description**
        * `OnStart` function deletes all chart objects from the
          primary data window of the active chart
        * Utility developed for application in parallel to `libot.mq4`


**Correlated Projects**

* [Open Trading Toolkit - libot Wiki][libot-wiki]
* [Open Trading Toolkit - Documentation Library][otlib-doc]
* [Open Trading Toolkit - Project Web Resources][otlib-site]

# Copyright

Copyright (c) 2016, Sean Champ

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met: 

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the
   distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[libot]: https://github.com/otlib/otlib-libot "Open Trading Toolkit - Open Trading Library"
[libot-wiki]: https://github.com/otlib/otlib-libot/wiki "Open Trading Toolkit - libot wiki"
[otlib-doc]: https://github.com/otlib/otlib-doc "Open Trading Toolkit - Documentation Library"
[otlib-site]: https://github.com/otlib/otlib.github.io "Open Trading Toolkit - Project Web Resources"
