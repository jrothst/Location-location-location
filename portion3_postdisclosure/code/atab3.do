/*
Program to construct best linear predictor of LEHD-based CZ earnings premiums
based on ACS data. Coefficients are constructed based on released results,
and only approximate the coefficients that would be obtained with internal data.
Internal investigation indicates that the coefficients aren't so close, but that 
the index is very highly correlated with the index that woudl be obtained internally.

Jesse Rothstein, 8/3/23
*/

use "${acsraw}/cznames.dta", clear
rename place_name czname
tempfile cznames
save `cznames'

use "${acsoutput}/czeffects_earns", clear
gen frachighed=wcount_13p/wcount
keep cz frachighed

merge 1:1 cz using "${acsoutput}/czeffects"
gen lnsize=ln(wcount)

corr cz_effects_m1 lnsize frachighed [aw=wcount], cov
matrix XX=r(C)

local dpsilehd_psiacs=1.331 // T6, col. 5 - based on disclosure 9, tab 1, cell c6
local sdpsilehd=0.079 // T6, col. 1 - based on disclosure 7, tab 2, cells C7 and C9 
local dpsilehd_lnsize=0.034 // T3, col. 2 - based on disclosure 7, tab 6, cell D10
local dpsilehd_educ=0.664 // T3, col. 3 - based on disclosure 7, tab 6, cell D13
matrix bivariate=(`dpsilehd_psiacs'*((`sdpsilehd'^2)/el(XX,1,1)), `dpsilehd_lnsize', `dpsilehd_educ')
matrix XXdiag=diag(vecdiag(XX))
matrix Xy=XXdiag*(bivariate')
matrix coeffs=inv(XX)*Xy
matrix list coeffs
local b1=el(coeffs,1,1)
local b2=el(coeffs,2,1)
local b3=el(coeffs,3,1)
gen index=(`b1')*cz_effects_m1 + (`b2')*lnsize + (`b3')*frachighed
*gen index=0.7316644*cz_effects_m1 - 0.01088*lnsize - 0.031929*frachighed
su index [aw=wcount]
replace index=index-r(mean)

keep cz index cz_effects_m1 frachighed lnsize wcount
rename index psi_acspredict
su [aw=wcount]

merge 1:1 cz using `cznames', assert(3) nogen

sort cz
gsort -lnsize
order cz czname psi_acspredict cz_effects_m1 frachighed lnsize wcount
save "${results}/atab3_full.dta", replace
export excel using "${results}/atab3_full.xlsx", replace firstrow(variables) keepcellfmt

