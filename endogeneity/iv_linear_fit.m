function r=iv_linear_fit(y,A,cluster)
% OLS with HC1/CR1, including all estimated regressors in degrees of freedom.
assert(all(isfinite([y,A]),'all'),'IV:Missing','Nonfinite data.');
assert(rank(A)==size(A,2),'IV:Rank','Collinear design.');
r.b=A\y;r.e=y-A*r.b;
[r.V,r.df,r.G]=iv_sandwich(A,r.e,A'*A,cluster,size(A,2));
end
