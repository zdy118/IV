function [V,df,G]=iv_sandwich(H,u,bread,cluster,k)
% 用回归设计和结构残差计算HC1或省级CR1三明治协方差。
n=size(H,1);S=H.*u;
assert(n>k,'IV:Sample','No residual degrees of freedom.');
if isempty(cluster)
    adj=n/(n-k);df=n-k;G=NaN;
else
    assert(numel(cluster)==n && all(isfinite(cluster)),'IV:Cluster','Invalid clusters.');
    [~,~,g]=unique(cluster);G=max(g);
    assert(G>1,'IV:Cluster','At least two clusters required.');
    SS=zeros(G,size(S,2));
    for j=1:size(S,2),SS(:,j)=accumarray(g,S(:,j));end
    S=SS;adj=G/(G-1)*(n-1)/(n-k);df=G-1;
end
V=adj*(bread\(S'*S)/bread');V=(V+V')/2;
end
