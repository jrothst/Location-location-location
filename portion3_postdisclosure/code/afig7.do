cap log close
log using afig7.log, text replace

import excel "$disclosure7", sheet(9) cellrange(A5:F165) firstrow clear
set scheme cleanplots

rename Quartileoforigin startq
rename Quartileofdestination endq

scatter y_m_xb Eventtime if startq==4 & endq==4, connect(l) || ///
scatter y_m_xb Eventtime if startq==4 & endq==3, connect(l) || ///
scatter y_m_xb Eventtime if startq==4 & endq==2, connect(l) || ///
scatter y_m_xb Eventtime if startq==4 & endq==1, connect(l) || ///
scatter y_m_xb Eventtime if startq==1 & endq==4, connect(l) msymbol(plus) || ///
scatter y_m_xb Eventtime if startq==1 & endq==3, connect(l) || ///
scatter y_m_xb Eventtime if startq==1 & endq==2, connect(l) || ///
scatter y_m_xb Eventtime if startq==1 & endq==1, connect(l) || ///
  , legend(label(1 "4 to 4") label(2 "4 to 3") label(3 "4 to 2") label(4 "4 to 1") ///
           label(5 "1 to 4") label(6 "1 to 3") label(7 "1 to 2") label(8 "1 to 1") ///
		   cols(1) pos(3) rowgap(3.6) ///
		   subtitle("Quartile of origin" "and destination" "firm effect", size(small))) ///
    xlabel(-5 -4 -3 -2 -1 0 "1" 1 "2" 2 "3" 3 "4" 4 "5" ) xline(-0.5, lpattern(dash)) ///
	xtitle("Quarters relative to start of new job after move") ///
	ytitle("Mean log adjusted earnings") ///
	title("A. Earnings (adjusted for age and year)", pos(11) span) fxsize(100) /// 
	name(panelA, replace) nodraw

scatter akm_res Eventtime if startq==4 & endq==4, connect(l) || ///
scatter akm_res Eventtime if startq==4 & endq==3, connect(l) || ///
scatter akm_res Eventtime if startq==4 & endq==2, connect(l) || ///
scatter akm_res Eventtime if startq==4 & endq==1, connect(l) || ///
scatter akm_res Eventtime if startq==1 & endq==4, connect(l) msymbol(plus) || ///
scatter akm_res Eventtime if startq==1 & endq==3, connect(l) || ///
scatter akm_res Eventtime if startq==1 & endq==2, connect(l) || ///
scatter akm_res Eventtime if startq==1 & endq==1, connect(l) || ///
  , legend(off) ///
    xlabel(-5 -4 -3 -2 -1 0 "1" 1 "2" 2 "3" 3 "4" 4 "5" ) xline(-0.5, lpattern(dash)) ///
	xtitle("Quarters relative to start of new job after move") ///
	ytitle("Mean AKM residual") ///
	title("B. AKM residual", pos(11) span) fxsize(85) /// 
	name(panelB, replace) nodraw


graph combine panelA panelB, ///
	  imargin(0 0 0 0) ///
	  saving("${results}/afig7.gph", replace) 
graph export "${results}/afig7.png", replace

log close
