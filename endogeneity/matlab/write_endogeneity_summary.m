function summary=write_endogeneity_summary(results,pretrend,outputDirectory)
%WRITE_ENDOGENEITY_SUMMARY 输出中文摘要，保留D、Z及各Y的原始变量名。
% 摘要根据本次结果生成，不写死系数、显著性或内生性结论。
r=results(results.outcome=="Y_actual" & results.specification=="baseline" & ...
    results.vce=="province",:);
assert(height(r)==1,'IV:Summary','无法唯一定位Y_actual基准省级聚类结果。');
if r.endog_p<.05
    conclusion="在5%水平拒绝D外生的原假设；该判断以工具变量有效等识别条件为前提。";
else
    conclusion="在5%水平未拒绝D外生的原假设；这不证明D或Z外生，也不自动决定采用OLS。";
end
arText=replace(string(r.AR95),["all real","empty","-Inf","Inf"," U "], ...
    ["全体实数","空集","负无穷","正无穷"," 并 "]);
summary=join([
    "内生性检验结果摘要"
    "研究区间：2010—2020年；每个city_id对应一个城市。"
    "因变量：Y_actual；内生解释变量：D；排除工具变量：Z。"
    "基准控制：ln_pop0、edu0、ln_budget0；标准误按province聚类。"
    string(sprintf('估计样本：%d个城市，%d个省级聚类。',r.N,r.clusters))
    string(sprintf('OLS：系数=%.4f，标准误=%.4f。',r.ols_b,r.ols_se))
    string(sprintf('2SLS：系数=%.4f，标准误=%.4f，p值=%.4g。',r.iv_b,r.iv_se,r.iv_p))
    string(sprintf('第一阶段：Z系数=%.4f，排除工具F=%.2f，偏R平方=%.4f。',r.first_b,r.first_F,r.partial_R2))
    string(sprintf('稳健内生性检验：F=%.4f，p值=%.4g。',r.endog_F,r.endog_p))
    conclusion
    "Anderson–Rubin 95%置信集合："+arText+"。"
    string(sprintf('AR零效应检验p值=%.4g；弱识别稳健推断仍依赖工具外生等条件。',r.AR0_p))
    string(sprintf('事前趋势诊断：样本%d，Z系数=%.4f，p值=%.4g；不能据此证明排除性。',pretrend.N,pretrend.Z_b,pretrend.p))
    "当前为一个Z对应一个D的恰好识别模型，不能进行过度识别检验。"
    string(sprintf('完整结果共%d组，包含Y_actual、Y_frontier、Y_actual_w和Y_frontier_w。',height(results)))
    "第一阶段F不检验工具外生性；不将其机械对比同方差Stock–Yogo阈值。"
    "Y_actual等已经是对数TFP的长差分，不再次取对数。"
    ],newline);
fid=fopen(fullfile(outputDirectory,'内生性检验摘要.txt'),'w','n','UTF-8');
assert(fid>=0,'IV:SummaryFile','无法写入中文摘要文件。');
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',char(summary));
% 便于阅读的中文结果表；数值字段名称只在此展示副本中翻译。
view=results(:,{'outcome','specification','vce','N','clusters','ols_b','ols_se', ...
    'iv_b','iv_se','iv_p','first_F','partial_R2','endog_F','endog_p','AR0_p','AR95'});
view.specification=replace(string(view.specification),["baseline","province","age"], ...
    ["基准控制","加入省份固定效应","加入基期年龄及平方"]);
view.vce=replace(string(view.vce),["HC1","province"],["异方差稳健","按省聚类"]);
view.AR95=replace(string(view.AR95),["all real","empty","-Inf","Inf"," U "], ...
    ["全体实数","空集","负无穷","正无穷"," 并 "]);
view.Properties.VariableNames={'因变量','模型设定','标准误类型','样本量','省级聚类数', ...
    'OLS系数','OLS标准误','两阶段系数','两阶段标准误','两阶段p值','第一阶段F', ...
    '第一阶段偏R平方','内生性检验F','内生性检验p值','AR零效应p值','AR百分之95置信集合'};
writetable(view,fullfile(outputDirectory,'内生性检验摘要.csv'),'Encoding','UTF-8');
end
