*extracthousing.do

cap log close extracthousing
log using extracthousing.log, replace text 

! \rm ${tmp}/psam_hus?.sas7bdat
! \rm ${tmp}/ACS2014_2018_PUMS_README.pdf
! unzip  ${raw}/housing/unix_hus.zip -d ${tmp}

! sas household.sas

! \rm ${scratch}/household.dta
! st ${tmp}/household.sas7bdat ${scratch}/household.dta

log close
