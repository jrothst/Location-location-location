cap log close
log using fig2.log, text replace

/*  
Uses Stata packages:
spmap:       <ssc install spmap>
cleanplots:  <net install cleanplots, from(http://fmwww.bc.edu/RePEc/bocode/c)>
maptile.ado: <net install maptile, from(http://fmwww.bc.edu/RePEc/bocode/m)>
CZ90 geography, installed with: <maptile_install using "http://files.michaelstepner.com/geo_cz1990.zip">
*/ 
which spmap
which maptile


import excel using "${disclosure8}", sheet(1) cellrange(G3:K154) firstrow clear
set scheme cleanplots
*set scheme plotplain

forval q=1/5 {
split Q`q', parse(:) destring
drop Q`q'2 Q`q'
}
rename Q?1 Q?
forval q=1/5 {
preserve
keep Q`q'
rename Q`q' cz
gen q=`q'
tempfile Q`q'
save `Q`q'', replace
restore
}
clear
forval q=1/5 {
append using `Q`q''
}
drop if cz==.
assert _N==741

/* 

preserve
* ACS is missing a few CZs (latest ACS dataset from Dave - July 2023, phi_cz_acs.do)
merge 1:1 cz using "${scratch}/acs_vars.dta", keepusing(logwage) keep(match)
assert _N==690
maptile q, geography(cz1990) cutvalues(1.5(1)4.5) twopt(title("CZ Effects (LEHD)") legend(position(4) ring(1) lab(1 "No data") lab(2 "Lowest") lab(3 "2") lab(4 "3") lab(5 "4") lab(6 "Highest")) name(czeffects, replace))
maptile logwage, geography(cz1990) nq(5) twopt(title("Wages (ACS)") legend(position(4) ring(1) lab(1 "No data") lab(2 "Lowest") lab(3 "2") lab(4 "3") lab(5 "4") lab(6 "Highest")) name(wages, replace))
*maptile logwage, geography(cz1990) nq(5) twopt(title("Wages") legend(off) name(wages, replace))
graph combine wages czeffects, row(2) title("Figure 3: Map of CZ's by Quintiles of Wages and CZ Effects")
graph export ${results}/fig2_alt.png, replace
restore
*/

* full CZ sample
merge 1:1 cz using "${acsoutput}/acs_vars.dta", keepusing(logwage)
* AK is grouped as cz 99999 in ACS, it is in the top quintile 
* czs in AK 34101 34102 34103 34104 34105 34106 34107 34108 34109 34110 34111 34112 34113 34114 34115
foreach cz in 34101 34102 34103 34104 34105 34106 34107 34108 34109 34110 34111 34112 34113 34114 34115 {
qui sum logwage if cz==99999
qui replace logwage=r(mean) if cz==`cz'
}
drop if cz==99999
maptile q, geography(cz1990) cutvalues(1.5(1)4.5) ///
  twopt(title("CZ Effects (LEHD)") ///
  legend(position(4) ring(1) lab(1 "No data") lab(2 "Lowest") lab(3 "2") ///
         lab(4 "3") lab(5 "4") lab(6 "Highest")) ///
  name(czeffects, replace))
  
maptile logwage, geography(cz1990) nq(5) ///
  twopt(title("Wages (ACS)") ///
  legend(position(4) ring(1) lab(1 "No data") lab(2 "Lowest") lab(3 "2") ///
         lab(4 "3") lab(5 "4") lab(6 "Highest")) ///
  name(wages, replace))
// Version with a title
// graph combine wages czeffects, row(2) title("Figure 3: Map of CZ's by Quintiles of Wages and CZ Effects") saving(${results}/fig2, replace)
// graph export ${results}/fig2.png, replace

graph combine wages czeffects, row(2) title("") saving(${results}/fig2, replace)
graph export ${results}/fig2.png, replace

exit

