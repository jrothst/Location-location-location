/*----------------------------------------------------------------------------*\

	Disclosure 7
	
	Output Created Here:
		- Disc 7: tabs 3 (partial)

Program to compare three models of industry effects:
1) Run AKM (1-step) on full population, then average firm effects only over young people.
2) Run AKM (1-step) on young people
3) Run AKM (1 step) on young people, using extra experience controls

This program runs (2) and (3). To avoid running the full AKM again, we can merge the data
that this program generates to those from (1), and compare. We likely want to compare the 
CZ-industry means, or perhaps the CZ means.

	Input Datasets:
		- "$datadir/mig5_pikqtime_1018_cz*.dta"
		- "$yidata/m5_ecf_seinunit.dta"
		- "$yidata/cw_cty_czone.dta"
		
	Datasets Created Here:
		- "$data2step/young_comparemodels_25.dta"

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
include ${homedir}/mig5_paths.do

// CHOOSE TOP X CZs FOR "largeczs"
local size = 25

if `size'==1 {
	local size "top`size'"
	local largeczs "20500"
}
else if `size'==10 {
	local size "top`size'"
	local largeczs "38300, 19400, 24300, 11304, 19600, 32000, 19700, 20500, 37800, 9100"
}
else if `size'==25 {
	local size "top`size'"
local largeczs "38300, 19400, 24300, 11304, 19600, 32000, 19700, 20500, 37800, 9100, 11600, 39400, 33100, 7000, 35001, 21501, 20901, 28900, 38000, 37400, 11302, 6700, 37500, 15200, 24701"
}



// Pick CZs to loop over -- all, or a named one.
local first=1
local files: dir "$datadir" files "mig5_*_cz*.dta"
foreach file in `files' {

		di "Opening: `file'"
		local cz = regexr("`file'", ".dta", "")
		local cz = regexr("`cz'", "mig5_pikqtime_1018_", "")
		local cz = regexr("`cz'", "[czd]+", "")
		di "Entering loop for CZ `cz'"
		
		use "$datadir/`file'", clear
		order pikn state qtime cz sein seinunit naics2d naics4d firmid y firmsize age
		
		* Add CZ for division 1-9
		if `cz'<10 {
			gen year=floor((qtime-1)/4+1985)
			gen quarter=qtime-4*(year-1985)
			merge m:1 sein seinunit year quarter using "$yidata/m5_ecf_seinunit.dta", keep(master match) keepusing(leg_state leg_county) nogen
			gen cty_fips = leg_state+leg_county
			destring cty_fips, replace
			merge m:1 cty_fips using "$yidata/cw_cty_czone.dta", keep(1 3) nogen
			drop year quarter leg_state leg_county cty_fips
		}
		else if `cz'>10 {
			gen czone = cz
		}
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
	
	// Clean up data
	drop sein seinunit
	ren cz top59cz

  // Define age and identify the young person sample
  gen age101=age - (qtime-101)/4
  bys pikn: egen minage101=min(age101)
  assert age101<minage101+1
  gen byte young=minage101<=26 // NOTE: THIS MAY NOT BE THE DEFINITION WE SETTLE ON.
  keep if young==1
  drop age101 young minage101

  timer clear 12
  timer on 12
  qui count
  di "Original sample has observation count=`r(N)'"
  isid pikn qtime

  // Make dynamic experience
  sort pikn qtime
  by pikn: gen czfirst=czone[1] // new change 
  by pikn: gen exper=_n-1
  gen largecz=inlist(czone,`largeczs')
  by pikn: gen bigexper=sum(largecz)-largecz
  gen exper_big=exper*largecz
  gen bigexper_big=bigexper*largecz

  sort czone firmid pikn qtime
  egen double firmnum=group(czone firmid)
  // We are going to normalize a single industry to have zero mean firm effect
  // Note: 7225 is restaurants
  gen byte normind=(naics4d==7225)
  sort pikn qtime
  tempfile basedata
  save `basedata'

  capture program drop runAKM
  // A small program to run the AKM model and pull in the main results
  program define runAKM
    args tempdir depvar size
    export delimited pikn qtime firmnum `depvar' age czone normind ///
                   using "$dynamic_tempdir/data2matlab_`size'.raw", replace
    tempfile data2matlab
    save `data2matlab'
    *Clean up, so we will know if AKM worked
     cap rm $dynamic_tempdir/datafrommatlab_`size'.raw
     cap rm $dynamic_tempdir/datafrommatlab_`size'_stats.raw
     cap rm $dynamic_tempdir/datafrommatlab_`size'_firm.raw
     cap rm $dynamic_tempdir/datafrommatlab_`size'_person.raw
     cap rm $dynamic_tempdir/datafrommatlab_`size'_xb.raw
    *Run matlab to run the AKM model
     di "Starting the matlab call - dependent variable is `depvar'"
     ! matlab -nodisplay -nosplash -batch ///
        "firmAKM_callable('$dynamic_tempdir/data2matlab_`size'.raw', '$dynamic_tempdir/datafrommatlab_`size'')"
     di "Matlab call finished" 
    *Read in the results
     import delimited using $dynamic_tempdir/datafrommatlab_`size'_firm.raw, clear
     rename v1 firmnum
     rename v2 akm_firm
     tempfile firmfx
     save `firmfx'
     import delimited using $dynamic_tempdir/datafrommatlab_`size'_person.raw, clear
     rename v1 pikn
     rename v2 akm_person
     tempfile personfx
     save `personfx'
     import delimited using $dynamic_tempdir/datafrommatlab_`size'_xb.raw, clear
     rename v1 pikn
     rename v2 qtime
     rename v3 xb
     tempfile xbfx
     save `xbfx'
  
    use pikn qtime czone state firmid firmnum `depvar' naics4d using `data2matlab'
    qui merge m:1 pikn using `personfx', assert(1 3) nogen
    qui merge m:1 firmnum using `firmfx', assert(1 3) nogen
    qui merge 1:1 pikn qtime using `xbfx', assert(1 3) nogen
    assert akm_person==. if akm_firm==.
    assert akm_person<. if akm_firm<.
    assert xb==. if akm_firm==.
    assert xb<. if akm_firm<.
    keep if akm_person<.
    gen e=`depvar'-akm_person-akm_firm-xb
    keep pikn qtime czone state firmid `depvar' naics4d xb ///
         e akm_person akm_firm
  end // end runAKM

  // Now run for each of our dynamic controls.
  foreach v in y exper bigexper exper_big bigexper_big {
    use `basedata'
    runAKM $dynamic_tempdir `v' `size'
    if "`v'"=="y" {
      preserve
      // Grab the DOF statistic for use in short regression
      import delimited using $dynamic_tempdir/datafrommatlab_`size'_stats.raw, clear
      local dof_akm=dof
      restore
    } 
    else {
      keep pikn qtime e
    }
    rename e e_`v'
    tempfile AKMresults_`v'
    save `AKMresults_`v'', replace
  }
  use `basedata'
  merge 1:1 pikn qtime using `AKMresults_y', nogen keepusing(pikn qtime e_y akm_person akm_firm xb)
  foreach v in exper bigexper exper_big bigexper_big {
    merge 1:1 pikn qtime using `AKMresults_`v'', nogen
  }
  // Run the "short" F-W regression
    // we are going to do it in an eclass program so we can fix the output
     cap program drop reg_shortfw
     program define reg_shortfw, eclass
       syntax varlist, dof_akm(integer) [robust]
       di "Unadjusted short regression, without DOF correction
       regress `varlist', noconstant `robust' vce(cluster czfirst) // new change
       local olddof=e(N)-e(df_m)-1
       local newdof=`dof_akm'-e(df_m)
       matrix beta=e(b)
       matrix V=e(V)
       matrix V2=(`olddof'/`newdof')*V
       ereturn repost V=V2
       di "Adjusted short regression, with DOF correction
       di "N = " e(N)
       di "Unadjusted model degrees-of-freedom is " e(df_m)
       di "Unadjusted residual degrees-of-freedom is " e(N)-e(df_m)-1
       di "AKM model has " (e(N)-`dof_akm') " model and " `dof_akm' " residual degrees of freedom."
       di "Adjusted model DOF is " (e(N)-`dof_akm'+e(df_m)) " and residual DOF is " `newdof'
       ereturn display
    end

// D7: OUTPUT 3   
   reg_shortfw e_y e_exper e_bigexper e_exper_big e_bigexper_big , dof_akm(`dof_akm') // new change

  gen double tildey=y - exper*_b[e_exper] ///
                     - bigexper*_b[e_bigexper] ///
                     - exper_big*_b[e_exper_big] ///
                     - bigexper_big*_b[e_bigexper_big]
  // Now rerun the AKM with the Z-adjusted y as the dependent variable
  runAKM $dynamic_tempdir tildey `size'
  rename akm_person akm_person_dynamic
  rename akm_firm akm_firm_dynamic
  rename xb xb_dynamic
  rename e e_dynamic
  keep pikn qtime tildey *dynamic
  tempfile AKMresults_y_adj
  save `AKMresults_y_adj'
  use `basedata'
  merge 1:1 pikn qtime using `AKMresults_y', nogen
  merge 1:1 pikn qtime using `AKMresults_y_adj', nogen
  save $data2step/young_comparemodels_`size'.dta, replace

  di "Finished for CZs `keepczs'"
  timer off 12
  qui timer list 12
  di "This took `r(t12)' seconds to complete"
  di "It finished on `c(current_date)' at `c(current_time)'"
  di ""
  di ""
  

log close
