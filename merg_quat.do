clear all 
set more off
local naics=448
global inp="C:/Users/kk/Dropbox/BLS/QWECdata/`naics'"
global inp2="C:/Users/kk/Dropbox/BLS/QWECdata/population"
global mid1="C:/Users/kk/Dropbox/BLS/Data/ny_final/out"
global mid="C:/Users/kk/Dropbox/BLS/QWECdata/regressions_county"
global out="C:/Users/kk/Dropbox/BLS/QWECdata/448"
cd $inp

/*
cd $inp2
foreach i in 9 23 25 33 34 36 42 44 50    {
	insheet using state`i'.csv, clear comma
	capture drop county
	gen county=`i'*1000+fips
	drop if missing(county)
	forval j=3/26 {
		replace v`j'=subinstr(v`j',",","",.)
		destring v`j', force replace
		local k=`j'+1987
		rename v`j' pop`k'
	}
	keep county pop1990-pop2013
	reshape long pop, i(county) j(year)
	if `i'==9 {
		save $inp/population, replace
	}
	else {
		append using $inp/population
		sort county year
		save $inp/population, replace
	}
}
*/
/*
clear
cd $inp

/*
forval i=1997/2014 {
! rename *`i'* `i'.csv
}
*/

! dir *.csv /a-d /b >$inp\filelist.txt

file open myfile using "$inp\filelist.txt", read
file read myfile line
local i=1996
import delim using `line'

save $inp/master_data, replace

file read myfile line
while r(eof)==0 {
	local i=`i'+1
	display `i'
	clear
	
	import delim using `line'
	append using $inp/master_data
	save $inp/master_data, replace
	file read myfile line
}
*/
use $inp/master_data, clear
gen county_name = regexs(1) if regexm( area_title , "([a-zA-Z]+)[ ]*(County)")
replace county_name=lower(county_name)

gen disc=1
replace disc=0 if strpos(disclosure_code,"N")
replace disc=-1 if strpos(disclosure_code,"-")
sort area_title
merge n:n area_title using fips_county
drop if _merge==2
gen state=real(substr(area_fips, 1,2))
gen county=real(area_fips)

keep if !missing(county)



keep county county_name state year qtr qtrly_estabs_count total_qtrly_wages ///
taxable_qtrly_wages avg_wkly_wage disc
sort county year qtr
drop if (county==county[_n-1] &  year==year[_n-1] & qtr==qtr[_n-1]) ///
| county==county[_n+1] &  year==year[_n+1] & qtr==qtr[_n+1]

gen quat=ym(year, qtr)

keep if state==9 | state==23 | state==25 | state==33 | state==34 ///
| state==36 | state==42 | state==44 | state==50 | state==17 | ///
state==18 | state==26 | state==39 | state==55 

**Creating treatment vars


sort state county quat
save $mid/tmp, replace

