% computing net income; tax free income = 80
function[Vw,Vr] = valuef(data,pdef,param)
 benefits=data.pensionb;
 wage=data.wage;
 
 t=pdef.t;
 W=pdef.W;
 beta=pdef.beta;
 N=length(wage);
 NRA=length(pdef.A)+pdef.A(1)-1;
 agedeath=pdef.lifeexp;
 maxA=length(pdef.A); %how many years until NRA looking from 60;
 Vr=NaN(N,maxA,2);
 Vw=NaN(N,maxA);
 retirement=2; work=1; %according working hours in vector W() on position 1 or 2.
 evmeanN=0.5772*ones(N,1);

 
 firstbenefits=1; %benefits received for the first time
 benefitslastp=2; % benefits received last period for the first time --> determines benefit level
 
 Vr(:,maxA,firstbenefits) = ... 
     ( flowutility(param,benefits(:,maxA),retirement,W,t,evmeanN) ) ... 
     *(beta.^(0:agedeath-NRA))*ones(agedeath-NRA+1,1);
 Vr(:,maxA,benefitslastp) = ... 
     ( flowutility(param,benefits(:,maxA-1),retirement,W,t,evmeanN) ) ... 
     *(beta.^(0:agedeath-NRA))*ones(agedeath-NRA+1,1);
  Vw(:,maxA) = -150.*ones(N,1);
 
 for recursiveage=maxA-(1:maxA-1);
 Vw(:,recursiveage)= flowutility(param,wage(:,recursiveage),work,W,t,evmeanN) ...
     + beta.*( log(exp(Vw(:,recursiveage+1))+exp(Vr(:,recursiveage+1,firstbenefits))));
 Vr(:,recursiveage,firstbenefits) = ... 
     ( flowutility(param,benefits(:,recursiveage),retirement,W,t,evmeanN) ) ...
     *(beta.^(0:agedeath-NRA+(maxA-recursiveage)))*ones(agedeath-NRA+(maxA-recursiveage)+1,1);
 if recursiveage>1
 Vr(:,recursiveage,benefitslastp) = ... 
     ( flowutility(param,benefits(:,recursiveage-1),retirement,W,t,evmeanN) ) ...
     *(beta.^(0:agedeath-NRA+(maxA-recursiveage)))*ones(agedeath-NRA+(maxA-recursiveage)+1,1);
 end
 end;
 
end