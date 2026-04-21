*read simple data sets created by myyyy.do 
* creates czchars_allp.dta data (characteristics of entire adult pop)
* creates wcount_allp = weighted count of adults in each CZ
*  does NOT create count of people with wage data



cap log close
log using cz_chars.log, replace

set seed 921109


forvalues y=2010/2011 {

use ${scratch}/simple`y'.dta, clear

keep age female educ twage hrswkly weeksly imm wnh bnh anh hispanic pweight ncz cz1-cz10 af1-af10

drop if age>62
drop if age<educ+7

gen logwage=log(twage)
gen emp=(weeksly>0 & weeksly<=52)
gen college=(educ>=16)



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
gen s10=af1+af2+af3+af4+af5+af6+af7+af8+af9+af10

gen cz=cz1 if ncz==1
replace cz=cz1*(rv<=s1)+cz2*(rv>s1) if ncz==2
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2) if ncz==3
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3) if ncz==4
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4) if ncz==5
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5) if ncz==6
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6) if ncz==7
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7) if ncz==8
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8) if ncz==9
replace cz=cz1*(rv<=s1)+cz2*(rv>s1)*(rv<=s2)+cz3*(rv>s2)*(rv<=s3)+cz4*(rv>s3)*(rv<=s4)+cz5*(rv>s4)*(rv<=s5)+cz6*(rv>s5)*(rv<=s6)+cz7*(rv>s6)*(rv<=s7)+cz8*(rv>s7)*(rv<=s8)+cz9*(rv>s8)*(rv<=s9)+cz10*(rv>s9) if ncz==10
sum cz

tempfile temp`y'
save `temp`y'', replace

sum female age educ college twage imm wnh bnh anh hispanic imm   
sum female age educ college twage imm wnh bnh anh hispanic imm [aw=pweight] 
clear


 }



forvalues y=2012/2018 {

use ${scratch}/simple`y'.dta

keep age female educ twage hrswkly weeksly imm wnh bnh anh hispanic pweight ncz cz1-cz9 af1-af9

drop if age>62
drop if age<educ+7

gen logwage=log(twage)
gen emp=(weeksly>0 & weeksly<=52)
gen college=(educ>=16)



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
tempfile temp`y'
save `temp`y'', replace

sum female age educ college twage imm wnh bnh anh hispanic imm   
sum female age educ college twage imm wnh bnh anh hispanic imm [aw=pweight] 


 }


clear


use `temp2010'
append using `temp2011' `temp2012' `temp2013' `temp2014' `temp2015' `temp2016' `temp2017' `temp2018'




gen alaska=(cz>=34101)*(cz<=34115)

tab alaska 
replace cz=99999 if alaska==1

 
sum emp logwage female age educ college imm wnh bnh anh hispanic 
sum emp logwage female age educ college imm wnh bnh anh hispanic [aw=pweight]

*unweighted tabs to check basic patterns
tab female emp, row col
tab educ emp, row col
tab imm emp, row col

gen c=1

gen ipw=1/pweight

collapse (mean) logwage emp female educ college imm wnh bnh anh hispanic (sum) count_allp=ipw wcount_allp=c [pw=pweight], by(cz)

rename female female_allp
rename educ educ_allp
rename college college_allp
rename imm imm_allp
rename wnh wnh_allp
rename bnh bnh_allp
rename anh anh_allp
rename hispanic hispanic_allp


sum
sum [w=wcount_allp]

save ${scratch}/czchars_allp, replace
log close
