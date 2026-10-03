version 16.0
set more off
* 手动导入 iv-essential data2.xlsx：Sheet1，A2:X865，不勾选首行作为变量名。
* 变量应为 A—X；合计行自动去除。当前目录须有 national_g.dta。
drop if A=="合计"
rename (A B C) (city_name city_id year)
drop D E
destring city_id year F-X, replace
recast double F-X
assert !missing(city_id,year)
assert inlist(year,2000,2010,2020)
isid city_id year
bysort city_id: assert _N==3
foreach v of varlist F-X {
    assert !missing(`v') & `v'>=0
}
gen double pop0=F+G
drop F G
rename (H I J K L M N O P Q R S T U V W X) ///
       (pop5 pop10 pop15 pop20 pop25 pop30 pop35 pop40 pop45 pop50 pop55 pop60 pop65 pop70 pop75 pop80 pop85)

* 1. 实际老龄化：60+人口/20+人口；计算2010—2020年长差分。
preserve
egen double older=rowtotal(pop60-pop85)
egen double adult=rowtotal(pop20-pop85)
assert adult>0 & older>0
gen double OR=older/adult
keep if year!=2000
keep city_id year OR
reshape wide OR, i(city_id) j(year)
gen double D=ln(OR2020)-ln(OR2010)
tempfile actual
save `actual'
restore

* 2. 两期预测均使用2000年城市人口和全国g。
keep if year==2000
* 尾部合并，保证每个基期年龄组只计入一次。
egen double tail10=rowtotal(pop75-pop85)
egen double tail20=rowtotal(pop65-pop85)
drop year
reshape long pop, i(city_id) j(age)
merge m:1 age using national_g.dta, keep(master match) nogen
assert !missing(g10) if age<=75
assert !missing(g20) if age<=65
gen double p10=pop*g10 if age<75
replace p10=tail10*g10 if age==75
gen double p20=pop*g20 if age<65
replace p20=tail20*g20 if age==65
* 达到60岁或20岁按目标年龄（基期年龄+10或+20）判断。
gen double older10=p10 if age+10>=60
gen double adult10=p10 if age+10>=20
gen double older20=p20 if age+20>=60
gen double adult20=p20 if age+20>=20
collapse (sum) older10 adult10 older20 adult20, by(city_id city_name)
assert min(older10,adult10,older20,adult20)>0
gen double predOR2010=older10/adult10
gen double predOR2020=older20/adult20
gen double Z=ln(predOR2020)-ln(predOR2010)

* 3. 每市一行，D为实际变化，Z为工具变量。
merge 1:1 city_id using `actual', assert(match) nogen
keep city_id city_name OR2010 OR2020 predOR2010 predOR2020 D Z
order city_id city_name OR2010 OR2020 predOR2010 predOR2020 D Z
sort city_id
save iv_2010_2020.dta, replace
export excel using iv_2010_2020.xlsx, firstrow(variables) replace
