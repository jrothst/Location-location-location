cap log close
log using fig4.log, text replace

import excel "$disclosure7", sheet(13) cellrange(A6:J406) firstrow clear
set scheme cleanplots
*set scheme plotplain


reg d_y_m_xb d_psic 
local b : display %4.2f _b[d_psic]
scatter d_y_m_xb d_psic, msymbol(p) || function y=x, ///
 range(-0.3 0.3) xlabel(-0.3 (0.3) 0.3) ylabel(-0.3 (0.3) 0.3)  ///
 legend(off) scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("A. Age-adjusted log earnings ({it:y-X{&beta}})", size(small)) name(dy, replace) nodraw

reg d_akm_res d_psic 
local b : display %4.2f _b[d_psic]
scatter d_akm_res d_psic, msymbol(p) || function y=x,  ///
 range(-0.3 0.3) xlabel(-0.3 (0.3) 0.3) ylabel(-0.3 (0.3) 0.3)  ///
 legend(off)  scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("B. AKM residual ({it:{&epsilon}})", size(small)) name(de, replace) nodraw

reg d_df_m_psic d_psic 
local b : display %4.2f _b[d_psic]
scatter d_df_m_psic d_psic, msymbol(p) || function y=x, ///
 range(-0.3 0.3) xlabel(-0.3 (0.3) 0.3) ylabel(-0.3 (0.3) 0.3)  ///
 legend(off)  scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("C. Hierarchy effect ({it:h})", size(small)) name(ddelta, replace) nodraw

 gen d_earn_adj=d_y_m_xb-d_df_m_psic
reg d_earn_adj d_psic 
local b : display %4.2f _b[d_psic]
 scatter d_earn_adj d_psic, msymbol(p) || function y=x, ///
 range(-0.3 0.3) xlabel(-0.3 (0.3) 0.3) ylabel(-0.3 (0.3) 0.3)  ///
 legend(off)  scale(1.5)  ///
 text(-0.25 0.15 "Slope = `b'", just(left) size(vsmall)) ///
 title("D. Earnings net of" "hierarchy effect ({it:y-X{&beta}-h})", size(small)) name(dadjy, replace)  nodraw
 
graph combine dy de ddelta dadjy, xcommon ycommon ///
  b1title("Change in CZ premium") l1title("Change in earnings component") ///
	saving("${results}/fig4.gph", replace) 
graph export "${results}/fig4.png", replace

log close
