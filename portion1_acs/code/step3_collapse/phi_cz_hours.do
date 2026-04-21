*program phi_cz_hours - follows hours1 using working data set with all adult obs
*uses wage model from industry paper

*     step1: clean up industry codes 
*     step2: fit hours models get ind effects and xb by CZ, with and without extra controls
*     step3: collapse to CZ and output


*need to update directories

cap log close
log using phi_cz_hours.log, replace

set seed 912109

*input data
local acs2010_2018 "${scratch}/hours_alldata.dta" // ACS



use `acs2010_2018', clear



*STEP1 : define sample, set up covariates 


*drop obs to be consistent with 'sub' files used for main ACS analysis
drop if age < educ + 7 
drop if age > 62

gen alaska=(cz>=34101)*(cz<=34115)
replace cz=99999 if alaska==1


gen hours=hrswkly*weeksly
gen emp=weeksly>0

sum hours hrswkly weeksly female educ college wnh bnh anh imm if emp==0 [w=pweight]
sum hours hrswkly weeksly female educ college wnh bnh anh imm if emp==1 [w=pweight]


di _N

*set up X's

egen race_ind = rowmax(hispanic wnh bnh anh)
gen onh = (race_ind == 0)
drop race_ind 

foreach race in hispanic wnh bnh anh onh {
	gen f_`race' = female*`race'
}

gen ysa = year - yoep // years since arrival
replace ysa = 0 if imm == 0
gen useducated = 0 // educated in us
replace useducated = 1 if imm == 1 & ysa > exp+5
tab educ useducated if imm == 1

gen imm_LatAm = (region_birth == 3 & imm == 1) // region of birth indicators: omitted group is 'other'
gen imm_Asia = (region_birth == 4 & imm == 1)
gen imm_EurNAOceania = (inlist(region_birth,5,7,8) & imm == 1)
gen imm_LatAm_ysa = imm_LatAm*ysa
gen imm_Asia_ysa = imm_Asia*ysa
gen imm_EurNAOceania_ysa = imm_EurNAOceania*ysa

*extra covariates
gen f_age=female*age
gen exp4=exp2*exp2
gen f_exp4=female*exp4



gen fod = field_degree_agg // 0's for non-college grads
replace fod = 0 if fod == .




*now adjust industry codes using hand fixes from compare_ind.do in data/raw/2018/ 
*ind is now 2018 coding of ind

set seed 9211
gen u1=runiform()
sum u1


gen ind_old=ind
replace ind=1691 if ind==1680
replace ind=1691 if ind==1690

replace ind=3095 if ind==3090

replace ind=3291 if ind==3190
replace ind=3291 if ind==3290

replace ind=3365 if ind==3360

replace ind=3875 if ind==3870

replace ind=3895 if ind==3890

replace ind=4195 if ind==4190

replace ind=4265 if ind==4260

replace ind=4795 if ind==4790

replace ind=4971 if ind==4970
replace ind=4971 if ind==4972

replace ind=5275 if ind==5270

replace ind=5295 if ind==5290

*dept stores and superstores mess
*up to 2017 depart and discount in 5380, misc general in 5390
*in 2018+ depart in 5381 (about 45% of 5380), misc general+superstores in 5391 (all 5390+55% of 5380)

replace ind=5381 if ind==5380 & u1<=0.45
replace ind=5391 if ind==5380 & u1>0.45
replace ind=5391 if ind==5390


replace ind=5593 if ind==5590
replace ind=5593 if ind==5591
replace ind=5593 if ind==5592

replace ind=6991 if ind==6990 & u1<=0.75
replace ind=6992 if ind==6990 & u1>0.75

replace ind=7071 if ind==7070 & u1<=0.78
replace ind=7072 if ind==7070 & u1>0.78

replace ind=7181 if ind==7170
replace ind=7181 if ind==7180

replace ind=8191 if ind==8190 & u1<=0.98
replace ind=8192 if ind==8190 & u1>0.98

replace ind=8561 if ind==8560 & u1<=0.21
replace ind=8562 if ind==8560 & u1>0.21 & u1<=0.39
replace ind=8563 if ind==8560 & u1>0.39 & u1<=0.59
replace ind=8564 if ind==8560 & u1>0.59 

replace ind=8891 if ind==8880


* in IND paper we then pool inds that go to same naics.  NOT USED HERE (38 cases)



***STEP2 fit models

*sum [w=pweight]
*tab cz [w=pweight]

*model1: basic mincer

areg emp female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year [aw=pweight], absorb(cz)
predict cz_emp_m1, d
predict sk_emp_m1, xb

areg hours female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year [aw=pweight], absorb(cz)
predict cz_hours_m1, d
predict sk_hours_m1, xb


*model2: main model but no industry

