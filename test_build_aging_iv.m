function test_build_aging_iv
% Synthetic data only. Tests use independent aggregate calculations.
grid=(0:5:80)';
national=table(repelem([2000;2010;2020],17),repmat(grid,3,1), ...
    [100*ones(17,1);120*ones(17,1);80*ones(17,1)], ...
    'VariableNames',{'year','age_start','population'});
city=addvars(national,repmat("001",51,1),'Before',1,'NewVariableNames','city_id');
city.population=city.population*0.1;
[r,c]=build_aging_iv(city,national);
% A city proportional to nation must reproduce target national ratios.
assert(abs(r.pred_OR_2010-5/13)<1e-12);
assert(abs(r.pred_OR_2020-5/13)<1e-12);
assert(abs(r.Z)<1e-12 && abs(r.D)<1e-12);
assert(any(c.cohort_factor>1)); % Never cap national ratios at one.
a=audit_national_counts(national);
assert(~any(a.requires_review));
badNational=national;
badNational.population(badNational.year==2010 & badNational.age_start==40)=12000603484;
a=audit_national_counts(badNational);
assert(a.requires_review(a.year==2010));
ca=audit_city_counts(city);
assert(~any(ca.requires_review));
badCity=city; badCity.population(1)=1e10;
ca=audit_city_counts(badCity);
assert(any(ca.requires_review));
reference=national; reference.population=reference.population*0.1;
coverage=compare_reference_coverage(city,reference);
assert(all(coverage.equals_sample));
coverage=compare_reference_coverage(city,national);
assert(~any(coverage.equals_sample));
% Nonuniform baseline distinguishes horizons and tests open-tail pooling.
city.population(1:17)=(1:17)';
[r,c]=build_aging_iv(city,national);
expected10=(sum(11:14)*1.2+sum(15:17)*0.4)/ ...
    (sum(3:14)*1.2+sum(15:17)*0.4);
expected20=(sum(9:12)*0.8+sum(13:17)*0.16)/ ...
    (sum(1:12)*0.8+sum(13:17)*0.16);
assert(abs(r.pred_OR_2010-expected10)<1e-12);
assert(abs(r.pred_OR_2020-expected20)<1e-12);
assert(abs(r.Z-log(expected20/expected10))<1e-12);
assert(sum(c.is_open_group)==2);
assert(isequal(r.city_id,"001"));
% Later local counts affect D but cannot enter the instrument.
city2=city; city2.population(city2.year==2020 & city2.age_start>=60)=200;
r2=build_aging_iv(city2,national);
assert(r2.Z==r.Z && r2.D~=r.D);
% Row order is irrelevant; malformed data fail loudly.
r3=build_aging_iv(city(end:-1:1,:),national(end:-1:1,:));
assert(isequal(r,r3));
mustFail(@()build_aging_iv(city(2:end,:),national),'IV:Incomplete');
mustFail(@()build_aging_iv([city;city(1,:)],national),'IV:Incomplete');
bad=city; bad.population(1)=NaN;
mustFail(@()build_aging_iv(bad,national),'IV:Numeric');
bad=national; bad.population(1)=0;
mustFail(@()build_aging_iv(city,bad),'IV:ZeroNational');
fprintf('All build_aging_iv tests passed.\n');
end
function mustFail(f,id)
try
    f();
catch e
    assert(strcmp(e.identifier,id),'Unexpected error: %s',e.message);
    return
end
error('Expected failure %s did not occur.',id);
end
