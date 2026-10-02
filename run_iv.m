% Edit file paths below, then run this script (MATLAB R2020b or later).
% Source counts stay local; outputs are written to results/.
root=fileparts(mfilename('fullpath'));
cityFile=fullfile(root,'data','city_age.csv');
nationalFile=fullfile(root,'data','national_age.csv');
outputDir=fullfile(root,'results');

% Keep city codes as strings, including any leading zeros.
opts=detectImportOptions(cityFile,'VariableNamingRule','preserve');
opts=setvartype(opts,'city_id','string');
city=readtable(cityFile,opts);
national=readtable(nationalFile,'VariableNamingRule','preserve');
[iv,cohorts,nationalRates]=build_aging_iv(city,national);
if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(iv,fullfile(outputDir,'iv_2010_2020.csv'));
writetable(cohorts,fullfile(outputDir,'cohort_audit.csv'));
writetable(nationalRates,fullfile(outputDir,'national_cohort_rates.csv'));
save(fullfile(outputDir,'iv_2010_2020.mat'),'iv','cohorts','nationalRates');
disp(iv(1:min(10,height(iv)),:));
fprintf('Saved %d city IV observations to %s\n',height(iv),outputDir);
