function text=ar_confidence_set(a,b,c)
% All real beta satisfying a*beta^2+b*beta+c<=0, including unbounded sets.
assert(all(isfinite([a,b,c])),'IV:AR','Nonfinite polynomial.');
if a==0
    if b>0,text=string(sprintf('(-Inf, %.8g]',-c/b));
    elseif b<0,text=string(sprintf('[%.8g, Inf)',-c/b));
    elseif c<=0,text="all real";
    else,text="empty";end
    return
end
disc=b*b-4*a*c;
if disc<0
    if a<0,text="all real";else,text="empty";end
    return
end
% Stable quadratic roots, including repeated roots.
if disc==0
    r=[-b/(2*a),-b/(2*a)];
else
    sg=1;if b<0,sg=-1;end
    q=-.5*(b+sg*sqrt(disc));r=sort([q/a,c/q]);
end
if a>0,text=string(sprintf('[%.8g, %.8g]',r(1),r(2)));
else,text=string(sprintf('(-Inf, %.8g] U [%.8g, Inf)',r(1),r(2)));end
end
