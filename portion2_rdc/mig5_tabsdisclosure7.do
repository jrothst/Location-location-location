/*----------------------------------------------------------------------------*\
Disclosure package 7 
tabs: 7 14 15 16 17 18 19 20 22 23

input files:
czranking6_alt-wage.dta
cw_cty_czone.dta
sample8NOUNC_peq.dta
mig5_pikqtime_1018_educacs
M9twostep_step1xbr.dta
AKMests_2stepfull_jc.dta
young_comparemodels_top10.dta 
young_comparemodels_top25.dta 
M10_AKM_10pctB.txt
M10_AKM_10pctB_jc.txt
\*----------------------------------------------------------------------------*/

clear
set more off
set linesize 155

// Set directories
include mig5_paths.do
cd $yidata



* Decomposition program: K2 decomposition (weighted PQ)
cap program drop decomp2
program define decomp2
args name y components fw
cap drop col*`name'
qui gen col1`name'="var(`y') - sd - shr=" if _n==1
qui sum `y' [fw=`fw']
local var=r(Var)
qui gen col2`name'=r(Var) if _n==1
qui gen col3`name'=r(sd) if _n==1
qui gen col4`name'=`var'/r(Var) if _n==1
noi dis "sd and var(`y') share=" _col(55) "&"  round(r(sd),.0001) _col(65) "& (" round(r(Var)/`var',.0001) ")"
local i=1
foreach comp1 in `components' {
	qui sum `comp1' [fw=`fw']
	noi dis "sd and var(`comp1') share=" _col(55) "&"  round(r(sd),.0001) _col(65) "& (" round(r(Var)/`var',.0001) ")"
	qui replace col1`name'="var(`comp1') - sd - shr=" if _n==`i'+1
	qui replace col2`name'=round(r(Var),.000001) if _n==`i'+1
	qui replace col3`name'=round(r(sd),.000001) if _n==`i'+1
	qui replace col4`name'=round(r(Var)/`var',.000001) if _n==`i'+1
	local i=`i'+1
}
foreach comp1 in `components' {
	foreach comp2 in `components' {
	if (`comp1'==`comp2') {
	continue
	}
	cap confirm number `covshr_`comp2'`comp1''
	if _rc==0 {
		*dis "`covshr_`comp2'`comp1'' already exists"
		continue
	}
	qui correlate `comp1' `comp2' [fw=`fw']
	local rho=r(rho)
	qui correlate `comp1' `comp2' [fw=`fw'], covariance
	local covshr_`comp1'`comp2'= 2*r(cov_12)/`var'
	qui replace col1`name'="cov(`comp1',`comp2') - rho - shr=" if _n==`i'+1
	qui replace col2`name'=round(r(cov_12),.000001) if _n==`i'+1
	qui replace col3`name'=round(`rho',.000001) if _n==`i'+1
	qui replace col4`name'=round(`covshr_`comp1'`comp2'',.000001) if _n==`i'+1
	noi dis "rho and 2cov(`comp1',`comp2') share=" _col(55) "&"  round(`rho',.0001) _col(65) "& (" round(`covshr_`comp1'`comp2'',.0001) ")"
	local i=`i'+1
}
}
noi dis "Observations" _col(55) "&"  %30.0fc r(N)
qui replace col1`name'="N=" if _n==`i'+1
drbrclass N , countscalars(N)
qui replace col2`name'=r(N) if _n==`i'+1
drbvars col2`name' col3`name' col4`name', replace
format  col2`name' col3`name' col4`name'  %030.6gc
list col1`name' col2`name' col3`name' col4`name' if col1`name'~=""
end


