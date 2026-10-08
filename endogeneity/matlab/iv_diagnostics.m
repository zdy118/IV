function s=iv_diagnostics(y,d,z,X,cluster)
% 单内生变量D、单排除工具Z的完整检验；因变量由原表Y_actual等列传入。
% 所有模型采用同一样本，支持HC1或省级CR1；不机械套用Stock–Yogo阈值。
y=double(y(:));d=double(d(:));z=double(z(:));X=double(X);
n=numel(y);C=[ones(n,1),X];Q=[C,z];A=[C,d];k=size(A,2);
assert(size(X,1)==n && numel(d)==n && numel(z)==n,'IV:Size','Dimension mismatch.');
assert(all(isfinite([y,d,z,X]),'all'),'IV:Missing','Missing/nonfinite observations.');
assert(rank(Q)==size(Q,2) && rank(A)==k,'IV:Rank','Collinear regressors/instruments.');
fs=iv_linear_fit(d,Q,cluster);ols=iv_linear_fit(y,A,cluster);
restricted=iv_linear_fit(d,C,cluster);
% Actual structural residual y-A*b is required in the 2SLS sandwich.
H=Q*(Q\A);
assert(rcond(H'*A)>1e-14,'IV:Identification','Singular/near-singular instrumented design.');
b=(H'*A)\(H'*y);u=y-A*b;
[V,df,G]=iv_sandwich(H,u,H'*A,cluster,k);
aug=iv_linear_fit(y,[A,fs.e],cluster);
rf=iv_linear_fit(y,Q,cluster);
% Covariance of reduced-form coefficients on Z (same Q and same VCE).
rz=z-C*(C\z);zz=rz'*rz;
sy=rz.*rf.e/zz;sd=rz.*fs.e/zz;
if isempty(cluster)
    cross=n/(n-k)*(sy'*sd);
else
    [~,~,g]=unique(cluster);
    cross=G/(G-1)*(n-1)/(n-k)* ...
        (accumarray(g,sy)'*accumarray(g,sd));
end
crit=iv_f_critical(.05,rf.df);
a=fs.b(end)^2-crit*fs.V(end,end);
bb=-2*rf.b(end)*fs.b(end)+2*crit*cross;
c=rf.b(end)^2-crit*rf.V(end,end);
s.N=n;s.clusters=G;s.ols_b=ols.b(end);s.ols_se=sqrt(ols.V(end,end));
s.iv_b=b(end);s.iv_se=sqrt(V(end,end));s.iv_p=iv_f_tail(b(end)^2/V(end,end),df);
s.first_b=fs.b(end);s.first_se=sqrt(fs.V(end,end));
s.first_F=fs.b(end)^2/fs.V(end,end);s.first_p=iv_f_tail(s.first_F,fs.df);
s.partial_R2=1-(fs.e'*fs.e)/(restricted.e'*restricted.e);
s.endog_F=aug.b(end)^2/aug.V(end,end);s.endog_p=iv_f_tail(s.endog_F,aug.df);
s.AR0_F=rf.b(end)^2/rf.V(end,end);s.AR0_p=iv_f_tail(s.AR0_F,rf.df);
s.AR_A=a;s.AR_B=bb;s.AR_C=c;s.AR_critical=crit;
s.AR95=ar_confidence_set(a,bb,c);
end
