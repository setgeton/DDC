clear;

%% Datasimulation
% SIMULATE A DATA SET TO TRY OUT IF ESTIMATION PROCEDURE WORKS

% defining parameters
beta2   = [0.4 -0.4 0.4 -0.8]';  %coefficients of regressors to be simulated
gamm = 0.5; %curvature param of utility function
alpha=1.5; %growth factor of working disutility
nu_loc=2.0; %location of initial working disutility (this is not the mean)
nu_scale=1; %scale of the working disutility generating EV1 distribution
nu_mean=-nu_loc+0.5772.*nu_scale;
del=0.95; %discount factor
delta_inc=0.01; %yearly change in wages
ded=0.036; %retirement deductions
c=2; %number of choices
T=20; %Time horizon after age65
pmax=4;
N =10000;
b2=length(beta2); %# of other coefficients (covariates)

fprintf('Analysis using %6.0f units in up to %2.0f periods \n',N,pmax)

simdataseed = RandStream('mt19937ar','seed',116);
RandStream.setGlobalStream(simdataseed);


p=pmax; %periods until definite retirement



%for age=60:65


%% simulate reitrement benefits and labor income

u_ret=randn(N,p+1); %discontinuities in retirement wealth accrual ~N(0,1)

d.incw=zeros(N,p+1);
d.incw(:,1)=5+50*rand(N,1);
d.rente=zeros(N,p+1);
d.rente(:,1)=10+28*rand(N,1);
for it=2:p+1
d.rente(:,it)=(1+0.036).*d.rente(:,it-1)+d.incw(:,it-1)*0.01+u_ret(:,it); %+0.2*d.rente(:,1,it-1).*(it==3)
d.incw(:,it)=d.incw(:,it-1).*(1+delta_inc);
end

%% generate some explanatorys
d.x2=-2+4*rand(N,b2);

%% Prob of involuntary job loss
d.prob_fric=[0.02+0.1.*rand(N,1) NaN(N,pmax-1)];
for ip=2:pmax
    d.prob_fric(:,ip)=d.prob_fric(:,1) +0.10.*(ip-1).*d.prob_fric(:,1);
end


%% SIMULATE RETIREMENT DECISION
% generate extreme value errors
% using evrnd (as here), negate value for type-1 extreme value errors.
% (NB. asymmetric distribution - see help file for details)
e.ev_c = -evrnd(0,1,N,c,p); %choice utility error


para_eV=[del gamm alpha nu_loc beta2'] ;
sim=1;

[eVFt,ch,d.ret]=eVfunc(para_eV,d,p,pmax,b2,T,N,sim,e);

d.ch=ch;

fprintf('\n average time/periods until retirement: %12.2f\n',mean(d.ret))

d.N=N;
darr{1}=d;
d2=d;
firstret=d.ret;
for pj=1:pmax-1
    clear d;
sampch=ch(:,pj)==0&firstret>pj;
d.incw = d2.incw(sampch==1,pj+1:end);
d.rente = d2.rente(sampch==1,pj+1:end);
d.x2 = d2.x2(sampch==1,:);
d.prob_fric = d2.prob_fric(sampch==1,:);
d.ch = d2.ch(sampch==1,pj+1:end);
d.N=length(d.incw);

darr{pj+1}=d;
end
clear d;
clear d2;

save('synthdata.mat','darr','c','T','b2','pmax','N');




