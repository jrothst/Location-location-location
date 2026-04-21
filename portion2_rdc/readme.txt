README FOR RDC ANALYSES

This component of the replication package conducts our analysis of confidential Census
Bureau Data, inside the Census RDC secure system. It is conducted after the analysis of 
Public ACS data, and before the "postdisclosure" analyses that create the paper's displays
from the disclosed Census results.

Input files
-----------

Public files: 
This component of the analysis uses two data files that are produced by the first portion 
of our package. These files are called czranking6_alt-wage.dta and czeffects.dta, and are 
created by the "makecensusfiles.do" program in step 6 of that portion of the analysis. 
Those files are then brought into the RDC system and saved in the project's home directory. 
Also placed in that directory is a data file, "cz_cty_czone.dta", that crosswalks counties 
to commuting zones. This file was obtained from David Dorn's website, 
http://ddorn.net/data/cw_cty_czone.zip, on September 10, 2023. It is included in this 
replication archive.

Confidential files: 
This component of the analysis also requires a number of files that are available only in 
the RDC. The specific files needed are:

   - phf_interleave_b.sas7bdat
   - icf_us.sas7bdat
   - ecf_interleave_seinunit_t13.sas7bdat
   - vpers2001_1yr.sas7bdat
   - vpers2002_1yr.sas7bdat
   - vpers2003_1yr.sas7bdat
   - vpers2004_1yr.sas7bdat
   - vpers2005_1yr.sas7bdat
   - vpers2006_1yr.sas7bdat
   - vpers2007_1yr.sas7bdat
   - vpers2008_1yr.sas7bdat
   - vpers2009_1yr.sas7bdat
   - vpers2010_1yr.sas7bdat
   - vpers2011_1yr.sas7bdat
   - vpers2012_1yr.sas7bdat
   - vpers2013_1yr.sas7bdat
   - vpers2014_1yr.sas7bdat
   - vpers2015_1yr.sas7bdat
   - acs2016_vpers_1yr.sas7bdat
   - crosswalk_acs2001.sas7bdat
   - crosswalk_acs2002.sas7bdat
   - crosswalk_acs2003.sas7bdat
   - crosswalk_acs2004.sas7bdat
   - crosswalk_acs2005.sas7bdat
   - crosswalk_acs2006.sas7bdat
   - crosswalk_acs2007.sas7bdat
   - crosswalk_acs2008.sas7bdat
   - crosswalk_acs2009.sas7bdat
   - crosswalk_acs2010.sas7bdat
   - crosswalk_acs2011.sas7bdat
   - crosswalk_acs2012.sas7bdat
   - crosswalk_acs2013.sas7bdat
   - crosswalk_acs2014.sas7bdat
   - crosswalk_acs2015.sas7bdat
   - crosswalk_acs2016.sas7bdat
   - crosswalk_acs2017.sas7bdat

Programs
--------
There are two utility programs that are used to set directory locations and are called by 
many other programs:
- mig5_paths.sas
- mig5_paths.do
These programs are discussed in detail below.

The project is structured with a single master program that calls all others in the 
necessary sequence. We list the programs in the order called below, indenting programs to 
indicate nesting. The above utility programs are called repeatedly, but are not listed 
repeatedly below.

master_rdc.do - Runs the entire sequence
  mig5_clean1.sas                        - Initial cleaning of input data files.
  mig5_clean2.do                         - Further cleaning
  runakm_2step_rep.do                    - Manages estimation of the main AKM model
    firmAKM_spelldata_callable.m         - Prepares data in Matlab for AKM estimation
      akm_pcg.m                          - Estimates the AKM model
  M10_AKM_10pctB_czind.m                 - Estimates person and CZ-industry FE model.
  M10_AKM_10pctB_cz.m                    - Estimates person and CZ FE model
  dynamic_young/young_comparemodels_top10.do - Manages estimation of dynamic models with 
                                               experience in top-10 CZs
    dynamic_young/firmakm_callable.m     - Prepares data in Matlab and manages two-step 
                                           estimation
    dynamic_young/akm_pcg.m              - Estimates the AKM model.
  dynamic_young/young_comparemodels_top25.do - Estimates dynamic models with experience in
                                               top-25 CZs
    dynamic_young/firmakm_callable.m     - Prepares data in Matlab and manages two-step
                                           estimation
    dynamic_young/akm_pcg.m              - Estimates the AKM model.
  6_disc7-8_rep.do                       - Prepares most disclosed results
  mig5_tabsdisclosure7.do                - Prepares additional disclosed results
  mig5_tabsdisclosure9.do                - Prepares final disclosed results

Directories
-----------
To replicate the work, users will need to obtain access to the RDC system and the above 
files. They should establish a main project home directory that contains all of the above 
programs (with some in a "dynamic_young" subdirectory. They should also put in that main 
project directory the public data files listed above, and the following non-public data 
files (from the list above):
   - phf_interleave_b.sas7bdat
   - ecf_interleave_seinunit_t13.sas7bdat
Other non-public data can be left in the directories where it is provided. 

Macros in the mig5_paths.sas program should be adjusted to point to these directories. 
Similarly, the global macro "lehd2018" in mig5_paths.do should also be adjusted to point 
to the LEHD data directory (the same one pointed to as "ppath" in the SAS program).

The "YIDATA" path in the two paths programs should be adjusted to point to the main project 
home directory.

Next, the user should create empty directories, either within the project home directory 
or elsewhere, to hold intermediate files, and adjust the following macros (all in 
"mig5_paths.do") to point to them:
- logs
- datadir
- tempdir
- data2step
- data
- tempdata
- output
- dynamic_tempdir
- doutput
These should each be distinct directories.

Last, three programs have directory locations hard-coded in. The "master_rdc.do" program 
has a global macro, "homedir", which should point to the main project home directory. The 
two Matlab programs "M10_AKM_10pctB_cz.m" and "M10_AKM_10pctB_czind.m", need to be edited 
to point to the correct locations for the "data" and "yidata" macros, as well as to the 
location of the Matlab BGL package.

Mapping to disclosure output tables
-----------------------------------

disclosure 7 - 23 tabs. Created by:
   - mig5_tabsdisclosure7.do (7 14 15 16 17 18 19 20 22 23)
   - 6_disc7-8_rep.do (rest)
disclosure 8 - 2 tabs. Created by:
   - 6_disc7-8_rep.do (see end of program)
disclosure 9 - 5 tabs. Created by:
   - mig5_tabsdisclosure9.do
Mapping of specific line numbers to table output is in main replication archive readme.


