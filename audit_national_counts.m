function audit=audit_national_counts(national)
% Data-quality diagnostics; thresholds flag review, not mortality restrictions.
% g remains unmodified, including values greater than one.
years=[2000 2010 2020];
totals=zeros(3,1); maxShare=zeros(3,1); relativeTo2000=zeros(3,1);
for k=1:3
    p=national.population(national.year==years(k));
    assert(~isempty(p) && all(isfinite(p)) && all(p>=0) && sum(p)>0, ...
        'IV:NationalAudit','Missing/invalid national population data.');
    totals(k)=sum(p); maxShare(k)=max(p)/totals(k);
end
relativeTo2000=totals/totals(1);
% A five-year/open-age bin above 25% or a >2x/<0.5x census total
% requires explicit review in this Chinese census application.
requires_review=maxShare>0.25 | relativeTo2000>2 | relativeTo2000<0.5;
audit=table(years',totals,maxShare,relativeTo2000,requires_review, ...
    'VariableNames',{'year','total_population','largest_age_group_share', ...
    'total_relative_to_2000','requires_review'});
end
