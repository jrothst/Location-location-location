cap log close
log using makecensusfiles.log, replace

clear


use ${scratch}/czeffects, clear
keep cz logwage cz_effects_m1 cz_effects_m2 cz_effects_m3
sort cz
save ${tocensus}/czeffects, replace

use "${scratch}/phi_cz_alt-wage.dta" , clear
keep cz mlogwage4 wcount
save ${tocensus}/czranking6_alt-wage.dta, replace

* Code below this is useful for ensuring we reproduce what was sent to Census in 2021.
* See commented out code in step 1 and 2 to accomplish this.
* Without that code, we will not exactly match it, due to different random number seed,
* but results will be very similar.
cap program drop verify
program define verify
  args file
  
  di "Verifying `file'"
  use ${tocensus}/`file', clear
  d, varlist
  local vlist "`r(varlist)'"
  rename * replic_*
  rename replic_cz cz
  sort cz
  tempfile replic
  save `replic'

  use ${tocensus}/2021/`file'
  sort cz
  rename * orig_*
  rename orig_cz cz
  merge 1:1 cz using `replic', nogen assert(3)
  
  foreach v of local vlist {
    if "`v'"~="cz" {
      qui count if abs(replic_`v'-orig_`v')>1e-9 | (missing(replic_`v')~=missing(orig_`v'))
      if r(N)>0 {
        qui corr replic_`v' orig_`v'
        di "Variable `v' does not match. Correlation = " r(rho)
      }
      else {
        di "Variable `v' verified"
      }
    }
  }
  di "Finished verifying `file'"
end

*verify czeffects
*verify czranking6_alt-wage
  
log close