* CZ restriction
use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
rename czone cz
bys cz: keep if _n==1
merge n:1 cz using czranking6_alt-wage.dta , keep(match) nogen keepusing(cz)
drop if cz==28601  | cz==30906
tempfile czlist_4V
save `czlist_4V', replace


* DATA CLEANING
use pikn qtime cz naics2d educacs pik state sein seinunit using mig5_pikqtime_1018_educacs.dta, replace
gen educ=(educacs==2|educacs==3|educacs==4)
drop educacs
merge n:1 cz using `czlist_4V', keep(match) nogen
destring state, replace
rename cz czone_b
rename state state_b
rename sein sein_b
rename seinunit seinunit_b
merge 1:1 pikn qtime using "$data2step/M9twostep_step1xbr.dta", keep(master match) keepusing(czone naics4d akm_person akm_firm xb r state sein seinunit)
foreach v in czone state {
replace `v'=`v'_b if `v'==. & `v'_b~=.
drop `v'_b
}
foreach v in sein seinunit {
replace `v'=`v'_b if `v'=="" & `v'_b~=""
drop `v'_b
}
egen double firmnum=group(czone state sein seinunit)
assert firmnum~=.
gen y = akm_person + akm_firm + xb + r
* impute
foreach v in y akm_person akm_firm xb r {
qui sum `v'
replace `v'=r(mean) if _merge==1 & `v'==.
}
save M9twostep_step1xbr_4VEDUC.dta, replace

* cz aggregations
use if educ==0 & _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacsHS=1
fcollapse (mean) y_educacsHS=y pe_educacsHS=akm_person fe_educacsHS=akm_firm xbjcL=xb r_educacsHS=r (sum) n_educacsHS, by(cz)
tempfile hs
save `hs', replace
use if educ==1 & _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacsCplus=1
fcollapse (mean) y_educacsCplus=y pe_educacsCplus=akm_person fe_educacsCplus=akm_firm xbjcH=xb  r_educacsCplus=r  (sum) n_educacsCplus, by(cz)
tempfile cplus
save `cplus', replace
use if _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacs=1
fcollapse (mean) y_educacs=y pe_educacs=akm_person fe_educacs=akm_firm r_educacs=r   (sum) n_educacs, by(cz)
merge 1:1 cz using `hs', nogen
merge 1:1 cz using `cplus', nogen
save mig5_educpsis_c_new_IMP.dta, replace

