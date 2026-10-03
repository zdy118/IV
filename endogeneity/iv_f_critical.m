function c=iv_f_critical(alpha,df)
t=betaincinv(alpha,df/2,.5);c=df*(1-t)/t;
end
