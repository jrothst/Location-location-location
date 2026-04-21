cap log close
log using afig8.log, text replace

import excel "$disclosure7", sheet(10) cellrange(A6:F406) firstrow clear
set scheme cleanplots
*set scheme plotplain


reg d_y_m_xb d_df
local b : display %4.2f _b[d_df]
scatter d_y_m_xb d_df, msymbol(p) || function y=x, ///
 range(-1 1) xlabel(-1 (0.5) 1) ylabel(-1 (0.5) 1)  ///
 legend(off) scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("A. Age-adjusted log earnings ({it:y-X{&beta}})", size(small)) name(dy, replace) nodraw

reg d_akm_res d_df
local b : display %4.2f _b[d_df]
scatter d_akm_res d_df, msymbol(p) || function y=x,  ///
 range(-1 1) xlabel(-1 (0.5) 1) ylabel(-1 (0.5) 1)  ///
 legend(off)  scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("B. AKM residual ({it:{&epsilon}})", size(small)) name(de, replace) nodraw

graph combine dy de  , xcommon ycommon ///
  b1title("Change in firm premium") l1title("Change in earnings")   ///
  saving("${results}/afig8.gph", replace) 
graph export "${results}/afig8.png", replace
log close
