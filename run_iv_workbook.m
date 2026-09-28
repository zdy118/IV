% Entry point for the user's original wide workbook; source remains unchanged.
root=fileparts(mfilename('fullpath'));
cityWorkbook='D:\SZU\aging&TFP&labour\aging\IV\iv-essential data.xlsx';
nationalFile=fullfile(root,'data','national_age.csv');
% IMPORTANT: false until the 45-49 female header is verified as a typo.
confirm4549BothSexes=false;
city=read_city_workbook(cityWorkbook,confirm4549BothSexes);
assert(isfile(nationalFile),'IV:MissingNational', ...
    'Supply nationwide counts for 2000/2010/2020 in data/national_age.csv.');
national=readtable(nationalFile,'VariableNamingRule','preserve');
[iv,cohorts]=build_aging_iv(city,national);
outputDir=fullfile(root,'results');
if ~exist(outputDir,'dir'), mkdir(outputDir); end
writetable(iv,fullfile(outputDir,'iv_2010_2020.csv'));
writetable(cohorts,fullfile(outputDir,'cohort_audit.csv'));
save(fullfile(outputDir,'iv_2010_2020.mat'),'iv','cohorts');
fprintf('Saved %d cities to %s\n',height(iv),outputDir);
