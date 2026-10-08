function T=read_endogeneity_sample(sampleFile)
%READ_ENDOGENEITY_SAMPLE 按eng-sample.xls原始变量名读取并校验样本。
% 不翻译、缩写或重命名输入变量；按列名读取，不依赖Excel列顺序。
% 同时支持拥有完全相同表头的XLSX或CSV，默认读取Excel第一张表。
if nargin<1, sampleFile='eng-sample.xls'; end
T=readtable(sampleFile,'VariableNamingRule','preserve');
required={'city_id','city_name','OR2010','OR2020','predOR2010','predOR2020', ...
    'D','Z','panel_city','edu_pre','ln_pop_pre','ln_budget_pre','age0','edu0', ...
    'ln_pop0','ln_budget0','Y_actual','Y_frontier','Y_actual_w','Y_frontier_w', ...
    'Y_pre','age0_sq','sample_ok','province'};
missingNames=setdiff(required,T.Properties.VariableNames,'stable');
assert(isempty(missingNames),'IV:Columns','缺少原表变量：%s',strjoin(missingNames,', '));
numericNames=setdiff(required,{'city_name','panel_city'},'stable');
for j=1:numel(numericNames)
    assert(isnumeric(T.(numericNames{j})),'IV:Type', ...
        '变量%s必须为数值型；请核对Excel中的文本或缺失标记。',numericNames{j});
end
assert(height(T)>10,'IV:Sample','样本量不足。');
assert(all(isfinite(T.city_id) & T.city_id==fix(T.city_id) & ...
    T.city_id>=100000 & T.city_id<=999999),'IV:CityID','city_id必须为六位整数编码。');
assert(numel(unique(T.city_id))==height(T),'IV:Duplicate','每个city_id必须只有一行。');
assert(all(T.sample_ok==1),'IV:SampleFlag','sample_ok含非1记录，请先核实估计样本。');
assert(all(T.province==floor(T.city_id/10000)),'IV:Province','province与city_id前两位不一致。');
assert(all(~ismissing(string(T.city_name)) & strlength(string(T.city_name))>0) && ...
    all(string(T.city_name)==string(T.panel_city)),'IV:CityName','city_name与panel_city须非空且一致。');
core=setdiff(numericNames,{'Y_pre','edu_pre','ln_pop_pre','ln_budget_pre'},'stable');
assert(all(isfinite(T{:,core}),'all'),'IV:Missing','主回归变量存在缺失或非有限值。');
assert(max(abs(T.age0_sq-T.age0.^2))<1e-8,'IV:Age','age0_sq不等于age0平方。');
assert(all(T.OR2010>0 & T.OR2020>0 & T.predOR2010>0 & T.predOR2020>0), ...
    'IV:Ratio','实际和预测老龄化比率必须为正。');
assert(max(abs(T.D-log(T.OR2020./T.OR2010)))<1e-10,'IV:D','D与实际比率对数变化不一致。');
assert(max(abs(T.Z-log(T.predOR2020./T.predOR2010)))<1e-10,'IV:Z','Z与预测比率对数变化不一致。');
end
