cap log close
log using afig2-4.log, replace

use ${scratch}/acs_vars.dta, clear

set scheme cleanplots

gsort -wcount
gen sizerank=_n

reg cz_all_w_m3 logwage [aw=wcount], r
local a=_b[_cons]
local b=_b[logwage]
su logwage [aw=wcount], meanonly
local xmean=r(mean)

scatter cz_all_w_m3 logwage if sizerank<=600,  ///
 || function y=x-(`xmean'), range(2.5 3.2) ///
 || function y=(`a')+(`b')*x, range(2.5 3.2) ///
 ||, legend(off) xlabel(2.5 (0.1) 3.2) ///
     xtitle("Mean Log CZ wage") ///
	 ytitle("Estimated CZ wage effect (normalized to mean 0)") ///
	 title("Figure A2: Estimated CZ Wage Effects from Cross-Sectional Model" ///
	       "versus Mean Log Wage in CZ") ///
	 saving("${results}/afig2.gph", replace)
graph export ${results}/afig2.png, replace
scatter cz_all_w_m3 logwage if sizerank<=600,  ///
 || function y=x-(`xmean'), range(2.5 3.2) ///
 || function y=(`a')+(`b')*x, range(2.5 3.2) ///
 ||, legend(off) xlabel(2.5 (0.1) 3.2) ///
     xtitle("Mean Log CZ wage") ///
	 ytitle("Estimated CZ wage effect (normalized to mean 0)") ///
	 saving("${results}/afig2_notitle.gph", replace)
graph export ${results}/afig2_notitle.png, replace

gen logsize=ln(wcount)
su logwage [aw=wcount], meanonly
local xmean=r(mean)
gen adjm3=cz_all_w_m3+`xmean'
scatter logwage logsize if sizerank<=600, msymbol(o) ///
|| scatter adjm3 logsize if sizerank<=600, msymbol(dh) mcolor(black) mlwidth(vthin) ///
  xtitle("Log CZ Size") ytitle("Mean Log Wage and Estimated CZ Wage Effect") ///
  xlabel(11 (1) 19) ///
  legend(ring(0) pos(10) cols(1) label(1 "Mean Log Wage (unadjusted)") label(2 "Estimated CZ Wage Effect")) ///
  title("Figure A3: Relationship of Mean Log Wage and" "Estimated CZ Wage Effect to Log of CZ Size") ///
  saving("${results}/afig3.gph", replace)
graph export ${results}/afig3.png, replace
scatter logwage logsize if sizerank<=600, msymbol(o) ///
|| scatter adjm3 logsize if sizerank<=600, msymbol(dh) mcolor(black) mlwidth(vthin) ///
  xtitle("Log CZ Size") ytitle("Mean Log Wage and Estimated CZ Wage Effect") ///
  xlabel(11 (1) 19) ///
  legend(ring(0) pos(10) cols(1) label(1 "Mean Log Wage (unadjusted)") label(2 "Estimated CZ Wage Effect")) ///
  saving("${results}/afig3_notitle.gph", replace)
graph export ${results}/afig3_notitle.png, replace



reg cz_hs_w_m3 cz_all_w_m3 [aw=wcount_hs], r
local a_hs=_b[_cons]
local b_hs=_b[cz_all_w_m3]

reg cz_coll_w_m3 cz_all_w_m3 [aw=wcount_coll], r
local a_coll=_b[_cons]
local b_coll=_b[cz_all_w_m3]
scatter cz_hs_w_m3 cz_all_w_m3  if sizerank<=600,  ///
|| scatter cz_coll_w_m3 cz_all_w_m3  if sizerank<=600, mlcolor(gs3) mlwidth(vvthin) ///
  || function y=(`a_hs'+x*(`b_hs')), range(-0.4 0.3) lstyle(p1) lwidth(thick) ///
  || function y=(`a_coll'+x*(`b_coll')), range(-0.3 0.25) lstyle(p2) lwidth(thick) ///
  xtitle("Estimated CZ Wage Effect for All Workers (normalized to mean 0)") ///
  ytitle("Estimated CZ Wage EFfects (normalized to mean 0)") ///
  title("Figure A4: Relation of Estimated CZ Wage Effects for High School" ///
        "and College Workers with CZ Wage EFfect for All Workers") ///
  legend(label(1 "CZ Effect for Workers with" "12 Years Education") ///
         label(2 "CZ Effect for Workers with" "16 Years Education") ///
		 order(1 2) ring(0) pos(10) cols(1)) ///
  saving("${results}/afig4.gph", replace)
graph export ${results}/afig4.png, replace
scatter cz_hs_w_m3 cz_all_w_m3  if sizerank<=600,  ///
|| scatter cz_coll_w_m3 cz_all_w_m3  if sizerank<=600, mlcolor(gs3) mlwidth(vvthin) ///
  || function y=(`a_hs'+x*(`b_hs')), range(-0.4 0.3) lstyle(p1) lwidth(thick) ///
  || function y=(`a_coll'+x*(`b_coll')), range(-0.3 0.25) lstyle(p2) lwidth(thick) ///
  xtitle("Estimated CZ Wage Effect for All Workers (normalized to mean 0)") ///
  ytitle("Estimated CZ Wage EFfects (normalized to mean 0)") ///
  legend(label(1 "CZ Effect for Workers with" "12 Years Education") ///
         label(2 "CZ Effect for Workers with" "16 Years Education") ///
		 order(1 2) ring(0) pos(10) cols(1)) ///
  saving("${results}/afig4_notitle.gph", replace)
graph export ${results}/afig4_notitle.png, replace
		 
  
log close