* jc aggregations
use if educ==0 & _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacsHS=1
fcollapse (mean) y_educacsHS=y pe_educacsHS=akm_person fe_educacsHS=akm_firm xbjcL=xb r_educacsHS=r (sum) n_educacsHS, by(cz naics2d)
tempfile hs
save `hs', replace
use if educ==1 & _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacsCplus=1
fcollapse (mean) y_educacsCplus=y pe_educacsCplus=akm_person fe_educacsCplus=akm_firm xbjcH=xb r_educacsCplus=r (sum) n_educacsCplus, by(cz naics2d)
tempfile cplus
save `cplus', replace
use if _merge~=20 using M9twostep_step1xbr_4VEDUC.dta, replace
gen n_educacs=1
fcollapse (mean) y_educacs=y pe_educacs=akm_person fe_educacs=akm_firm r_educacs=r   (sum) n_educacs, by(cz naics2d)
merge 1:1 cz naics2d using `hs', nogen
merge 1:1 cz naics2d using `cplus', nogen
fillin cz naics2d
foreach nvar in n_educacsHS n_educacsCplus n_educacs {
replace `nvar'=0 if _fillin==1
}
drop _fillin
save mig5_educpsis_jc_new_IMP.dta, replace




********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 7
* PSI_C COMPARISONS

* top 10, young
use czone naics2d  akm_firm akm_firm_dynamic using $data2step/young_comparemodels_top10.dta, replace
gen t=1
fcollapse (mean) psijc_m2=akm_firm psijc_m3=akm_firm_dynamic (sum) N_youngtop10=t, by(czone naics2d)
save m5_psijc_dyn100pct_top10young_m2m3.dta, replace
gen t=1
fcollapse (mean) psijc_m2 psijc_m3 (sum) t [fw=N_youngtop10], by(czone)
rename t N_youngtop10
save m5_psijc_dyn100pct_top10young_m2m3_cz.dta, replace

* top 25, young
use czone naics2d  akm_firm akm_firm_dynamic using $data2step/young_comparemodels_top25.dta, replace
gen t=1
fcollapse (mean) psijc_m2=akm_firm psijc_m3=akm_firm_dynamic (sum) N_youngtop25=t, by(czone naics2d)
save m5_psijc_dyn100pct_top25young_m2m3.dta, replace
gen t=1
fcollapse (mean) psijc_m2 psijc_m3 (sum) t [fw=N_youngtop25], by(czone)
rename t N_youngtop25
save m5_psijc_dyn100pct_top25young_m2m3_cz.dta, replace

* new cz only model (10pct sampleB)
import delimited $data/M10_AKM_10pctB.txt, clear
rename v1 cz 
rename v2 psi_c_czm
rename v3 N_c_czm
drop v4 // likely ybar_c
format N %50.0fc
tempfile fe_czm
save `fe_czm', replace

* cz-ind model estimates (10pct sampleB)
import delimited $data/M10_AKM_10pctB_jc.txt, clear
rename v1 czone
rename v2 naics2d
rename v3 psi_jc_czindm
rename v4 N_jc_czindm
gen t=1
fcollapse (mean) psi_c_czindm=psi_jc_czindm (sum) N_c_czindm=t [fw=N_jc_czindm], by(czone)
tempfile fe_czindm
save `fe_czindm', replace

* ground-up cz effects (baseline, 100pct sample)
use "$data2step/AKMests_2stepfull_jc.dta", replace
fcollapse (mean) psi_2jc_2step N_2jc_2step, by(czone naics2d)s=
gen t=1
fcollapse (mean) psi_c_gupm=psi_2jc_2step (sum) N_c_gupm=t [fw=N_2jc_2step], by(czone )
rename czone cz
format N %50.0fc
tempfile fe_gupm
save `fe_gupm', replace

* merge
use `fe_czm', replace
merge 1:1 cz using `fe_czindm', nogen
merge 1:1 cz using `fe_gupm', nogen
gen czone=cz
merge 1:1 czone using m5_psijc_dyn100pct_top10young_m2m3_cz.dta, nogen keepusing(psijc_m2 psijc_m3) 
rename psijc_m2 psijc_m2_young
rename psijc_m3 psijc_m3_top10young
merge 1:1 czone using m5_psijc_dyn100pct_top25young_m2m3_cz.dta, nogen keepusing(psijc_m3) 
rename psijc_m3 psijc_m3_top25young
drop czone
egen test=rowmiss(psi_c_*)
qui sum psi_c_czindm
replace psi_c_czindm =r(mean) if psi_c_czindm ==. 


eststo clear
qui eststo r1: reg psi_c_czindm         psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r2: reg psi_c_czm            psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r3: reg psijc_m2_young       psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r4: reg psijc_m3_top10young  psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r5: reg psijc_m3_top25young  psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
esttab r*, se r2 title("output 7 - comparison of psics") scalar(sddepvar)

forval c=1/5{
drbeclass r`c', eststo(dr`c') addcount(count Npq) addest(r2 r2_a sddepvar)
}
noi esttab dr* using ${doutput}/7.csv, keep(psi_c_gupm) r2 se nonotes nonumbers nostar noobs append  title("output 7 - comparison of psics") scalar("Npq Person-quarter observations" "sddepvar SD of dependent variable")


