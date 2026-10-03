function [results, pretrend] = run_endogeneity(sampleFile, outputDirectory)
%RUN_ENDOGENEITY Matched-sample OLS/2SLS, exogeneity, and weak-IV-robust AR.
% Example: run_endogeneity('endogeneity_sample.csv','matlab_results')
% Input is exported by prepare_endogeneity.do from the original Stata panel.
% Already-log TFP: Y_actual = lnTFP2020 - lnTFP2010; never log again.
% No Statistics/Econometrics Toolbox needed. No raw data are bundled.
if nargin<1, sampleFile='endogeneity_sample.csv'; end
if nargin<2, outputDirectory='matlab_endogeneity_results'; end
T=readtable(sampleFile,'VariableNamingRule','preserve');
required={'city_id','province','D','Z','Y_actual','Y_frontier', ...
    'Y_actual_w','Y_frontier_w','ln_pop0','edu0','ln_budget0','age0','age0_sq', ...
    'Y_pre','ln_pop_pre','edu_pre','ln_budget_pre'};
assert(all(ismember(required,T.Properties.VariableNames)), 'IV:Columns','Missing required columns.');
assert(numel(unique(T.city_id))==height(T),'IV:Duplicate','One row per city is required.');
assert(height(T)>10,'IV:Sample','Insufficient sample.');
assert(all(T.province==floor(T.city_id/10000)),'IV:Province','Province/code mismatch.');
core=required(1:13);
assert(all(isfinite(T{:,core}),'all'),'IV:Missing','Nonfinite main-sample values; use sample_audit.csv.');
assert(all(isfinite(T.age0_sq)),'IV:Missing','Missing squared age.');
assert(max(abs(T.age0_sq-T.age0.^2))<1e-8,'IV:Age','Age square mismatch.');
if all(ismember({'OR2010','OR2020','predOR2010','predOR2020'},T.Properties.VariableNames))
    assert(all(T.OR2010>0 & T.OR2020>0 & T.predOR2010>0 & T.predOR2020>0),'IV:Ratio','Nonpositive ratio.');
    assert(max(abs(T.D-log(T.OR2020./T.OR2010)))<1e-10,'IV:D','D definition mismatch.');
    assert(max(abs(T.Z-log(T.predOR2020./T.predOR2010)))<1e-10,'IV:Z','Z definition mismatch.');
end
results=table();
for outcome=["Y_actual","Y_frontier","Y_actual_w","Y_frontier_w"]
    for specification=["baseline","province","age"]
        X=T{:,{'ln_pop0','edu0','ln_budget0'}};
        if specification=="age", X=[X,T.age0,T.age0_sq]; end
        if specification=="province"
            provinces=unique(T.province);
            X=[X,double(T.province==provinces(2:end)')]; % first province omitted
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
% Pretrend diagnostic: control only for 2004 attributes, not 2009 attributes.
m=all(isfinite(T{:,{'Y_pre','Z','ln_pop_pre','edu_pre','ln_budget_pre'}}),2);
B=[ones(sum(m),1),T{m,{'ln_pop_pre','edu_pre','ln_budget_pre','Z'}}];
p=iv_linear_fit(T.Y_pre(m),B,T.province(m));
F=p.b(end)^2/p.V(end,end);
pretrend=table(sum(m),numel(unique(T.province(m))),p.b(end),sqrt(p.V(end,end)), ...
    F,iv_f_tail(F,p.df),'VariableNames',{'N','clusters','Z_b','Z_se','F','p'});
if ~isfolder(outputDirectory), mkdir(outputDirectory); end
writetable(results,fullfile(outputDirectory,'endogeneity_results.csv'));
writetable(pretrend,fullfile(outputDirectory,'pretrend_diagnostic.csv'));
disp(results); disp(pretrend);
end
