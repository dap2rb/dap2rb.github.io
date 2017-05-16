clear all 
set more off
local naics=448

//lapton

 
global inp="D:/RES/CE"
global inp2="D:/RES/CE"
global mid1="D:/RES/CE/ny_final/"
global mid="D:/RES/CE"
global out="D:/RES/CE"

*/

/*
global inp="d:/Dropbox/BLS/QWECdata/`naics'"
global inp2="d:/Dropbox/BLS/QWECdata/population"
global mid1="d:/Dropbox/BLS/Data/ny_final/out"
global mid="d:/Dropbox/BLS/QWECdata/regressions_county"
global out="d:/Dropbox/BLS/QWECdata/448"
*/

/*
global inp="C:/Users/kk/Dropbox/BLS/QWECdata/`naics'"
global inp2="C:/Users/kk/Dropbox/BLS/QWECdata/population"
global mid1="C:/Users/kk/Dropbox/BLS/Data/ny_final/out"
global mid="C:/Users/kk/Dropbox/BLS/QWECdata/regressions_county"
global out="C:/Users/kk/Dropbox/BLS/QWECdata/448"
*/
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


cd $inp


***Obtaining county names based on county fips
import delim using $inp/county_names.txt, clear
gen county = v2*1000+v3
gen county_name = regexs(1) if regexm( v4 , "([a-zA-Z]+)[ ]*(County)")
replace county_name=lower(county_name)

rename v2 state
local ne_states state==9 | state==23 | state==25 | state==33 | state==34 | state==36 | state==42 | state==44 | state==50

keep if `ne_states'
keep county county_name
save $inp/county_names, replace



***Obtaining NY tax rates
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




***Import apparel retail data
import delim using $inp/code.csv, clear

**Combing vars
gen disc=1
replace disc=0 if strpos(lq_disclosure_code,"N")

keep if state==9 | state==23 | state==25 | state==33 | ///
state==34 | state==36 | state==42 | state==44 | state==50

keep if month==1
rename area_fips county
gen quat=ym(year, qtr)

format %tq quat

**Reshaping data set
keep county quat industry_code qtrly_estabs total_qtrly_wages ///
avg_wkly_wage  disc year state qtr

reshape wide qtrly_estabs_count total_qtrly_wages ///
 avg_wkly_wage disc, i(county quat) j(industry_code)

rename qtrly_estabs_count448 qtrly_estabs_count
rename total_qtrly_wages448 total_qtrly_wages
rename avg_wkly_wage448 avg_wkly_wage
rename disc448 disc






**Creating treatment vars

sort county 
merge n:1 county using $mid/county_names


drop _merge


*drop if _merge==2

sort county quat
save $mid/tmp_quat, replace

use  $mid/tmp_quat, clear



*NY:
keep if state==36

replace county_name="newyork" if county_name=="york"
replace county_name="st.lawrence" if county_name=="lawrence"


merge 1:1 county_name quat using $mid/county_ny_quat
foreach var in county_rate55 county_rate110 county_rate999 {
	replace `var'=4 if missing(`var') & strpos(county_name, "oswe")
}

drop if _merge==2
drop _merge

merge 1:1 county quat using $mid/tmp_quat
drop _merge

**Merge with population data
*replace year= 1960+floor(mon/12)
sort county year
merge n:1 county year using $inp/population
sort county quat 
drop if _merge==2


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
replace samp=1 if state==9  | state==23 | state==25 | state==33 | state==34 ///
| state==36 | state==42 | state==44 | state==50  
//9 23 25 33 44 50 34 36 42 
/*
9 - CT - all counties are big
*/
gen samp_broad=0
replace samp_broad=1 if samp==1 | state==17 | state==18 | state==26 | ///
state==39 | state==55 
//18 17 26 39 55

xtset county quat, q
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

rename qtrly_estabs_count estab
rename total_qtrly_wages payroll
replace payroll=real(payroll)
rename avg_wkly_wage wage

local vars estab payroll  wage
foreach v of var `vars' {
	capture drop l`v'
	replace `v'=. if disc!=1
	gen l`v'=log(`v')
} 

/*
xtreg emp treat i.mon if samp==1, fe cluster(state)
xtreg emp treat time*st* i.mon  if samp==1, fe cluster(state)
use regres, clear
*/
capture drop lemp //lemp_sport isemp_sport isemp
replace emp=. if disc!=1
gen lemp=log(emp)
replace emp_sport=. if disc_sport!=1
gen lemp_sport=log(emp_sport)
gen isemp_sport=log(emp_sport+sqrt(emp_sport*emp_sport+1))
gen isemp=log(emp+sqrt(emp*emp+1))

/*
xtreg emp treat  if samp==1, fe cluster(state)
outreg2 treat using level, word replace
xtreg emp treat i.mon if samp==1, fe cluster(state)
outreg2 treat using level, word append
xtreg emp treat i.mon mon_st* if samp==1, fe cluster(state)
outreg2 treat using level, word append
xtreg emp treat i.mon time*st* if samp==1, fe cluster(state)
outreg2 treat using level, word append
*/

