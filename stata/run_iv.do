version 16.0
clear all
set more off
set type double
* Open Stata with the downloaded repository root as the working directory.
* Edit these paths; paths use / to avoid Stata macro/backslash interactions.
local code "."
local data "D:/SZU/aging&TFP&labour/aging/IV"
local cityfile "`data'/iv-essential data2.xlsx"
local nationalfile "`data'/total_national.xlsx"
local stamp=subinstr("`c(current_date)'_`c(current_time)'"," ","",.)
local stamp=subinstr("`stamp'",":","",.)
capture mkdir "`code'/results"
local out "`code'/results/stata_`stamp'"
mkdir "`out'"
log using "`out'/run.log", text name(ivlog)
do "`code'/stata/iv_lib.do"
do "`code'/stata/import_census.do" "`cityfile'" "`nationalfile'" "`out'"

* Audit population concentration and sample-vs-national coverage before g.
use "`out'/city_age.dta", clear
bysort city_id year: egen double total_population=total(population)
gen double share=population/total_population
gen byte requires_review=missing(share) | share>.5
export delimited using "`out'/city_data_audit.csv", replace
assert requires_review==0
collapse (sum) sample_population=population, by(year age_start)
merge 1:1 year age_start using "`out'/national_age.dta", assert(match) nogen
gen double difference=population-sample_population
export delimited using "`out'/reference_coverage_audit.csv", replace
count if abs(difference)>1e-8
if r(N)==0 {
    display as error "Reference equals study-city sums. Supply independent nationwide data."
    exit 459
}
use "`out'/national_age.dta", clear
bysort year: egen double total_population=total(population)
gen double share=population/total_population
quietly summarize total_population if year==2000, meanonly
gen double relative_total=total_population/r(mean)
gen byte requires_review=missing(share,relative_total) | share>.25 | ///
    relative_total<.5 | relative_total>2
export delimited using "`out'/national_data_audit.csv", replace
assert requires_review==0

iv_g using "`out'/national_age.dta", saving("`out'/national_cohort_rates.dta")
export delimited using "`out'/national_cohort_rates.csv", replace
iv_build using "`out'/city_age.dta", rates("`out'/national_cohort_rates.dta") ///
    saving("`out'/iv_2010_2020.dta") audit("`out'/cohort_audit.dta")
export delimited using "`out'/iv_2010_2020.csv", replace
list city_id city_name D Z in 1/5, noobs
use "`out'/cohort_audit.dta", clear
export delimited using "`out'/cohort_audit.csv", replace
display as result "Results saved to: `out'"
log close ivlog
