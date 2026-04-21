README FOR ACS ANALYSES

This component of the replication package conducts our analysis of public ACS data. It
is executed first, before the LEHD analysis conducted inside the Census Bureau RDC system
(which uses some results generated here).

These analyses are divided into five steps:
1. Construct PUMA-to-CZ crosswalk files.
2. Extract individual-level one-year ACS files
3. Construct CZ-level files from ACS data
4. Merge the CZ-level files and conduct analyses in text
5. Extract household-level information from 5-year ACS file and analyze housing prices

A master program, "main_acs.do", runs all steps in the appropriate sequence. It assumes the
following directory structure. Asterisks indicate folders included in this archive (with
any needed subfolders). Folders without asterisks may need to be created.
<project root>/
  acs/
    code/ *
    intermediate/
    origdata/ *
    results/
    tmp/
    
The steps are described in more detail below.    

****** STEP 1 **************************************************************************** 

Process PUMA-CZ files and create data sets to merge to ACS

1.  input files were downloaded from David Dorn's website

cw_pum2000_czone (created Oct 15, 2012 by Dorn)
  - has 3 vars: puma2000  czone   afactor = share of puma in czone
  - uses 2000 puma codes for ACS in 2010 and 2011

cw_pum2000_czone (created Jan 22, 2017 by Dorn)
  - has 3 vars: puma2010  czone   afactor = share of puma in czone
  - uses 2010 puma codes for ACS in 2012+

2. Processing progams:

a) puma2000_prep.do reads cw_pum2000_czone and creates a file with one record per puma
   (pumas are identified by state + puma) 
   has 2071 records and up to 10 CZ's (czX) that the puma is allocated to, with shares afX
   ncz is number of CZ's for the puma (range 1-10, mean = 1.340415)


a) puma2010_prep.do reads cw_pum2010_czone and creates a file with one record per puma
   (pumas are identified by state + puma) 
   has 2351 records and up to 9 CZ's (czX) that the puma is allocated to, with shares afX
   ncz is number of CZ's for the puma (range 1-9, mean = 1.918758)

****** STEP 2 **************************************************************************** 
Creation of ACS person-level extract files:
    (1) workers; 
    (2) all adults (simple);   
    (3) all adults (full) 

Substep 1. Create working files of micro records (one per year). Managed by extractacs.do
A) Micro Records
For each year 2010-2018:
a) combine public ACS files for each year using unix utility CAT (note that csv files from 
   census are in 2 files “a” and “b”)
b) convert to SAS using STAT TRANSFER
c) read with SAS program extractYY.sas, keep ages 18-66, drop extra variables, save as SAS 
   format
d) convert to STATA using STAT TRANSFER

Example for 2010:
    a) unzip csv_pus_2010.zip
	a) cat ss10pusa.csv ss10pusb.csv > acs2010.csv
	b) st acs2010.csv acs2010.sas7bdat
	c) run extract10.sas  
               --> extract2010.sas7bdat
	d) st extract2010.sas7bdat extract2010.dta

CHECKSUM: 
sample sizes for extractYYYY.sas7bdat 
     2010 =  1,941,443
     2018 =  2,011,848


Substep 2.  Create working extract file of obs with wages, and separate file of all adult
            obs (for hours models)

 run readacs.do program (in STATA)
	- keeps key variables
	- renames e.g.  indp--> ind
	- generates several key variables like rgroup, imm, educ, weeksly, wage
	- merges acs with pumaZ_cz   (Z = 2000 for 2010 and 2011 ACS, Z=2010 for 2012+)
	         - this has up to 10 cz’s  per PUMA (and shares of puma in each cz):  cz(j) 
	           and af(j)
    - creates simpleyyyy.dta  with 1 record for each person

 run rank_revised_extravars.do
	- reads simpleyyyy.dta
                   - drops people with no wage 
	- randomly assigns cz based on af(j) 
	- creates naics var with 1-19 codes
	- recodes Field of degree
	- creates key vars for regression models
	
	====> work2010-2018_extravars.dta

 run  hours1.do
	- reads simpleyyyy.dta
                   - randomly assigns cz based on af(j) 
	- recodes Field of degree
	- creates key vars for regression models

	====> hours_alldata.dta


****** STEP 3 **************************************************************************** 

Collapse Programs -- create CZ-level characteristics files

1)  Characteristics of all workers

cz_chars.do 
	- reads simpleyyyy.dta
	- randomly assigns cz based on af(j) 
	- creates mean characteristics of adult pop for each CZ
	-> czchars_allp.dta

2) CZ effects and mean Xb for different models

phi_cz_acs.do
    - reads    working2010-2018_extravars.dta
	- clean up industry codes 
	- fit wage model get CZ effects and xb, with and without extra controls (3 models)
	- collapse to CZ and output.  Also creates: 
                        logwage = mean log wage
                        educ = mean education of workers; female = female share of workers
                        wcount = weighted count of #workers by CZ
    -> czeffects.dta
                      
3) CZ effects in wages by education (exactly 12 and exactly 16 years)

phi_cz_byed.do
	- reads working2010-2018_extravars.dta
	-same steps as phi_cz_acs  (2 models)
    - creates:  logwagehs logwagecoll cz_effects_hs_m# cz_effects_coll_m#   for # = 2,3 
    -> czeffects_byed.dta

4) CZ effects in earnings (and for wages)

phi_cz_earns.do
	- reads working2010-2018_extravars.dta
	- same steps as phi_cz_acs  (model #2 and model #3) for all, educ=12, educ=16,  educ>=13
    -> czeffects_earns.dta

5) CZ effects in employment and mean hours (with 0 hours for nonworkers)

phi_cz_hours.do 
	- reads  hours_alldata.dta  (created by hours1.do)
	same steps as phi_cz_acs  (2 models; emp and hours, both genders and by gender)
    -> hourseffects.dta

6) CZ effects in wages, alternative model 
phi_cz_acs.do
    - reads    working2010-2018_extravars.dta
	- fit wage models to get CZ effects and xb (2 models)
    -> phi_cz_alt-wage.dta

****** STEP 4 **************************************************************************** 

Program.do reads the collapsed CZ files from step 3 (5 files) and merges them.  It also adds 
CZ place names from the file czname.dta included in the archive (and which contains only
CZ numbers and names).

The program does some renaming then creates results mentioned in text (section II) and 
Appendix A, then fits slopes for Appendix Figures 2-3-4 (mentioned in text, section II), 
then fits models in Appendix Table 1 and Appendix Table 2.

Final lines of program keep a small set of variables that are output to a file called 
“acs_vars.dta” for use in plotting Appendix figures 2-4 and for use in LEHD.

Additional programs create appendix figure 2-4 and the external component of Table 6.

****** STEP 5 **************************************************************************** 

1) data are in unix_hus.zip  downloaded from Census Bureau web site
    these are SAS data sets (4) that are the household records from the 2018 5-year ACS file
    N=6,803,985

2) run SAS program household.sas   This creates a working file “household.sas7bdat”

3) covert to STATA using Stat Transfer:   st household.sas7bdat household.dta

4) run STATA program hprices.do   This creates the estimates in Appendix Table 7

NOTE: program reads acs_vars.dta, created in STEP 4 of the person-level analysis (which 
has weighted count variables to construct logsize and to use as a weight)

****** STEP 6 **************************************************************************** 

Final preparation of files to pass up to Census RDC for use in the internal component of
the project.


