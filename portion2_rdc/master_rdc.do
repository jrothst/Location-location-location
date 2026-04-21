
  global homedir "[HOMEDIR]"
  // Programs that define paths used by other code: mig5_paths.do, mig5_paths.sas
  // NOTE: Paths are also hard-coded in M10_AKM_10pctB_cz.m and M10_AKM_10pctB_czind.m
  
/*  
Uses Stata packages:
estout:      <ssc install estout>
ftools:      <ssc install ftools>
egenmore:    <ssc install egenmore>
*/ 
which estout
which ftools
which _grownvals // egenmore is not itself an ado file, but this is one of the components
  
  ! sas mig5_clean1.sas
  cd "${homedir}"
  do mig5_clean2.do
  cd "${homedir}"
  do runakm_2step_rep.do
  cd "${homedir}"
  ! matlab -nodisplay -nosplash -batch "M10_AKM_10pctB_czind.m"
  cd "${homedir}"
  ! matlab -nodisplay -nosplash -batch "M10_AKM_10pctB_cz.m"
  cd "${homedir}"
  do dynamic_young/young_comparemodels_top10.do
  cd "${homedir}"
  do dynamic_young/young_comparemodels_top25.do

  cd "${homedir}"
  do 6_disc7-8_rep.do
  cd "${homedir}"
  do mig5_tabsdisclosure7.do
  cd "${homedir}"
  do mig5_tabsdisclosure9.do
