    % flowutility
function[u] = flowutility(param,grinc,nw,W,t,ev)
gamm   = param(1);
thet   = param(2);
alph   = param(3);

cons=netinc(grinc,t); % net consumption
u=gamm*((cons.^(1-thet)-1)/(1-thet) - alph*W(nw))+ev; %CRRA utility


end