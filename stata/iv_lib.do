version 16.0
* Core routines work on standardized DTA files. Counts must be double precision.
capture program drop iv_check
program define iv_check
    syntax [, CITY]
    confirm numeric variable year age_start population
    assert inlist(year,2000,2010,2020)
    assert !missing(population) & population>=0
    assert inrange(age_start,0,85) & mod(age_start,5)==0
    local key ""
    if "`city'"!="" {
        confirm string variable city_id city_name
        assert city_id!="" & city_name!=""
        local key city_id
        bysort city_id (city_name): assert city_name[1]==city_name[_N]
    }
    isid `key' year age_start
    bysort `key' year (age_start): assert _N==18 & age_start==5*(_n-1)
    bysort `key' age_start (year): assert _N==3 & year==2000+10*(_n-1)
    assert _N>0
end

capture program drop iv_g
program define iv_g
    syntax using/, SAVing(string)
    use "`using'", clear
    iv_check
    tempfile source base g10
    save `source'
    foreach tau in 10 20 {
        local target=2000+`tau'
        local cut=85-`tau'
        use `source', clear
        keep if year==2000
        gen base_age_start=min(age_start,`cut')
        collapse (sum) base_population=population, by(base_age_start)
        gen age_start=base_age_start+`tau'
        save `base', replace
        use `source', clear
        keep if year==`target' & age_start>=`tau'
        rename population target_population
        merge 1:1 age_start using `base', assert(match) nogen
        assert base_population>0 & !missing(base_population)
        gen double g=target_population/base_population
        assert !missing(g)
        rename age_start target_age_start
        rename year target_year
        gen base_year=2000
        gen horizon_years=`tau'
        gen byte is_open_group=target_age_start==85
        order base_year target_year horizon_years base_age_start target_age_start ///
            is_open_group base_population target_population g
        sort base_age_start
        if `tau'==10 save `g10'
    }
    append using `g10'
    sort target_year base_age_start
    isid target_year target_age_start
    assert _N==30
    save "`saving'", replace
end

capture program drop iv_build
program define iv_build
    syntax using/, RATES(string) SAVing(string) AUDIT(string)
    use "`using'", clear
    iv_check, city
    tempfile city actual base predicted10 audit10
    save `city'
    keep if inlist(year,2010,2020)
    gen double A=cond(age_start>=60,population,0)
    gen double N=cond(age_start>=20,population,0)
    collapse (sum) A N, by(city_id city_name year)
    assert A>0 & N>0 & !missing(A,N)
    gen double OR=A/N
    reshape wide A N OR, i(city_id city_name) j(year)
    gen double D=ln(OR2020)-ln(OR2010)
    save `actual'
    foreach tau in 10 20 {
        local target=2000+`tau'
        local cut=85-`tau'
        use `city', clear
        keep if year==2000
        gen target_age_start=min(age_start,`cut')+`tau'
        collapse (sum) base_city_population=population, by(city_id target_age_start)
        gen target_year=`target'
        save `base', replace
        use "`rates'", clear
        keep if target_year==`target'
        isid target_year target_age_start
        tempfile thisrate
        save `thisrate', replace
        use `base', clear
        merge m:1 target_year target_age_start using `thisrate', assert(match) nogen
        assert !missing(g) & g>=0
        gen double predicted_population=base_city_population*g
        assert !missing(predicted_population)
        if `tau'==10 save `audit10'
        else {
            preserve
            append using `audit10'
            sort city_id target_year target_age_start
            save "`audit'", replace
            restore
        }
        gen double predA=cond(target_age_start>=60,predicted_population,0)
        gen double predN=cond(target_age_start>=20,predicted_population,0)
        collapse (sum) predA predN, by(city_id target_year)
        assert predA>0 & predN>0 & !missing(predA,predN)
        gen double predOR=predA/predN
        if `tau'==10 save `predicted10'
    }
    append using `predicted10'
    reshape wide predA predN predOR, i(city_id) j(target_year)
    gen double Z=ln(predOR2020)-ln(predOR2010)
    merge 1:1 city_id using `actual', assert(match) nogen
    order city_id city_name OR2010 OR2020 predOR2010 predOR2020 D Z
    sort city_id
    save "`saving'", replace
end
