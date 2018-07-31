%% LIKELIHOOD COMPUTATION
function sumll=lik(param,data,pdef)



W=pdef.W;
NW=length(W);
%param(1)=1;
gamm  = abs(param(1)); %gamma should be positive
thet   = abs(param(2)); % theta should be positive
alph   = param(3);
param=[gamm thet alph];
beta   = pdef.beta;
grinc=data.grinc;
retage=data.retage;
t=pdef.t;

choice=data.optchoice;

N=length(grinc(:,1,1));
NA=length(grinc(1,:,1));

[Vw,Vr]=valuef(data,pdef,param);

utility=NaN(N,NA-1,NW);

for nw=1:NW
    for period=1:NA-1
    utility(:,period,nw)=  (nw==1).*( flowutility(param,grinc(:,period,nw),nw,W,t,0.5772.*ones(N,1)) ...
                            + beta.*( log(exp(Vw(:,period+1))+exp(Vr(:,period+1,nw))))) ...
                         + (nw==2).*(flowutility(param,grinc(:,period,nw),nw,W,t,0.5772.*ones(N,1)) ...
                            +  beta.*( log(exp(Vr(:,period+1,nw)))))    ;
    end
end

ll_period=NaN(N,NA-1);
for period=1:NA-1
uc1=NaN(N,1);
uc2=NaN(N,1);    
uc1(:,:)=  utility(:,period,1) ; %utility choice 1 (work)
uc2(:,:)=  utility(:,period,2) ; %utility choice 2 (retirement)

ll_period(:,period) =  (retage>=period).*(     ...
        (choice(:,period)==1).*log(   1./(1+exp( uc2  - uc1 ))       ) ...
    +   (choice(:,period)==2).*log(1./(1+exp( uc1  - uc2 )))   ) ...
    + (retage<period).*(-.0001)  ; % not use utility if observation is already retired
end



sumll=sum(sum(min(abs(ll_period),30.*ones(N,NA-1)))); %sum up likelihood! replace NaN (caused by matlabs inability to construct log of something very small) by 15

