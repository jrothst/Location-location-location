/*----------------------------------------------------------------------------*\

	Disclosures 7 & 8
	Note: 
	
	Output Created Here:
		- Disc 7: tabs 1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 21
		- Disc 8: tabs 1, 2
		
	Input Datasets:
		- "$data2step/M9twostep_step1xbr.dta"
		- "$data2step/AKMests_2step.dta"
		- "$yidata/m5_ecf_seinunit.dta"
		- "$yidata/cw_cty_czone.dta"
		- "$yidata/mig5_pikqtime_1018_educacstop59_new.raw"
		- "$datadir/mig5_pikqtime_1018_cz*.dta"
		- "$lehd2018/icf_us.sas7bdat"
		- "$yidata/mig5_pikqtime_1018_finalpiklist.dta"
		- "$tempdir/datafrommatlab_firm.raw", clear
		- "$yidata/czranking6_alt-wage.dta"		
		
	Datasets Created Here:
		- CZ switchers "$data/top59_cz_switchers.dta"
		- Firmnum switchers "$data/top59_firmnum_switchers.dta"
		- AKM estimates "$data2step/AKMests_2stepfull_jc.dta"
		- Event Study (CZ) "$data/event_study_czone.dta"
		- Event Study (firmnum) "$data/event_study_firmnum.dta"
		- CZ level variables "$data2step/czone_vars.dta"

\*----------------------------------------------------------------------------*/

// Basic setup
cap log close
set more off
clear
clear matrix
clear mata
set linesize 95
set rmsg on

// Set directories
include mig5_paths.do


// Data Switches
local cz_switchers = 1
local firm_switchers = 1
local akm_ests = 1
local eventstudy_data_cz = 1
local eventstudy_data_firmnum = 1
local czone_vars = 1

// Analysis Switches
local d7_tab1 = 1
local d7_tab2 = 1
local d7_tab4 = 1
local d7_tab5 = 1
local d7_tab6 = 1
local d7_tab8 = 1
local d7_tab9_10 = 1
local d7_tab11 = 1
local d7_tab12 = 1
local d7_tab13 = 1
local d7_tab21 = 1
local d8_tab1 = 1
local d8_tab2 = 1


//------------------------------------------------------------------------------
// DATA: 
//------------------------------------------------------------------------------

// CZ SWITCHERS
//------------------------------------------------------------------------------
if `cz_switchers'==1 {
	
	// Log
	log using "$logs/6_fullAKM_czswitchers.log", text replace
	
	local first=1
	local files: dir "$datadir" files "mig5_*_cz*.dta"
	foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		di "Entering loop for CZ `cz'"
		
		use pikn qtime cz sein seinunit using "$datadir/`file'", clear
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
		gen cty_fips = leg_state+leg_county
		destring cty_fips, replace
		merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
		keep pikn cz czone
		gduplicates drop
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	
	// Find CZ-switchers
	sort pikn czone
	by pikn czone: gen temp = 1 if _n==1
	by pikn: egen n_czs = total(temp)
	tab n_czs
	keep if n_czs>=2
	drop temp n_czs cz czone
	gduplicates drop
	
	// Save CZ-switcher skinny file
	save "$data/top59_cz_switchers.dta", replace
	
cap log close
}


// Firmnum SWITCHERS
//------------------------------------------------------------------------------
if `firm_switchers'==1 {
	
	// Log
	log using "$logs/6_fullAKM_firmswitchers.log", text replace
	
	local first=1
	local files: dir "$datadir" files "mig5_*_cz*.dta"
	foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		di "Entering loop for CZ `cz'"
		
		use pikn qtime cz sein seinunit using "$datadir/`file'", clear
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
		gen cty_fips = leg_state+leg_county
		destring cty_fips, replace
		merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
		
		* Keep pikn-firmnum obs with _n>4
		egen double firmnum=group(czone leg_state sein seinunit)
		bys pikn firmnum: gen byte keep_obs = _n>4
		drop if keep_obs==0
		keep pikn czone leg_state sein seinunit
		duplicates drop
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	
	// Find firmnum-switchers
	egen double firmnum=group(czone leg_state sein seinunit)
	keep pikn firmnum
	sort pikn firmnum
	by pikn firmnum: gen temp = 1 if _n==1
	by pikn: egen n_firms = total(temp)
	tab n_firms
	keep if n_firms>=2
	keep pikn
	duplicates drop
	
	// Save CZ-switcher skinny file
	save "$data/top59_firmnum_switchers.dta", replace
	*/
cap log close
}


