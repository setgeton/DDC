clear;

simdataseed = RandStream('mt19937ar','seed',314); 
RandStream.setGlobalStream(simdataseed);


% (1) Simulating Dataset:
%% parameters defining problem
clear;
gamm    = 2.0;      %scaling
thet   = 1.5;       %curvature of utility function
alph   = 0.25;       %cost of work 
gammthetalph=[gamm thet alph];
beta=0.98; def.beta=beta;
N = 20000; %number of observations
A=[60 61 62 63 64 65]; NA=length(A); def.A=A; %A=[ages in the model]; NA=number of years/periods;
W = [1 0]'; NW = length(W);  def.W=W; % work status; Choice 1=work, Choice 2=retirement
t=0.0; def.t=t; %income tax
%t2=0.2; def.t2=t2;
maxpensexp = 45; %max years of work experience used for pension calculation
replrate= 0.5;  %replacement rate= share of last income
dedfactor=0.00; % actuarial deductions for every year of early retirement
def.lifeexp=65; % life expectancy
wagedeclineperc=0.03;
% generate monthly income for all individuals
mu_wage = 1.1; 
sd_wage = 0.3;
d.wage=NaN(N,NA);
d.wage = (exp(mu_wage + sd_wage*randn(N,1)))*(ones(1,NA)-(0:NA-1).*wagedeclineperc);
%ln_wage = mu_wage + sd_wage*randn(N,1);
%ksdensity(ln_wage)
ksdensity(d.wage(:,1),'suppor','positive')


% random utility shock, non-labour income and pension benefits:
ev_h = -evrnd(0,1,N,NA,NW); %extreme value I error

%work experience; uniform distribution on [30,45]
d.workexp = round(30+15*rand(N,1))*ones(1,NA);

%pension benefits
for period=1:NA
d.pensionb(:,period) = (d.workexp(:,period)./maxpensexp).*replrate.*d.wage(:,1) ;
end;


fprintf('work experience 1st period: mean %3.2f, max %3.2f, min  %3.2f \n',mean(d.workexp(:,1)),max(d.workexp(:,1)),min(d.workexp(:,1)))
fprintf('gross wage 1st period: mean %3.2f, max %3.2f, min  %3.2f \n',mean(d.wage(:,1)),max(d.wage(:,1)),min(d.wage(:,1)))
fprintf('pension benefits 1st period: mean %3.2f, max %3.2f, min  %3.2f \n\n',mean(d.pensionb(:,1)),max(d.pensionb(:,1)),min(d.pensionb(:,1)))

%% individual retirement choices:
% generate utility for all choices  (CRRA)
% --> need to compute utility for choices: feed gross inc into
% flowutility fct, where net inc fct is called (net inc = consumption).



d.grinc=NaN(N,NA,NW); %gross income in the form (obs,period,choice)
for period=1:NA
d.grinc(:,period,:)=[(d.wage(:,period)),(d.pensionb(:,period))]; %consumption for choices
end;


utility=NaN(N,NA-1,NW); %Utility (including continuation value /value function)

[Vw,Vr]=valuef(d,def,gammthetalph); %compute value functions (finite horizon; until death) in form [obs,period,choice]

for nw=1:NW
    for period=1:NA-1
    utility(:,period,nw)=  (nw==1).*( flowutility(gammthetalph,d.grinc(:,period,nw),nw,W,t,ev_h(:,period,nw)) ...
                                + beta.*( log(exp(Vw(:,period+1))+exp(Vr(:,period+1,nw))))) ...
                        +  (nw==2).*(flowutility(gammthetalph,d.grinc(:,period,nw),nw,W,t,ev_h(:,period,nw)) ...
                                + beta.*( log(exp(Vr(:,period+1,nw))))  )    ;
    end
end

% maximize utility:
d.uopt=NaN(N,NA-1); %utility of optimal choice
d.optchoice=NaN(N,NA-1); %optimal choice (obs,period)
for period=1:NA-1
uperiod=NaN(N,NW); %utility (incl continuation Value) of the two choices in specific period 
uperiod(:,:)=utility(:,period,:);
[d.uopt(:,period),d.optchoice(:,period)]=max(uperiod,[],2);
end
d.hopt=W(d.optchoice); %hours?
d.retage=zeros(N,1);
for period=1:NA-1
d.retage=d.retage+(d.optchoice(:,period)==2).*period.*(d.retage==0);
end
d.retage=d.retage+NA.*(d.retage==0);
hist(A(d.retage),A); % histogram of retirement entry


fprintf('cum. share retired in\n\n');
for period=1:NA %cumululative retirement shares
fprintf('period %2.0f: %4.2f\n',period,sum((d.retage<period+1))/N);
end

save('simdata.mat','d','def');




%% (2) Estimation
clear; 
% load data set from simulation
load('simdata.mat');

x0 = [2.5 2.5 2.5]; % starting values

options = optimset('display','iter','largescale','off','MaxFunEvals',2000);
[paras_est,fval,exitflag,output,grad,hessian] = fminunc(@(paras_x) lik(paras_x,d,def),x0,options);

gamma   = abs(paras_est(1));
theta   = abs(paras_est(2));
alpha   = paras_est(3);

fprintf('gamma: %12.8f\n',gamma)
fprintf('theta: %12.8f\n',theta)
fprintf('alpha: %12.8f\n',alpha)


