Process PUMA-CZ files and create data sets to merge to ACS


1.  Input files were downloaded from David Dorn's website,
http://ddorn.net/data.htm#Local%20Labor%20Market%20Geography

Item E5: cw_pum2000_czone (created Oct 15, 2012 by Dorn)
  - has 3 vars: puma2000  czone   afactor = share of puma in czone
  - uses 2000 puma codes for ACS in 2010 and 2011

Item E6: cw_pum2000_czone (created Jan 22, 2017 by Dorn)
  - has 3 vars: puma2010  czone   afactor = share of puma in czone
  - uses 2010 puma codes for ACS in 2012+

Item E7: cw_cty_czone (created Aug 30, 2016 by Dorn)

Reference for all of these files is:
David Autor and David Dorn. "The Growth of Low Skill Service Jobs and the Polarization of 
the U.S. Labor Market." American Economic Review, 103(5), 1553-1597, 2013.


2. Processing progams:

a) puma2000_prep.do read cw_pum2000_czone and creates a file with one record per puma
   (pumas are identified by state + puma) 
   has 2071 records and up to 10 CZ's (czX) that the puma is allocated to, with shares afX
   ncz is number of CZ's for the puma (range 1-10, mean = 1.340415)


b) puma2010_prep.do read cw_pum2010_czone and creates a file with one record per puma
   (pumas are identified by state + puma) 
   has 2351 records and up to 9 CZ's (czX) that the puma is allocated to, with shares afX
   ncz is number of CZ's for the puma (range 1-9, mean = 1.918758)

The county-commuting zone crosswalk is used in the "RDC" portion of the code. See readme 
for that portion for information about where it needs to be placed.