********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 14
* RETURNS TO SKILL - DECOMPOSITION - REGRESSION BASED
use mig5_educpsis_jc_new_IMP.dta, replace
replace xbjcL=xbjcL+r_educacsHS
replace xbjcH=xbjcH+r_educacsCplus
rename y_educacsHS     yjcL
rename y_educacsCplus  yjcH
rename pe_educacsHS    ajcL
rename pe_educacsCplus ajcH
rename fe_educacsHS    phijcL
rename fe_educacsCplus phijcH
rename fe_educacs      phijc
gen phijc_alt=phijcL*(n_educacsHS/n_educacs)+phijcH*(n_educacsCplus/n_educacs)
by cz: egen czpopHS=sum(n_educacsHS)
by cz: egen czpopCplus=sum(n_educacsCplus)
by cz: egen czpopeducacs=sum(n_educacs)
gen sjcL=n_educacsHS/czpopHS
gen sjcH=n_educacsCplus/czpopCplus
assert n_educacsHS+n_educacsCplus==n_educacs
gen sjc=n_educacs/czpopeducacs
sum phi* sjc*
* construct main components
gen ycH=yjcH*sjcH
gen ycL=yjcL*sjcL
gen A=sjc*(phijcH-phijcL)
gen B=sjcH*ajcH-sjcL*ajcL
gen C=(sjcH-sjcL)*phijc
gen D=(sjcH-sjc)*(phijcH-phijc)-(sjcL-sjc)*(phijcL-phijc)
gen E=sjcH*xbjcH-sjcL*xbjcL
collapse (sum) ycH ycL A B C D E n_educacs sjc*, by(cz)
gen AplusD=A+D
merge 1:1 cz using mig5_educpsis_c_new_IMP.dta, keep(master match) keepusing(y_educacsHS y_educacsCplus n_educacsHS n_educacsCplus)
compare y_educacsHS ycL 
compare y_educacsCplus ycH
drop y_educacsHS y_educacsCplus
assert abs(ycH-ycL-(A+B+C+D+E))<=0.0001
gen dy=ycH-ycL
gen ln_n_educacs=ln(n_educacs)
merge n:1 cz using czranking6_alt-wage.dta, keep(match) nogen keepusing(mlogwage4 wcount)
gen logsize_c=ln(wcount/9)
eststo clear
local c=1
eststo clear
foreach rhs in mlogwage4 logsize_c {
foreach comp in dy A B C D E AplusD {
	qui eststo c`c': reg `comp' `rhs' [fw=n_educacs], vce(cluster cz)
	qui estadd scalar Npq=e(N)
	local c=`c'+1
}
forval c=1/7 {
drbeclass c`c', eststo(dc`c') addcount(count Npq)
}
if "`rhs'"=="mlogwage4" {
noi esttab dc* using ${doutput}/14.csv, keep(`rhs') se nonumbers nostar fragment noobs append title("Returns to Skill Decomposition - Regressions Based")
}
else if "`rhs'"~="mlogwage4" {
noi esttab dc* using ${doutput}/14.csv, keep(`rhs') se nonumbers nostar fragment noobs append nomtitles scalar("Npq Person-quarter observations")
}
local c=1
}

// D7: OUTPUT 15
* Variance decomposition of dy
qui sum dy [fw=n_educacs]
local Npq_educacs=r(N)
decomp2 dybsln dy "A B C D E AplusD" n_educacs
keep col*dy*
drop if col1dy==""
export excel col*dybsln using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(15, modify)



********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 16
* REGRESSIONS OF FE AND PE ON SIZE (C level)

* C-level
use mig5_educpsis_c_new_IMP.dta, replace
merge n:1 cz using czranking6_alt-wage.dta, keep(match) nogen keepusing(wcount)
gen logsize_c=ln(wcount/9)
cap drop y_c

foreach rhs in logsize_c {
eststo clear
local c=1
foreach sample in educacsHS educacsCplus {
qui eststo r`c': reg y_`sample'    `rhs'    [fw = n_`sample'], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
local c=`c'+1
qui eststo r`c': reg pe_`sample'    `rhs'    [fw = n_`sample'], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
local c=`c'+1
qui eststo r`c': reg fe_`sample'    `rhs'    [fw = n_`sample'], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
local c=`c'+1
}

forval c=1/6 {
drbeclass r`c', eststo(dr`c') addcount(count Npq)
}
if "`rhs'"=="logsize_c" {
noi esttab dr* using ${doutput}/16.csv, se keep(`rhs') nonotes nonumbers nostar noobs append title("Regressions akm components on size") scalar("Npq Person-quarter observations")
}
}



********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 17
* MAIN DECOMPOSITION - EDUCATION SAMPLE

* LOW EDUC 
use if educ==0 & _merge~=99  using M9twostep_step1xbr_4VEDUC.dta, replace
rename akm_person pe
rename akm_firm   fe
sort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
sort pikn qtime
by pikn: gen x=(_n==1)
decomp2 L   y       "pe fe xb r"             1
decomp2 Lc  y_c     "pe_c fe_c xb_c r_c"     1
keep col*
drop if col1L==""
export excel col2L col3L col4L  col2Lc col3Lc col4Lc using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(17, modify) cell(K1)


* HIGH EDUC
use if educ==1 & _merge~=99 using M9twostep_step1xbr_4VEDUC.dta, replace
rename akm_person pe
rename akm_firm   fe
sort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
sort pikn qtime
by pikn: gen x=(_n==1)
decomp2 H   y       "pe fe xb r"             1
decomp2 Hc  y_c     "pe_c fe_c xb_c r_c"     1
keep col*
drop if col1H==""
export excel col2H col3H col4H col2Hc col3Hc col4Hc using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(17, modify) cell(T1)



********************************************************************************
// D7: OUTPUT 18
use pikn qtime czone akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
gen y = akm_person + akm_firm + xb + r
rename akm_person pe
rename akm_firm fe
rename czone cz
* cz mover status
sort pikn qtime
by pikn: gen t1=1 if (_n>1 & ((cz~=cz[_n-1])))
by pikn: egen cmovecnt=sum(t1)
drop t1
gen mover=cmovecnt>=1
tab cmovecnt mover, miss
drop cmovecnt

* decomposition (movers)
preserve
keep if mover==1
fsort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
decomp2 indiv y       "pe fe xb r"           1
decomp2 c     y_c     "pe_c fe_c xb_c r_c"   1
export excel col1indiv col2indiv col3indiv col4indiv col2c col3c col4c if col1indiv~="" using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(18, modify) cell(A4)
restore 

* decomposition (stayers only)
keep if mover==0
fsort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
decomp2 indiv y       "pe fe xb r"               1 
decomp2 c     y_c     "pe_c fe_c xb_c r_c"       1 
export excel col1indiv col2indiv col3indiv col4indiv col2c col3c col4c if col1indiv~="" using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(18, modify) cell(A21) 



********************************************************************************
// D7: OUTPUT 19
* no uncertainty group
use pikn qtime czone akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
merge 1:1 pikn qtime using sample8NOUNC_peq.dta, keep(match) nogen
gen y = akm_person + akm_firm + xb + r
rename akm_person pe
rename akm_firm fe
rename czone cz
fsort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
decomp2 indiv y       "pe fe xb r"           1
decomp2 c     y_c     "pe_c fe_c xb_c r_c"   1
export excel col1indiv col2indiv col3indiv col4indiv col2c col3c col4c if col1indiv~="" using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(19, modify) cell(A4)

* uncertainty group
use pikn qtime czone akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
merge 1:1 pikn qtime using sample8NOUNC_peq.dta, keep(master) nogen
gen y = akm_person + akm_firm + xb + r
rename akm_person pe
rename akm_firm fe
rename czone cz
fsort cz
foreach v in y pe fe xb r {
by cz: egen `v'_c=mean(`v')
}
decomp2 indiv y       "pe fe xb r"               1 
decomp2 c     y_c     "pe_c fe_c xb_c r_c"       1 
export excel col1indiv col2indiv col3indiv col4indiv col2c col3c col4c if col1indiv~="" using ${doutput}/Yi_1_tabs_T13T26.xlsx, firstrow(variable) keepcellfmt sheet(19, modify) cell(A21) 


********************************************************************************
// D7: OUTPUT 20
use "$data2step/AKMests_2stepfull_jc.dta", replace
fcollapse (mean) alpha_2jc_2step y_2jc xb_2jc r_2jc psi_2jc_2step N_2jc_2step, by(czone naics2d)
gen t=1
fcollapse (mean) alpha_2jc_2step y_2jc xb_2jc r_2jc psi_2jc_2step N_2jc_2step (sum) N_c_gupm=t [fw=N_2jc_2step], by(czone )
drop N_2jc_2step
rename czone cz
 rename y_2jc y 
 rename alpha_2jc_2step pe
 rename psi_2jc_2step fe
 rename xb_2jc xb
 rename r_2jc r
 assert abs(y-(pe+fe+xb+r))<0.00001
format N %50.0fc
rename N_c_gupm fecnt 
count
qui sum y [fw=fecnt]
dis %030.0fc r(N)
rename y y_c
rename fe phi_c
rename pe pe_c
rename xb xb_c

preserve
use cw_cty_czone.dta, replace
tostring cty, replace format(%05.0f)
gen state=substr(cty,1,2)
destring state, replace
sort cz state
keep cz state
by cz: keep if _n==1
rename czone cz
tempfile czst
save `czst', replace
restore

merge 1:1 cz using `czst', keep(master match) nogen
replace cz=99999 if cz==34102
merge n:1 cz using czranking6_alt-wage.dta, keep(master match) nogen keepusing(wcount)
replace cz=34102 if cz==99999
gen size_c=wcount/9
replace size_c=10 if size_c==.
gen over25k=size_c>25000

xtile phi_c_quintile=phi_c, n(5)
gsort -over25k -phi_c
gen top10_phi_c=_n<=10
gsort -over25k phi_c
gen bottom10_phi_c=_n<=10
gen mid1090_phi_c=top10_phi_c==0 & bottom10_phi_c==0 & over25k==1
gen top4_phi_metro=(cz==11304|cz==19400|cz==37800|cz==37500)
gen top6_phi_rsrc=(cz==30801|cz==36404|cz==34102|cz==31401|cz==37601|cz==30904)  
gen small=over25k==0
egen test=rowtotal(top10_phi_c bottom10_phi_c mid1090_phi_c small)
assert test==1
drop test
egen test=rowtotal(top4_phi_metro top6_phi_rsrc bottom10_phi_c mid1090_phi_c small)
assert test==1
drop test
label var y_c     "$ y_{c}$"   
label var pe_c    "$\alpha_{c}$"
label var phi_c   "$\Psi_{c}$" 
label var xb_c    "$ X'\beta$"   

eststo clear
qui eststo c0: estpost sum  y_c pe_c   phi_c xb_c
qui sum y_c [fw=fecnt] 
estadd scalar Npq=r(N)
qui unique cz
qui estadd scalar nczs=r(sum)
qui eststo c1: estpost sum  y_c pe_c  phi_c xb_c if top4_phi_metro==1
qui sum y_c [fw=fecnt] if top4_phi_metro==1
estadd scalar Npq=r(N)
qui unique cz if top4_phi_metro==1
qui estadd scalar nczs=r(sum) 
qui eststo c2: estpost sum  y_c pe_c  phi_c xb_c if top6_phi_rsrc==1
qui sum y_c [fw=fecnt] if top6_phi_rsrc==1
estadd scalar Npq=r(N)
qui unique cz if top6_phi_rsrc==1
qui estadd scalar nczs=r(sum)
qui eststo c3: estpost sum  y_c pe_c  phi_c xb_c if mid1090_phi_c==1
qui sum y_c [fw=fecnt] if mid1090_phi_c==1
estadd scalar Npq=r(N)
qui unique cz if mid1090_phi_c==1
qui estadd scalar nczs=r(sum)
qui eststo c4: estpost sum  y_c pe_c   phi_c xb_c if bottom10_phi_c==1 
qui sum y_c [fw=fecnt] if bottom10_phi_c==1 
estadd scalar Npq=r(N)
qui unique cz if bottom10_phi_c==1 
qui estadd scalar nczs=r(sum)
qui eststo c5: estpost sum  y_c pe_c   phi_c xb_c if small==1 
qui sum y_c [fw=fecnt] if small==1 
estadd scalar Npq=r(N)
qui unique cz if small==1 
qui estadd scalar nczs=r(sum)
qui eststo c6: estpost sum  y_c pe_c   phi_c xb_c if phi_c_quintile==1 
qui sum y_c [fw=fecnt] if phi_c_quintile==1
estadd scalar Npq=r(N)
qui unique cz if phi_c_quintile==1
qui estadd scalar nczs=r(sum)
qui eststo c7: estpost sum  y_c pe_c   phi_c xb_c if phi_c_quintile==2 
qui sum y_c [fw=fecnt] if phi_c_quintile==2
estadd scalar Npq=r(N)
qui unique cz if phi_c_quintile==2
qui estadd scalar nczs=r(sum)
qui eststo c8: estpost sum  y_c pe_c   phi_c xb_c if phi_c_quintile==3 
qui sum y_c [fw=fecnt] if phi_c_quintile==3
estadd scalar Npq=r(N)
qui unique cz if phi_c_quintile==3
qui estadd scalar nczs=r(sum)
qui eststo c9: estpost sum  y_c pe_c   phi_c xb_c if phi_c_quintile==4 
qui sum y_c [fw=fecnt] if phi_c_quintile==4
estadd scalar Npq=r(N)
qui unique cz if phi_c_quintile==4
qui estadd scalar nczs=r(sum)
qui eststo c10: estpost sum  y_c pe_c   phi_c xb_c if phi_c_quintile==5 
qui sum y_c [fw=fecnt] if phi_c_quintile==5
estadd scalar Npq=r(N)
qui unique cz if phi_c_quintile==5
qui estadd scalar nczs=r(sum)
forval c=0/10 {
drbeclass c`c',  addest(mean sd) eststo(c`c') addcount(nczs) suppress(3)
}
* actual output
noi esttab  c* using ${doutput}/20.csv, main(mean) aux(sd) scalar( "nczs Number of CZs") nonotes nonumbers nostar noobs append mtitles("All" "Top 4 metro" "Top 6 rsrc" "Mid 10-90" "Bottom 10" "small25k" "Q1" "Q2" "Q3" "Q4" "Q5") title("Group level means of earnings and akm components - unweighted") 


********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 22
* match testing - EDUC SAMPLE, L + H. - firm level
use if _merge~=99 using M9twostep_step1xbr_4VEDUC.dta, replace
rename akm_person pe
rename akm_firm   fe
gen Nfe=1
fcollapse (mean) mfe=r (sum) Nfe, by(firmnum educ)
preserve
keep if educ==0
drop educ
rename mfe mfeL
rename Nfe NfeL
tempfile L
save `L', replace
restore
keep if educ==1
drop educ
rename mfe mfeH
rename Nfe NfeH
merge 1:1 firmnum using `L'
gen Nfe=NfeH+NfeL
save mig5_educmatcheffects_f.dta, replace

use mig5_educmatcheffects_f.dta, replace
assert Nfe==. if NfeH==.
assert Nfe==. if NfeL==.
gen subgroup_ov=Nfe~=.
replace subgroup_ov=0 if firmnum==.
replace Nfe=NfeH if NfeH~=. & Nfe==.
replace Nfe=NfeL if NfeL~=. & Nfe==.
qui sum mfeH
replace mfeH=r(mean) if mfeH==. & subgroup_ov==0
qui sum mfeL
replace mfeL=r(mean) if mfeL==. & subgroup_ov==0
eststo clear
qui eststo r1: reg mfeH mfeL [fw=Nfe] if subgroup_ov==1, vce(cluster firmnum)
cap qui estadd scalar Npq=e(N)
esttab r?, se r2 

forval c=1/1 {
drbeclass r`c', eststo(dr`c') addcount(count Npq Np)
}
noi esttab dr* using ${doutput}/22.csv, se nonotes nonumbers nostar noobs append mgroups("OV SUBGROUP1" "SUBGROUP0") title("Regressions of firm match effects for different education groups") scalar("Npq Person-quarter observations")



********************************************************************************
********************************************************************************
********************************************************************************
// D7: OUTPUT 23
* match testing - EDUC SAMPLE, L + H. - pik-firm level
use mig5_educmatcheffects_f.dta, replace
assert Nfe==. if NfeH==.
assert Nfe==. if NfeL==.
gen subgroup_ov=Nfe~=.
replace subgroup_ov=0 if firmnum==.
keep firmnum subgroup
tempfile subgrouplist
save `subgrouplist', replace


use if _merge~=99 using M9twostep_step1xbr_4VEDUC.dta, replace
rename akm_person pe
rename akm_firm   fe
gen Nif=1
fcollapse (mean) mif=r educ (sum) Nif, by(pikn firmnum )
fmerge m:1 firmnum using `subgrouplist', keep(master match) nogen
egen double firmnum_ed=group(firmnum educ)
assert educ==0 | educ==1
eststo clear
eststo r1: areg mif i.educ [w=Nif], absorb(firmnum) vce(cluster firmnum)
eststo r2: areg mif        [w=Nif], absorb(firmnum_ed) vce(cluster firmnum)
eststo r3: areg mif i.educ [w=Nif] if subgroup==1, absorb(firmnum) vce(cluster firmnum)
eststo r4: areg mif        [w=Nif] if subgroup==1, absorb(firmnum_ed) vce(cluster firmnum)
forval c=1/4 {
drbeclass r`c', eststo(dr`c') addcount(count)
}
noi esttab dr* using ${doutput}/23.csv, drop(*) r2 ar2 nonotes nonumbers nostar noobs append mgroups("EDUC" "OV SUBGROUP1") title("Regressions of pik-firm match effects on firm and educ dummies") scalar("Npq Person-quarter observations")