// AKM ESTIMATES
//------------------------------------------------------------------------------
if `akm_ests'==1 {

	// Log 
	log using "$logs/6_fullAKM_ests.log", text replace
	
	// 4jc 
	use "$data2step/AKMests_2step.dta", clear
	bys czone naics4d: egen N_4jc_2step = total(joblength)
	collapse (mean) psi_4jc_2step=akm_firm alpha_4jc_2step=akm_person N_4jc_2step [aw=joblength], by(czone naics4d)
	xtile ving_4jc = psi_4jc_2step, n(20)
	xtile vingw_4jc = psi_4jc_2step [fw=N_4jc_2step], n(20)
	
	// 2jc 
	order czone
	gen naics2d = floor(naics4d/100), b(naics4d)
	preserve
		collapse (mean) psi_2jc_2step=psi_4jc_2step alpha_2jc_2step=alpha_4jc_2step [fw=N_4jc_2step], by(czone naics2d)
		tempfile psi_2jc_2step
		save `psi_2jc_2step'
	restore
	merge m:1 czone naics2d using `psi_2jc_2step', assert(3) nogen
	preserve
		collapse (sum) N_2jc_2step=N_4jc_2step, by(czone naics2d)
		tempfile N_2jc_2step
		save `N_2jc_2step'
	restore
	merge m:1 czone naics2d using `N_2jc_2step', assert(3) nogen
	preserve
		keep czone naics2d *_2jc_2step
		duplicates drop
		xtile ving_2jc = psi_2jc_2step, n(20)
		xtile vingw_2jc = psi_2jc_2step [fw=N_2jc_2step], n(20)
		keep czone naics2d ving*
		tempfile ving_2jc
		save `ving_2jc'
	restore
	merge m:1 czone naics2d using `ving_2jc', assert(3) nogen
	tempfile AKMests_2stepfull_jc
	save `AKMests_2stepfull_jc'
	
	// Rest of CZ-ind variables
	preserve
	use czone naics4d akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen naics2d = floor(naics4d/100), b(naics4d)
	gen y = akm_person + akm_firm + xb + r
	merge m:1 czone naics4d using `AKMests_2stepfull_jc', assert(3) nogen keepusing(psi_2jc_2step)
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	collapse (mean) y_2jc=y xb_2jc=xb r_2jc=r df_m_psi2jc_2jc=df_m_psi2jc, by(czone naics2d)
	tempfile yxbr
	save `yxbr'
	restore
	merge m:1 czone naics2d using `yxbr', assert(3) nogen
	
	// Save CZ-ind AKM ests
	isid czone naics4d
	save "$data2step/AKMests_2stepfull_jc.dta", replace
	
cap log close
	
}


// EVENT STUDY DATA (CZ MOVES)
//------------------------------------------------------------------------------
if `eventstudy_data_cz'==1 {	
	
	// Log
	log using "$logs/6_fullAKM_esdata_cz.log", text replace
	
	// Two-step CZ-4d ind effects
	use czone naics4d psi_4jc_2step alpha_4jc_2step N_4jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
	xtile ving_4jc = psi_4jc_2step, n(20)
	tempfile psi_4jc_2step
	save `psi_4jc_2step'
	
	// Two-step CZ-2d ind effects
	use czone naics2d psi_2jc_2step alpha_2jc_2step N_2jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
	duplicates drop
	xtile ving_2jc = psi_2jc_2step, n(20)
	tempfile psi_2jc_2step
	save `psi_2jc_2step'
	
	// Two-step 4-digit ind effects
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (mean) psi_4j_2step=psi_4jc_2step alpha_4j_2step=alpha_4jc_2step [fw=N_4jc_2step], by(naics4d)
	preserve
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (sum) N_4j_2step=N_4jc_2step, by(naics4d)
	tempfile N_4j_2step
	save `N_4j_2step'
	restore
	merge 1:1 naics4d using `N_4j_2step', assert(3) nogen
	xtile ving_4j = psi_4j_2step, n(20)
	tempfile psi_4j_2step
	save `psi_4j_2step'
	
	// Two-step 2-digit ind effects
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (mean) psi_2j_2step=psi_4jc_2step alpha_2j_2step=alpha_4jc_2step [fw=N_4jc_2step], by(naics2d)
	preserve
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (sum) N_2j_2step=N_4jc_2step, by(naics2d)
	tempfile N_2j_2step
	save `N_2j_2step'
	restore
	merge 1:1 naics2d using `N_2j_2step', assert(3) nogen
	xtile ving_2j = psi_2j_2step, n(20)
	tempfile psi_2j_2step
	save `psi_2j_2step'
	
	
	// Firm hierarchy variables
	//--------------------------------------------------------------------------
	use "$data2step/AKMests_2step.dta", clear
	gen naics2d = floor(naics4d/100), b(naics4d)
	merge m:1 czone naics4d using `psi_4jc_2step', assert(3) nogen
	merge m:1 czone naics2d using `psi_2jc_2step', assert(3) nogen
	merge m:1 naics4d using `psi_4j_2step', assert(3) nogen
	merge m:1 naics2d using `psi_2j_2step', assert(3) nogen
	
	// Mean firm effect 4d - mean firm effect 2d
	gen psi4j_m_psi2j = psi_4j_2step - psi_2j_2step
	
	// AKM hierarchy variables
	gen df_m_psi4j = akm_firm - psi_4j_2step
	gen df_m_psi2j = akm_firm - psi_2j_2step
	gen df_m_psi4jc = akm_firm - psi_4jc_2step
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	
	// split firmid into sein and seinunit
	*split firmid, generate(sein) parse("_")
	*ren sein1 sein
	*ren sein2 seinunit
	
	keep czone firmid naics4d psi4j_m_psi2j df_m_psi*
	gduplicates drop
	tempfile y_vars
	save `y_vars', replace
***	
	// AKM residuals (~60 mins; saved for troubleshooting)
	use "$data/top59_cz_switchers.dta", clear
	merge 1:m pikn using "$data2step/M9twostep_step1xbr.dta", keep(3) keepusing(pikn qtime sein seinunit jobid akm_person akm_firm xb r) nogen
	save "$tempdata/akm_resids.dta", replace
***/	
	
	// CZ-switchers
	//--------------------------------------------------------------------------
	local first=1
	local files: dir "$datadir" files "mig5_*_cz*.dta"
	foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		di "Entering loop for CZ `cz'"
		
		// Start with CZ-switcher pik list and merge LEHD data
		use "$data/top59_cz_switchers.dta", clear
		merge 1:m pikn using "$datadir/`file'", keep(3) nogen
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		
		// Merge on CZ (important for division-level obs)
		merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
		gen cty_fips = leg_state+leg_county
		destring cty_fips, replace
		merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
		order czone, a(cz)
		ren cz top59cz
		drop sein seinunit state division year quarter leg_county cty_fips
		ren leg_state st_fips
		destring(st_fips), replace
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	sort pikn qtime
	
	
	// Mobility restrictions - pre-post
	by pikn: gen t1=1 if (_n>1 & ((czone~=czone[_n-1]) | (naics2d~=naics2d[_n-1])))
	* stayed in destination CZ & ind in 4 consecutive quarters
	by pikn: gen t2=1 if t1==1 & ((qtime[_n+1]==qtime+1) & (czone==czone[_n+1]) & (naics2d==naics2d[_n+1])) & ///
	 ((qtime[_n+2]==qtime+2) & (czone==czone[_n+2]) & (naics2d==naics2d[_n+2])) & ///
	 ((qtime[_n+3]==qtime+3) & (czone==czone[_n+3]) & (naics2d==naics2d[_n+3])) & ///
	 ((qtime[_n+4]==qtime+4) & (czone==czone[_n+4]) & (naics2d==naics2d[_n+4]))
	
	* stayed in origin CZ & ind in 5 previous quarters (origin is at t-1)
	* IMPORTANT: allowing up to 3 quarters in between (since dropped transitional quarters) 
	by pikn: gen t3=1 if t1==1  & ///
	 ((qtime[_n-2]==qtime[_n-1]-1) & (czone[_n-1]==czone[_n-2]) & (naics2d[_n-1]==naics2d[_n-2])) & ///
	 ((qtime[_n-3]==qtime[_n-2]-1) & (czone[_n-2]==czone[_n-3]) & (naics2d[_n-2]==naics2d[_n-3])) & ///
	 ((qtime[_n-4]==qtime[_n-3]-1) & (czone[_n-3]==czone[_n-4]) & (naics2d[_n-3]==naics2d[_n-4])) & ///
	 ((qtime[_n-5]==qtime[_n-4]-1) & (czone[_n-4]==czone[_n-5]) & (naics2d[_n-4]==naics2d[_n-5]))
	
	* flag - t4 are the relevant moves (not unique by pikn)
	egen t4=rowtotal(t1 t2 t3)
	drop t1 t2 t3
	gen t1=(t4==3) 
	gen edate=0 if t1==1

	****
	by pikn: egen multmoves=sum(t1)
	keep if multmoves==1
	**! need to make adjustment for multiple moves per pik, will need to expand!
	* for now, ignore those with multiple moves
	********
	by pikn: replace edate=edate[_n-1]+1 if edate[_n-1]~=.
	forval i=1/5{
	by pikn: replace edate=edate[_n+1]-1 if edate[_n+1]~=.
	}
	keep if edate>=-5 & edate<=4

	* transition gap restrictions
	by pikn: gen gap=(qtime-qtime[_n-1]-1) if t1==1  
	tab gap
	drop if gap==0
	*** looks like "0 gaps" are due to reclassification of industries or establishment moves
	by pikn: egen mgap=max(gap) 
	keep if mgap<=6
	drop mgap

	// Merge on AKM residuals
	split firmid, gen(sein) parse("_")
	ren sein1 sein
	ren sein2 seinunit
	merge 1:1 pikn qtime sein seinunit using "$tempdata/akm_resids.dta", keep(3) keepusing (jobid akm_person akm_firm xb r) nogen
	cap rm "$tempdata/akm_resids.dta"
	drop sein seinunit
	ren xb m9twostep_xb
	ren r m9twostep_r
	
	by pikn: gen czswitch=1 if (_n>1 & (czone~=czone[_n-1]))
	by pikn: gen naics2dswitch=1 if (_n>1 & (naics2d~=naics2d[_n-1])) 
	* note that here we assume there is only one relevant move per pik - so far that's the case, but not necessarily true always

	* switch types
	gen switchtype=1 if czswitch==1 & naics2dswitch==.
	replace switchtype=2 if czswitch==. & naics2dswitch==1
	replace switchtype=3 if czswitch==1 & naics2dswitch==1
	tab switchtype if edate==0, miss
	
	* origin and destination CZ/ind
	gen x=czone if t1[_n+1]==1
	by pikn: egen czorig=max(x)
	drop x
	gen x=naics2d if t1[_n+1]==1
	by pikn: egen naics2dorig=max(x)
	drop x
	gen x=naics4d if t1[_n+1]==1
	by pikn: egen naics4dorig=max(x)
	drop x
	gen x=czone if t1==1
	by pikn: egen czdest=max(x)
	drop x
	gen x=naics2d if t1==1
	by pikn: egen naics2ddest=max(x)
	drop x
	gen x=naics4d if t1==1
	by pikn: egen naics4ddest=max(x)
	drop x
	rename czone truecz
	rename naics2d truenaics2d
	rename naics4d truenaics4d
	
	* merge 2step CZ-4d ind effect
	rename czorig czone
	rename naics4dorig naics4d
	merge n:1 czone naics4d using `psi_4jc_2step', keep(master match) nogen keepusing(psi_4jc_2step ving_4jc)
	rename psi_4jc_2step psi_4jc_2steporig
	rename ving_4jc ving_4jcorig
	rename czone czorig
	rename naics4d naics4dorig
	rename czdest czone
	rename naics4ddest naics4d
	merge n:1 czone naics4d using `psi_4jc_2step', keep(master match) nogen keepusing(psi_4jc_2step ving_4jc)
	rename psi_4jc_2step psi_4jc_2stepdest
	rename ving_4jc ving_4jcdest
	rename czone czdest
	rename naics4d naics4ddest
	drop if psi_4jc_2steporig==. | psi_4jc_2stepdest==.
	
	* merge 2step CZ-2d ind effect
	rename czorig czone
	rename naics2dorig naics2d
	merge n:1 czone naics2d using `psi_2jc_2step', keep(master match) nogen keepusing(psi_2jc_2step ving_2jc)
	rename psi_2jc_2step psi_2jc_2steporig
	rename ving_2jc ving_2jcorig
	rename czone czorig
	rename naics2d naics2dorig
	rename czdest czone
	rename naics2ddest naics2d
	merge n:1 czone naics2d using `psi_2jc_2step', keep(master match) nogen keepusing(psi_2jc_2step ving_2jc)
	rename psi_2jc_2step psi_2jc_2stepdest
	rename ving_2jc ving_2jcdest
	rename czone czdest
	rename naics2d naics2ddest
	drop if psi_2jc_2steporig==. | psi_2jc_2stepdest==.
	
	* merge 2step 4d ind effect
	rename naics4dorig naics4d
	merge n:1 naics4d using `psi_4j_2step', keep(master match) nogen keepusing(psi_4j_2step ving_4j)
	rename psi_4j_2step psi_4j_2steporig
	rename ving_4j ving_4jorig
	rename naics4d naics4dorig
	rename naics4ddest naics4d
	merge n:1 naics4d using `psi_4j_2step', keep(master match) nogen keepusing(psi_4j_2step ving_4j)
	rename psi_4j_2step psi_4j_2stepdest
	rename ving_4j ving_4jdest
	rename naics4d naics4ddest
	drop if psi_4j_2steporig==. | psi_4j_2stepdest==.
	
	* merge 2step 2d ind effect quartiles
	rename naics2dorig naics2d
	merge n:1 naics2d using `psi_2j_2step', keep(master match) nogen keepusing(psi_2j_2step ving_2j)
	rename psi_2j_2step psi_2j_2steporig
	rename ving_2j ving_2jorig
	rename naics2d naics2dorig
	rename naics2ddest naics2d
	merge n:1 naics2d using `psi_2j_2step', keep(master match) nogen keepusing(psi_2j_2step ving_2j)
	rename psi_2j_2step psi_2j_2stepdest
	rename ving_2j ving_2jdest
	rename naics2d naics2ddest
	drop if psi_2j_2steporig==. | psi_2j_2stepdest==.
	
	* merge firm hierarchy measure
	ren truenaics4d naics4d
	ren truenaics2d naics2d
	ren truecz czone
	merge m:1 czone firmid naics4d using `y_vars', keep(1 3) nogen keepusing(psi4j_m_psi2j df_m_psi*)
	
	* add earnings measures
	rename y lne
	qui reg lne ibn.qtime c.age##c.age##c.age, nocons
	predict lnea, res
	order lnea, a(lne)
	
	* enough to do tempevent
	sort pikn qtime
	
	// Save
	save "$data/event_study_czone.dta", replace
	
cap log close
}


// EVENT STUDY DATA (FIRMNUM MOVES)
//------------------------------------------------------------------------------
if `eventstudy_data_firmnum'==1 {	
	
	// Log
	log using "$logs/6_fullAKM_esdata_firmnum.log", text replace
	
	// Two-step CZ-4d ind effects
	use czone naics4d psi_4jc_2step alpha_4jc_2step N_4jc_2step ving_4jc vingw_4jc using "$data2step/AKMests_2stepfull_jc.dta", clear
	tempfile psi_4jc_2step
	save `psi_4jc_2step'
	
	// Two-step CZ-2d ind effects
	use czone naics2d psi_2jc_2step alpha_2jc_2step N_2jc_2step ving_2jc vingw_2jc y_2jc xb_2jc r_2jc df_m_psi2jc_2jc using "$data2step/AKMests_2stepfull_jc.dta", clear
	duplicates drop
	tempfile psi_2jc_2step
	save `psi_2jc_2step'
	
	// Two-step 4-digit ind effects
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (mean) psi_4j_2step=psi_4jc_2step alpha_4j_2step=alpha_4jc_2step [fw=N_4jc_2step], by(naics4d)
	preserve
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (sum) N_4j_2step=N_4jc_2step, by(naics4d)
	tempfile N_4j_2step
	save `N_4j_2step'
	restore
	merge 1:1 naics4d using `N_4j_2step', assert(3) nogen
	xtile ving_4j = psi_4j_2step, n(20)
	tempfile psi_4j_2step
	save `psi_4j_2step'
	
	// Two-step 2-digit ind effects
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (mean) psi_2j_2step=psi_4jc_2step alpha_2j_2step=alpha_4jc_2step [fw=N_4jc_2step], by(naics2d)
	preserve
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	collapse (sum) N_2j_2step=N_4jc_2step, by(naics2d)
	tempfile N_2j_2step
	save `N_2j_2step'
	restore
	merge 1:1 naics2d using `N_2j_2step', assert(3) nogen
	xtile ving_2j = psi_2j_2step, n(20)
	tempfile psi_2j_2step
	save `psi_2j_2step'
	
	
	// Firm hierarchy variables
	//--------------------------------------------------------------------------
	use "$data2step/AKMests_2step.dta", clear
	gen naics2d = floor(naics4d/100), b(naics4d)
	merge m:1 czone naics4d using `psi_4jc_2step', assert(3) nogen
	merge m:1 czone naics2d using `psi_2jc_2step', assert(3) nogen
	merge m:1 naics4d using `psi_4j_2step', assert(3) nogen
	merge m:1 naics2d using `psi_2j_2step', assert(3) nogen
	
	// Mean firm effect 4d - mean firm effect 2d
	gen psi4j_m_psi2j = psi_4j_2step - psi_2j_2step
	
	// AKM hierarchy variables
	gen df_m_psi4j = akm_firm - psi_4j_2step
	gen df_m_psi2j = akm_firm - psi_2j_2step
	gen df_m_psi4jc = akm_firm - psi_4jc_2step
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	
	// split firmid into sein and seinunit
	*split firmid, generate(sein) parse("_")
	*ren sein1 sein
	*ren sein2 seinunit
	
	keep czone firmid naics4d psi4j_m_psi2j df_m_psi*
	gduplicates drop
	tempfile y_vars
	save `y_vars', replace
/***	
	// AKM residuals (~60 mins; saved for troubleshooting)
	use "$data/top59_firmnum_switchers.dta", clear
	merge 1:m pikn using "$data2step/M9twostep_step1xbr.dta", keep(3) keepusing(pikn qtime sein seinunit jobid akm_person akm_firm xb r) nogen
	save "$tempdata/akm_resids.dta", replace
***/	
	
	// CZ-switchers
	//--------------------------------------------------------------------------
	local first=1
	local files: dir "$datadir" files "mig5_*_cz*.dta"
	*foreach file in mig5_pikqtime_1018_cz900.dta mig5_pikqtime_1018_czd1.dta {
	foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		di "Entering loop for CZ `cz'"
		
		// Start with firmnum-switcher pik list and merge LEHD data
		use "$data/top59_firmnum_switchers.dta", clear
		merge 1:m pikn using "$datadir/`file'", keep(3) nogen
		gen year=floor((qtime-1)/4+1985)
		gen quarter=qtime-4*(year-1985)
		
		// Merge on CZ (important for division-level obs)
		merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
		gen cty_fips = leg_state+leg_county
		destring cty_fips, replace
		merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
		order czone, a(cz)
		ren cz top59cz
		drop sein seinunit state division year quarter leg_county cty_fips
		ren leg_state st_fips
		destring(st_fips), replace
		if `first'==1 {
			local czs `cz'
		}
		else if `first'==0 {
			local czs `czs' `cz'
		}
		tempfile temp_`cz'
		save `temp_`cz'', replace
		local first=0
	}
	
	di "`czs'"

	local first=1
	foreach cz in `czs' {
		if `first'==1 {
			di "`cz'"
			use `temp_`cz'', clear
		}
		else if `first'==0 {
			append using `temp_`cz''
		}
		local first=0
	}
	sort pikn qtime
	
	
	// Mobility restrictions - pre-post
	egen double firmnum=group(czone st_fips firmid)
	by pikn: gen t1=1 if (_n>1 & ((firmnum~=firmnum[_n-1])))
	* stayed in destination firmnum in 4 consecutive quarters
	by pikn: gen t2=1 if t1==1 & ((qtime[_n+1]==qtime+1) & (firmnum==firmnum[_n+1])) & ///
	 ((qtime[_n+2]==qtime+2) & (firmnum==firmnum[_n+2])) & ///
	 ((qtime[_n+3]==qtime+3) & (firmnum==firmnum[_n+3])) & ///
	 ((qtime[_n+4]==qtime+4) & (firmnum==firmnum[_n+4]))
	
	* stayed in origin firmnum in 5 previous quarters (origin is at t-1)
	* IMPORTANT: allowing up to 3 quarters in between (since dropped transitional quarters) 
	by pikn: gen t3=1 if t1==1  & ///
	 ((qtime[_n-2]==qtime[_n-1]-1) & (firmnum[_n-1]==firmnum[_n-2])) & ///
	 ((qtime[_n-3]==qtime[_n-2]-1) & (firmnum[_n-2]==firmnum[_n-3])) & ///
	 ((qtime[_n-4]==qtime[_n-3]-1) & (firmnum[_n-3]==firmnum[_n-4])) & ///
	 ((qtime[_n-5]==qtime[_n-4]-1) & (firmnum[_n-4]==firmnum[_n-5]))
	
	* flag - t4 are the relevant moves (not unique by pikn)
	egen t4=rowtotal(t1 t2 t3)
	drop t1 t2 t3
	gen t1=(t4==3) 
	gen edate=0 if t1==1

	****
	by pikn: egen multmoves=sum(t1)
	keep if multmoves==1
	**! need to make adjustment for multiple moves per pik, will need to expand!
	* for now, ignore those with multiple moves
	********
	by pikn: replace edate=edate[_n-1]+1 if edate[_n-1]~=.
	forval i=1/5{
	by pikn: replace edate=edate[_n+1]-1 if edate[_n+1]~=.
	}
	keep if edate>=-5 & edate<=4

	* transition gap restrictions
	by pikn: gen gap=(qtime-qtime[_n-1]-1) if t1==1  
	tab gap
	drop if gap==0
	*** looks like "0 gaps" are due to reclassification of industries or establishment moves
	by pikn: egen mgap=max(gap) 
	keep if mgap<=6
	drop mgap

	// Merge on AKM residuals
	split firmid, gen(sein) parse("_")
	ren sein1 sein
	ren sein2 seinunit
	merge 1:1 pikn qtime sein seinunit using "$tempdata/akm_resids.dta", keep(3) keepusing (jobid akm_person akm_firm xb r) nogen
***	cap rm "$tempdata/akm_resids.dta"
	drop sein seinunit
	ren xb m9twostep_xb
	ren r m9twostep_r
	
	by pikn: gen czswitch=1 if (_n>1 & (czone~=czone[_n-1]))
	by pikn: gen naics2dswitch=1 if (_n>1 & (naics2d~=naics2d[_n-1]))
	by pikn: gen firmnumswitch=1 if (_n>1 & (firmnum~=firmnum[_n-1]))
	* note that here we assume there is only one relevant move per pik - so far that's the case, but not necessarily true always

	* CZ-ind switch types
	gen switchtype=1 if czswitch==1 & naics2dswitch==.
	replace switchtype=2 if czswitch==. & naics2dswitch==1
	replace switchtype=3 if czswitch==1 & naics2dswitch==1
	tab switchtype if edate==0, miss
	
	* origin and destination CZ/ind/akm_firm
	gen x=czone if t1[_n+1]==1
	by pikn: egen czorig=max(x)
	drop x
	gen x=naics2d if t1[_n+1]==1
	by pikn: egen naics2dorig=max(x)
	drop x
	gen x=naics4d if t1[_n+1]==1
	by pikn: egen naics4dorig=max(x)
	drop x
	gen x=akm_firm if t1[_n+1]==1
	by pikn: egen akm_firmorig=max(x)
	drop x
	gen x=czone if t1==1
	by pikn: egen czdest=max(x)
	drop x
	gen x=naics2d if t1==1
	by pikn: egen naics2ddest=max(x)
	drop x
	gen x=naics4d if t1==1
	by pikn: egen naics4ddest=max(x)
	drop x
	gen x=akm_firm if t1==1
	by pikn: egen akm_firmdest=max(x)
	drop x
	rename czone truecz
	rename naics2d truenaics2d
	rename naics4d truenaics4d
	
	* merge 2step CZ-4d ind effect
	rename czorig czone
	rename naics4dorig naics4d
	merge n:1 czone naics4d using `psi_4jc_2step', keep(master match) nogen keepusing(psi_4jc_2step ving_4jc)
	rename psi_4jc_2step psi_4jc_2steporig
	rename ving_4jc ving_4jcorig
	rename czone czorig
	rename naics4d naics4dorig
	rename czdest czone
	rename naics4ddest naics4d
	merge n:1 czone naics4d using `psi_4jc_2step', keep(master match) nogen keepusing(psi_4jc_2step ving_4jc)
	rename psi_4jc_2step psi_4jc_2stepdest
	rename ving_4jc ving_4jcdest
	rename czone czdest
	rename naics4d naics4ddest
	drop if psi_4jc_2steporig==. | psi_4jc_2stepdest==.
	
	* merge 2step CZ-2d ind effect
	rename czorig czone
	rename naics2dorig naics2d
	merge n:1 czone naics2d using `psi_2jc_2step', keep(master match) nogen keepusing(psi_2jc_2step ving_2jc)
	rename psi_2jc_2step psi_2jc_2steporig
	rename ving_2jc ving_2jcorig
	rename czone czorig
	rename naics2d naics2dorig
	rename czdest czone
	rename naics2ddest naics2d
	merge n:1 czone naics2d using `psi_2jc_2step', keep(master match) nogen keepusing(psi_2jc_2step ving_2jc)
	rename psi_2jc_2step psi_2jc_2stepdest
	rename ving_2jc ving_2jcdest
	rename czone czdest
	rename naics2d naics2ddest
	drop if psi_2jc_2steporig==. | psi_2jc_2stepdest==.
	
	* merge 2step 4d ind effect
	rename naics4dorig naics4d
	merge n:1 naics4d using `psi_4j_2step', keep(master match) nogen keepusing(psi_4j_2step ving_4j)
	rename psi_4j_2step psi_4j_2steporig
	rename ving_4j ving_4jorig
	rename naics4d naics4dorig
	rename naics4ddest naics4d
	merge n:1 naics4d using `psi_4j_2step', keep(master match) nogen keepusing(psi_4j_2step ving_4j)
	rename psi_4j_2step psi_4j_2stepdest
	rename ving_4j ving_4jdest
	rename naics4d naics4ddest
	drop if psi_4j_2steporig==. | psi_4j_2stepdest==.
	
	* merge 2step 2d ind effect quartiles
	rename naics2dorig naics2d
	merge n:1 naics2d using `psi_2j_2step', keep(master match) nogen keepusing(psi_2j_2step ving_2j)
	rename psi_2j_2step psi_2j_2steporig
	rename ving_2j ving_2jorig
	rename naics2d naics2dorig
	rename naics2ddest naics2d
	merge n:1 naics2d using `psi_2j_2step', keep(master match) nogen keepusing(psi_2j_2step ving_2j)
	rename psi_2j_2step psi_2j_2stepdest
	rename ving_2j ving_2jdest
	rename naics2d naics2ddest
	drop if psi_2j_2steporig==. | psi_2j_2stepdest==.
	
	* merge firm hierarchy measure
	ren truenaics4d naics4d
	ren truenaics2d naics2d
	ren truecz czone
	merge m:1 czone firmid naics4d using `y_vars', keep(1 3) nogen keepusing(psi4j_m_psi2j df_m_psi*)
	
	* add earnings measures
	rename y lne
	qui reg lne ibn.qtime c.age##c.age##c.age, nocons
	predict lnea, res
	order lnea, a(lne)
	
	* enough to do tempevent
	sort pikn qtime
	
	// Save
	save "$data/event_study_firmnum.dta", replace
