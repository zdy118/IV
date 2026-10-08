function [results, pretrend] = run_endogeneity(sampleFile, outputDirectory)
%RUN_ENDOGENEITY 根据原始表头完成长差分OLS、2SLS及内生性检验。
% 默认读取当前目录eng-sample.xls；表内24个变量名原样保留。
% 示例：run_endogeneity('D:/SZU/aging&TFP&labour/aging/IV/eng-sample.xls')
% Y_actual等已是对数TFP长差分，不再次取对数；D、Z直接使用表中值。
% 输出24组结果、事前趋势诊断和中文摘要；估计不需要额外工具箱。
if nargin<1, sampleFile='eng-sample.xls'; end
if nargin<2, outputDirectory='matlab_endogeneity_results'; end
T=read_endogeneity_sample(sampleFile);
results=table();
for outcome=["Y_actual","Y_frontier","Y_actual_w","Y_frontier_w"]
    for specification=["baseline","province","age"]
        X=T{:,{'ln_pop0','edu0','ln_budget0'}};
        if specification=="age", X=[X,T.age0,T.age0_sq]; end
        if specification=="province"
            provinces=unique(T.province);
            X=[X,double(T.province==provinces(2:end)')]; % 省份虚拟变量省略第一类作为参照
        end
        for vce=["HC1","province"]
            cluster=[];
            if vce=="province", cluster=T.province; end
            s=iv_diagnostics(T.(outcome),T.D,T.Z,X,cluster);
            row=struct2table(s);
            row=addvars(row,outcome,specification,vce,'Before',1);
            results=[results;row]; %#ok<AGROW>
        end
    end
end
% 事前趋势诊断只控制2004年特征，不使用2009年特征。
m=all(isfinite(T{:,{'Y_pre','Z','ln_pop_pre','edu_pre','ln_budget_pre'}}),2);
B=[ones(sum(m),1),T{m,{'ln_pop_pre','edu_pre','ln_budget_pre','Z'}}];
p=iv_linear_fit(T.Y_pre(m),B,T.province(m));
F=p.b(end)^2/p.V(end,end);
pretrend=table(sum(m),numel(unique(T.province(m))),p.b(end),sqrt(p.V(end,end)), ...
    F,iv_f_tail(F,p.df),'VariableNames',{'N','clusters','Z_b','Z_se','F','p'});
if ~isfolder(outputDirectory), mkdir(outputDirectory); end
writetable(results,fullfile(outputDirectory,'endogeneity_results.csv'));
writetable(pretrend,fullfile(outputDirectory,'pretrend_diagnostic.csv'));
summary=write_endogeneity_summary(results,pretrend,outputDirectory);
disp(summary);
end
