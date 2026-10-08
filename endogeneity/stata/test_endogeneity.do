version 18.0
set more off
* 先运行prepare_endogeneity.do，当前目录需有endogeneity_sample.dta。
* 请完整运行；循环局部宏的作用域不可跨选中执行块。
use endogeneity_sample.dta, clear
isid city_id
log using endogeneity_stata.log, text replace name(endo)
postfile results str14 outcome str12 specification str8 vce ///
    double(N clusters ols_b ols_se iv_b iv_se iv_p first_b first_se first_F first_p partial_R2 ///
    endog_F endog_p AR0_F AR0_p AR_A AR_B AR_C AR_critical) ///
    using endogeneity_results.dta, replace
foreach y in Y_actual Y_frontier Y_actual_w Y_frontier_w {
    foreach spec in baseline province age {
        local X "ln_pop0 edu0 ln_budget0"
        if "`spec'"=="province" local X "`X' i.province"
        if "`spec'"=="age" local X "`X' age0 age0_sq"
        foreach vc in HC1 province {
            local V "robust"
            if "`vc'"=="province" local V "cluster province"
            quietly regress `y' D `X', vce(`V')
            scalar ob=_b[D]
            scalar os=_se[D]
            scalar NN=e(N)
            scalar GG=.
            if "`vc'"=="province" scalar GG=e(N_clust)

            * 第一阶段：只检验排除工具Z，而不是整条方程的总体F。
            * 设计矩阵维度不能用聚类VCE的rank代替（后者可能小于参数数目）。
            quietly regress D Z `X'
            scalar kq=e(rank)
            quietly regress D Z `X', vce(`V')
            scalar fb=_b[Z]
            scalar fs=_se[Z]
            scalar fsrss=e(rss)
            scalar dfr=e(df_r)
            predict double vhat, residuals
            test Z
            scalar ff=r(F)
            scalar fp=r(p)
            quietly regress D `X'
            scalar pr2=1-fsrss/e(rss)

            * 原生2SLS标准误；不能把第一阶段拟合值直接拿去普通OLS。
            ivregress 2sls `y' `X' (D=Z), vce(`V') small
            scalar ib=_b[D]
            scalar ise=_se[D]
            test D
            scalar ip=r(p)
            estat endogenous
            scalar ef=r(regF)
            scalar ep=r(p_regF)

            * AR检验H0:beta=0。与内生性检验H0:D外生不同。
            quietly regress `y' Z `X', vce(`V')
            scalar ry=_b[Z]
            scalar vy=_se[Z]^2
            predict double ey, residuals
            test Z
            scalar af=r(F)
            scalar ap=r(p)
            scalar crit=invFtail(1,e(df_r),.05)
            * 完整AR置信集合：解 A*beta^2+B*beta+C<=0，不设任意网格边界。
            quietly regress Z `X'
            predict double rz, residuals
            quietly summarize rz
            scalar zz=(r(N)-1)*r(Var)+r(N)*r(mean)^2
            gen double sy=rz*ey/zz
            gen double sd=rz*vhat/zz
            if "`vc'"=="province" {
                bysort province: egen double cy=total(sy)
                bysort province: egen double cd=total(sd)
                egen byte tag=tag(province)
                gen double cross=cy*cd if tag
                scalar adj=GG/(GG-1)*(NN-1)/(NN-kq)
            }
            else {
                gen double cross=sy*sd
                scalar adj=NN/(NN-kq)
            }
            quietly summarize cross, meanonly
            scalar vyd=adj*r(sum)
            scalar aa=fb^2-crit*fs^2
            scalar bb=-2*ry*fb+2*crit*vyd
            scalar cc=ry^2-crit*vy
            post results ("`y'") ("`spec'") ("`vc'") (NN) (GG) (ob) (os) ///
                (ib) (ise) (ip) (fb) (fs) (ff) (fp) (pr2) (ef) (ep) ///
                (af) (ap) (aa) (bb) (cc) (crit)
            drop vhat ey rz sy sd cross
            if "`vc'"=="province" drop cy cd tag
        }
    }
}
postclose results
* 事前趋势是排除性风险诊断，不是有效性的证明；不用2009控制解释过去。
regress Y_pre Z ln_pop_pre edu_pre ln_budget_pre, vce(cluster province)
scalar pn=e(N)
scalar pg=e(N_clust)
scalar pb=_b[Z]
scalar ps=_se[Z]
test Z
matrix pre=(pn,pg,pb,ps,r(F),r(p))
matrix colnames pre=N clusters Z_b Z_se F p
preserve
clear
svmat double pre, names(col)
export delimited using pretrend_diagnostic.csv, replace
restore
preserve
use endogeneity_results.dta, clear
* A、B、C决定完整置信集合，Inf边界用文字表达。
gen double disc=AR_B^2-4*AR_A*AR_C
gen double r1=(-AR_B-sqrt(disc))/(2*AR_A) if disc>=0 & AR_A!=0
gen double r2=(-AR_B+sqrt(disc))/(2*AR_A) if disc>=0 & AR_A!=0
gen double lo=min(r1,r2)
gen double hi=max(r1,r2)
gen str120 AR95=""
replace AR95="["+string(lo,"%12.6g")+", "+string(hi,"%12.6g")+"]" if AR_A>0 & disc>=0
replace AR95="(-Inf, "+string(lo,"%12.6g")+"] U ["+string(hi,"%12.6g")+", Inf)" if AR_A<0 & disc>=0
replace AR95="empty" if AR_A>0 & disc<0
replace AR95="all real" if AR_A<0 & disc<0
replace AR95="(-Inf, "+string(-AR_C/AR_B,"%12.6g")+"]" if AR_A==0 & AR_B>0
replace AR95="["+string(-AR_C/AR_B,"%12.6g")+", Inf)" if AR_A==0 & AR_B<0
replace AR95="all real" if AR_A==0 & AR_B==0 & AR_C<=0
replace AR95="empty" if AR_A==0 & AR_B==0 & AR_C>0
assert AR95!=""
drop disc r1 r2 lo hi
save endogeneity_results.dta, replace
export delimited using endogeneity_results.csv, replace
list outcome specification vce N first_F endog_p iv_b iv_p AR95, noobs
restore
log close endo
