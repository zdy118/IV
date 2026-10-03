function test_endogeneity()
% Synthetic tests: no private data, no external toolbox.
n=400;i=(1:n)';
B=[sin(i),cos(i),sin(i*sqrt(2)),cos(i*sqrt(3))];
B=B-mean(B,1);[B,~]=qr(B,0);B=B*sqrt(n);
x=B(:,1);z=B(:,2);v=B(:,3);e=B(:,4);
d=.4*x+z+v;y=2*d+.7*x+1.5*v+e;
for clustered=[false,true]
    group=[];if clustered,group=ceil(i/20);end
    s=iv_diagnostics(y,d,z,x,group);
    assert(abs(s.iv_b-2)<1e-10,'Known 2SLS coefficient failed.');
    assert(s.endog_p<.001,'Synthetic endogeneity not detected.');
    assert(abs(s.ols_b-2.75)<1e-10,'OLS benchmark failed.');
    scaled=iv_diagnostics(y,d,z*7,x,group);
    assert(abs(scaled.iv_b-s.iv_b)<1e-10 && abs(scaled.iv_se-s.iv_se)<1e-10, ...
        'Instrument scaling should not change IV inference.');
    shuffled=iv_diagnostics(flipud(y),flipud(d),flipud(z),flipud(x),flipud(group));
    assert(abs(shuffled.iv_b-s.iv_b)<1e-10,'Row-order invariance failed.');
    assert(s.AR_A*2^2+s.AR_B*2+s.AR_C<=0,'True beta excluded in exact synthetic case.');
end
assert(ar_confidence_set(1,0,-1)=="[-1, 1]");
assert(ar_confidence_set(-1,0,1)=="(-Inf, -1] U [1, Inf)");
assert(ar_confidence_set(-1,0,-1)=="all real");
assert(ar_confidence_set(1,0,1)=="empty");
assert(ar_confidence_set(0,1,-1)=="(-Inf, 1]");
assert(ar_confidence_set(0,-1,1)=="[1, Inf)");
failed=false;
try,iv_diagnostics(y,d,ones(n,1),x,[]);catch ME,failed=strcmp(ME.identifier,'IV:Rank');end
assert(failed,'Constant instrument must fail.');
fprintf('Synthetic endogeneity tests passed.\n');
end