***/	
cap log close
}


// CZ-level variables
//------------------------------------------------------------------------------
if `czone_vars'==1 {	
	
	// Log
	log using "$logs/6_fullAKM_czone_vars.log", text replace
	
	// y_c
	//--------------------------------------------------------------------------
	use czone akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen y = akm_person + akm_firm + xb + r
	drop akm_person akm_firm xb r
	sort czone
	collapse (mean) y_c=y, by(czone)
	tempfile y_c
	save `y_c'
	
	// logsize_c
	//--------------------------------------------------------------------------
	use czone joblength using "$data2step/AKMests_2step.dta", replace
	collapse (sum) N_c=joblength, by(czone)
	gen lnN_c = ln(N_c)
	tempfile lnN_c
	save `lnN_c'
	
	// educ_c
	//--------------------------------------------------------------------------
	import delimited using "$yidata/mig5_pikqtime_1018_educacstop59_new.raw", clear
	ren v1 pikn
	ren v2 qtime
	ren v3 firmid
	ren v4 y
	ren v5 firmsize
	ren v6 age
	ren v7 cz
	ren v8 naics4d
	ren v9 educ
	drop firmid y firmsize age v10 v11 v12 v13
	
	// Merge on CZ for division-level obs
	// NOTE: start back here 2/4, _N=163,060,185
	preserve
	keep if cz<10
	local first=1
	local files: dir "$datadir" files "mig5_*_cz*.dta"
	foreach file in mig5_pikqtime_1018_czd1.dta mig5_pikqtime_1018_czd2.dta mig5_pikqtime_1018_czd3.dta mig5_pikqtime_1018_czd4.dta mig5_pikqtime_1018_czd5.dta mig5_pikqtime_1018_czd6.dta mig5_pikqtime_1018_czd7.dta mig5_pikqtime_1018_czd8.dta mig5_pikqtime_1018_czd9.dta {
	*foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		local cz = regexr("`cz'", "[czd]+", "")
		di "Entering loop for CZ `cz'"
		
		if `first'==1 {
			merge 1:1 pikn qtime using "$datadir/`file'", keep(1 3) keepusing(firmid) nogen
		}
		else if `first'==0 {
			merge 1:1 pikn qtime using "$datadir/`file'", keep(1 3 4) keepusing(firmid) nogen update
		}
		local first=0
		
	}
	split firmid, gen(sein) parse("_")
	ren sein1 sein
	ren sein2 seinunit
	drop firmid
	gen year=floor((qtime-1)/4+1985)
	gen quarter=qtime-4*(year-1985)
	merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
	gen cty_fips = leg_state+leg_county
	destring cty_fips, replace
	merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
	order czone, a(cz)
	ren cz top59cz
	drop sein seinunit year quarter leg_state leg_county cty_fips
	ren educ educacs
	gen byte educ = (educacs==2|educacs==3|educacs==4)
	collapse (mean) educ_c=educ, by(czone) fast
	tempfile educ_c
	save `educ_c'
	restore
	
	// Top 50 CZs
	keep if cz>10
	ren educ educacs
	ren cz czone
	gen educ = (educacs==2|educacs==3|educacs==4)
	collapse (mean) educ_c=educ, by(czone) fast
	append using `educ_c'
	sort czone
	tempfile educ_c
	save `educ_c', replace
	
	// PE sd and deciles, full sample, aggregated at c level (tempest.do)
	//--------------------------------------------------------------------------
	use czone joblength akm_firm akm_person using "$data2step/AKMests_2step.dta", replace
	xtile pedec=akm_person [fw=joblength], nq(10)
	gen byte pedec1=(pedec==1)
	gen byte pedec10=(pedec==10)
	collapse (mean) pe_full_c=akm_person fe_full_c=akm_firm (sd) sdpe_full_c=akm_person (mean) pedec1_full_c=pedec1 pedec10_full_c=pedec10 [fw=joblength], by(czone) fast
	tempfile mig5_pedecsshares_full_c
	save `mig5_pedecsshares_full_c'
	
	// Person-industry effect correlations by CZ
	//--------------------------------------------------------------------------
	use "$data2step/AKMests_2step.dta", replace
	drop firmid
	qui levelsof czone, local(cz_list)
	gen corr_pe_fe = .
	foreach cz in `cz_list' {
		di "Calculating correlation for CZ `cz'"
		corr akm_person akm_firm [fw=joblength] if czone==`cz'
		qui replace corr_pe_fe = r(rho) if czone==`cz'
	}
	keep czone corr_pe_fe
	duplicates drop
	tempfile rho_c
	save `rho_c'
	
	// Hierarchy effect
	//--------------------------------------------------------------------------
	use "$data2step/AKMests_2step.dta", replace
	merge m:1 czone naics4d using "$data2step/AKMests_2stepfull_jc.dta", assert(3) nogen keepusing(psi_2jc_2step)
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	collapse (mean) df_m_psi2jc_c=df_m_psi2jc [fw=joblength], by(czone)
	tempfile hierarchy
	save `hierarchy'
	
	// Merge together
	use `y_c', replace
	merge 1:1 czone using `lnN_c', assert(3) nogen
	merge 1:1 czone using `educ_c', assert(3) nogen
	merge 1:1 czone using `mig5_pedecsshares_full_c', assert(3) nogen
	merge 1:1 czone using `rho_c', assert(3) nogen
	merge 1:1 czone using `hierarchy', assert(3) nogen
	
	// Save
	compress czone
	save "$data2step/czone_vars.dta", replace
	
cap log close
}



//------------------------------------------------------------------------------
// ANALYSIS
//------------------------------------------------------------------------------

// D7: OUTPUT 1 [Summary Stats]
//------------------------------------------------------------------------------
if `d7_tab1'==1 {
	
	* full estimation sample (connected set) - aggregate at the pik level, saving Npq
	
	use "$data2step/M9twostep_step1xbr.dta", replace
	drop sein seinunit
	gen byte Npq=1
	bys pikn naics4d czone: gen byte naics4dcnt=_n==1
	gen y = akm_person+akm_firm+xb+r
	fcollapse (sum) Npq naics4dcnt (mean) y age, by(pikn czone) fast smart
	save "$data2step/indsample1.dta", replace
	
	* demographic variables
	import sas using "$lehd2018/icf_us.sas7bdat", clear case(lower)
	keep pik race ethnicity sex dob pob
	tempfile icffile
	save `icffile', replace
	
	* so far this sample has pikn-cz unique values, now get pik level
	use "$data2step/indsample1.dta", replace
	gen byte N=1
	collapse (mean) y age (sum) N [fw=Npq], by(pikn)
	rename N Npq
	fmerge 1:1 pikn using "$yidata/mig5_pikqtime_1018_finalpiklist.dta", keepusing(pik) keep(master match) nogen
	tempfile t1
	save `t1', replace

	use "$data2step/indsample1.dta", replace
	gen byte czcnt=1
	gen naics4dswitch=naics4dcnt-1 // switches will allow us to solve the problem of stayers in multiple cz having a nais4dcnt>1
	fcollapse (sum) czcnt naics4dswitch, by(pikn) fast smart
	fmerge 1:1 pikn using `t1', keep(match) nogen

	* merge individual (time invariant characteristics)
	merge n:1 pik using `icffile', keep(master match) nogen
	foreach v in race sex {
		rename `v' `v'c
		encode `v'c, gen(`v')
		drop `v'c
	}
	gen hisp=(ethnicity=="H")
	gen forborn=(pob~="A")
	drop pob ethnicity dob
	destring sex, replace
	gen czcnt1=(czcnt==1)
	gen czcnt2=(czcnt==2)
	gen czcnt3=(czcnt>=3)
	gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
	gen naics4dswitch1=(naics4dswitch==1)
	gen naics4dswitch2=(naics4dswitch>=2)
	
	replace sex=0 if sex==2
	ren sex gender
	save "$data2step/indsample1.dta", replace


	*** (9/19) Disclosure counts for binary variables==1
	use "$data2step/indsample1.dta", replace
	
	* defining samples
	gen byte czswitch=czcnt-1, a(czcnt)
	gen s3 = czswitch==0 // never changed  cz
	gen s4 = czswitch>0 //  changed cz at least once
	egen test=rowtotal(s3 s4)
	assert test==1
	drop test

foreach var of varlist gender hisp forborn czcnt1 czcnt2 czcnt3 naics4dswitch0 naics4dswitch1 naics4dswitch2 {
	qui gen `var'_Npq_1 = Npq if `var'==1
	qui gen `var'_Npq_0 = Npq if `var'==0
	qui gen `var'_upik_1 = 1 if `var'==1
	qui gen `var'_upik_0 = 1 if `var'==0
}

