*models for ACS results in paper

*uses summary files 
*       czeffects (wages + wage models for all workers, chars for all workers)
*       czchars_allp (characteristics of all adults)
*       czeffects_byed (models for 12 and 16 year education groups)
*       czeffects_earns (models for log earnings)
*       hourseffects (models for employment and hours with 0 for nonworkers) 
*       
*       also uses file with cznames (czname.dta)


* naming convention for model results
*  effects =   cz_group_outcome_model#    group:  all;  (hs, coll, 13p); (m, f)   
*                                       outcome: w (wage); e (earnings); hours; emp  
*                                       model#  1=basic mincer 2=plus extras 3=plus ind effects
*
*  Xb from model = skill_group_outcome_model#


cap log close 
log using program.log, replace


*pre-process czeffects_earns
use ${scratch}/czeffects_earns
drop logwage wcount
tempfile temp1
save `temp1', replace
clear

*pre-process hourseffects
use ${scratch}/hourseffects
drop count wcount
drop sk*

*fix naming convention
rename cz_emp_m1 cz_all_emp_m1
rename cz_emp_m2 cz_all_emp_m2
rename cz_hours_m1 cz_all_hours_m1
rename cz_hours_m2 cz_all_hours_m2

rename cz_emp_m_m1  cz_m_emp_m1
rename cz_emp_m_m2  cz_m_emp_m2
rename cz_hours_m_m1 cz_m_hours_m1
rename cz_hours_m_m2 cz_m_hours_m2

rename cz_emp_f_m1 cz_f_emp_m1
rename cz_emp_f_m2 cz_f_emp_m2
rename cz_hours_f_m1 cz_f_hours_m1
rename cz_hours_f_m2 cz_f_hours_m2

tempfile temp2
save `temp2', replace
clear


*now start the big merge


use ${scratch}/czchars_allp

*drop wage from this collapse since the weight is wrong
drop logwage

label var count_allp "count of all adults in CZ"
label var wcount_allp "weighted count of all adults in CZ"


*** add names of czs in variable called place_name
***
merge 1:1 cz using ${raw}/cznames
drop _merge





merge 1:1 cz using ${scratch}/czeffects
drop _merge

*rename female and education to distinguish from means for all adults 
rename female female_allw
rename educ educ_allw

*have double checked that cz effects match those from phi_cz_earns
*retain only the ones that are not in czeffects_earns

drop cz_effects_m2 
drop cz_effects_m3 
rename cz_effects_m1 cz_all_w_m1
rename skill_m1 skill_all_w_m1
rename skill_m2 skill_all_w_m2
rename skill_m3 skill_all_w_m3

label var count "count of all workers in CZ"
label var wcount "weighted count of all workers in CZ"


sum


merge 1:1 cz using ${scratch}/czeffects_byed
drop _merge

*drop vars that will be collected from czeffects_earns
drop logwagehs
drop logwagecoll
drop cz_effects_hs_m2
drop cz_effects_hs_m3
drop cz_effects_coll_m2
drop cz_effects_coll_m3
drop wcount_hs
drop wcount_coll

rename skill_hs_m2 skill_hs_w_m2
rename skill_hs_m3 skill_hs_w_m3
rename skill_coll_m2 skill_coll_w_m2
rename skill_coll_m3 skill_coll_w_m3

sum


*now merge with czeffects_earns (pre-processed to drop logwage and wcount)
merge 1:1 cz using `temp1'
drop _merge




*now merge with hourseffects (pre-processed to drop some vars and fix naming)
merge 1:1 cz using `temp2'
drop _merge





***** THIS IS THE MERGED CZ LEVEL DATA SET

*size is based on total count of adults in CZ (working or not)
gen logsize=ln(wcount_allp)


*check the count vars
sum count wcount count_allp wcount_allp wcount_hs wcount_coll
corr count wcount count_allp wcount_allp wcount_hs wcount_coll

