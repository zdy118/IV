% 只计算全国g，不需要城市或TFP数据。MATLAB R2020b+，无额外工具箱。
root=fileparts(mfilename('fullpath'));
nationalFile='D:\SZU\aging&TFP&labour\aging\IV\total_national.xlsx';
national=read_national_workbook(nationalFile);
audit=audit_national_counts(national);
disp(audit);
assert(~any(audit.requires_review),'IV:NationalOutlier', ...
    'National counts require source review before computing g.');
nationalRates=compute_national_cohort_rates(national);
resultRoot=fullfile(root,'results');
if ~exist(resultRoot,'dir'), mkdir(resultRoot); end
outputDir=tempname(resultRoot); mkdir(outputDir);
writetable(nationalRates,fullfile(outputDir,'national_cohort_rates.csv'));
writetable(audit,fullfile(outputDir,'national_data_audit.csv'));
save(fullfile(outputDir,'national_cohort_rates.mat'),'nationalRates','national','audit','nationalFile');
disp(nationalRates);
fprintf('National cohort rates saved to %s\n',outputDir);