areg emp age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year [aw=pweight], absorb(cz)
predict cz_emp_m2, d
predict sk_emp_m2, xb

areg hours age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year [aw=pweight], absorb(cz)
predict cz_hours_m2, d
predict sk_hours_m2, xb




**** now just for men
*model1: basic mincer

areg emp female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year if female==0 [aw=pweight], absorb(cz)
predict cz_emp_m_m1, d
predict sk_emp_m_m1, xb
replace cz_emp_m_m1=. if female==1 
replace sk_emp_m_m1=. if female==1 

areg hours female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year if female==0 [aw=pweight], absorb(cz)
predict cz_hours_m_m1, d
predict sk_hours_m_m1, xb
replace cz_hours_m_m1=. if female==1 
replace sk_hours_m_m1=. if female==1 


*model2: main model but no industry

areg emp age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year if female==0 [aw=pweight], absorb(cz)
predict cz_emp_m_m2, d
predict sk_emp_m_m2, xb
replace cz_emp_m_m2=. if female==1 
replace sk_emp_m_m2=. if female==1 

areg hours age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year if female==0 [aw=pweight], absorb(cz)
predict cz_hours_m_m2, d
predict sk_hours_m_m2, xb
replace cz_hours_m_m2=. if female==1 
replace sk_hours_m_m2=. if female==1 




**** now just for women

*model1: basic mincer

areg emp female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year if female==1 [aw=pweight], absorb(cz)
predict cz_emp_f_m1, d
predict sk_emp_f_m1, xb
replace cz_emp_f_m1=. if female==0
replace sk_emp_f_m1=. if female==0 

areg hours female educ f_educ exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_bnh f_anh f_hispanic  ///
i.year if female==1 [aw=pweight], absorb(cz)
predict cz_hours_f_m1, d
predict sk_hours_f_m1, xb
replace cz_hours_f_m1=. if female==0
replace sk_hours_f_m1=. if female==0 


*model2: main model but no industry

areg emp age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year if female==1 [aw=pweight], absorb(cz)
predict cz_emp_f_m2, d
predict sk_emp_f_m2, xb
replace cz_emp_f_m2=. if female==0
replace sk_emp_f_m2=. if female==0 

areg hours age female f_age exp exp2 exp3 exp4 f_exp f_exp2 f_exp3 f_exp4 wnh bnh anh hispanic f_wnh f_bnh f_anh f_hispanic imm useducated i.educ ///
i.educ#female i.educ#imm i.educ#useducated imm_LatAm imm_Asia imm_EurNAOceania ysa imm_LatAm_ysa imm_Asia_ysa imm_EurNAOceania_ysa i.fod i.fod#female i.year if female==1 [aw=pweight], absorb(cz)
predict cz_hours_f_m2, d
predict sk_hours_f_m2, xb
replace cz_hours_f_m2=. if female==0
replace sk_hours_f_m2=. if female==0 




gen emp_m=emp
replace emp_m=. if female==1
gen hours_m=hours
replace hours_m=. if female==1

gen emp_f=emp
replace emp_f=. if female==0
gen hours_f=hours
replace hours_f=. if female==0

sum emp emp_m emp_f hours hours_m hours_f [w=pweight]
corr emp sk_emp_m1 sk_emp_m2  [w=pweight]
corr hours sk_hours_m1 sk_hours_m2 [w=pweight]

corr emp_m sk_emp_m_m1 sk_emp_m_m2  if female==0 [w=pweight]
corr hours_m sk_hours_m_m1 sk_hours_m_m2  if female==0 [w=pweight]

corr emp_f sk_emp_f_m1 sk_emp_f_m2  if female==1 [w=pweight]
corr hours_f sk_hours_f_m1 sk_hours_f_m2  if  female==1 [w=pweight]



**STEP3 collapse 

gen c=1
gen iw=1/pweight

collapse (mean) emp hours emp_m emp_f hours_m hours_f  ///
 cz_emp_m1   cz_emp_m2    cz_hours_m1   cz_hours_m2  ///
 cz_emp_m_m1 cz_emp_m_m2  cz_hours_m_m1 cz_hours_m_m2     ///
 cz_emp_f_m1 cz_emp_f_m2  cz_hours_f_m1 cz_hours_f_m2     ///
 sk_emp_m1   sk_emp_m2    sk_hours_m1   sk_hours_m2             ///
 sk_emp_m_m1 sk_emp_m_m2  sk_hours_m_m1 sk_hours_m_m2      ///
 sk_emp_f_m1 sk_emp_f_m2  sk_hours_f_m1 sk_hours_f_m2     ///
 (sum) count=iw wcount=c [pw=pweight], by(cz)

save ${scratch}/hourseffects, replace

sum
sum [w=wcount]
log close

