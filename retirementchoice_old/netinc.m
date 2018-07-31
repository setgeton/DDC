% computing net income; tax free income = 80
function[y,tax] = netinc(earn,t);
               tax = (t*(earn - 0.800).*(earn>0.800));
               y = earn - tax;
end