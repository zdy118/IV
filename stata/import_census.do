version 16.0
* Called by run_iv.do with three quoted paths. Do not destring with force.
args cityfile nationalfile outdir
import excel using "`cityfile'", sheet("Sheet1") allstring clear
assert A[1]=="地区名称" & B[1]=="城市编码" & C[1]=="year"
assert F[1]=="0岁人口" & G[1]=="1-4岁人口(人)"
assert P[1]=="45-49岁人口(人)"
assert X[1]=="85岁及以上人口(人)"
local cols H I J K L M N O P Q R S T U V W
local age=5
foreach col of local cols {
    local end=`age'+4
    if `age'==60 assert inlist(`col'[1],"60-64岁口(人)","60-64岁人口(人)")
    else assert `col'[1]=="`age'-`end'岁人口(人)"
    local age=`age'+5
}
drop in 1
replace A=ustrtrim(A)
drop if inlist(A,"合计","全国","总计")
rename (A B C) (city_name city_id year)
replace city_id=ustrtrim(city_id)
assert city_id!="" & city_name!=""
keep city_name city_id year F-X
destring year F-X, replace
foreach v of varlist F-X {
    assert !missing(`v') & `v'>=0
    recast double `v'
}
gen double pop0=F+G
drop F G
local age=5
foreach col of local cols {
    rename `col' pop`age'
    local age=`age'+5
}
rename X pop85
isid city_id year
reshape long pop, i(city_id year) j(age_start)
rename pop population
iv_check, city
save "`outdir'/city_age.dta", replace

import excel using "`nationalfile'", sheet("Sheet1") cellrange(A1:D22) allstring clear
assert A[1]=="year" & B[1]=="2000" & C[1]=="2010" & D[1]=="2020"
keep in 4/22
assert _N==19
assert A[1]=="0岁人口" & A[2]=="1-4岁人口(人)"
assert A[19]=="85岁及以上人口(人)"
forvalues r=3/18 {
    local age=5*(`r'-2)
    local end=`age'+4
    if `age'==60 assert inlist(A[`r'],"60-64岁口(人)","60-64岁人口(人)")
    else assert A[`r']=="`age'-`end'岁人口(人)"
}
rename (B C D) (pop2000 pop2010 pop2020)
destring pop*, replace
foreach v of varlist pop* {
    assert !missing(`v') & `v'>=0
    recast double `v'
}
gen age_start=cond(_n<=2,0,5*(_n-2))
collapse (sum) pop*, by(age_start)
reshape long pop, i(age_start) j(year)
rename pop population
iv_check
save "`outdir'/national_age.dta", replace