* Sample 8
tabstat gender_Npq_1 gender_Npq_0 forborn_Npq_1 forborn_Npq_0 hisp_Npq_1 hisp_Npq_0 czcnt1_Npq_1 czcnt1_Npq_0 czcnt2_Npq_1 czcnt2_Npq_0 czcnt3_Npq_1 czcnt3_Npq_0 naics4dswitch0_Npq_1 naics4dswitch0_Npq_0 naics4dswitch1_Npq_1 naics4dswitch1_Npq_0 naics4dswitch2_Npq_1 naics4dswitch2_Npq_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

tabstat gender_upik_1 gender_upik_0 forborn_upik_1 forborn_upik_0 hisp_upik_1 hisp_upik_0 czcnt1_upik_1 czcnt1_upik_0 czcnt2_upik_1 czcnt2_upik_0 czcnt3_upik_1 czcnt3_upik_0 naics4dswitch0_upik_1 naics4dswitch0_upik_0 naics4dswitch1_upik_1 naics4dswitch1_upik_0 naics4dswitch2_upik_1 naics4dswitch2_upik_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

* Sample 8A (CZ-stayers)
tabstat gender_Npq_1 gender_Npq_0 forborn_Npq_1 forborn_Npq_0 hisp_Npq_1 hisp_Npq_0 czcnt1_Npq_1 czcnt1_Npq_0 czcnt2_Npq_1 czcnt2_Npq_0 czcnt3_Npq_1 czcnt3_Npq_0 naics4dswitch0_Npq_1 naics4dswitch0_Npq_0 naics4dswitch1_Npq_1 naics4dswitch1_Npq_0 naics4dswitch2_Npq_1 naics4dswitch2_Npq_0 if s3==1, stat(sum) col(stat) varwidth(24) format(%12.0g)

tabstat gender_upik_1 gender_upik_0 forborn_upik_1 forborn_upik_0 hisp_upik_1 hisp_upik_0 czcnt1_upik_1 czcnt1_upik_0 czcnt2_upik_1 czcnt2_upik_0 czcnt3_upik_1 czcnt3_upik_0 naics4dswitch0_upik_1 naics4dswitch0_upik_0 naics4dswitch1_upik_1 naics4dswitch1_upik_0 naics4dswitch2_upik_1 naics4dswitch2_upik_0 if s3==1, stat(sum) col(stat) varwidth(24) format(%12.0g)

* Sample 8B (CZ-switchers)
tabstat gender_Npq_1 gender_Npq_0 forborn_Npq_1 forborn_Npq_0 hisp_Npq_1 hisp_Npq_0 czcnt1_Npq_1 czcnt1_Npq_0 czcnt2_Npq_1 czcnt2_Npq_0 czcnt3_Npq_1 czcnt3_Npq_0 naics4dswitch0_Npq_1 naics4dswitch0_Npq_0 naics4dswitch1_Npq_1 naics4dswitch1_Npq_0 naics4dswitch2_Npq_1 naics4dswitch2_Npq_0 if s4==1, stat(sum) col(stat) varwidth(24) format(%12.0g)

tabstat gender_upik_1 gender_upik_0 forborn_upik_1 forborn_upik_0 hisp_upik_1 hisp_upik_0 czcnt1_upik_1 czcnt1_upik_0 czcnt2_upik_1 czcnt2_upik_0 czcnt3_upik_1 czcnt3_upik_0 naics4dswitch0_upik_1 naics4dswitch0_upik_0 naics4dswitch1_upik_1 naics4dswitch1_upik_0 naics4dswitch2_upik_1 naics4dswitch2_upik_0 if s4==1, stat(sum) col(stat) varwidth(24) format(%12.0g)

	// Event Study (Firm-movers)
	use pikn qtime age lne akm_firm czone naics4d using "$data/event_study_firmnum.dta", replace
	fmerge m:1 pikn using "$data2step/indsample1.dta", keep(master match) nogen keepusing(gender forborn hisp)
	gen e=exp(lne)
	gen e3800=1
	gen econd=e
	bys pikn czone: gen t=_n==1
	by pikn: egen czcnt=sum(t)
	gen czcnt1=(czcnt==1)
	gen czcnt2=(czcnt==2)
	gen czcnt3=(czcnt>=3)
	drop t
	bys pikn czone naics4d: gen t=_n==1
	by pikn czone: egen naics4dcnt=sum(t) // naics4dcount is count of ind within same cz
	gen naics4dswitch=naics4dcnt-1
	gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
	gen naics4dswitch1=(naics4dswitch==1)
	gen naics4dswitch2=(naics4dswitch>=2)
	drop t
	fsort pikn qtime

	foreach var of varlist gender hisp forborn czcnt1 czcnt2 czcnt3 naics4dswitch0 naics4dswitch1 naics4dswitch2 {
		qui gen `var'_Npq_1 = 1 if `var'==1
		qui gen `var'_Npq_0 = 1 if `var'==0
		qui bys pikn: gen `var'_upik_1 = 1 if `var'==1 & _n==1
		qui bys pikn: gen `var'_upik_0 = 1 if `var'==0 & _n==1
	}

tabstat gender_Npq_1 gender_Npq_0 forborn_Npq_1 forborn_Npq_0 hisp_Npq_1 hisp_Npq_0 czcnt1_Npq_1 czcnt1_Npq_0 czcnt2_Npq_1 czcnt2_Npq_0 czcnt3_Npq_1 czcnt3_Npq_0 naics4dswitch0_Npq_1 naics4dswitch0_Npq_0 naics4dswitch1_Npq_1 naics4dswitch1_Npq_0 naics4dswitch2_Npq_1 naics4dswitch2_Npq_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

tabstat gender_upik_1 gender_upik_0 forborn_upik_1 forborn_upik_0 hisp_upik_1 hisp_upik_0 czcnt1_upik_1 czcnt1_upik_0 czcnt2_upik_1 czcnt2_upik_0 czcnt3_upik_1 czcnt3_upik_0 naics4dswitch0_upik_1 naics4dswitch0_upik_0 naics4dswitch1_upik_1 naics4dswitch1_upik_0 naics4dswitch2_upik_1 naics4dswitch2_upik_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

	// Event Study (CZ-movers)
	use pikn qtime age lne akm_firm czone naics4d switchtype using "$data/event_study_czone.dta", replace
	gen x1=(switchtype==1 | switchtype==3) // moises fix
	bys pikn: egen x2=max(x1) 
	keep if x2==1
	drop x2 switchtype
	fmerge m:1 pikn using "$data2step/indsample1.dta", keep(master match) nogen keepusing(gender forborn hisp)
	gen e=exp(lne)
	gen e3800=1
	gen econd=e
	bys pikn cz: gen t=_n==1
	by pikn: egen czcnt=sum(t)
	gen czcnt1=(czcnt==1)
	gen czcnt2=(czcnt==2)
	gen czcnt3=(czcnt>=3)
	drop t
	bys pikn czone naics4d: gen t=_n==1
	by pikn czone: egen naics4dcnt=sum(t) // naics4dcount is count of ind within same cz
	gen naics4dswitch=naics4dcnt-1
	gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
	gen naics4dswitch1=(naics4dswitch==1)
	gen naics4dswitch2=(naics4dswitch>=2)
	drop t
	fsort pikn qtime

	foreach var of varlist gender hisp forborn czcnt1 czcnt2 czcnt3 naics4dswitch0 naics4dswitch1 naics4dswitch2 {
		qui gen `var'_Npq_1 = 1 if `var'==1
		qui gen `var'_Npq_0 = 1 if `var'==0
		qui bys pikn: gen `var'_upik_1 = 1 if `var'==1 & _n==1
		qui bys pikn: gen `var'_upik_0 = 1 if `var'==0 & _n==1
	}

tabstat gender_Npq_1 gender_Npq_0 forborn_Npq_1 forborn_Npq_0 hisp_Npq_1 hisp_Npq_0 czcnt1_Npq_1 czcnt1_Npq_0 czcnt2_Npq_1 czcnt2_Npq_0 czcnt3_Npq_1 czcnt3_Npq_0 naics4dswitch0_Npq_1 naics4dswitch0_Npq_0 naics4dswitch1_Npq_1 naics4dswitch1_Npq_0 naics4dswitch2_Npq_1 naics4dswitch2_Npq_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