forval i=1997/2012 {
	forval q=1/4 {	
		local j=`q'*3-1 
		if `i'==1997 & `q'==1 {
			
			use $mid1/county_`i'`j', clear
			gen quat=ym(`i',`q')
		}
		else {
			
			append using $mid1/county_`i'`j'
			replace quat=ym(`i',`q') if missing(quat)
		}
	}
}
sort county quat
keep county quat county_rate55 county_rate110 county_rate999
rename county county_name
save $mid/county_ny_quat, replace 




use $mid/tmp, replace

*NY:
keep if state==36
drop if county==36000 | county==36999
replace county_name="newyork" if county_name=="york"
replace county_name="st.lawrence" if county_name=="lawrence"


merge 1:1 county_name quat using $mid/county_ny_quat
drop if _merge!=3
drop _merge

merge 1:1 county quat using $mid/tmp
drop _merge

**Merge with population data
sort county year
merge n:1 county year using $inp/population
drop if _merge==2
/*
gen state_exem=0
gen state_taxdrop=0
gen state_threshold=1

**NY state
replace state_exem=1 if state==36 & mon>=ym(2000,3) & mon<ym(2003,6)
replace state_exem=1 if state==36 & mon>=ym(2006,4) & mon<ym(2010,10)
replace state_exem=1 if state==36 & mon>=ym(2011,4) &  mon<ym(2012,4)
replace state_exem=1 if state==36 & mon>=ym(2012,4)
replace state_taxdrop=4 if state==36 & mon>=ym(2000,3) & mon<ym(2003,6)
replace state_taxdrop=4 if state==36 & ((mon>=ym(2006,4) & mon<ym(2010,10)) | ///
mon>=ym(2011,4))
replace state_threshold=1/(1+log(1+110)) if state==36 & ((mon>=ym(2000,3) ///
& mon<ym(2003,6)) | (mon>=ym(2006,4) & mon<ym(2010,10)) | mon>=ym(2012,4))
replace state_threshold=1/(1+log(1+55)) if state==36 & mon>=ym(2011,4) ///
&  mon<ym(2012,4)

**CT state
replace state_exem=1 if state==9 & mon<ym(2003,4)
/*replace state_taxdrop=6 if state==9 & mon<ym(2011,7)
replace state_threshold=1/(1+log(1+75)) if state==9 & mon<ym(2003,4)
replace state_threshold=1/(1+log(50+1)) if state==9 & mon>=ym(2003,4) ///
& mon<ym(2011,7)
*/
**VT state
replace state_exem=1 if state==50 & mon>=ym(1999,12)
replace state_taxdrop=5 if state==50 & mon>=ym(1999,12) & mon<ym(2003,10)
replace state_taxdrop=6 if state==50 & mon>=ym(2003,10)
replace state_threshold=1/(1+log(1+110)) if state==50 & mon>=ym(1999,12)
replace state_threshold=0 if state==50 & mon>=ym(2007,1)

**MA state
replace state_exem=1 if state==25
replace state_taxdrop=5 if state==25
replace state_taxdrop=6.25 if state==25 & mon>=ym(2009,8)
replace state_threshold=1/(1+log(1+175)) if state==25 & mon>=ym(2009,8) //verify the threshold for the exemptions

**RI state
replace state_exem=1 if state==44
replace state_taxdrop=7 if state==44
replace state_threshold=0 if state==44
replace state_threshold=1/(1+log(1+250)) if state==44 & mon>=ym(2012,10)
*/

drop quat
gen quat=yq(year,qtr)
capture drop rate
gen rate=0
/*
replace rate=4 if state==36
replace rate=0 if state==36 & mon>=ym(2000,3) & mon<ym(2003,6)
replace rate=4.25 if state==36 & mon>=ym(2003,6) & mon<ym(2005,6)
replace rate=0 if state==36 & mon>=ym(2006,4) & mon<ym(2010,10)
*/
replace rate=county_rate110 if state==36

replace rate=0  if state==9
replace rate=0 if state==9  & quat>=yq(2003,2)
replace rate=6.5  if state==9 & quat>yq(2011,2)


replace rate=5  if state==50 
replace rate=0  if state==50 & quat>=yq(2000,1)



/*
gen treat1=0
replace treat1=110/(1+110) if state==36 & mon>=ym(2000,3) & mon<ym(2003,6)
replace treat1=110/(1+110) if state==36 & mon>=ym(2006,4) & mon<ym(2010,10)
replace treat1=55/(1+55) if state==36 & mon>=ym(2011,4) &  mon<ym(2012,4)
replace treat1=110/(1+110) if state==36 & mon>=ym(2012,4)
replace treat1=55/(1+55) if state==36 & mon>=ym(2011,4) &  mon<ym(2012,4)

replace treat1=50/(1+50)  if state==9 & mon>=ym(2003,4) & mon<ym(2011,7)
replace treat1=75/(1+75) if state==9  & mon<ym(2003,4)
replace treat1=250/(1+250) if state==44
replace treat1=1 if state==44  & mon<ym(2012,10)

*/




capture drop samp
gen samp=0
replace samp=1 if state==9 | state==23 | state==25 | state==33 | state==34 ///
| state==36 | state==42 | state==44 | state==50  
//9 23 25 33 44 50 34 36 42 
/*
9 - CT - all counties are big
*/
gen samp_broad=0
replace samp_broad=1 if samp==1 | state==17 | state==18 | state==26 | ///
state==39 | state==55 
//18 17 26 39 55

xtset county quat, monthly
gen time1=quat-yq(1997,1)
forval j=1/6 {
	local k=`j'+1
	capture drop time`k'
	gen time`k'=time`j'*time1
}

foreach i in 9 17 18 23 25 26 33 34 36 39 42 44 50 55  {

	forval j=1/4 {
	capture drop time`j'_st`i'
	gen time`j'_st`i'=time`j'*(state==`i')
	}
}

forval j=1/4 {
	foreach i in 9 17 18 23 25 26 33 34 36 39 42 44  50 55  {
	capture drop quat_st`i'_`j'
		gen quat_st`i'_`j'=(qtr==`j')*(state==`i')
	}
}

//drop if quat>=yq(2014,2)
/*
xtreg emp treat i.mon if samp==1, fe cluster(state)
xtreg emp treat time*st* i.mon  if samp==1, fe cluster(state)
use regres, clear
*/

rename qtrly_estabs_count estab
rename total_qtrly_wages payroll
rename taxable_qtrly_wages tpayroll
rename avg_wkly_wage wage

local vars estab payroll tpayroll  wage
foreach v of var `vars' {
	capture drop l`v'
	replace `v'=. if disc!=1
	gen l`v'=log(`v')
} 
gen lest=log(estab+sqrt(estab*estab+1))



set matsize 1000
set more off


capture drop samp_min
/*
bysort county: egen emp0_all=total(emp==0)



gen miss=missing(emp)
bysort county: egen miss_all=total(miss)
gen samp_min=samp
replace samp_min=0 if miss_all>0
sort county mon
*/
capture drop exclusion
gen exclusion=0
forval i=1/60 {
	replace exclusion=1 if county>=(`i'*1000-10) & county<=`i'*1000
}
drop if exclusion ==1

set matsize 1000
set more off
//xtreg isemp treat1 if samp==1 & !exclusion, fe cluster(state)
//outreg2 treat1 using percent_exc, word replace

//All time controls with state exemption dummy only
gen lpop=log(pop)
set more off

by county: egen min_pop=min(pop)
gen pop_enough=0
replace pop_enough=1 if min_pop>50000


**Summary Statistics

//xtline emp if county==50007 & year>=1997 & mon<=ym(2011,4), xline(478)
clear mata
keep if state==9 | state==23 | state==25 | state==33 | state==34 | state==36 ///
| state==42 | state==44 | state==50
replace payroll=payroll/1000
replace tpayroll=tpayroll/1000

tabstat estab payroll tpayroll wage, s(me sd count) by(state) save
matrix stat=r(Stat1)', r(Stat2)', r(Stat3)', r(Stat4)', r(Stat5)', r(Stat6)', ///
r(Stat7)', r(Stat8)', r(Stat9)'


matrix list stat
*

 table using $out/sum_q, statmat(stat) varlabels substat(2) plain ///
rtitle("Establishments" \ "" \ "Obs." \ "Payroll, thsd \$" \ "" \ "Obs." \ "Taxed Payroll, thsd \$" \ "" \ "Obs." ///
\"Weekly Wages, \$" \""\"Obs.") ///
ctitles( "" "CT" "ME" "MA" "NH" "NJ" "NY" "PA"  "VT" "RI") replace ///
 brackets("" \ "(" ")" \"")  sdec(0 \0 \0 \0 \0 \0 \0 \0 \0\0 \0 \0 \0 \0 \0) tex

replace rate=rate/100

sort county quat
drop if missing(wage) | missing(payroll) | missing(tpayroll) | missing(estab)
quietly by county:  gen dup = cond(_N==1,0,_n)
by county: egen max_obs=max(dup)


**Basic
set more off

foreach var in wage payroll tpayroll estab {
display "`var'"
if strpos("wage","`var'")==1 {
/*
xtreg l`var' rate lpop  i.quat  if samp==1 & !exclusion & _merge==3, ///
fe cluster(state)
outreg2 rate lpop using Table2_`var', tex replace
*/
xtreg l`var'  rate lpop time*st* i.quat  if samp==1 & !exclusion & ///
_merge==3 ,  fe cluster(state)
outreg2 rate lpop using Table2, tex replace
}
else {
/*
xtreg l`var' rate lpop  i.quat  if samp==1 & !exclusion & _merge==3, ///
fe cluster(state)
outreg2 rate lpop using Table2_`var', tex append
*/
xtreg l`var' rate lpop  i.quat  if samp==1 & !exclusion & _merge==3 , ///
fe cluster(state)
outreg2 rate lpop using Table2, tex append
}


}
/*
xtreg isemp  state_exem lpop time*st* i.mon  if samp==1 & !exclusion & ///
_merge==3 & pop_enough, fe cluster(state)
outreg2 state_exem lpop using percent_exem_pop, word append

**Rate instead of exemption dummy
/*
by county: egen min_pop=min(pop)
gen pop_enough=0
replace pop_enough=1 if min_pop>50000
*/


**Rate instead of exemption dummy
*Basic
set more off
xtreg isemp rate lpop  i.mon  if samp==1 & !exclusion & _merge==3 ///
 & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2 rate lpop using percent_rate, tex replace

xtreg isemp  rate lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 ///
 & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate, tex append

xtreg isemp rate lpop time*st* i.mon  if samp==1 & !exclusion & _merge==3 ///
 & _merge==3 & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate, tex append 

*Population above 50,000
xtreg lwage rate lpop  i.quat  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2 rate lpop using percent_rate_pop_enough_wage , tex replace

xtreg lwage  rate lpop  quat_st* i.quat  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough_wage, tex append

xtreg lwage rate lpop time*st* i.quat  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & _merge==3 & quat<ym(2011,2) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough_wage, tex append 

**Rate instead of exemption dummy

xtreg isemp rate lpop  i.mon  if samp==1 & !exclusion & _merge==3 ///
& state!=9 & pop_enough & mon<=ym(2011,4)  & year>=1997, fe cluster(state)
outreg2 rate lpop using percent_rate_pop_enough_noct, tex replace

xtreg isemp  rate lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& state!=9 & pop_enough & mon<=ym(2011,4)  & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough_noct, tex append

xtreg isemp rate lpop time*st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& state!=9 & pop_enough & _merge==3 & mon<=ym(2011,4)  & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough_noct, tex append 


**Rate instead of exemption dummy

xtreg isemp rate lpop  i.mon  if samp==1 & !exclusion & _merge==3 ///
& miss_all<114 & mon<=ym(2011,4), fe cluster(state)
outreg2 rate lpop using percent_rate_totmiss160, word replace

xtreg isemp  rate lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& miss_all<114  & mon<=ym(2011,4), fe cluster(state)
outreg2  rate lpop using percent_rate_totmiss160, word append

xtreg isemp rate lpop time*st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& miss_all<114  & _merge==3 & mon<=ym(2011,4), fe cluster(state)
outreg2  rate lpop using percent_rate_totmiss160, word append 

/*
//State exemption dummy + Interaction between exemption and tax drop
xtreg isemp state_exem c.state_exem#c.state_taxdrop lpop  i.mon  if samp==1 ///
& !exclusion & _merge==3, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop lpop using percent_exc1, word append

xtreg isemp state_exem c.state_exem#c.state_taxdrop mon_st* i.mon  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop using percent_exc1, word append

xtreg isemp state_exem c.state_exem#c.state_taxdrop mon_st* time*st*  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop using percent_exc1, word append


//State exemption dummy + Interaction between exemption and tax drop
//+Interaction between exemptino and threshold
xtreg isemp state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold  i.mon  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold ///
using percent_exc2, word replace

xtreg isemp state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold mon_st* i.mon  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold ///
using percent_exc2, word append

xtreg isemp state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold mon_st* time*st*  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop c.state_exem#c.state_threshold ///
 using percent_exc2, word append

//State exemption dummy + Interaction between exemption and tax drop
//+Interaction between exemptino and threshold+triple interaction

xtreg isemp state_exem c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold ///
i.mon  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold ///
 using percent_exc2, word append

xtreg isemp state_exem c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold ///
mon_st* i.mon  if samp==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold///
 using percent_exc2, word append

xtreg isemp state_exem state_exem state_taxdrop c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold ///
mon_st* time*st*  if samp_min==1 & !exclusion, ///
fe cluster(state)
outreg2 state_exem c.state_exem#c.state_taxdrop ///
c.state_exem#c.state_threshold c.state_exem#c.state_taxdrop#c.state_threshold ///
 using percent_exc2, word append

/*
//xtreg isemp treat1 if samp==1 & !exclusion & state!=9 & year<=2010, fe cluster(state)
//outreg2 treat1 using percent_exc, word replace
xtreg isemp treat i.mon  if samp==1 & !exclusion & state!=9 & year<=2010, fe cluster(state)
outreg2 treat using percent_exc1, word replace
xtreg isemp treat mon_st* i.mon  if samp==1 & !exclusion & state!=9 & year<=2010, fe cluster(state)
outreg2 treat using percent_exc1, word append
xtreg isemp treat time*st* i.mon  if samp==1 & !exclusion & state!=9 & year<=2010, ///
fe cluster(state)
outreg2 treat using percent_exc1, word append

/*
**excluding four smallest in population counties in the data 
** (the smallest county is not in QWEC data)
foreach mc in 36049 36095 36097 36123 {
	replace exclusion=1 if county==`mc'
}

**excluding missings and zeros together
/*
foreach mc in 36121 36107 36115 36079 {
	replace exclusion=1 if county==`mc'
}
*/ 
//replace exclusion=1 if miss_all


set matsize 1000
set more off
*/
xtreg isemp treat1 i.mon  if samp_min & !exclusion, fe cluster(state)
outreg2 treat1 using percent_exc_zerAmis, word replace
xtreg isemp treat1 mon_st* i.mon  if samp_min & !exclusion, fe cluster(state)
outreg2 treat1 using percent_exc_zerAmis, word append
xtreg isemp treat1 time*st* i.mon  if samp_min & !exclusion, fe cluster(state)
outreg2 treat1 using percent_exc_zerAmis, word append


/* 
forval i=24/36 {

	xtreg isemp treat i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word replace
	xtreg isemp treat mon_st* i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append
	xtreg isemp treat time*st* i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append
}

local i=25
	xtreg isemp treat i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word replace
	xtreg isemp treat mon_st* i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append
	xtreg isemp treat time*st* i.mon  if emp0_all<`i' & !exclusion, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append

local i=73
	xtreg isemp treat i.mon  if emp0_all<`i' & !exclusion & samp, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word replace
	xtreg isemp treat mon_st* i.mon  if emp0_all<`i' & !exclusion & samp, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append
	xtreg isemp treat time*st* i.mon  if emp0_all<`i' & !exclusion & samp, fe cluster(state)
	outreg2 treat using percent_emp0_`i', word append


	
foreach var in emp_dum treat {
	capture drop `var'_m
	capture drop av_`var' 
	bysort mon: egen av_`var'=mean(`var')
	gen `var'_m=`var'-av_`var'
}


xtlogit emp_dum treat i.month i.year  if  !exclusion & samp==1, fe
outreg2 treat using planA, word append
xtreg emp_dum treat i.mon  if  !exclusion & samp==1, fe
outreg2 treat using planA, word append
xtreg emp_dum treat mon_st* i.mon  if samp & !exclusion, fe cluster(state)
outreg2 treat using planA, word append
xtreg emp_dum treat time*st* i.mon  if samp & !exclusion, fe cluster(state)
outreg2 treat using planA, word append


/*
set matsize 1000
set more off
xtreg isemp treat if samp_min==1, fe cluster(state)
outreg2 treat using percent_ref, word replace
xtreg isemp treat i.mon  if samp_min==1, fe cluster(state)
outreg2 treat using percent_ref, word append
xtreg isemp treat mon_st* i.mon  if samp_min==1, fe cluster(state)
outreg2 treat using percent_ref, word append
xtreg isemp treat time*st* i.mon  if samp_min==1, fe cluster(state)
outreg2 treat using percent_ref, word append

//save regres, replace
/*
collapse emp treat, by(state mon)
local j=ym(2000,2)
twoway (line emp mon if state==36) (line emp mon if state==9) ///
if mon>=ym(1999,1) & mon<ym(2002,1), xline(`j')

local j=ym(2003,6)
twoway (line emp mon if state==36) (line emp mon if state==9) ///
if mon>=ym(2002,1) & mon<ym(2005,1), xline(`j')

local j=ym(2003,5)
twoway (line emp mon if state==36) (line emp mon if state==9) ///
if mon>=ym(2002,1) & mon<ym(2005,1), xline(`j')

local j=ym(2006,3)
twoway (line emp mon if state==36) (line emp mon if state==17) ///
if mon>=ym(2005,1) & mon<ym(2008,1), xline(`j')


local j1=ym(2010,10)
local j2=ym(2011,4)
local j3=ym(2012,4)
twoway (line emp mon if state==36) (line emp mon if state==17) ///
if mon>=ym(2009,1) & mon<ym(2014,1), xline(`j1' `j2' `j3')
