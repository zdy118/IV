% Entry point for the user's original wide workbook; source remains unchanged.
root=fileparts(mfilename('fullpath'));
dataDir='D:\SZU\aging&TFP&labour\aging\IV';
% Updated file has the corrected both-sex age label; keep filename explicit.
cityWorkbook=fullfile(dataDir,'iv-essential data2.xlsx');
nationalFile=fullfile(dataDir,'total.xlsx');
% Corrected both-sex header is accepted automatically by the reader.
confirm4549BothSexes=false;
% Change only after checking the original statistical source, never to force a run.
allowReviewedNationalOutliers=false;
allowReviewedCityOutliers=false;
% "national" implements the document. "sample_aggregate" is an explicit
% alternative design, only after choosing to use the covered-city aggregate.
referenceScope="national";
assert(ismember(referenceScope,["national","sample_aggregate"]));
[city,cityNames]=read_city_workbook(cityWorkbook,confirm4549BothSexes);
national=read_national_workbook(nationalFile);
audit=audit_national_counts(national);
cityAudit=audit_city_counts(city);
coverage=compare_reference_coverage(city,national);
% Separate each attempt so failed validation cannot expose stale IV output.
resultRoot=fullfile(root,'results');
if ~exist(resultRoot,'dir'), mkdir(resultRoot); end
outputDir=tempname(resultRoot);
mkdir(outputDir);
writetable(audit,fullfile(outputDir,'national_data_audit.csv'));
writetable(cityAudit,fullfile(outputDir,'city_data_audit.csv'));
writetable(coverage,fullfile(outputDir,'reference_coverage_audit.csv'));
fprintf('Diagnostics saved to %s\n',outputDir);
disp(audit);
disp(cityAudit(cityAudit.requires_review,:));
assert(~any(cityAudit.requires_review) || allowReviewedCityOutliers, ...
    'IV:CityOutlier','City age counts require review; see city_data_audit.csv.');
assert(~any(audit.requires_review) || allowReviewedNationalOutliers, ...
    'IV:NationalOutlier', ...
    ['National counts require review; see national_data_audit.csv. ', ...
    'Check source cells before calculating an IV. No counts are corrected automatically.']);
assert(referenceScope~="national" || ~all(coverage.equals_sample), ...
    'IV:ReferenceCoverage', ...
    ['Reference counts equal the study-city sums in every cell. Supply independent ', ...
    'nationwide data, or explicitly choose sample_aggregate as an alternative design.']);
[iv,cohorts]=build_aging_iv(city,national);
iv=join(iv,cityNames,'Keys','city_id');
iv.reference_scope=repmat(referenceScope,height(iv),1);
writetable(city,fullfile(outputDir,'city_age_standardized.csv'));
writetable(national,fullfile(outputDir,'national_age_standardized.csv'));
writetable(iv,fullfile(outputDir,'iv_2010_2020.csv'));
writetable(cohorts,fullfile(outputDir,'cohort_audit.csv'));
save(fullfile(outputDir,'iv_2010_2020.mat'),'iv','cohorts','audit', ...
    'cityWorkbook','nationalFile','allowReviewedNationalOutliers');
save(fullfile(outputDir,'iv_2010_2020.mat'),'referenceScope', ...
    'allowReviewedCityOutliers','cityAudit','coverage','-append');
fprintf('Saved %d cities to %s\n',height(iv),outputDir);
