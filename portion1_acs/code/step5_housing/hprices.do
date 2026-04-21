*read 2014-18 household acs extract, merge on cz information
*acs h records created by household.sas --> st to state

*also uses acs_vars file created in step4 of person analysis


cap log close
log using hprices.log, replace

use ${scratch}/household.dta, clear


destring puma, replace


merge m:1 state puma using ${scratch}/puma2010_cz
tab _merge
list state puma if _merge==2
keep if _merge==3
drop _merge

tab ncz 
sum cz1-cz9 af1-af9 afsum


*code to assign one CZ at random from up to 9 possible (from rank_revised.do)

set seed 883141
gen rv=runiform()
gen s1=af1
gen s2=af1+af2
gen s3=af1+af2+af3 
gen s4=af1+af2+af3+af4 
gen s5=af1+af2+af3+af4+af5 
gen s6=af1+af2+af3+af4+af5+af6
gen s7=af1+af2+af3+af4+af5+af6+af7
gen s8=af1+af2+af3+af4+af5+af6+af7+af8
gen s9=af1+af2+af3+af4+af5+af6+af7+af8+af9

sum s1 if ncz==1
sum s1 s2 if ncz==2
sum s1-s3 if ncz==3
sum s1-s4 if ncz==4
sum s1-s5 if ncz==5
sum s1-s6 if ncz==6
sum s1-s7 if ncz==7
sum s1-s8 if ncz==8
sum s1-s9 if ncz==9

sum rv , detail

gen cz=cz1 if ncz==1
replace cz=cz1*(rv<=s1)+cz2*(rv>s1) if ncz==2
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2) if ncz==3
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3) if ncz==4
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4) if ncz==5
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5) if ncz==6
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6) if ncz==7
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7) if ncz==8
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8) if ncz==9

sum cz

drop s1-s9 cz1-cz9 af1-af9

destring adjinc, replace

replace adjinc=adjinc/1000000
sum adjinc if year==2014
sum adjinc if year==2018

gen rvalue=adjinc*propertyvalue
replace rvalue=4500 if rvalue<4500 & rvalue>1000
replace rvalue=. if rvalue<=1000
gen logvalue=log(rvalue)


gen rrent=adjinc*rent
replace rrent=100 if rrent<100 
gen logrent=log(rrent)

gen rtax=adjinc*taxes
gen rhinc=adjinc*hinc

gen logtax=log(rtax)
gen loghinc=log(rhinc)


gen rentorown=0
replace rentorown=1 if posrent==1
replace rentorown=1 if posvalue==1

gen renter=(posrent==1)
replace renter=. if rentorown==0


sum posrent posvalue rentorown renter

gen single_det=(numunits==2)
gen single_att=(numunits==3)
gen apt1=(numunits==4)
gen apt2=(numunits==5)
gen apt3=(numunits==6)
gen apt4=(numunits==7)
gen apt5=(numunits==8)
gen apt6=(numunits==9)
gen mobile=(numunits==1)

drop rv
gen rv=(numunits==10)

gen bedroom2=(num_bedrooms==2)
gen bedroom3=(num_bedrooms==3)
gen bedroom4=(num_bedrooms==4)
gen bedroom5=(num_bedrooms>=5)
replace bedroom5=. if num_bedrooms==.


*numunits = 1 for mobile 2=sf det 3=sf att 4-9=apt complex 10=rv
tab numunits renter



sum logrent logvalue single_det single_att apt1-apt6 mobile bedroom* num_rooms 
sum logrent logvalue single_det single_att apt1-apt6 mobile bedroom* num_rooms if rentorown==1
sum logrent logvalue single_det single_att apt1-apt6 mobile bedroom* num_rooms if renter==1
sum logrent logvalue single_det single_att apt1-apt6 mobile bedroom* num_rooms if renter==0

destring ybl, replace

tab ybl renter, row col

gen logrooms=log(num_rooms)

gen has_mort=(ten=="1")

*rents

sum logrent, detail
areg logrent single_att mobile apt1-apt5 bedroom* *inrent logrooms i.ybl [aw=wgtp], absorb(cz)
predict cz_rent, d


*home values

sum logvalue, detail
areg logvalue single_att mobile apt1-apt5 bedroom* logrooms i.ybl has_mort [aw=wgtp], absorb(cz)
predict cz_value, d

 
collapse (mean) logrent logvalue cz_rent cz_value [pw=wgtp], by(cz)


merge 1:1 cz using ${scratch}/acs_vars
*merge 1:1 cz using ${scratch}/hourseffects, nogen keepusing(wcount)
*rename wcount wcount_allp


drop if cz==99999  /*alaska*/
drop if cz==28601  /*oberlin KS*/
drop if cz==30906  /*Memphis TX*/

gsort -wcount_allp

gen top50=_n<=50
gen top200=_n<=200

tab top200 top50
tab top200 top50 [w=wcount], row col

gen logsize=ln(wcount_allp)

*weighted by wtd cnt of adult pop



*column 1
reg logvalue logsize [aw=wcount_allp],robust
est sto at7_c1_r1
reg cz_value logsize [aw=wcount_allp],robust
est sto at7_c1_r2
reg logrent logsize [aw=wcount_allp],robust
est sto at7_c1_r3
reg cz_rent logsize [aw=wcount_allp],robust
est sto at7_c1_r4


*column 2:  top 50 CZ's only
reg logvalue logsize if top50==1 [aw=wcount_allp],robust
est sto at7_c2_r1
reg cz_value logsize if top50==1 [aw=wcount_allp],robust
est sto at7_c2_r2
reg logrent logsize  if top50==1 [aw=wcount_allp],robust
est sto at7_c2_r3
reg cz_rent logsize  if top50==1 [aw=wcount_allp],robust
est sto at7_c2_r4

outreg2 [at7_c?_r1 at7_c?_r2 at7_c?_r3 at7_c?_r4] using "${results}/apptab7.txt",  dec(5) text noaster noparen depvar replace 


log close

