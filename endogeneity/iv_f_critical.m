function c=iv_f_critical(alpha,df)
% 计算F(1,df)分布的上尾临界值，不依赖统计工具箱。
t=betaincinv(alpha,df/2,.5);c=df*(1-t)/t;
end
