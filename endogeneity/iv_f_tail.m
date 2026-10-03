function p=iv_f_tail(F,df)
% Upper tail of F(1,df), avoiding a Statistics Toolbox dependency.
assert(df>0 && F>=0,'IV:Statistic','Invalid F/df.');
p=betainc(df/(df+F),df/2,.5);
end