set matsize 1000
set more off
/*
xtreg isemp treat if samp==1, fe cluster(state)
outreg2 treat using percent, word replace
xtreg isemp treat i.mon  if samp==1, fe cluster(state)
outreg2 treat using percent, word append
xtreg isemp treat mon_st* i.mon  if samp==1, fe cluster(state)
outreg2 treat using percent, word append
xtreg isemp treat time*st* i.mon  if samp==1, fe cluster(state)
outreg2 treat using percent, word append


set matsize 1000
set more off
xtreg isemp treat if samp_broad==1, fe cluster(state)
outreg2 treat using percent_broad, word replace
xtreg isemp treat i.mon  if samp_broad==1, fe cluster(state)
outreg2 treat using percent_broad, word append
xtreg isemp treat mon_st* i.mon  if samp_broad==1, fe cluster(state)
outreg2 treat using percent_broad, word append
xtreg isemp treat time*st* i.mon  if samp_broad==1, fe cluster(state)
outreg2 treat using percent_broad, word append

*/

set matsize 1000
set more off


capture drop samp_min

bysort county: egen emp0_all=total(emp==0)


capture drop miss
gen miss=missing(emp)
capture drop miss_sport
gen miss_sport=missing(emp_sport)
bysort county: egen miss_all=total(miss)
gen samp_min=samp
replace samp_min=0 if miss_all>0
sort county quat

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

save $mid/analysis_quat, replace
use $mid/analysis_quat, clear


set more off 
local vars emp emp miss pop rate 
clear mata
keep if state==9 | state==23 | state==25 | state==33 | state==34 | state==36 ///
| state==42 | state==44 | state==50



gen pmiss=100*miss

capture drop state_ss
gen state_ss=state
replace state_ss=23 if state_ss==33
replace state_ss=state+100 if state==9 | state==36 | state==50 

capture drop miss_county
bysort county: egen miss_county=max(miss)






tabstat estab payroll wage pmiss pop if year<2013 & ///
	year>=1997 & (!missing(emp) | !missing(emp_sport)), s(me sd count) by(state_ss) save
matrix stat=r(Stat1)', r(Stat2)', r(Stat3)', r(Stat4)', r(Stat5)', r(Stat6)', ///
r(Stat7)', r(Stat8)', r(StatTotal)'



frmttable using $out/sum, statmat(stat) varlabels substat(2) plain ///
rtitle("Employees" \ "" \ "Obs." \ "Missing, \%" \ "" \ "Obs." \ "Employees" \ "" \ "Obs." ///
\ "Missing, \%" \ "" \ "Obs."\"Population" \""\"Obs.") ///
ctitles( "" "CT" "NY" "VT" "ME-NH"  "MA" "NJ" "PA" "RI" "Total") replace ///
 brackets("" \ "(" ")" \"")  sdec(0 \0 \0 \2 \1 \0 \0 \0 \0\1 \1 \0 \0 \0 \0) tex

 

save $mid/analysis_1_quat, replace
use $mid/analysis_1_quat, clear

capture drop Ncounty_sport
keep if !missing(emp_sport)
bysort county: gen Ncounty_sport=_n
tab state if Ncounty_sport==1

use $mid/analysis_1, clear
capture drop Ncounty_pop
keep if !missing(emp_sport) | !missing(emp)
bysort county: gen Ncounty_sport=_n
tab state_ss if Ncounty_sport==1


use $mid/analysis_1_quat, clear
 
 
 
 

//Treatment vs. Control
set more off 
local vars emp emp miss pop rate 
clear mata



replace rate=rate/100

**First Employment Table

xtreg lemp rate  lpop i.mon if samp==1 & !exclusion & _merge==3 & ///
year<2013 & year>=1997, ///
fe cluster(state)
outreg2 rate lpop using $inp/Table1, tex replace

xtreg lemp rate lpop time*st* i.mon if samp==1 & !exclusion & ///
_merge==3 & year<2013 & year>=1997, fe cluster(state)
//gen samp_ss=e(sample)
outreg2 rate lpop using $inp/Table1, tex append





save $inp/tmp_drop, replace
use $inp/tmp_drop, clear
sort county mon
drop if missing(emp)
capture drop dup
capture drop max_obs
quietly by county:  gen dup = cond(_N==1,0,_n)
by county: egen max_obs=max(dup)

xtreg lemp rate lpop time*st* i.mon if max_obs==192 & mon<ym(2013,1) ///
& year>=1997, fe cluster(state)
outreg2 rate lpop using $inp/Table1, tex append

xtreg lemp rate lpop time*st* i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<ym(2013,1) & year>=1997 & pop_enough, fe cluster(state)
outreg2 rate lpop using $inp/Table1, tex append
 

