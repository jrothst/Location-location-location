
/*----------------------------------------------------------------------------*\
REPLICATION CODE

Disclosure 9

input files:
czeffects.dta
czranking6_alt-wage.dta 
event_study_firmnum.dta 
AKMests_2stepfull_jc.dta 
mig5_educpsis_c_new_IMP.dta 
mig5_educpsis_jc_new_IMP.dta 

\*----------------------------------------------------------------------------*/

// Basic setup
set more off
clear
clear matrix
clear mata
set linesize 255
set maxvar 10000


// Set directories
do mig5_paths.do
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

********************************************************************************
// D9: OUTPUT 1 

* ground-up cz effects (baseline, 100pct sample)
use "$data2step/AKMests_2stepfull_jc.dta", replace
fcollapse (mean) psi_2jc_2step N_2jc_2step, by(czone naics2d)
gen t=1
fcollapse (mean) psi_c_gupm=psi_2jc_2step (sum) N_c_gupm=t [fw=N_2jc_2step], by(czone )
rename czone cz
format N %50.0fc
tempfile fe_gupm
save `fe_gupm', replace
* merge
use `fe_gupm', replace
gen czone=cz
merge 1:1 cz using czeffects.dta,  keepusing(logwage) keep(master match)
replace cz=99999 if _merge==1
drop logwage _merge
collapse (mean) psi_c_gupm (sum) N_c_gupm, by(cz)
merge 1:1 cz using czeffects.dta,  keepusing(logwage cz_effects_*) assert(match)
eststo clear
qui eststo r1: reg logwage         psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r2: reg cz_effects_m1            psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r3: reg cz_effects_m2       psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r4: reg  cz_effects_m3  psi_c_gupm   [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
esttab r*, se r2 ar2 title("output 1 - comparison of psics") scalar(sddepvar)
forval c=1/4{
drbeclass r`c', eststo(dr`c') addcount(count Npq) addest(r2 r2_a sddepvar)
}
noi esttab dr* using ${doutput}/1.csv, keep(psi_c_gupm) r2  se nonotes nonumbers nostar noobs append  title("output 1 - comparison of psics") scalar("Npq Person-quarter observations" "sddepvar SD of dependent variable")


********************************************************************************
// D9: OUTPUT 2 
use pikn qtime edate akm_firm lne m9twostep_xb m9twostep_r akm_person st_fips firm_vingtile_worig firm_vingtile_wdest using "$data/event_study_firmnum.dta", replace

	ren st_fips state
	gen y_m_xb = lne - m9twostep_xb
	ren m9twostep_r akm_res
	sort pikn qtime
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'=`v'-`v'[_n-1] if edate==0
	}
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'_t4=`v'[_n+4]-`v'[_n-1] if edate==0
	}
	keep if edate==0 
	xtile petercile=akm_person, n(3)	
	fcollapse (mean) d_akm_res d_y_m_xb d_akm_firm *_t4 (count) Npq=d_akm_res, by(firm_vingtile_worig firm_vingtile_wdest petercile) fast smart	
	eststo clear
	qui eststo r1: 	reg d_akm_res d_akm_firm if petercile==1
	qui eststo r2: 	reg d_akm_res d_akm_firm if petercile==2
	qui eststo r3: 	reg d_akm_res d_akm_firm if petercile==3
	qui eststo r4: 	reg d_akm_res_t4 d_akm_firm if petercile==1
	qui eststo r5: 	reg d_akm_res_t4 d_akm_firm if petercile==2
	qui eststo r6: 	reg d_akm_res_t4 d_akm_firm if petercile==3

forval c=1/6{
drbeclass r`c', eststo(dr`c') addcount(count) addest(r2)
}
noi esttab dr* using ${doutput}/2.csv, se nonotes nonumbers nostar noobs replace  title("output 2 - binscatter slope- terciles") scalar("Npq Person-quarter observations")


	
********************************************************************************
// D9: OUTPUT 3 
use pikn qtime edate akm_firm lne m9twostep_xb m9twostep_r akm_person st_fips firm_vingtile_worig firm_vingtile_wdest using "$data/event_study_firmnum.dta", replace
	ren st_fips state
	gen y_m_xb = lne - m9twostep_xb
	ren m9twostep_r akm_res
	sort pikn qtime
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'=`v'-`v'[_n-1] if edate==0
	}
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'_t4=`v'[_n+4]-`v'[_n-1] if edate==0
	}
	keep if edate==0 
	fcollapse (mean) d_akm_res d_y_m_xb d_akm_firm *_t4 (count) Npq=d_akm_res, by(firm_vingtile_worig firm_vingtile_wdest) fast smart
