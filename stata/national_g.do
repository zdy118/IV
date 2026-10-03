version 18.0
set more off
* 手动导入 total_national.xlsx：Sheet1，A4:D22，不勾选首行作为变量名。
* 导入后变量为 A B C D；结果保存到 Stata 当前工作目录。
keep A B C D
assert _N==19
rename (B C D) (n2000 n2010 n2020)
destring n*, replace
recast double n*
assert !missing(n2000,n2010,n2020) & min(n2000,n2010,n2020)>=0
* 合并0岁和1—4岁，最后一组为85+。
gen age=cond(_n<=2,0,5*(_n-2))
collapse (sum) n2000 n2010 n2020, by(age)
sort age
assert n2000>0

* age为2000年年龄；向后移动2组/4组对应10年/20年。
gen double g10=n2010[_n+2]/n2000 if age<75
gen double g20=n2020[_n+4]/n2000 if age<65
* 尾组：2010年85+/2000年75+；2020年85+/2000年65+。
quietly summarize n2000 if age>=75, meanonly
replace g10=n2010[18]/r(sum) if age==75
quietly summarize n2000 if age>=65, meanonly
replace g20=n2020[18]/r(sum) if age==65
assert !missing(g10) if age<=75
assert !missing(g20) if age<=65
keep age g10 g20
keep if age<=75
label variable age "2000年基期年龄下限（尾组需合并）"
label variable g10 "2000至2010全国队列人口比"
label variable g20 "2000至2020全国队列人口比"
save national_g.dta, replace
export excel using national_g.xlsx, firstrow(variables) replace
