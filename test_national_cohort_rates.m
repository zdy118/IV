function test_national_cohort_rates
% Hand-computed factors and pooled-tail identities; synthetic counts only.
for top=[80 85]
    grid=(0:5:top)'; n=numel(grid);
    national=table(repelem([2000;2010;2020],n),repmat(grid,3,1), ...
        [100*ones(n,1);120*ones(n,1);80*ones(n,1)], ...
        'VariableNames',{'year','age_start','population'});
    rates=compute_national_cohort_rates(national);
    for target=[2010 2020]
        t=rates(rates.target_year==target,:);
        tau=target-2000;
        expected=1.2; pooled=0.4;
        if target==2020, expected=0.8; pooled=0.16; end
        assert(all(abs(t.g(~t.is_open_group)-expected)<1e-12));
        assert(sum(t.is_open_group)==1);
        assert(abs(t.g(t.is_open_group)-pooled)<1e-12);
        assert(t.base_age_start(end)==top-tau && t.target_age_start(end)==top);
        assert(sum(t.base_population)==100*n); % Each baseline person once.
        assert(all(t.target_age_start-t.base_age_start==tau));
    end
    assert(isequal(rates,compute_national_cohort_rates(national(end:-1:1,:))));
    city=addvars(national,repmat("001",height(national),1), ...
        'Before',1,'NewVariableNames','city_id');
    [~,cohorts,shared]=build_aging_iv(city,national);
    assert(isequal(shared,rates));
    assert(isequal(cohorts.cohort_factor,rates.g));
    bad=national; bad.population(1)=0;
    mustFail(@()compute_national_cohort_rates(bad),'IV:ZeroNational');
    mustFail(@()compute_national_cohort_rates(national(2:end,:)),'IV:Incomplete');
    mustFail(@()compute_national_cohort_rates([national;national(1,:)]),'IV:Incomplete');
    bad=national; bad.population(1)=NaN;
    mustFail(@()compute_national_cohort_rates(bad),'IV:Numeric');
    bad=national; bad.population(1)=-1;
    mustFail(@()compute_national_cohort_rates(bad),'IV:Negative');
end
fprintf('All national cohort rate tests passed.\n');
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
