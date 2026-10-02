version 16.0
clear all
set more off
set type double
do "stata/iv_lib.do"
tempfile national city rates result audit
set obs 54
gen year=2000+10*floor((_n-1)/18)
gen age_start=5*mod(_n-1,18)
gen double population=cond(year==2000,100,cond(year==2010,120,80))
save `national'
iv_g using `national', saving("`rates'")
assert _N==30
assert abs(g-1.2)<1e-12 if target_year==2010 & !is_open_group
assert abs(g-.8)<1e-12 if target_year==2020 & !is_open_group
assert abs(g-.4)<1e-12 if target_year==2010 & is_open_group
assert abs(g-.16)<1e-12 if target_year==2020 & is_open_group
assert base_age_start==75 if target_year==2010 & is_open_group
assert base_age_start==65 if target_year==2020 & is_open_group
use `national', clear
gen str3 city_id="001"
gen str8 city_name="TestCity"
replace population=population*.1
save `city'
iv_build using `city', rates("`rates'") saving("`result'") audit("`audit'")
assert abs(predOR2010-6/14)<1e-12 & abs(predOR2020-6/14)<1e-12
assert abs(Z)<1e-12 & abs(D)<1e-12
use `city', clear
replace population=age_start/5+1 if year==2000
save `city', replace
iv_build using `city', rates("`rates'") saving("`result'") audit("`audit'")
assert abs(predOR2010-(65*1.2+51*.4)/(117*1.2+51*.4))<1e-12
assert abs(predOR2020-(55*.8+80*.16)/(91*.8+80*.16))<1e-12
scalar savedZ=Z[1]
use `city', clear
replace population=200 if year==2020 & age_start>=60
save `city', replace
iv_build using `city', rates("`rates'") saving("`result'") audit("`audit'")
assert Z==savedZ
use `national', clear
replace population=0 in 1
save `national', replace
capture iv_g using `national', saving("`rates'")
assert _rc!=0
display as result "ALL STATA IV TESTS PASSED"
