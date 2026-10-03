version 18.0
set more off
* 先手动 use 最全数据面板.dta, clear；再完整运行本文件。
* 当前工作目录需有已完成的 iv_2010_2020.xlsx；所有结果写入当前目录。
* TFP已是ln(TFP)，不能再次取对数。新IV只解释2010—2020长差分。
keep if inrange(year,2004,2022)
rename (code 地级市 省份) (city_id panel_city province_name)
isid city_id year
keep city_id panel_city province_name year 新时不变实际tfp 新时不变前沿tfp ///
    常住人口万人 平均受教育年限 人均财政支出 新平均劳动年龄
rename (新时不变实际tfp 新时不变前沿tfp 常住人口万人 平均受教育年限 人均财政支出 新平均劳动年龄) ///
    (tfp_actual tfp_frontier population education budget age)
* 记录全样本统计，与论文表2-1匹配；不自动选择“显著”的数据版本。
summarize tfp_actual tfp_frontier population education budget age
* 缩尾敏感性：在2004—2022全样本的lnTFP上做1%/99%缩尾，再长差分。
foreach v in actual frontier {
    quietly summarize tfp_`v', detail
    gen double tfp_`v'_w=tfp_`v'
    replace tfp_`v'_w=r(p1) if tfp_`v'<r(p1) & !missing(tfp_`v')
    replace tfp_`v'_w=r(p99) if tfp_`v'>r(p99) & !missing(tfp_`v')
}
keep if inlist(year,2004,2009,2010,2020)
* 省份以行政代码前两位定义；另存原始省名不一致记录供核查。
bysort city_id (year): gen byte province_label_changed=province_name!=province_name[1]
preserve
keep if province_label_changed
export delimited using province_label_audit.csv, replace
restore
drop province_name province_label_changed
bysort city_id (year): assert panel_city==panel_city[1]
* 2009年为事前控制；2004年用于事前趋势诊断。
assert population>0 & budget>0 if !missing(population,budget)
gen double ln_population=ln(population)
gen double ln_budget=ln(budget)
drop population budget
reshape wide tfp_actual tfp_frontier tfp_actual_w tfp_frontier_w ///
    ln_population education ln_budget age, i(city_id panel_city) j(year)
isid city_id
gen double Y_actual=tfp_actual2020-tfp_actual2010
gen double Y_frontier=tfp_frontier2020-tfp_frontier2010
gen double Y_actual_w=tfp_actual_w2020-tfp_actual_w2010
gen double Y_frontier_w=tfp_frontier_w2020-tfp_frontier_w2010
gen double Y_pre=tfp_actual2009-tfp_actual2004
rename (ln_population2009 education2009 ln_budget2009 age2009) (ln_pop0 edu0 ln_budget0 age0)
gen double age0_sq=age0^2
rename (ln_population2004 education2004 ln_budget2004) (ln_pop_pre edu_pre ln_budget_pre)
keep city_id panel_city Y_* ln_pop0 edu0 ln_budget0 age0 age0_sq ///
    ln_pop_pre edu_pre ln_budget_pre
save panel_long_difference.dta, replace

import excel iv_2010_2020.xlsx, firstrow clear
confirm numeric variable city_id D Z OR2010 OR2020 predOR2010 predOR2020
* 仅统一直辖市市辖区编码与整市编码；不模糊匹配其他城市。
replace city_id=110000 if city_id==110100 & city_name=="北京市"
replace city_id=120000 if city_id==120100 & city_name=="天津市"
replace city_id=310000 if city_id==310100 & city_name=="上海市"
replace city_id=500000 if city_id==500100 & city_name=="重庆市"
isid city_id
assert !missing(D,Z,OR2010,OR2020,predOR2010,predOR2020)
assert min(OR2010,OR2020,predOR2010,predOR2020)>0
assert abs(D-(ln(OR2020)-ln(OR2010)))<1e-10
assert abs(Z-(ln(predOR2020)-ln(predOR2010)))<1e-10
merge 1:1 city_id using panel_long_difference.dta
tab _merge
export delimited using merge_audit.csv, replace
keep if _merge==3
drop _merge
assert city_name==panel_city
* 明确记录缺失排除，不填0，不默默删去未匹配城市。
gen byte sample_ok=!missing(Y_actual,Y_frontier,Y_actual_w,Y_frontier_w,D,Z,ln_pop0,edu0,ln_budget0,age0,age0_sq)
export delimited using sample_audit.csv, replace
keep if sample_ok
gen province=floor(city_id/10000)
isid city_id
sort city_id
save endogeneity_sample.dta, replace
export delimited using endogeneity_sample.csv, replace
* CSV也用于MATLAB，确保两种语言使用完全相同的观测与变量。
