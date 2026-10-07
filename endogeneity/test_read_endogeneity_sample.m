function test_read_endogeneity_sample(sampleFile)
%TEST_READ_ENDOGENEITY_SAMPLE 校验原表列名、乱序、重复键及错误定义的拦截。
% 可选：test_read_endogeneity_sample('eng-sample.xls')检验真实输入。
if nargin>0
    T=read_endogeneity_sample(sampleFile);
    fprintf('实际文件校验完成：%d个城市，列名按原表保留。\n',height(T));
end
n=20;T=table();
T.city_id=(130100:100:132000)';T.city_name="测试城市"+string((1:n)');
T.OR2010=repmat(.2,n,1);T.OR2020=repmat(.25,n,1);
T.predOR2010=repmat(.18,n,1);T.predOR2020=repmat(.23,n,1);
T.D=log(T.OR2020./T.OR2010);T.Z=log(T.predOR2020./T.predOR2010);
T.panel_city=T.city_name;T.edu_pre=repmat(8,n,1);T.ln_pop_pre=repmat(5,n,1);
T.ln_budget_pre=repmat(7,n,1);T.age0=repmat(35,n,1);T.edu0=repmat(9,n,1);
T.ln_pop0=repmat(6,n,1);T.ln_budget0=repmat(8,n,1);
T.Y_actual=repmat(.1,n,1);T.Y_frontier=T.Y_actual;
T.Y_actual_w=T.Y_actual;T.Y_frontier_w=T.Y_actual;
T.Y_pre=repmat(.05,n,1);T.age0_sq=T.age0.^2;T.sample_ok=ones(n,1);
T.province=floor(T.city_id/10000);
file=[tempname,'.csv'];cleanup=onCleanup(@()delete(file)); %#ok<NASGU>
writetable(T,file);loaded=read_endogeneity_sample(file);
assert(isequal(loaded.Properties.VariableNames,T.Properties.VariableNames),'原始变量名发生变化。');
writetable(T(:,end:-1:1),file);loaded=read_endogeneity_sample(file);
assert(max(abs(loaded.D-T.D))<1e-12,'乱序列的读取不正确。');
bad=T;bad.D(1)=.9;expectFailure(bad,file,'IV:D');
bad=T;bad.city_id(2)=bad.city_id(1);expectFailure(bad,file,'IV:Duplicate');
bad=T;bad.sample_ok(1)=0;expectFailure(bad,file,'IV:SampleFlag');
bad=T;bad.Properties.VariableNames{'Y_actual'}='YActual';expectFailure(bad,file,'IV:Columns');
fprintf('输入列名与数据校验测试完成。\n');
end

function expectFailure(T,file,identifier)
writetable(T,file);failed=false;
try,read_endogeneity_sample(file);catch ME,failed=strcmp(ME.identifier,identifier);end
assert(failed,'未按预期拦截错误输入：%s',identifier);
end