tabstat gender_upik_1 gender_upik_0 forborn_upik_1 forborn_upik_0 hisp_upik_1 hisp_upik_0 czcnt1_upik_1 czcnt1_upik_0 czcnt2_upik_1 czcnt2_upik_0 czcnt3_upik_1 czcnt3_upik_0 naics4dswitch0_upik_1 naics4dswitch0_upik_0 naics4dswitch1_upik_1 naics4dswitch1_upik_0 naics4dswitch2_upik_1 naics4dswitch2_upik_0, stat(sum) col(stat) varwidth(24) format(%12.0g)

	// OUTPUT (Sample 8)
	use pikn qtime age akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen lne = akm_person + akm_firm + xb + r
	drop akm_person akm_firm xb r
	fcollapse (mean) lne, by(pikn) fast smart
	fmerge 1:1 pikn using "$data2step/indsample1.dta", keep(master match) nogen
	
	* defining subsamples
	gen byte czswitch=czcnt-1, a(czcnt)
	gen s3 = czswitch==0 // never changed  cz
	gen s4 = czswitch>0 //  changed cz at least once
	egen test=rowtotal(s3 s4)
	assert test==1
	drop test
	
	* column (1): sample 8 [fw=Npq]
	gen qobserved=Npq
	gen byte e3800=1
	qui eststo c2: estpost sum lne age gender forborn hisp czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved [fw=Npq]
	drbeclass, addest(mean sd) addcount(count) eststo(dc2) 
	count
	estadd scalar dpikcount=r(N)
	drbrclass N, countscalar(N)
	estadd scalar pikcount=r(N)
	qui sum e3800 [fw=Npq]
	estadd scalar dNpq=r(N)
	drbrclass N, countscalar(N)
	estadd scalar Npq=r(N)

	* columns (2) & (3): sample 8 cz movers & stayer subgroups [fw=Npq]
	forval s=3/4 {
	qui eststo c`s': estpost sum lne age gender forborn hisp czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved if s`s'==1 [fw=Npq]
	drbeclass, addest(mean sd) addcount(count) eststo(dc`s') 
	count if s`s'==1
	estadd scalar dpikcount=r(N)
	drbrclass N, countscalar(N)
	estadd scalar pikcount=r(N)
	qui sum e3800 [fw=Npq] if s`s'==1
	estadd scalar dNpq=r(N)
	drbrclass N, countscalar(N)
	estadd scalar Npq=r(N)
	}
	
	* column (4): event study - firm movers
	use pikn qtime age lne akm_firm czone naics4d using "$data/event_study_firmnum.dta", replace
	fmerge m:1 pikn using "$data2step/indsample1.dta", keep(master match) nogen keepusing(gender forborn hisp)
	gen e=exp(lne)
	gen e3800=1
	gen econd=e
	bys pikn czone: gen t=_n==1
	by pikn: egen czcnt=sum(t)
	gen czcnt1=(czcnt==1)
	gen czcnt2=(czcnt==2)
	gen czcnt3=(czcnt>=3)
	drop t
	bys pikn czone naics4d: gen t=_n==1
	by pikn czone: egen naics4dcnt=sum(t) // naics4dcount is count of ind within same cz
	gen naics4dswitch=naics4dcnt-1
	gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
	gen naics4dswitch1=(naics4dswitch==1)
	gen naics4dswitch2=(naics4dswitch>=2)
	drop t
	fsort pikn qtime
	
	by pikn: gen qobserved=_N
	qui eststo c5: estpost sum lne age gender forborn hisp czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved
	drbeclass,  addest(mean sd) addcount(count) eststo(dc5) 
	gunique pikn
	estadd scalar dpikcount=r(unique)
	drbrclass unique, countscalar(unique)
	estadd scalar pikcount=r(unique)
	qui sum e3800
	estadd scalar dNpq=r(N)
	drbrclass N, countscalar(N)
	estadd scalar Npq=r(N)
	
	* column (5): event study - CZ movers
	use pikn qtime age lne akm_firm czone naics4d switchtype using "$data/event_study_czone.dta", replace
	gen x1=(switchtype==1 | switchtype==3) // moises fix
	bys pikn: egen x2=max(x1) 
	keep if x2==1
	drop x2 switchtype
	fmerge m:1 pikn using "$data2step/indsample1.dta", keep(master match) nogen keepusing(gender forborn hisp)
	gen e=exp(lne)
	gen e3800=1
	gen econd=e
	bys pikn cz: gen t=_n==1
	by pikn: egen czcnt=sum(t)
	gen czcnt1=(czcnt==1)
	gen czcnt2=(czcnt==2)
	gen czcnt3=(czcnt>=3)
	drop t
	bys pikn czone naics4d: gen t=_n==1
	by pikn czone: egen naics4dcnt=sum(t) // naics4dcount is count of ind within same cz
	gen naics4dswitch=naics4dcnt-1
	gen naics4dswitch0=(naics4dswitch==0) // if no switches, means never changed inds within CZ
	gen naics4dswitch1=(naics4dswitch==1)
	gen naics4dswitch2=(naics4dswitch>=2)
	drop t
	fsort pikn qtime
	
	by pikn: gen qobserved=_N
	qui eststo c6: estpost sum lne age gender forborn hisp czcnt1 czcnt2 czcnt3  naics4dswitch0 naics4dswitch1 naics4dswitch2 qobserved
	drbeclass,  addest(mean sd) addcount(count) eststo(dc6) 
	gunique pikn
	estadd scalar dpikcount=r(unique)
	drbrclass unique, countscalar(unique)
	estadd scalar pikcount=r(unique)
	qui sum e3800
	estadd scalar dNpq=r(N)
	drbrclass N, countscalar(N)
	estadd scalar Npq=r(N)
	
	* output
	esttab dc2 dc3 dc4 dc5 dc6 using "${output}/tab1_output.csv", type c(mean sd (par)) label replace title("Sample descriptives") mtitles("Estim" "CZ stay" "CZ mov" "ES-firm" "ES-CZ") noobs scalar("pikcount Unique PIKs" "Npq Person-quarter observations" "dpikcount Unique PIKs" "dNpq Person-quarter observations" "Npq Person-quarter observations")

	* disclosure stats
	esttab c2 c3 c4 c5 c6 using "${output}/tab1_disc.csv", type label replace title("Sample descriptives") mtitles("Estim" "CZ stay" "CZ mov" "ES-firm" "ES-CZ") scalar("dpikcount Unique PIKs" "dNpq Person-quarter observations" "Npq Person-quarter observations")
*/

cap log close
}


// D7: OUTPUT 2 [AKM Decomp, PQ- and CZ-level]
//------------------------------------------------------------------------------
if `d7_tab2'==1 {
	
	// CZ-ind estimates
	//--------------------------------------------------------------------------
	use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	tempfile czs
	save `czs'
	
	use naics2d using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	joinby temp using `czs'
	drop temp
	
	preserve
		use czone naics2d psi_2jc_2step alpha_2jc_2step N_2jc_2step y_2jc xb_2jc r_2jc df_m_psi2jc_2jc using "$data2step/AKMests_2stepfull_jc.dta", clear
		duplicates drop
		tempfile ests_2jc
		save `ests_2jc'
	restore
	merge 1:1 czone naics2d using `ests_2jc', assert(1 3) nogen
	
	// CZ estimates
	//--------------------------------------------------------------------------
	preserve
	bys czone: egen N_c = total(N_2jc_2step)
	keep czone N_c
	duplicates drop
	tempfile n_c
	save `n_c'
	restore
	
	preserve
	collapse (mean) y_c=y_2jc pe_c=alpha_2jc_2step fe_c=psi_2jc_2step xb_c=xb_2jc r_c=r_2jc df_m_psi2jc_c=df_m_psi2jc_2jc [fw=N_2jc_2step], by(czone)
	tempfile ests_c
	save `ests_c'
	restore
	merge m:1 czone using `ests_c', assert(3) nogen
	merge m:1 czone using `n_c', assert(3) nogen
	
	// Rename variables
	ren alpha_2jc_2step pe_2jc
	ren psi_2jc_2step fe_2jc
	ren N_2jc_2step N_2jc
	foreach v of var pe_2jc fe_2jc N_2jc df_m_psi2jc_2jc {
		replace `v' = 0 if mi(`v')
	}
	
	// Save CZ and CZ-ind estimates
	tempfile ests
	save `ests'
	
	// Job-level data
	use czone naics4d akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen y = akm_person + akm_firm + xb + r
	gen byte n_1 = 1 /* temporary variable for decomp2w prog */
	merge m:1 czone naics4d using "$data2step/AKMests_2stepfull_jc.dta", assert(3) nogen keepusing(naics2d psi_2jc_2step)
	gen df_m_psi2jc = akm_firm - psi_2jc_2step
	drop naics4d
	
	// Rename vars
	ren czone cz
	ren akm_person pe
	ren akm_firm fe
	
	* KLINE 2 decomposition [fw]
	cap program drop decomp2w
	program define decomp2w
	args name y components fw
	cap drop col*`name'
	qui gen col1`name'="sd and var(`y') share=" if _n==1
	qui sum `y' [fw=`fw']
	local var=r(Var)
	qui gen col2`name'=r(sd) if _n==1
	qui gen col3`name'=`var'/r(Var) if _n==1
	noi dis "sd and var(`y') share=" _col(45) "&"  round(r(sd),.0001) _col(55) "& (" round(r(Var)/`var',.0001) ")"
	local i=1
	foreach comp1 in `components' {
		qui sum `comp1' [fw=`fw']
		noi dis "sd and var(`comp1') share=" _col(45) "&"  round(r(sd),.0001) _col(55) "& (" round(r(Var)/`var',.0001) ")"
		qui replace col1`name'="sd and var(`comp1') share=" if _n==`i'+1
		qui replace col2`name'=round(r(sd),.000001) if _n==`i'+1
		qui replace col3`name'=round(r(Var)/`var',.000001) if _n==`i'+1
		local ++i
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
		qui replace col1`name'="rho and 2cov(`comp1',`comp2') share=" if _n==`i'+1
		qui replace col2`name'=round(`rho',.000001) if _n==`i'+1
		qui replace col3`name'=round(`covshr_`comp1'`comp2'',.000001) if _n==`i'+1
		noi dis "rho and 2cov(`comp1',`comp2') share=" _col(45) "&"  round(`rho',.0001) _col(55) "& (" round(`covshr_`comp1'`comp2'',.0001) ")"
		local ++i
	}
	}
	noi dis "Observations" _col(55) "&"  %30.0fc r(N)
	qui replace col1`name'="N=" if _n==`i'+1
	drbrclass N , countscalars(N)
	qui replace col2`name'=r(N) if _n==`i'+1
	drbvars col2`name' col3`name', replace
	format  col2`name' col3`name'  %030.6gc
	list col1`name' col2`name' col3`name' if col1`name'~=""
	end
	
	decomp2w y y      "pe fe xb r"    n_1
	keep col*
	drop if col1y==""
	export excel col*y using "${output}/tab2loc.xlsx", firstrow(variable) keepcellfmt cell(A3) sheet(1, modify)
	use `ests', replace
	drop naics2d *_2jc
	duplicates drop
	decomp2w y_c y_c     "pe_c fe_c xb_c r_c"    N_c
	keep col*
	drop if col1y_c==""
	drop col1y_c
	export excel col*y_c using "${output}/tab2loc.xlsx", firstrow(variable) keepcellfmt cell(D3) sheet(1, modify)

cap log close
}


// D7: OUTPUT 4 [R2 of psi_jc on i.cz, i.naics2d, etc]
//------------------------------------------------------------------------------
if `d7_tab4'==1 {

	// M9 twostep estimates
	use czone naics2d psi_2jc_2step N_2jc_2step using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	
	// Rename variables
	ren N_2jc_2step m9twostep_N_jc
	ren czone cz
	ren psi_2jc_2step m9twostep_psi_jc
	
	// Collapse to naics2d
	*gen naics2d = floor(naics4d/100), a(cz)
	*bys cz naics2d: egen m9twostep_N_jc = total(N_jc)
	*collapse (mean) m9twostep_psi_jc m9twostep_N_jc [fw=N_jc], by(cz naics2d)
	
	// Generate share variables
	bys cz: egen czpop = sum(m9twostep_N_jc)
	gen sjc = m9twostep_N_jc/czpop
	gen lsjc = ln(sjc)
	
	// Regressions
	tostring cz, gen(t) format(%05.0f)
	gen czind=string(naics2d)+t
	drop t
	destring czind, replace
	assert czind~=.

	eststo clear
	qui eststo r1: areg m9twostep_psi_jc [aw=m9twostep_N_jc], absorb(cz) vce(cluster czind)
	qui eststo r2: areg m9twostep_psi_jc [aw=m9twostep_N_jc], absorb(naics2d) vce(cluster czind)
	qui eststo r3: areg m9twostep_psi_jc i.naics2d [aw=m9twostep_N_jc], absorb(cz) vce(cluster czind)

	qui eststo r4: areg m9twostep_psi_jc sjc i.naics2d [aw=m9twostep_N_jc], absorb(cz) vce(cluster czind)
	qui eststo r5: areg m9twostep_psi_jc lsjc i.naics2d [aw=m9twostep_N_jc], absorb(cz) vce(cluster czind)

	forval r=1/5 {
	drbeclass r`r',  addest(r2 r2_a rmse) eststo(r`r')
	}
	esttab r? using "${output}/tab4loc.csv", keep(sjc lsjc) se r2 ar2 label replace type title("Models for Twostep $ \Psi_{jc} $ ") mtitles("CZ" "Ind" "CZ-Ind" "CZ+Ind+Sjc" "CZ-ind+lSjc")  scalar(rmse)

	
	
cap log close	
}


// D7: OUTPUT 5 [AKM Decomp, naics2d vs naics4d]
//------------------------------------------------------------------------------
if `d7_tab5'==1 {

	* Decomposition program: KLINE 2 decomposition (weighted PQ)
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
	
	// PART 1: M9 twostep estimates (naics2d)
	use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	tempfile czs
	save `czs'
	
	use naics2d using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	joinby temp using `czs'
	
	preserve
		use czone naics2d psi_2jc_2step N_2jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
		duplicates drop
		tempfile ests_2jc
		save `ests_2jc'
	restore
	merge 1:1 czone naics2d using `ests_2jc', assert(1 3) nogen
	
	// Rename variables
	ren czone cz
	ren psi_2jc_2step m9twostep_psi_2jc 
	ren N_2jc_2step m9twostep_N_2jc
	replace m9twostep_N_2jc = 0 if mi(m9twostep_N_2jc)
	
	// Generate share variables
	bys cz: egen czpop = sum(m9twostep_N_2jc)
	gen s2jc = m9twostep_N_2jc/czpop
	gen ls2jc = ln(s2jc)
	
	// Save CZpop
	preserve
	keep cz czpop
	duplicates drop
	tempfile czpop
	save `czpop'
	restore
	
	* get industry means (weighted by cz pop)
	preserve
	collapse (mean) m9twostep_psi_2j=m9twostep_psi_2jc s2j=s2jc [fw=czpop], by(naics2d) fast
	tempfile jmeans
	save `jmeans', replace
	restore
	merge m:1 naics2d using `jmeans', assert(match) nogen
	
	* construct main and components
	gen t1=m9twostep_psi_2jc*s2jc
	gen phi_c_A=s2j*m9twostep_psi_2j
	gen phi_c_B=s2j*(m9twostep_psi_2jc-m9twostep_psi_2j)
	gen phi_c_C=(s2jc-s2j)*m9twostep_psi_2j
	gen phi_c_D=(s2jc-s2j)*(m9twostep_psi_2jc-m9twostep_psi_2j)
	collapse (sum) phi_c=t1 phi_c_A phi_c_B phi_c_C phi_c_D, by(cz)
	merge 1:1 cz using `czpop', assert(3) nogen
	
	* output 8 (first half, naics2d)
	decomp2 phi phi_c "phi_c_A phi_c_B phi_c_C phi_c_D" czpop
	keep col*
	drop if col1phi==""
	export excel col*phi using "${output}/tab5loc.xlsx", firstrow(variable) keepcellfmt cell(A3) sheet(1, modify)
	
	// PART 2: M9 twostep estimates (naics4d)
	use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	tempfile czs
	save `czs'
	
	use naics4d using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	joinby temp using `czs'
	merge 1:1 czone naics4d using "$data2step/AKMests_2stepfull_jc.dta", assert(1 3) nogen
	drop alpha_4jc_2step
	
	// Rename variables
	ren N_4jc_2step m9twostep_N_jc
	replace m9twostep_N_jc = 0 if mi(m9twostep_N_jc)
	ren czone cz
	ren psi_4jc_2step m9twostep_psi_jc
	
	// Generate share variables
	bys cz: egen czpop = sum(m9twostep_N_jc)
	gen sjc = m9twostep_N_jc/czpop
	gen lsjc = ln(sjc)
	
	// Save CZpop
	preserve
	keep cz czpop
	duplicates drop
	tempfile czpop
	save `czpop'
	restore
	
	* get industry means (weighted by cz pop)
	preserve
	collapse (mean) m9twostep_psi_j=m9twostep_psi_jc sj=sjc [fw=czpop], by(naics4d) fast
	tempfile jmeans
	save `jmeans', replace
	restore
	merge m:1 naics4d using `jmeans', assert(match) nogen
	
	* construct main and components
	gen t1=m9twostep_psi_jc*sjc
	gen phi_c_A=sj*m9twostep_psi_j
	gen phi_c_B=sj*(m9twostep_psi_jc-m9twostep_psi_j)
	gen phi_c_C=(sjc-sj)*m9twostep_psi_j
	gen phi_c_D=(sjc-sj)*(m9twostep_psi_jc-m9twostep_psi_j)
	collapse (sum) phi_c=t1 phi_c_A phi_c_B phi_c_C phi_c_D, by(cz)
	merge 1:1 cz using `czpop', assert(3) nogen
	
	* output 8 (second half, naics4d)
	decomp2 phi phi_c "phi_c_A phi_c_B phi_c_C phi_c_D" czpop
	keep col*
	drop if col1phi==""
	drop col1phi
	export excel col*phi using "${output}/tab5loc.xlsx", firstrow(variable) keepcellfmt cell(E3) sheet(1, modify)
	
	* disclosure statistics (baseline sample)
	use "$data2step/AKMests_2step.dta", clear
	unique pikn
	local Np=r(sum)
	sum akm_person [fw=joblength]
	local Npq=r(N)
	use "$data2step/AKMests_2stepfull_jc.dta", clear
	unique czone naics2d
	local N2jc=r(sum)
	unique czone naics4d
	local N4jc=r(sum)
	unique czone
	local Ncz=r(sum)
	clear
	set obs 5
	gen Description="Number of unique workers" if _n==1
	replace Description="Number of person-quarter observations" if _n==2
	replace Description="Number of CZ-industries (2d)" if _n==3
	replace Description="Number of CZ-industries (4d)" if _n==4
	replace Description="Number of CZs" if _n==5
	forval c=1/2 {
	gen column`c'="`Np'" if _n==1
	replace column`c'="`Npq'" if _n==2
	replace column`c'="`N2jc'" if _n==3
	replace column`c'="`N4jc'" if _n==4
	replace column`c'="`Ncz'" if _n==5
	}
	export excel using "${output}/dtab5loc.xlsx", firstrow(variable) keepcellfmt cell(A2) sheet(1, modify)
	
}


