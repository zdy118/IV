function compare_stata_results(stataCsv, matlabCsv)
% Optional cross-language check using files generated from identical sample.
a=readtable(stataCsv,'TextType','string');b=readtable(matlabCsv,'TextType','string');
keys={'outcome','specification','vce'};
a=sortrows(a,keys);b=sortrows(b,keys);
assert(isequal(a{:,keys},b{:,keys}),'IV:Models','Different specifications.');
fields={'N','ols_b','ols_se','iv_b','iv_se','iv_p','first_b','first_se', ...
    'first_F','first_p','partial_R2','endog_F','endog_p','AR0_F','AR0_p', ...
    'AR_A','AR_B','AR_C','AR_critical'};
for j=1:numel(fields)
    av=a.(fields{j});bv=b.(fields{j});
    assert(all(abs(av-bv)<=1e-7*(1+abs(av))), 'IV:Mismatch','Mismatch in %s',fields{j});
end
fprintf('Stata/MATLAB numeric comparison passed for %d models.\n',height(a));
end