rename firm_vingtile_worig Vingtileoforigin
rename firm_vingtile_wdest Vingtileofdestination
rename d_akm_firm d_df
keep Vingtileoforigin Vingtileofdestination  d_y_m_xb_t4 d_df
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
eststo clear
eststo r1: reg changedown changeup
cap qui estadd scalar Npq=e(N)
forval c=1/1{
drbeclass r`c', eststo(dr`c') addest(r2)
}
noi esttab dr* using ${doutput}/3.csv, se nonotes nonumbers nostar noobs replace  title("output 3 - symmetry plot slope") 


********************************************************************************
// D9: OUTPUT 4
* ground-up cz effects 
use "$data2step/AKMests_2stepfull_jc.dta", replace
fcollapse (mean) psi_2jc_2step N_2jc_2step, by(czone naics2d)
gen t=1
fcollapse (mean) psi_c_gupm=psi_2jc_2step (sum) N_c_gupm=t [fw=N_2jc_2step], by(czone )
rename czone cz
format N %50.0fc
tempfile fe_gupm
save `fe_gupm', replace

use mig5_educpsis_c_new_IMP.dta, replace
merge 1:1 cz using `fe_gupm', keepusing(psi_c_gupm N_c_gupm)
replace cz=99999 if _merge~=3
collapse (mean) fe_educacsHS fe_educacsCplus fe_educacs psi_c_gupm (sum) N_c_gupm, by(cz)
foreach v in fe_educacsHS fe_educacsCplus fe_educacs {
qui sum `v'
replace `v'=r(mean) if `v'==.	
}

eststo clear
qui eststo r1: reg fe_educacsHS     psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r2: reg fe_educacsCplus  psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r3: reg fe_educacs       psi_c_gupm     [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r4: reg  fe_educacsHS    fe_educacs   [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r5: reg  fe_educacsCplus fe_educacs   [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
qui eststo r6: reg  fe_educacsHS    fe_educacsCplus   [fw=N_c_gupm], vce(cluster cz)
cap qui estadd scalar Npq=e(N)
qui sum `e(depvar)'  [fw=N_c_gupm]
qui estadd scalar sddepvar=r(sd)
esttab r*, se r2 ar2 title("output 4 - comparison of psics") scalar(sddepvar)
forval c=1/6{
drbeclass r`c', eststo(dr`c') addcount(count Npq) addest(r2 r2_a sddepvar)
}
noi esttab dr* using ${doutput}/4.csv, keep(psi_c_gupm fe_educacs fe_educacsCplus) r2  se nonotes nonumbers nostar noobs replace  title("output 4 - comparison of psics") scalar("Npq Person-quarter observations" "sddepvar SD of dependent variable")




********************************************************************************
// D9: OUTPUT 5 
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
gen ycH=yjcH*sjcH
gen ycL=yjcL*sjcL
gen A=sjc*(phijcH-phijcL)
gen B=sjcH*ajcH-sjcL*ajcL
gen C=(sjcH-sjcL)*phijc
gen D=(sjcH-sjc)*(phijcH-phijc)-(sjcL-sjc)*(phijcL-phijc)
gen E=sjcH*xbjcH-sjcL*xbjcL
collapse (sum) ycH ycL A B C D E n_educacs sjc*, by(cz)
gen AplusD=A+D
gen ACD=A+C+D
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
foreach comp in ACD {
	qui eststo c`c': reg `comp' `rhs' [fw=n_educacs], vce(cluster cz)
	qui estadd scalar Npq=e(N)
	local c=`c'+1
}
forval c=1/1 {
drbeclass c`c', eststo(dc`c') addcount(count Npq)
}
if "`rhs'"=="mlogwage4" {
noi esttab dc* using ${doutput}/5.csv, keep(`rhs') se nonumbers nostar fragment noobs append title("Returns to Skill Decomposition - Regressions Based")
}
else if "`rhs'"~="mlogwage4" {
noi esttab dc* using ${doutput}/5.csv, keep(`rhs') se nonumbers nostar fragment noobs append nomtitles scalar("Npq Person-quarter observations")
}
local c=1
}