// D7: OUTPUT 6 [Regressions of FE and PE on Y (C-level)]
//------------------------------------------------------------------------------
if `d7_tab6'==1 {

	* Sample XX (741 CZs), 1 sample (full)
	cap erase ${output}/tab7loc.csv
	cap erase ${output}/dtab7loc.csv


	* count of unique workers in sample for disclosure
	use pikn /*state*/ czone using "$data2step/AKMests_2step.dta", replace
	unique pikn
	local Np_full=r(sum)
	*unique state
	*local nstates=r(sum)
	local nstates=.
	
	// PART 1: M9 twostep estimates (naics2d)
	use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	tempfile czs
	save `czs'
	
	use naics2d using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	joinby temp using `czs'
	
	preserve
		use czone naics2d psi_2jc_2step alpha_2jc_2step xb_2jc r_2jc N_2jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
		duplicates drop
		tempfile ests_2jc
		save `ests_2jc'
	restore
	merge 1:1 czone naics2d using `ests_2jc', assert(1 3) nogen
	
	// Rename variables
	ren czone cz
	ren psi_2jc_2step m9twostep_psi_2jc 
	ren N_2jc_2step m9twostep_N_2jc
	replace m9twostep_N_2jc = 0 if mi(m9twostep_N_2jc)
	
	// Generate share variables
	bys cz: egen czpop = sum(m9twostep_N_2jc)
	gen s2jc = m9twostep_N_2jc/czpop
	gen ls2jc = ln(s2jc)
	
	// Save CZpop
	preserve
	keep cz czpop
	duplicates drop
	tempfile czpop
	save `czpop'
	restore
	
	* get industry means (weighted by cz pop)
	preserve
	collapse (mean) m9twostep_psi_2j=m9twostep_psi_2jc s2j=s2jc [fw=czpop], by(naics2d) fast
	tempfile jmeans
	save `jmeans', replace
	restore
	merge m:1 naics2d using `jmeans', assert(match) nogen
	
	* construct main and components
	gen t1=m9twostep_psi_2jc*s2jc
	gen phi_c_A=s2j*m9twostep_psi_2j
	gen phi_c_B=s2j*(m9twostep_psi_2jc-m9twostep_psi_2j)
	gen phi_c_C=(s2jc-s2j)*m9twostep_psi_2j
	gen phi_c_D=(s2jc-s2j)*(m9twostep_psi_2jc-m9twostep_psi_2j)
	collapse (sum) phi_c=t1 phi_c_A phi_c_B phi_c_C phi_c_D, by(cz)
	merge 1:1 cz using `czpop', assert(3) nogen
	ren cz czone
	tempfile tab5_vars
	save `tab5_vars'
	
	// TEMP
	use "$data2step/AKMests_2stepfull_jc.dta", replace
	collapse (mean) akm_firm_full=psi_4jc_2step akm_person_full=alpha_4jc_2step [fw=N_4jc_2step], by(czone)
	tempfile temp_data
	save `temp_data'
	
	use "$data2step/czone_vars.dta", replace
	merge 1:1 czone using `temp_data', assert(3) nogen
	gen y_full = y_c
	merge 1:1 czone using `tab5_vars', assert(3) nogen
	
	foreach rhs in y_c lnN_c educ_c {
	eststo clear
	local c=1
	foreach sample in full {
	qui eststo r`c': reg y_`sample'    `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg akm_person_`sample'    `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg akm_firm_`sample'    `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg sdpe_`sample'_c    `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg pedec1_`sample'_c  `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg pedec10_`sample'_c `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg akm_firm_`sample' `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg phi_c_B `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg phi_c_C `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg phi_c_D `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg corr_pe_fe `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	qui eststo r`c': reg df_m_psi2jc_c `rhs'    [fw = N_c], vce(cluster czone)
	qui estadd scalar Npq=e(N)
	qui estadd scalar Np=`Np_`sample''
	qui estadd scalar nstates=`nstates'
	local ++c
	}

	forval c=1/12 {
	drbeclass r`c', eststo(dr`c') addcount(count Npq Np)
	}
	if "`rhs'"=="y_c" {
	noi esttab dr* using ${output}/tab7loc.csv, se keep(`rhs') nonotes nonumbers nostar noobs append mgroups("Baseline Sample", pattern(1 0 0 0 0 0 )) title("Regressions y_c pe_c fe_c sdpe_c pedec1 pedec10 on earnings & size & education (CZ and CZ-ind level)") scalar("Np `rhs' - Unique workers" "Npq Person-quarter observations") 
	}
	else if "`rhs'"=="lnN_c" {
	noi esttab dr* using ${output}/tab7loc.csv, se keep(`rhs') nonotes nonumbers nostar fragment noobs append nomtitles scalar("Np `rhs' - Unique workers" "Npq Person-quarter observations") 
	}
	else if "`rhs'"=="educ_c" {
	noi esttab dr* using ${output}/tab7loc.csv, se keep(`rhs') nonotes nonumbers nostar fragment noobs append nomtitles scalar("Np `rhs' - Unique workers" "Npq Person-quarter observations") 
	}
	}
	
}


// D7: OUTPUT 8 [Residuals by deciles of PE and FE]
//------------------------------------------------------------------------------
if `d7_tab8'==1 {

	// Log
	log using "$logs/6_fullAKM_afig3.log", text replace
	
	// Person decile ranges
	use "$data2step/AKMests_2step.dta", clear
	xtile pedec = akm_person [fw=joblength], nquantiles(10)
	forvalues q = 1/10 {
		sum akm_person if pedec==`q'
		local pe`q'_min = r(min)
		local pe`q'_max = r(max)
	}
	
	// Firm decile ranges
	xtile fedec = akm_firm [fw=joblength], nquantiles(10)
	forvalues q = 1/10 {
		sum akm_firm if fedec==`q'
		local fe`q'_min = r(min)
		local fe`q'_max = r(max)
	}	
	
	// Create dataset with deciles
	//--------------------------------------------------------------------------
	use "$data2step/M9twostep_step1xbr.dta", clear
	keep pikn czone naics4d akm_* r state
	gen byte naics2d = floor(naics4d/100), b(naics4d)
	bys naics2d czone: egen psi_2jc = mean(akm_firm) /* takes about 1.5 hours */
	gen df_m_psi2jc = akm_firm - psi_2jc
	gen byte pedec = .
	forvalues decile = 1/10 {
		replace pedec = `decile' if mi(pedec) & akm_person>=`pe`decile'_min' & akm_person<(`pe`decile'_max'+0.00000001)
		*sum akm_person if pedec==`decile'
	}
	gen byte fedec = .
	forvalues decile = 1/10 {
		replace fedec = `decile' if mi(fedec) & akm_firm>=(`fe`decile'_min'-0.00000001) & akm_firm<(`fe`decile'_max'+0.00000001)
		*sum akm_firm if fedec==`decile'
	}
	
	// Appendix Figure 3, firm deciles w/residuals
	//--------------------------------------------------------------------------
	tempname p
	tab pedec fedec, matcell(`p')
	qui count if pedec<. & fedec<.
	matrix `p'=`p'/r(N)
	*table pedec fedec, contents(mean r)
	matrix out = J(10,10,.)
	forvalues i = 1/10 {
		forvalues j = 1/10 {
			sum r if pedec==`i' & fedec==`j'
			matrix out[`i',`j'] = r(mean)
		}
	}
	preserve
	clear
	svmat double out
	export excel using "${output}/afig3loc_resids_pedec_fedec.xlsx", keepcellfmt cell(B2) sheet("rawdata", modify)
	restore
	
	// Disclosure Statistics
	gen byte N = 1
	bys pedec fedec pikn: gen byte Np=_n==1
	bys pedec fedec state: gen byte Nstates=_n==1
	preserve
	fcollapse (sum) N Np Nstates, by(pedec fedec) fast smart
	export excel using "${output}/afig3loc_resids_pedec_fedec.xlsx", keepcellfmt cell(E1) firstrow(variables) sheet("rounded", modify)
	restore
	
	// Appendix Figure 3, CZ-industry deciles w/residuals
	//--------------------------------------------------------------------------
	tempname p
	tab pedec psi2jcdec, matcell(`p')
	qui count if pedec<. & psi2jcdec<.
	matrix `p'=`p'/r(N)
	*table pedec psi2jcdec, contents(mean r)
	matrix out = J(10,10,.)
	forvalues i = 1/10 {
		forvalues j = 1/10 {
			sum r if pedec==`i' & psi2jcdec==`j'
			matrix out[`i',`j'] = r(mean)
		}
	}
	preserve
	clear
	svmat double out
	export excel using "${output}/afig3loc_resids_pedec_psi2jcdec.xlsx", keepcellfmt cell(B2) sheet("rawdata", modify)
	restore

	// Appendix Figure 3, CZ-industry deciles w/hierarchy effects
	//--------------------------------------------------------------------------
	*table pedec psi2jcdec, contents(mean df_m_psi2jc)
	matrix out = J(10,10,.)
	forvalues i = 1/10 {
		forvalues j = 1/10 {
			sum df_m_psi2jc if pedec==`i' & psi2jcdec==`j'
			matrix out[`i',`j'] = r(mean)
		}
	}
	preserve
	clear
	svmat double out
	export excel using "${output}/afig3loc_h2jc_pedec_psi2jcdec.xlsx", keepcellfmt cell(B2) sheet("rawdata", modify)
	restore
	
cap log close
}


// D7: OUTPUT 9-10 [Firm movers: Event Study & Binscatters by Firm Quantiles]
//------------------------------------------------------------------------------
if `d7_tab9_10'==1 {
	
	// Unweighted firm quartiles
	import delimited using "$tempdir/datafrommatlab_firm.raw", clear
	rename v1 firmnum
	rename v2 akm_firm
	xtile firm_vingtile = akm_firm, n(20)
	forvalues q = 1/20 {
		sum akm_firm if firm_vingtile==`q'
		local q`q'_min = r(min)
		local q`q'_max = r(max)
	}
	tab firm_vingtile
	
	// Weighted firm quartiles
	use "$data2step/AKMests_2step.dta", clear
	xtile firm_vingtile_w = akm_firm [fw=joblength], n(20)
	forvalues q = 1/20 {
		sum akm_firm if firm_vingtile_w==`q'
		local q`q'w_min = r(min)
		local q`q'w_max = r(max)
	}
	tab firm_vingtile_w
	
	// Start with event study sample
	use "$data/event_study_firmnum.dta", replace
	*keep pikn qtime czone naics4d firmid jobid lne t1 edate akm_firm  akm_person m9twostep_xb m9twostep_r czswitch naics2dswitch firmnumswitch switchtype
	
	// Create firm vingiles variable
	gen byte firm_vingtile = .
	forvalues vingtile = 1/20 {
		replace firm_vingtile = `vingtile' if mi(firm_vingtile) & akm_firm>=(`q`vingtile'_min'-0.00000001) & akm_firm<(`q`vingtile'_max'+0.00000001)
		sum akm_firm if firm_vingtile==`vingtile'
	}
	tab firm_vingtile, m
	gen byte firm_vingtile_w = .
	forvalues vingtile = 1/20 {
		replace firm_vingtile_w = `vingtile' if mi(firm_vingtile_w) & akm_firm>=(`q`vingtile'w_min'-0.00000001) & akm_firm<(`q`vingtile'w_max'+0.00000001)
		sum akm_firm if firm_vingtile_w==`vingtile'
	}
	tab firm_vingtile_w, m
	preserve
	keep firmnum firm_vingtile
	duplicates drop
	tab firm_vingtile
	tempfile firm_vingtiles
	save `firm_vingtiles', replace
	restore
	ren firm_vingtile truefirm_vingtile
	preserve
	keep firmnum firm_vingtile_w
	duplicates drop
	tab firm_vingtile_w
	tempfile firm_vingtiles_w
	save `firm_vingtiles_w', replace
	restore
	ren firm_vingtile_w truefirm_vingtile_w
	
	// Firmnum origin and destination
	sort pikn qtime
	gen x=firmnum if t1[_n+1]==1
	by pikn: egen firmnumorig=max(x)
	drop x
	gen x=firmnum if t1==1
	by pikn: egen firmnumdest=max(x)
	drop x
	
	// Merge on firm vingtiles
	ren firmnum truefirmnum
	rename firmnumorig firmnum
	merge m:1 firmnum using `firm_vingtiles', assert(2 3) keep(3) nogen
	rename firm_*tile firm_*tileorig
	merge m:1 firmnum using `firm_vingtiles_w', assert(2 3) keep(3) nogen
	rename firm_*tile_w firm_*tile_worig
	rename firmnum firmnumorig
	rename firmnumdest firmnum
	merge m:1 firmnum using `firm_vingtiles', assert(2 3) keep(3) nogen
	rename firm_*tile firm_*tiledest
	merge m:1 firmnum using `firm_vingtiles_w', assert(2 3) keep(3) nogen
	rename firm_*tile_w firm_*tile_wdest
	rename firmnum firmnumdest
	ren truefirmnum firmnum
	ren truefirm_vingtile firm_vingtile
	ren truefirm_vingtile_w firm_vingtile_w
	
	// Gen firm quartiles from vingtiles
	gen byte firm_quartileorig = ceil(firm_vingtileorig/5), b(firm_vingtileorig)
	gen byte firm_quartiledest = ceil(firm_vingtiledest/5), b(firm_vingtiledest)
	gen byte firm_quartile_worig = ceil(firm_vingtile_worig/5), b(firm_vingtile_worig)
	gen byte firm_quartile_wdest = ceil(firm_vingtile_wdest/5), b(firm_vingtile_wdest)
	
	// Save event study data with vigintiles
	save "$data/event_study_firmnum.dta", replace

	
	// Event Studies (weighted)
	use "$data/event_study_firmnum.dta", replace
	ren st_fips state
	gen y_m_xb = lne - m9twostep_xb
	
	bys firm_quartile_worig firm_quartile_wdest edate pikn: gen byte Np=_n==1
	bys firm_quartile_worig firm_quartile_wdest edate state: gen byte Nstates=_n==1
	
	preserve
	
	collapse (mean) y_m_xb akm_res=m9twostep_r (count) Npq=y_m_xb (sum) Np Nstates, by(firm_quartile_worig firm_quartile_wdest edate) fast
	foreach v of var y_m_xb akm_res {
		twoway  (connected `v' edate if firm_quartile_worig==1 & firm_quartile_wdest==1) ///
			(connected `v' edate if firm_quartile_worig==1 & firm_quartile_wdest==2) /// 
			(connected `v' edate if firm_quartile_worig==1 & firm_quartile_wdest==3) ///
			(connected `v' edate if firm_quartile_worig==1 & firm_quartile_wdest==4) ///	
			(connected `v' edate if firm_quartile_worig==4 & firm_quartile_wdest==1) ///
			(connected `v' edate if firm_quartile_worig==4 & firm_quartile_wdest==2) /// 
			(connected `v' edate if firm_quartile_worig==4 & firm_quartile_wdest==3) ///
			(connected `v' edate if firm_quartile_worig==4 & firm_quartile_wdest==4) ///		
			, legend(label(1 "1 to 1") label(2 "1 to 2") label(3 "1 to 3") label(4 "1 to 4") label(5 "4 to 1") label(6 "4 to 2") label(7 "4 to 3") label(8 "4 to 4") cols(4))  title("Event Study - firmnum movers") subtitle("firm quartiles, weighted")
		graph export "$output/afig2w_es_`v'_byfirmq.pdf", replace
	}
	
	// Disclosure statistics and output	
	drbvars y_m_xb akm_res Npq, countsvars(Npq)  replace
export excel firm_quartile_worig firm_quartile_wdest edate y_m_xb akm_res Npq using "${output}/afig2w_es_akm_res_byfirmq.xlsx", firstrow(variable) keepcellfmt sheet(output, replace)  cell(A4)

	restore	
	
	
	// Bin Scatters
	use "$data/event_study_firmnum.dta", replace
	ren st_fips state
	gen y_m_xb = lne - m9twostep_xb
	ren m9twostep_r akm_res
	sort pikn qtime
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'=`v'-`v'[_n-1]
	}
	keep if edate==0 /* & firmnumswitch==1 <-- redundant */
	
	bys firm_vingtile_worig firm_vingtile_wdest edate pikn: gen byte Np=_n==1
	bys firm_vingtile_worig firm_vingtile_wdest edate state: gen byte Nstates=_n==1
	
	preserve
	
	fcollapse (mean) d_akm_res d_y_m_xb d_akm_firm (count) Npq=d_akm_res (sum) Np Nstates, by(firm_vingtile_worig firm_vingtile_wdest) fast smart
	* single slope
	foreach depvar in d_y_m_xb d_akm_res {
	reg `depvar' d_akm_firm [aw=Npq]
	local beta=round(_b[d_akm_firm],.001)
	twoway (scatter `depvar' d_akm_firm,  mcolor(%0) xline(0) yline(0) ylabel(-0.5(0.25)0.5))  (lfit `depvar' d_akm_firm) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==1, msize(small) msymbol(smcircle_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==3, msize(small) msymbol(smsquare_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==5, msize(small) msymbol(smtriangle_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==7, msize(small) msymbol(smdiamond_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==9, msize(small) msymbol(smplus)) ///       
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==11, msize(small) msymbol(smcircle_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==13, msize(small) msymbol(smsquare_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==15, msize(small) msymbol(smtriangle_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==17, msize(small) msymbol(smdiamond_hollow)) ///
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==19, msize(small) msymbol(smplus)) ///       
		   (scatter `depvar' d_akm_firm if firm_vingtile_worig==20, msize(small) msymbol(smcircle_hollow)) ///
		   , legend(off) title("`depvar' vs. d_akm_firm- firmnum movers") subtitle("slope `beta' - OLS")
	graph export "$output/afig2w_bs_`depvar'_byfirmvingw.pdf", replace
	}
	
	// Disclosure statistics and output
	drbvars d_y_m_xb d_akm_res d_akm_firm Npq, countsvars(Npq)  replace
export excel firm_vingtile_worig firm_vingtile_wdest d_y_m_xb d_akm_res d_akm_firm Npq using "${output}/afig2w_bs_akm_res_byfirmvingw.xlsx", firstrow(variable) keepcellfmt sheet(output, replace)  cell(A4)
	
	restore
	
	
cap log close
}


// D7: OUTPUT 11 [CZ-movers: Event Study by Earnings Quartiles]
//------------------------------------------------------------------------------
if `d7_tab11'==1 {
	
	// Log
	log using "$logs/6_fullAKM_fig2.log", text replace
	
	// CZ-level earnings quartiles
	use "$data2step/czone_vars.dta", clear
	xtile y_quartile = y_c, n(4)
	xtile y_quartilew = y_c [fw=N_c], n(4)
	keep czone y_quartile*
	tempfile cz_quartiles
	save `cz_quartiles'
	use "$data/event_study_czone.dta", replace
	
	// y_m_xb and y_m_xb_m_h2jc
	gen y_m_xb = lne - m9twostep_xb
	
	// CZ earnings quartiles
	ren czone trueczone
	rename czorig czone
	merge n:1 czone using `cz_quartiles', keep(master match) keepusing(y_quartile y_quartilew) nogen
	rename y_quartile y_quartileorig
	rename y_quartilew y_quartileworig
	rename czone czorig
	rename czdest czone
	merge n:1 czone using `cz_quartiles', keep(master match) keepusing(y_quartile y_quartilew) nogen
	rename y_quartile y_quartiledest
	rename y_quartilew y_quartilewdest
	rename czone czdest
	ren trueczone czone
	
	gen x1=(switchtype==1 | switchtype==3)
	bys pikn: egen x2=max(x1) 
	keep if x2==1
	bys y_quartileorig y_quartiledest edate pikn: gen byte Np=_n==1
	bys y_quartileorig y_quartiledest edate state: gen byte Nstates=_n==1
	
	preserve
	
	collapse (mean) y_m_xb (count) Npq=y_m_xb (sum) Np Nstates, by(y_quartileorig y_quartiledest edate) fast
	order y_quartileorig y_quartiledest edate Npq Np Nstates
	
	// Event study (unweighted earnings quartiles)
	foreach v of var y_m_xb {
		twoway  (connected `v' edate if y_quartileorig==1 & y_quartiledest==1) ///
			(connected `v' edate if y_quartileorig==1 & y_quartiledest==2) /// 
			(connected `v' edate if y_quartileorig==1 & y_quartiledest==3) ///
			(connected `v' edate if y_quartileorig==1 & y_quartiledest==4) ///	
			(connected `v' edate if y_quartileorig==4 & y_quartiledest==1) ///
			(connected `v' edate if y_quartileorig==4 & y_quartiledest==2) /// 
			(connected `v' edate if y_quartileorig==4 & y_quartiledest==3) ///
			(connected `v' edate if y_quartileorig==4 & y_quartiledest==4) ///		
			, legend(label(1 "1 to 1") label(2 "1 to 2") label(3 "1 to 3") label(4 "1 to 4") label(5 "4 to 1") label(6 "4 to 2") label(7 "4 to 3") label(8 "4 to 4") cols(4))  title("Event Study - CZ movers") subtitle("earnings quartiles")
		graph export "$output/fig2_es_y_m_xb_byearningsq.pdf", replace
	}
	
	// Disclosure statistics and output
	drbvars y_m_xb Npq, countsvars(Npq)  replace
export excel y_quartileorig y_quartiledest edate y_m_xb Npq using "${output}/fig2_es_y_m_xb_byearningsq.xlsx", firstrow(variable) keepcellfmt sheet(output, replace)  cell(A4)
	
	restore
	
cap log close
}


// D7: OUTPUT 12 [CZ-movers: Event Study by Psi_c Quartiles]
//------------------------------------------------------------------------------
if `d7_tab12'==1 {
	
	// Log
	log using "$logs/6_fullAKM_fig4_czq.log", text replace
	
	// Merge un-weighted CZ vingtiles
	use czone naics4d psi_4jc_2step N_4jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
	preserve
		collapse (sum) N_c = N_4jc_2step, by(czone)
		tempfile N_c
		save `N_c'
	restore
	collapse (mean) psi_c=psi_4jc_2step, by(czone)
	merge 1:1 czone using `N_c', assert(3) nogen
	xtile ving_c = psi_c, n(20)
	xtile vingw_c = psi_c [fw=N_c], n(20)
	tempfile ving_c
	save `ving_c'
	
	use "$data/event_study_czone.dta", replace
	merge m:1 czone using "$data2step/czone_vars.dta", keep(1 3) nogen keepusing(fe_full_c N_c)
	ren fe_full_c psi_c
	ren czone trueczone
	rename czorig czone
	merge n:1 czone using `ving_c', keep(master match) nogen keepusing(ving*)
	rename ving_c ving_corig
	rename vingw_c vingw_corig
	rename czone czorig
	rename czdest czone
	merge n:1 czone using `ving_c', keep(master match) nogen keepusing(ving*)
	rename ving_c ving_cdest
	rename vingw_c vingw_cdest
	rename czone czdest
	ren trueczone czone
	
	// y_m_xb and y_m_xb_m_h2jc
	gen y_m_xb = lne - m9twostep_xb
	gen y_m_xb_m_h2jc = lne - m9twostep_xb - df_m_psi2jc
	
	// Other hierarchy effects
	gen df_m_psic = akm_firm - psi_c
	gen psi2jc_m_psic = (akm_firm - df_m_psi2jc) - psi_c
	
	// CZ effect quartiles from vingtiles
	gen byte psi_c_quartileorig = ceil(ving_corig/5), b(ving_corig)
	gen byte psi_c_quartiledest = ceil(ving_cdest/5), b(ving_cdest)
	gen byte psi_c_wquartileorig = ceil(vingw_corig/5), b(vingw_corig)
	gen byte psi_c_wquartiledest = ceil(vingw_cdest/5), b(vingw_cdest)
	
	sort pikn qtime
	gen x1=(switchtype==1 | switchtype==3)
	by pikn: egen x2=max(x1) 
	keep if x2==1
	bys psi_c_quartileorig psi_c_quartiledest edate pikn: gen byte Np=_n==1
	bys psi_c_quartileorig psi_c_quartiledest edate state: gen byte Nstates=_n==1
	
	preserve
	
	collapse (mean) y_m_xb akm_res=m9twostep_r df_m_psi2jc df_m_psic psi2jc_m_psic y_m_xb_m_h2jc akm_firm (count) Npq=y_m_xb (sum) Np Nstates, by(psi_c_quartileorig psi_c_quartiledest edate) fast
	foreach v of var y_m_xb akm_res df_m_psic df_m_psi2jc psi2jc_m_psic y_m_xb_m_h2jc akm_firm {
		twoway  (connected `v' edate if psi_c_quartileorig==1 & psi_c_quartiledest==1) ///
			(connected `v' edate if psi_c_quartileorig==1 & psi_c_quartiledest==2) /// 
			(connected `v' edate if psi_c_quartileorig==1 & psi_c_quartiledest==3) ///
			(connected `v' edate if psi_c_quartileorig==1 & psi_c_quartiledest==4) ///	
			(connected `v' edate if psi_c_quartileorig==4 & psi_c_quartiledest==1) ///
			(connected `v' edate if psi_c_quartileorig==4 & psi_c_quartiledest==2) /// 
			(connected `v' edate if psi_c_quartileorig==4 & psi_c_quartiledest==3) ///
			(connected `v' edate if psi_c_quartileorig==4 & psi_c_quartiledest==4) ///		
			, legend(label(1 "1 to 1") label(2 "1 to 2") label(3 "1 to 3") label(4 "1 to 4") label(5 "4 to 1") label(6 "4 to 2") label(7 "4 to 3") label(8 "4 to 4") cols(4))  title("Event Study - CZ movers") subtitle("psic quartiles") name(g_`v'_bypsicq, replace)
		graph export "$output/fig4_es_`v'_bypsicq.pdf", replace
	}
	graph combine g_y_m_xb_bypsicq g_akm_res_bypsicq g_df_m_psi2jc_bypsicq g_df_m_psic_bypsicq g_psi2jc_m_psic_bypsicq g_y_m_xb_m_h2jc_bypsicq
	graph export "$output/fig4_es_bypsicq.pdf", replace

	// Disclosure statistics and output	
	drbvars y_m_xb akm_res df_m_psic df_m_psi2jc psi2jc_m_psic akm_firm Npq, countsvars(Npq)  replace
export excel psi_c_quartileorig psi_c_quartiledest edate y_m_xb akm_res df_m_psic df_m_psi2jc psi2jc_m_psic akm_firm Npq using "${output}/fig4_es_bypsicq.xlsx", firstrow(variable) keepcellfmt sheet(output, replace)  cell(A4)

	restore
	
	
cap log close
}


// D7: OUTPUT 13 [CZ movers: Binscatters by CZ Ventiles]
//------------------------------------------------------------------------------
if `d7_tab13'==1 {
	
	use czone naics4d psi_4jc_2step N_4jc_2step using "$data2step/AKMests_2stepfull_jc.dta", clear
	preserve
		collapse (sum) N_c = N_4jc_2step, by(czone)
		tempfile N_c
		save `N_c'
	restore
	collapse (mean) psi_c=psi_4jc_2step, by(czone)
	merge 1:1 czone using `N_c', assert(3) nogen
	xtile ving_c = psi_c, n(20)
	xtile vingw_c = psi_c [fw=N_c], n(20)
	tempfile ving_c
	save `ving_c'
	
	use "$data/event_study_czone.dta", replace
	merge m:1 czone using "$data2step/czone_vars.dta", keep(1 3) nogen keepusing(fe_full_c N_c)
	ren fe_full_c psi_c
	ren czone trueczone
	rename czorig czone
	merge n:1 czone using `ving_c', keep(master match) nogen keepusing(ving*)
	rename ving_c ving_corig
	rename vingw_c vingw_corig
	rename czone czorig
	rename czdest czone
	merge n:1 czone using `ving_c', keep(master match) nogen keepusing(ving*)
	rename ving_c ving_cdest
	rename vingw_c vingw_cdest
	rename czone czdest
	ren trueczone czone
	
	// Generate/rename variables as needed
	gen y_m_xb = lne - m9twostep_xb
	ren m9twostep_r akm_res
	gen y_m_xb_m_h2jc = lne - m9twostep_xb - df_m_psi2jc
	
	// Other hierarchy effects
	gen df_m_psic = akm_firm - psi_c
	gen psi2jc_m_psic = (akm_firm - df_m_psi2jc) - psi_c
	
	sort pikn qtime
	foreach v in psi_c lne y_m_xb df_m_psi2jc df_m_psic psi2jc_m_psic akm_res y_m_xb_m_h2jc akm_firm {
		by pikn: gen d_`v'=`v'-`v'[_n-1]
	}
	
	keep if edate==0 & czswitch==1
	
	bys ving_corig ving_cdest pikn: gen byte Np=_n==1
	bys ving_corig ving_cdest state: gen byte Nstates=_n==1
	
	// CZ Vingtiles
	foreach ving in ving {
	preserve
	fcollapse (mean) d_psi_c d_lne d_y_m_xb d_df_m_psi2jc d_df_m_psic d_psi2jc_m_psic d_akm_res d_y_m_xb_m_h2jc d_akm_firm (count) N=d_lne, by(`ving'w_corig `ving'w_cdest) fast smart
	* single slope
	foreach depvar in d_lne d_y_m_xb d_akm_res d_df_m_psi2jc d_df_m_psic d_psi2jc_m_psic d_y_m_xb_m_h2jc d_akm_firm {
	reg `depvar' d_psi_c [aw=N]
	local betaw_`depvar'=round(_b[d_psi_c],.001)
	}
	restore
	preserve
	
	fcollapse (mean) d_psi_c d_lne d_y_m_xb d_df_m_psi2jc d_df_m_psic d_psi2jc_m_psic d_akm_res d_y_m_xb_m_h2jc d_akm_firm (count) Npq=d_lne (sum) Np Nstates, by(`ving'_corig `ving'_cdest) fast smart
	* single slope
	foreach depvar in d_lne d_y_m_xb d_akm_res d_df_m_psi2jc d_df_m_psic d_psi2jc_m_psic d_y_m_xb_m_h2jc d_akm_firm {
	reg `depvar' d_psi_c [aw=Npq]
	local beta=round(_b[d_psi_c],.001)
	twoway (scatter `depvar' d_psi_c,  mcolor(%0) xline(0) yline(0) ylabel(-0.5(0.25)0.5))  (lfit `depvar' d_psi_c) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==1, msize(small) msymbol(smcircle_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==3, msize(small) msymbol(smsquare_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==5, msize(small) msymbol(smtriangle_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==7, msize(small) msymbol(smdiamond_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==9, msize(small) msymbol(smplus)) ///       
		   (scatter `depvar' d_psi_c if `ving'_corig==11, msize(small) msymbol(smcircle_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==13, msize(small) msymbol(smsquare_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==15, msize(small) msymbol(smtriangle_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==17, msize(small) msymbol(smdiamond_hollow)) ///
		   (scatter `depvar' d_psi_c if `ving'_corig==19, msize(small) msymbol(smplus)) ///       
		   (scatter `depvar' d_psi_c if `ving'_corig==20, msize(small) msymbol(smcircle_hollow)) ///
		   , legend(off) title("`depvar' vs. Psic- CZ movers") subtitle("slope `beta' vs weighted `betaw_`depvar''") name(g_`depvar'_bypsic`ving', replace)
	
	}
	graph combine g_d_y_m_xb_bypsic`ving' g_d_akm_res_bypsic`ving' g_d_df_m_psi2jc_bypsic`ving' g_d_y_m_xb_m_h2jc_bypsic`ving' g_d_df_m_psic_bypsic`ving'  g_d_psi2jc_m_psic_bypsic`ving' , ycommon xcommon
	graph export "$output/fig7ind_c`ving'.pdf", replace
	
	// Disclosure statistics and output	
	drbvars d_y_m_xb d_akm_res d_df_m_psic d_df_m_psi2jc d_psi2jc_m_psic d_psi_c d_akm_firm Npq, countsvars(Npq)  replace
export excel ving_corig ving_cdest d_y_m_xb d_akm_res d_df_m_psic d_df_m_psi2jc d_psi2jc_m_psic d_psi_c d_akm_firm Npq using "${output}/fig7ind_cving.xlsx", firstrow(variable) keepcellfmt sheet(output, replace)  cell(A4)
	
	restore
	
	
cap log close
	}
	
	
}


// D7: OUTPUT 21 [AKM Decomp, PQ psi_jc and psi_c components]
//------------------------------------------------------------------------------
if `d7_tab21'==1 {
	
	// CZ-ind estimates
	//--------------------------------------------------------------------------
	use czone using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	tempfile czs
	save `czs'
	
	use naics2d using "$data2step/AKMests_2stepfull_jc.dta", replace
	duplicates drop
	gen temp = 1
	joinby temp using `czs'
	drop temp
	
	preserve
		use czone naics2d psi_2jc_2step alpha_2jc_2step N_2jc_2step y_2jc xb_2jc r_2jc df_m_psi2jc_2jc using "$data2step/AKMests_2stepfull_jc.dta", clear
		duplicates drop
		tempfile ests_2jc
		save `ests_2jc'
	restore
	merge 1:1 czone naics2d using `ests_2jc', assert(1 3) nogen
	
	// CZ estimates
	//--------------------------------------------------------------------------
	preserve
	bys czone: egen N_c = total(N_2jc_2step)
	keep czone N_c
	duplicates drop
	tempfile n_c
	save `n_c'
	restore
	
	preserve
	collapse (mean) y_c=y_2jc pe_c=alpha_2jc_2step psi_c=psi_2jc_2step xb_c=xb_2jc r_c=r_2jc df_m_psi2jc_c=df_m_psi2jc_2jc [fw=N_2jc_2step], by(czone)
	tempfile ests_c
	save `ests_c'
	restore
	merge m:1 czone using `ests_c', assert(3) nogen
	merge m:1 czone using `n_c', assert(3) nogen
	
	// Rename variables
	ren alpha_2jc_2step pe_2jc
	ren psi_2jc_2step psi_2jc
	ren N_2jc_2step N_2jc
	foreach v of var pe_2jc psi_2jc N_2jc df_m_psi2jc_2jc {
		replace `v' = 0 if mi(`v')
	}
	
	// Save CZ and CZ-ind estimates
	tempfile ests
	save `ests'
	
	// Job-level data
	use czone naics4d akm_person akm_firm xb r using "$data2step/M9twostep_step1xbr.dta", replace
	gen y = akm_person + akm_firm + xb + r
	gen byte n_1 = 1 /* temporary variable for decomp2w prog */
	gen naics2d = floor(naics4d/100), a(naics4d)
	merge m:1 czone naics2d using `ests', assert(2 3) nogen keepusing(psi_2jc psi_c)
	replace n_1=0 if mi(akm_person)
	drop naics4d
	
	// Rename vars
	ren czone cz
	ren akm_person pe
	ren akm_firm fe
	
	* KLINE 2 decomposition [fw]
	cap program drop decomp2w
	program define decomp2w
	args name y components fw
	cap drop col*`name'
	qui gen col1`name'="sd and var(`y') share=" if _n==1
	qui sum `y' [fw=`fw']
	local var=r(Var)
	qui gen col2`name'=r(sd) if _n==1
	qui gen col3`name'=`var'/r(Var) if _n==1
	noi dis "sd and var(`y') share=" _col(45) "&"  round(r(sd),.0001) _col(55) "& (" round(r(Var)/`var',.0001) ")"
	local i=1
	foreach comp1 in `components' {
		qui sum `comp1' [fw=`fw']
		noi dis "sd and var(`comp1') share=" _col(45) "&"  round(r(sd),.0001) _col(55) "& (" round(r(Var)/`var',.0001) ")"
		qui replace col1`name'="sd and var(`comp1') share=" if _n==`i'+1
		qui replace col2`name'=round(r(sd),.000001) if _n==`i'+1
		qui replace col3`name'=round(r(Var)/`var',.000001) if _n==`i'+1
		local ++i
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
		qui replace col1`name'="rho and 2cov(`comp1',`comp2') share=" if _n==`i'+1
		qui replace col2`name'=round(`rho',.000001) if _n==`i'+1
		qui replace col3`name'=round(`covshr_`comp1'`comp2'',.000001) if _n==`i'+1
		noi dis "rho and 2cov(`comp1',`comp2') share=" _col(45) "&"  round(`rho',.0001) _col(55) "& (" round(`covshr_`comp1'`comp2'',.0001) ")"
		local ++i
	}
	}
	noi dis "Observations" _col(55) "&"  %30.0fc r(N)
	qui replace col1`name'="N=" if _n==`i'+1
	drbrclass N , countscalars(N)
	qui replace col2`name'=r(N) if _n==`i'+1
	drbvars col2`name' col3`name', replace
	format  col2`name' col3`name'  %030.6gc
	list col1`name' col2`name' col3`name' if col1`name'~=""
	end
	
	preserve
	decomp2w y_psic y      "pe psi_c xb r fe"    n_1
	keep col*
	drop if col1y_psic==""
	export excel col*y_psic using "${output}/tab2new.xlsx", firstrow(variable) keepcellfmt cell(A3) sheet(1, modify)
	restore
	preserve
	decomp2w y_psi2jc y     "pe psi_2jc xb r fe"    n_1
	keep col*
	drop if col1y_psi2jc==""
	export excel col*y_psi2jc using "${output}/tab2new.xlsx", firstrow(variable) keepcellfmt cell(A21) sheet(1, modify)
	restore
}

// D8: OUTPUT 1 [Groups of CZs]
//------------------------------------------------------------------------------
if `d8_tab1'==1 {
	
	* ground-up cz effects (baseline, 100pct sample)
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
	use "$yidata/cw_cty_czone.dta", replace
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

	*Table  means of each of the components of our decomposition
	merge 1:1 cz using `czst', keep(master match) nogen
	merge 1:1 cz using "$yidata/czranking6_alt-wage.dta", nogen keep(master match) keepusing(wcount)
	gen logsize_c=ln(wcount/9)	
	gen size_c=exp(logsize_c)
	replace size_c=10 if size_c==.
	gen over25k=size>25000

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
	
	foreach group in small top4_phi_metro top6_phi_rsrc mid1090_phi_c bottom10_phi_c psi_c_q1 psi_c_q2 psi_c_q3 psi_c_q4 psi_c_q5 {
	dis _n _n "CZ list for group `group'"
	list cz if `group'==1, clean noob
	}


}


// D8: OUTPUT 2 [Slope for bin scatter, 1 coeff + SE]
//------------------------------------------------------------------------------
if `d8_tab2'==1 {
	
	matrix T = J(3,2,.)
	matrix rownames T = d_y_m_xb d_akm_res d_match
	matrix colnames T = coeff se
	
	// Bin Scatters
	use "$data/event_study_firmnum.dta", replace
	ren st_fips state
	gen y_m_xb = lne - m9twostep_xb
	ren m9twostep_r akm_res
	sort pikn qtime
	foreach v in akm_firm y_m_xb akm_res {
		by pikn: gen d_`v'_t4=`v'[_n+4]-`v'[_n-1]
	}
	keep if edate==0 /* & firmnumswitch==1 <-- redundant */
	
	bys firm_vingtile_worig firm_vingtile_wdest edate pikn: gen byte Np=_n==1
	bys firm_vingtile_worig firm_vingtile_wdest edate state: gen byte Nstates=_n==1
	
	fcollapse (mean) d_akm_res_t4 d_akm_firm_t4 (count) Npq=d_akm_res (sum) Np Nstates, by(firm_vingtile_worig firm_vingtile_wdest) fast smart
	
	* single slope
	local r=1
	eststo clear
	foreach depvar in d_akm_res_t4 {
	eststo r`r': reg `depvar' d_akm_firm_t4
	qui matrix T[`r',1] = _b[d_akm_firm_t4]
	qui matrix T[`r',2] = _se[d_akm_firm_t4]
	mat list T
	local ++r	
	}
	
	// Output
	esttab r?, se r2 ar2 label replace type title("Slope for Binscatter: Firm Movers, t to t+4") mtitles("d_akm_res_t4")  scalar(rmse)

	forval r=1/1 {
	drbeclass r`r',  addest(r2 r2_a rmse) eststo(r`r')
	}
	esttab r?, se r2 ar2 label replace type title("Slope for Binscatter: Firm Movers, t to t+4") mtitles("d_akm_res_t4")  scalar(rmse)




}


cap log close


	
