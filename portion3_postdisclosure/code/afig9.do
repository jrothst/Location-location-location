cap log close
log using afig9.log, text replace

import excel "$disclosure7", sheet(10) cellrange(A6:F406) firstrow clear
set scheme cleanplots
*set scheme plotplain

rename Vigintileoforigin Vingtileoforigin
rename Vigintileofdestination Vingtileofdestination

keep Vingtileoforigin Vingtileofdestination d_y_m_xb d_df
drop if Vingtileoforigin==Vingtileofdestination
tempfile base
save `base'

keep if d_df>=0
rename d_y_m_xb changeup
tempfile moveup
save `moveup'

use `base'
keep if d_df<=0
rename d_df d_df_down
rename Vingtileoforigin temp
rename Vingtileofdestination Vingtileoforigin
rename temp Vingtileofdestination
rename d_y_m_xb changedown
merge 1:1 Vingtileoforigin Vingtileofdestination using `moveup', assert(3)

scatter changedown changeup ||  function y=-x, range(changeup) ///
  xtitle(`"Mean change in earnings for "upward" movers"') ///
  ytitle(`"Mean change in earnings for "downward" movers"') ///
  legend(off) ///
  saving("${results}/afig9.gph", replace) 
graph export "${results}/afig9.png", replace
log close
