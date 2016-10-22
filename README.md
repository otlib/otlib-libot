[[otlib-libot][libot]] libot - Open Trading Toolkit 
===================================================

# Description

**Project Status:** Development

**Project Resources**

**Ed Note:** This documentation may be at least _one week_ behind, in updates. Current information is available in the source code directory `src/main/mql/`

* `src/main/mql/libot.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Component functions library for MQL4 applications,
      Open Trading Toolkit 
    * **History**
        * This file originally contained the initial prototype for the
          EA0 mechanical trading concept
        * Later renamed to `SCR0.mq4`
        * Reusable functions from SCR0 have subsequently been
          reproduced in the file `libot.mq4`
        * File subsequently updated with additional functions that may
          be reusable in individual MQL4 prorams, so far as accessible
          via the MQL4 `#import` preprocessor directive

* `src/main/mql/SCR0.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Initial prototype of EA0 concept in application as
      a Metatrader 4 Script type program
    * **Description**: This program represents the canonical prototype
      of the EA0 concept, at this time.
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

* `src/main/mql/IND0.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Initial prototype of EA0 concept in application as
      a Metatrader 4 Indicator type program
    * **Description:**

      This program is representative of an adaptation of the SCR0
      program onto the semantics of MetaTrader 4 Indicator types
      programs. In adapting the SCR0 program for application as a
      MetaTrader 4 Indicator type program, a number of revisions have
      been produced onto the original SCR0 prototype. Mainly, data
      buffering in IND0 is produced onto a series of _time_ and _rate_
      buffers, rather than a single buffer of _Trend_ classes.

      In order to provide data values for application onto the
      indicator's `DRAW_SECTION` buffer style, an additional buffer
      has been defined for maintaining synchronization between the
      respective _data buffers_ in the IND0 implementation and the
      indicator's single _drawn buffer_.

    * **Known Issues**
        * Indicator should apply a manner of _smoothing_, to prevent
          recording of very short reverals (e.g. period <= 2m)

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

**Developers**

* Sean Champ
    * Blockchain Address: `1MA86SH2KWTh7Czn7qVrGn1qm3mcNReUhs`
    * [Onename Profile](https://onename.com/spchamp)

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
