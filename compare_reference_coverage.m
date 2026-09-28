function coverage=compare_reference_coverage(city,reference)
% Exact equality is evidence of sample aggregation, not proof of provenance.
[g,years,ages]=findgroups(city.year,city.age_start);
sample=table(years,ages,splitapply(@sum,city.population,g), ...
    'VariableNames',{'year','age_start','sample_population'});
coverage=innerjoin(reference,sample,'Keys',{'year','age_start'});
assert(height(coverage)==height(reference) && height(sample)==height(reference), ...
    'IV:Coverage','Reference and city age/year coverage differs.');
coverage.difference=coverage.population-coverage.sample_population;
coverage.equals_sample=abs(coverage.difference)<1e-8;
end
