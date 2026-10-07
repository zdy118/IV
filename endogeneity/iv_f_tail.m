function p=iv_f_tail(F,df)
% 计算F(1,df)分布上尾概率，不依赖统计工具箱。
assert(df>0 && F>=0,'IV:Statistic','Invalid F/df.');
p=betainc(df/(df+F),df/2,.5);
end
