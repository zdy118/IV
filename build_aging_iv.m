function [result, cohorts] = build_aging_iv(city, national)
%BUILD_AGING_IV 2000 baseline -> 2010/2020 predicted old-age ratios.
% city: city_id (string), year, age_start, population.
% national: year, age_start, population. Counts, not age shares.
% Complete five-year groups starting at 0; final group is open-ended.
% All years/areas must share the same age grid and geographic definition.
% The final open group must start at age >=80 (e.g. 80+, 85+, 100+).
% Inputs are deliberately strict: missing cells are not treated as zeros.

requireColumns(city, {'city_id','year','age_start','population'});
requireColumns(national, {'year','age_start','population'});
city.city_id = string(city.city_id);
assert(~any(ismissing(city.city_id) | strlength(strtrim(city.city_id))==0), ...
    'IV:CityID', 'City IDs cannot be missing/blank.');
validateNumbers(city); validateNumbers(national);
assert(isequal(sort(unique(national.year)), [2000;2010;2020]), ...
    'IV:Years', 'National data must contain exactly 2000, 2010, 2020.');
assert(all(ismember(city.year,[2000 2010 2020])), ...
    'IV:Years', 'City data contain unexpected years.');
grid = sort(unique(national.age_start));
top = grid(end);
assert(top>=80 && isequal(grid,(0:5:top)'), ...
    'IV:AgeGrid', 'Require 0,5,...,top with final open group top>=80.');
nat = zeros(numel(grid),3);
years = [2000 2010 2020];
for k=1:3
    nat(:,k) = getVector(national(national.year==years(k),:),grid);
end
ids = unique(city.city_id,'sorted');
n = numel(ids);
assert(n>0,'IV:Empty','No city observations.');
observed = zeros(n,2); predicted = zeros(n,2);
predA=zeros(n,2); predN=zeros(n,2);
obsA=zeros(n,2); obsN=zeros(n,2);
cohorts = table();
for i=1:n
    local = city(city.city_id==ids(i),:);
    base = getVector(local(local.year==2000,:),grid);
    for k=1:2
        target = years(k+1); tau=target-2000;
        actual = getVector(local(local.year==target,:),grid);
        obsA(i,k)=sum(actual(grid>=60));
        obsN(i,k)=sum(actual(grid>=20));
        assert(obsN(i,k)>0 && obsA(i,k)>0,'IV:Ratio', ...
            'Actual 60+ and 20+ counts must be positive for log ratios.');
        observed(i,k)=obsA(i,k)/obsN(i,k);

        % Top group T+ at target corresponds to ALL baseline ages (T-tau)+.
        % Pool that baseline tail once; never reuse target T+ for each group.
        cut=top-tau;
        regular=grid<cut;
        sourceAge=[grid(regular);cut];
        baseCity=[base(regular);sum(base(~regular))];
        baseNat=[nat(regular,1);sum(nat(~regular,1))];
        destination=sourceAge+tau;
        [found,index]=ismember(destination,grid);
        assert(all(found),'IV:Mapping','Cohort destination not found.');
        targetNat=nat(index,k+1);
        assert(all(baseNat>0),'IV:ZeroNational', ...
            'National baseline cohort counts must be positive.');
        g=targetNat./baseNat;
        p=baseCity.*g;
        predA(i,k)=sum(p(destination>=60));
        predN(i,k)=sum(p(destination>=20));
        assert(predA(i,k)>0 && predN(i,k)>0,'IV:Prediction', ...
            'Predicted 60+ and 20+ counts must be positive.');
        predicted(i,k)=predA(i,k)/predN(i,k);
        m=numel(p);
        block=table(repmat(ids(i),m,1),repmat(target,m,1),sourceAge, ...
            destination,destination==top,baseCity,baseNat,targetNat,g,p, ...
            'VariableNames',{'city_id','target_year','base_age_start', ...
            'target_age_start','is_open_group','base_city_population', ...
            'base_national_population','target_national_population', ...
            'cohort_factor','predicted_population'});
        cohorts=[cohorts;block]; %#ok<AGROW>
    end
end
result=table(ids,obsA(:,1),obsN(:,1),obsA(:,2),obsN(:,2), ...
    predA(:,1),predN(:,1),predA(:,2),predN(:,2), ...
    observed(:,1),observed(:,2),predicted(:,1),predicted(:,2), ...
    log(observed(:,2))-log(observed(:,1)), ...
    log(predicted(:,2))-log(predicted(:,1)), ...
    'VariableNames',{'city_id','actual_60plus_2010','actual_20plus_2010', ...
    'actual_60plus_2020','actual_20plus_2020','pred_60plus_2010', ...
    'pred_20plus_2010','pred_60plus_2020','pred_20plus_2020', ...
    'OR_2010','OR_2020','pred_OR_2010','pred_OR_2020','D','Z'});
end

function requireColumns(t,names)
assert(istable(t) && all(ismember(names,t.Properties.VariableNames)), ...
    'IV:Columns','Input table is missing required columns.');
end

function validateNumbers(t)
for name={'year','age_start','population'}
    x=t.(name{1});
    assert(isnumeric(x) && iscolumn(x) && all(isfinite(x)), ...
        'IV:Numeric','Year, age_start and population must be finite numeric columns.');
end
assert(all(t.population>=0),'IV:Negative','Negative population is invalid.');
assert(all(mod(t.age_start,5)==0 & t.age_start>=0), ...
    'IV:Age','Age starts must be nonnegative multiples of five.');
end

function p=getVector(t,grid)
[ages,order]=sort(t.age_start);
assert(isequal(ages,grid),'IV:Incomplete', ...
    'Each city-year/national-year needs every age group exactly once.');
p=t.population(order);
end