*check that means of wage, cz effects, and skill add up (mean of CZ effects should be 0)
sum logwage cz_all_w_m1 skill_all_w_m1 cz_all_w_m2 skill_all_w_m2 cz_all_w_m3 skill_all_w_m3 [w=wcount]
sum logwagehs   cz_hs_w_m2   skill_hs_w_m2   cz_hs_w_m3   skill_hs_w_m3   [w=wcount_hs]
sum logwagecoll cz_coll_w_m2 skill_coll_w_m2 cz_coll_w_m3 skill_coll_w_m3 [w=wcount_coll]

*define wage gap (coll=16 yrs ed, hs=12 years ed)
gen return=logwagecoll-logwagehs
gen return_m2=cz_coll_w_m2-cz_hs_w_m2
gen return_m3=cz_coll_w_m3-cz_hs_w_m3
sum return return_m2 return_m3 [w=wcount]



*check adding up -- all models should have coefficients of 1
reg logwage cz_all_w_m1 skill_all_w_m1 [w=wcount], robust
reg logwage cz_all_w_m2 skill_all_w_m2 [w=wcount], robust
reg logwage cz_all_w_m3 skill_all_w_m3 [w=wcount], robust
reg logwagehs cz_hs_w_m2 skill_hs_w_m2 [w=wcount_hs], robust
reg logwagehs cz_hs_w_m3 skill_hs_w_m3 [w=wcount_hs], robust
reg logwagecoll cz_coll_w_m2 skill_coll_w_m2 [w=wcount_coll], robust
reg logwagecoll cz_coll_w_m3 skill_coll_w_m3 [w=wcount_coll], robust




********************************************************************************

*Section II narrative

sum logwage cz_all_w_m3 [w=wcount] , detail


*Appendix A narrative about sample sizes

gsort -wcount_allp
gen rank = _n

list cz place_name logwage count wcount_all cz_all_w_m3 skill_all_w_m3 if rank<=20
list cz place_name logwage count wcount_all cz_all_w_m3 skill_all_w_m3 if rank>=197 & rank<=203
list cz place_name logwage count wcount_all cz_all_w_m3 skill_all_w_m3 if rank>=397 & rank<=403



****APPENDIX FIGURES 2-4 - slopes

*appendix figure 2 slope
reg cz_all_w_m3 logwage [w=wcount], robust

*appendix figure 3 slopes
reg logwage logsize [w=wcount], robust
reg cz_all_w_m3 logsize [w=wcount], robust
reg skill_all_w_m3 logsize [w=wcount], robust

*appendix figure 4 slopes (NOTE: weights are group specific weighted counts)
reg cz_hs_w_m3 cz_all_w_m3 [w=wcount_hs], robust
reg cz_coll_w_m3 cz_all_w_m3 [w=wcount_coll], robust




*Appendix Table 1 - size elasticities
estimates clear

*row 1 
reg logwage logsize [w=wcount], robust
est sto at1_r1_c1
reg cz_all_w_m2 logsize [w=wcount], robust
est sto at1_r1_c2
reg cz_all_w_m3 logsize [w=wcount], robust
est sto at1_r1_c3

*row 2 
reg logearn logsize [w=wcount], robust
est sto at1_r2_c1
reg cz_all_e_m2 logsize [w=wcount], robust
est sto at1_r2_c2
reg cz_all_e_m3 logsize [w=wcount], robust
est sto at1_r2_c3

*row 3 
reg logwagehs logsize [w=wcount], robust
est sto at1_r3_c1
reg cz_hs_w_m2 logsize [w=wcount], robust
est sto at1_r3_c2
reg cz_hs_w_m3 logsize [w=wcount], robust
est sto at1_r3_c3

*row 4
reg logearnhs logsize [w=wcount], robust
est sto at1_r4_c1
reg cz_hs_e_m2 logsize [w=wcount], robust
est sto at1_r4_c2
reg cz_hs_e_m3 logsize [w=wcount], robust
est sto at1_r4_c3

*row 5 
reg logwage13p logsize [w=wcount], robust
est sto at1_r5_c1
reg cz_13p_w_m2 logsize [w=wcount], robust
est sto at1_r5_c2
reg cz_13p_w_m3 logsize [w=wcount], robust
est sto at1_r5_c3

