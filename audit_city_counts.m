function audit=audit_city_counts(city)
% Flag gross within-city age concentration; do not modify any observations.
[group,ids,years]=findgroups(city.city_id,city.year);
total=splitapply(@sum,city.population,group);
largest=splitapply(@max,city.population,group);
share=largest./total;
requires_review=~isfinite(share) | share>0.5;
audit=table(ids,years,total,largest,share,requires_review, ...
    'VariableNames',{'city_id','year','total_population', ...
    'largest_age_group_population','largest_age_group_share','requires_review'});
end
