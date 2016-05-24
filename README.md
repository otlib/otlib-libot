[[otlib-libot][libot]] Open Trading Toolkit libot
=============================================

# Description

**Project Status:** Development

**Project Resources**

* `src/main/mql/libot.mq4`
    * **Platform:** MetaTrader 4
    * **Format:** MQL4
    * **Synopsis:** Prototype for otlib EA0
    * **Description**
        * Market Trend Detection and Trend Reversal Detection
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
* [Open Trading Toolkit - Project Web Resources}[otlib-site]

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
[otlib-site}: https://github.com/otlib/otlib.github.io "Open Trading Toolkit - Project Web Resources"
