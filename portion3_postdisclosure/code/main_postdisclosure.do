*Program to run all analyses involving disclosed LEHD results. Runs after external
*ACS analyses and internal LEHD analyses


cap log close postlog
log using main_postdisclosure.log, replace text name(postlog)
clear *

creturn list
global mainhome "~/replication/L3"
global home "${mainhome}/portion3_postdisclosure" // change to reflect local settings
global code "${home}/code"
global results "${home}/results"
global disclosed "${home}/disclosed"
global scratch "${home}/intermediate" // For intermediate files that we might want 

global acsraw "${mainhome}/portion1_acs/origdata"
global acsoutput "${mainhome}/portion1_acs/intermediate" // data files created by phase 1 of the project

global disclosure7 "${disclosed}/Yi_1_tabs_T13T26_7_L3.xlsx"
global disclosure8 "${disclosed}/Yi_1_tabs_T13T26_8_L3.xlsx"
global disclosure9 "${disclosed}/Yi_1_tabs_T13T26_9_L3.xlsx"

/*  
Uses Stata packages:
spmap:       <ssc install spmap>
cleanplots:  <net install cleanplots, from(http://fmwww.bc.edu/RePEc/bocode/c)>
maptile.ado: <net install maptile, from(http://fmwww.bc.edu/RePEc/bocode/m)>
CZ90 geography, installed with: <maptile_install using "http://files.michaelstepner.com/geo_cz1990.zip">
outreg2.ado: <net install outreg2, from(http://fmwww.bc.edu/RePEc/bocode/o)>
*/ 
which spmap
which maptile
which outreg2


do fig1.do
do fig2.do
do fig3
do fig4

do afig6
do afig7
do afig8
do afig9
do afig10

do atab3

log close postlog
