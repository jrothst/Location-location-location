cap log close
log using afig10.log, text replace

import excel "$disclosure7", sheet(13) cellrange(A6:J406) firstrow clear
set scheme cleanplots
*set scheme plotplain

rename Vigintileoforigin Vingtileoforigin
rename Vigintileofdestination Vingtileofdestination

keep Vingtileoforigin Vingtileofdestination d_y_m_xb d_psic
drop if Vingtileoforigin==Vingtileofdestination
tempfile base
save `base'

keep if d_psic>=0
rename d_y_m_xb changeup
tempfile moveup
save `moveup'

use `base'
keep if d_psic<=0
rename d_psic d_psic_down
rename Vingtileoforigin temp
rename Vingtileofdestination Vingtileoforigin
rename temp Vingtileofdestination
rename d_y_m_xb changedown
merge 1:1 Vingtileoforigin Vingtileofdestination using `moveup', assert(3)

scatter changedown changeup ||  function y=-x, range(changeup) ///
  xtitle(`"Mean change in earnings for "upward" movers"') ///
  ytitle(`"Mean change in earnings for "downward" movers"') ///
  legend(off) ///
  saving("${results}/afig10.gph", replace) 
graph export "${results}/afig10.png", replace
log close