*row 6
reg logearn13p logsize [w=wcount], robust
est sto at1_r6_c1
reg cz_13p_e_m2 logsize [w=wcount], robust
est sto at1_r6_c2
reg cz_13p_e_m3 logsize [w=wcount], robust
est sto at1_r6_c3

outreg2 [at1_*] using "${results}/apptab1.txt",  dec(5) text noaster noparen depvar replace 


*appendix Table 2 (NOTE  weighted by wcount_allp since these vars are over adult pop)

*row 1

reg emp logsize [w=wcount_allp], robust
est sto at2_r1_c1
reg emp logwage [w=wcount_allp], robust
est sto at2_r1_c2
reg emp cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r1_c3

reg emp_m logsize [w=wcount_allp], robust
est sto at2_r1_c4
reg emp_m logwage [w=wcount_allp], robust
est sto at2_r1_c5
reg emp_m cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r1_c6

reg emp_f logsize [w=wcount_allp], robust
est sto at2_r1_c7
reg emp_f logwage [w=wcount_allp], robust
est sto at2_r1_c8
reg emp_f cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r1_c9


*row 2

reg cz_all_emp_m2 logsize [w=wcount_allp], robust
est sto at2_r2_c1
reg cz_all_emp_m2 logwage [w=wcount_allp], robust
est sto at2_r2_c2
reg cz_all_emp_m2  cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r2_c3

reg cz_m_emp_m2 logsize [w=wcount_allp], robust
est sto at2_r2_c4
reg cz_m_emp_m2 logwage [w=wcount_allp], robust
est sto at2_r2_c5
reg cz_m_emp_m2 cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r2_c6

reg cz_f_emp_m2 logsize [w=wcount_allp], robust
est sto at2_r2_c7
reg cz_f_emp_m2 logwage [w=wcount_allp], robust
est sto at2_r2_c8
reg cz_f_emp_m2 cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r2_c9



*row 3

reg hours logsize [w=wcount_allp], robust
est sto at2_r3_c1
reg hours logwage [w=wcount_allp], robust
est sto at2_r3_c2
reg hours cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r3_c3

reg hours_m logsize [w=wcount_allp], robust
est sto at2_r3_c4
reg hours_m logwage [w=wcount_allp], robust
est sto at2_r3_c5
reg hours_m cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r3_c6

reg hours_f logsize [w=wcount_allp], robust
est sto at2_r3_c7
reg hours_f logwage [w=wcount_allp], robust
est sto at2_r3_c8
reg hours_f cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r3_c9


*row 4

reg cz_all_hours_m2 logsize [w=wcount_allp], robust
est sto at2_r4_c1
reg cz_all_hours_m2 logwage [w=wcount_allp], robust
est sto at2_r4_c2
reg cz_all_hours_m2  cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r4_c3

reg cz_m_hours_m2 logsize [w=wcount_allp], robust
est sto at2_r4_c4
reg cz_m_hours_m2 logwage [w=wcount_allp], robust
est sto at2_r4_c5
reg cz_m_hours_m2 cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r4_c6

reg cz_f_hours_m2 logsize [w=wcount_allp], robust
est sto at2_r4_c7
reg cz_f_hours_m2 logwage [w=wcount_allp], robust
est sto at2_r4_c8
reg cz_f_hours_m2 cz_all_w_m2 [w=wcount_allp], robust
est sto at2_r4_c9

outreg2 [at2_*] using "${results}/apptab2.txt",  dec(5) text noaster noparen depvar replace 


*****LAST STEP: output data set with key vars for graphing and for LEHD use

keep cz wcount wcount_allp wcount_hs wcount_coll wcount_13p logwage educ_allw cz_all_w_m1 cz_all_w_m2 cz_all_w_m3 cz_hs_w_m3 cz_coll_w_m3
gen collplus=wcount_13p/wcount
label var collplus "share of workers w/ some coll or more"

desc
sum

save ${scratch}/acs_vars, replace

log close