/*
****Robustness Checks and Other Vars
**check for New York City effect
gen nyc=0
replace nyc=1 if county==36005 | county==36047 | county==36061 | ///
county==36081 | county==36085

capture drop border
gen border=0
replace border=1 if county==09001 | county==09003 | county==09005 | ///
county==09013 | county==09015 | county==36003 | county==36005 | county==36007 | ///
county==36009 | county==36013 | county==36015 | county==36019 | county==36021 | ///
county==36025 | county==36027 | county==36029 | county==36061 | county==36071 | ///
county==36079 | county==36083 | county==36087 | county==36105 | county==36105 | ///
county==36107 | county==36115 | county==36119 | county==50001 | county==50003 | ///
county==50005 | county==50007 | county==50009 | county==50013 | county==50013 | ///
county==50017 | county==50021 | county==50025 | county==50027

capture drop rate_border
gen rate_border=rate*border
xtreg lemp rate rate_border lpop time*st* i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<=ym(2011,1) & year>=1997 & pop_enough & state!=9 & state!=50, fe cluster(state)

xtreg lemp rate rate_border lpop time*st* i.mon if max_obs==234 & mon<=ym(2011,1) ///
& year>=1997 & state!=9 & state!=50, fe cluster(state)

xtreg lemp rate rate_border lpop time*st*  lemp_sport i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<=ym(2011,1) & year>=1997 & state!=9 & state!=50, fe cluster(state)

*/

****Paper Checks

use $inp/tmp_drop, clear

xtreg lemp rate lpop time*st*  lemp_sport i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<ym(2013,1) & year>=1997, fe cluster(state)
outreg2 rate lpop using $inp/Table1, tex append

*replace lemp1_sport=. if disc<1
xtreg lemp_sport rate lpop time*st* i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<ym(2013,1) & year>=1997, fe cluster(state)
outreg2 rate lpop using $inp/Table1, tex append




forval i=441(1)443 {
	use $inp/tmp_drop, clear
	sort county mon
	drop if disc`i'==0
	capture drop dup
	capture drop max_obs
	quietly by county:  gen dup = cond(_N==1,0,_n)
	by county: egen max_obs=max(dup)
	
	gen lemp_ind=log(emp`i') 
	xtreg lemp rate lpop time*st*  lemp_ind i.mon if samp==1 & !exclusion & ///
	_merge==3 &  mon<ym(2013,1) & year>=1997, fe cluster(state)
	if (`i'==441) {
		outreg2 rate lpop using $inp/Table1_ind, tex replace
	}
	else  {
		outreg2 rate lpop using $inp/Table1_ind, tex append
	}
	

	
	xtreg lemp_ind rate lpop time*st* i.mon if samp==1 & !exclusion & ///
	_merge==3 &  mon<ym(2013,1) & year>=1997, fe cluster(state)
	outreg2 rate lpop using $inp/Table1_ind, tex append
}
*xtreg isemp_sport rate lpop time*st* i.mon if samp==1 & !exclusion & ///
*_merge==3 & mon<=ym(2013,1) & year>=1997, fe cluster(state)
*outreg2 rate lpop using $inp/Table1, tex append

**Check for missing
gen Ndisc=0
replace Ndisc =1 if missing(emp) & disc==0


gen Ndisc_t=0
replace Ndisc_t =1 if missing(emp) & disc<1

gen Nmis=0
replace Nmis=1 if missing(emp)

tab Ndisc if Nmis==1 & samp==1 & !exclusion & ///
_merge==3 & mon<=ym(2013,1) & year>=1997

xtreg Ndisc_t rate lpop time*st* i.mon if samp==1 & !exclusion & ///
_merge==3 & mon<ym(2013,1) & year>=1997, fe cluster(state)

/*
xtreg isemp state_exem lpop  i.mon  if samp==1 & !exclusion & _merge==3 & pop_enough, ///
fe cluster(state)
outreg2 state_exem lpop using percent_exem_pop, word replace

xtreg isemp state_exem lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 & pop_enough, ///
fe cluster(state)
outreg2 state_exem lpop using percent_exem_pop, word append

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
 & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2 rate lpop using percent_rate, tex replace

xtreg isemp  rate lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 ///
 & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate, tex append

xtreg isemp rate lpop time*st* i.mon  if samp==1 & !exclusion & _merge==3 ///
 & _merge==3 & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate, tex append 

*Population above 50,000
xtreg isemp rate lpop  i.mon  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2 rate lpop using percent_rate_pop_enough, tex replace

xtreg isemp  rate lpop  mon_st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough, tex append

xtreg isemp rate lpop time*st* i.mon  if samp==1 & !exclusion & _merge==3 ///
& pop_enough & _merge==3 & mon<=ym(2011,4) & year>=1997, fe cluster(state)
outreg2  rate lpop using percent_rate_pop_enough, tex append 

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
