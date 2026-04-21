*Program to run all ACS analyses. Based on public data, and some disclosed
*results from internal RDC analyses of LEHD data.


cap log close mainlog
log using main_acs.log, replace text name(mainlog)
clear *

// Which parts to run?
local dostep1 1 // Prepare PUMA-CZ crosswalks (quick)
local dostep2a 0 // Prepare ACS raw files - get into stata (v slow)
local dostep2b 1 // Prepare ACS raw files - preparation in stata (slow)
local dostep3 1 // Create CZ-level collapsed files
local dostep4 1 // Some cleanup and final results
local dostep5 1 // Housing data and analyses
local dostep6 1 // Make files to send to Census Bureau

creturn list

global home "~/replication/L3/acs" // change to reflect local settings
global code "${home}/code"
global raw "${home}/origdata"
global results "${home}/results"
global tocensus "${home}/tocensus"
global scratch "${home}/intermediate" // For intermediate files that we might want
global tmp "${home}/tmp" // for large, temporary files that can be wiped.
// On our system, this is a symbolic link to a directory on a temp drive.
// Note that the extract??.sas programs in step 2, and the household.sas program in
// step 5, hard-code its (relative) location, so may need to be adjusted if it is moved.

/*  
Uses Stata packages:
cleanplots:  <net install cleanplots, from(http://fmwww.bc.edu/RePEc/bocode/c)>
outreg2.ado: <net install outreg2, from(http://fmwww.bc.edu/RePEc/bocode/o)>
*/ 
which outreg2


if `dostep1'==1 {
  cd ${code}/step1_CZ_puma_files
  do puma2000_prep.do
  do puma2010_prep.do
  drop _all
}

if `dostep2a'==1 {
  cd ${code}/step2_extract_programs
  do extractacs.do // This is slow
  drop _all
}

if `dostep2b'==1 {
  cd ${code}/step2_extract_programs
  *Renaming, recoding, and merging CZs
  do readacs.do
  *Check sample sizes
  d using ${scratch}/simple2010
  assert r(N)==1941443
  d using ${scratch}/simple2018
  assert r(N)==2011848
  *Cleaning, assigning to CZs, NAICS; creating key variables for regressions
  do rank_revised_extravars.do
  *Single extract of all adults (even if not working)
  do hours1
  drop _all
}  

if `dostep3'==1 {
  cd ${code}/step3_collapse
  do cz_chars
  do phi_cz_acs
  do phi_cz_byed
  do phi_cz_earns
  do phi_cz_hours
  do phi_cz_alt-wage
  drop _all
}

if `dostep4'==1 {
  cd ${code}/step4_programs
  do program
  do tab6_external.do
  do afig2-4.do
  drop _all
}

if `dostep5'==1 {
  cd ${code}/step5_housing
  do extracthousing
  do hprices
  drop _all
}

if `dostep6'==1 {
  cd ${code}/step6_tocensus
  do makecensusfiles
  drop _all
}

// Change back to code home directory
cd $code

log close mainlog

