function rates = compute_national_cohort_rates(national)
%COMPUTE_NATIONAL_COHORT_RATES 全国队列变化率，两个跨度均以2000年为基期。
% 输入长表列：year, age_start, population（全国男女合计人数）。
% 普通组：g(b,tau)=P_N(b+tau,2000+tau)/P_N(b,2000)，tau=10或20。
% 最后一组为T+：将基期(T-tau)+先合并，再除以该合并人口。
% g是队列规模之比，不是年增长率、不减1、不年化、不截断至[0,1]。
% 每一行是一组可匹配的基期队列；开放组不能拆成多个重复分子。
assert(istable(national) && all(ismember({'year','age_start','population'}, ...
    national.Properties.VariableNames)), 'IV:Columns','Missing national input columns.');
for name={'year','age_start','population'}
    x=national.(name{1});
    assert(isnumeric(x) && iscolumn(x) && all(isfinite(x)), ...
        'IV:Numeric','National columns must be finite numeric vectors.');
end
assert(all(national.population>=0),'IV:Negative','Negative population is invalid.');
years=[2000 2010 2020];
assert(isequal(sort(unique(national.year)),years'), ...
    'IV:Years','Require exactly 2000, 2010 and 2020.');
grid=sort(unique(national.age_start));
assert(~isempty(grid),'IV:AgeGrid','Empty national age grid.');
top=grid(end);
assert(top>=80 && isequal(grid,(0:5:top)'), ...
    'IV:AgeGrid','Require complete five-year groups 0,...,T with open group T>=80.');
pop=zeros(numel(grid),3);
for k=1:3
    t=national(national.year==years(k),:);
    [ages,order]=sort(t.age_start);
    assert(isequal(ages,grid),'IV:Incomplete', ...
        'Each national year requires every age group exactly once.');
    pop(:,k)=t.population(order);
end
rates=table();
for k=2:3
    tau=years(k)-2000;
    cut=top-tau;
    regular=grid<cut;
    base_age_start=[grid(regular);cut];
    target_age_start=base_age_start+tau;
    base_population=[pop(regular,1);sum(pop(~regular,1))];
    [found,index]=ismember(target_age_start,grid);
    assert(all(found),'IV:Mapping','Unmatched cohort destination.');
    target_population=pop(index,k);
    assert(all(base_population>0),'IV:ZeroNational', ...
        'National baseline cohort denominators must be positive.');
    g=target_population./base_population;
    assert(all(isfinite(g)),'IV:Numeric','Nonfinite cohort factors.');
    m=numel(g);
    block=table(repmat(2000,m,1),repmat(years(k),m,1),repmat(tau,m,1), ...
        base_age_start,target_age_start,target_age_start==top, ...
        base_population,target_population,g, ...
        'VariableNames',{'base_year','target_year','horizon_years', ...
        'base_age_start','target_age_start','is_open_group', ...
        'base_population','target_population','g'});
    rates=[rates;block]; %#ok<AGROW>
end
end
