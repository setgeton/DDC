clear;

% load data set from simulation
load('H:\data\prepdata3.mat');
load('H:\data\survprob.mat');

%sample=[1;pmax]; % which periods to look at? [min,max]

randb2=[0.9.*ones(1,1) -0.1.*ones(1,b2-2) -1.*ones(1,1)]; %starting values for working disutility components
randstigma=[1+2.1*randn(1,b3-1) -1-2.1.*randn(1,1)]; %starting values for heterog stigma parameter
x0 = [randb2 1.5+randn(1,1) randstigma 0.2+0.5.*randn(1,1) 3+randn(1,1) 0.001];
model_para_vec=[b2,b3,h4];
era=60;
WDmin=0; %0==no reduced WorkingDisutility --- 1==reduced WorkingDisutility by 1 year --- 2==reduced by 2 years...


options = optimset('display','iter','largescale','off','MaxFunEvals',2000,'PlotFcns',@optimplotx,'TolFun', 1e-4);
[paras_trans,fval,exitflag,output,grad,hessian] = fminunc(@(paras_x) dpll(paras_x,darr,pmax,T,model_para_vec,survcsv,era,WDmin),x0,options);

fprintf('++++++++++++++++++++\r\n') 
fprintf('Parameter Estimates from Maximum Likelihood based on %4.1f observations (SD in brackets): \r\n',N)
fprintf('++++++++++++++++++++\r\n') 

%[paras_trans' sqrt(diag(inv(hessian)))];

global ESTIM
ESTIM=paras_trans';
paras_est=paras_trans';
paras_sd=sqrt(diag(inv(hessian)));
global PR_MEAN;

beta2   = (paras_est(1:b2,1));
beta2_sd   = (paras_sd(1:b2,1));
gamm = paras_est(b2+1,1);
gamm_sd = paras_sd(b2+1,1);
alpha   = paras_est(b2+b3+2,1);
alpha_sd   = paras_sd(b2+b3+2,1);
a63   = 0; %paras_est(b2+b3+5);
typprob(1)   = 1/(1+exp(-paras_est(b2+b3+4)));
typprob(2)=1-typprob(1); 
%typ2p   = (1-typ1p).*1/(1+exp(-paras_est(b2+b3+5)));
stigma = paras_est(b2+2:b2+b3+1,1);
stigma_sd = paras_sd(b2+2:b2+b3+1,1);
alpha2   = paras_est(b2+b3+3,1);
alpha2_sd   = paras_sd(b2+b3+3,1);
%alpha4   =paras_est(b2+b3+5);
%alpha3   = 1/(1+exp(-paras_est(b2+b3+5)));

for k=1:b2;
fprintf('beta2_%1.0f, covariate %1.0f of cost of work:              %12.8f (%10.8f) \n',k,k,beta2(k,1),beta2_sd(k,1))
end;
fprintf('gamma (risk aversion):                             %12.8f (%10.8f) \n',gamm(:,1),gamm_sd(:,1))
fprintf('alpha (age trend in cost of work):                 %12.8f (%10.8f) \n',alpha(:,1),alpha_sd(:,1))
fprintf('alpha2 (type-1-worker difference in cost of work): %12.8f (%10.8f) \n',alpha2(:,1),alpha2_sd(:,1))
%fprintf('alpha3: %12.8f\n',alpha3)
for k=1:b3;
fprintf('stigma_%1.0f, covariate %1.0f of UI benefit stigma:        %12.8f (%10.8f) \n',k,k,stigma(k,1),stigma_sd(k,1))
end;
fprintf('Probability to be worker of type 1:                %12.8f (-->bootstrap sd???) \r\n',typprob(1))
%fprintf('Pr(typ2): %12.8f\n',typ2p)
%fprintf('Eligibility for R63: %6.3f\n',a63)
%fprintf('nu_loc: %12.8f\n',nu_loc)

%for cohort=1:7 %cohort 1940:1945 and the overall means
%[PR_MEAN(:,1,cohort) PR_MEAN(:,2,cohort) PR_MEAN(:,3,cohort)]; %Pr_Runempl+Pr_Rreg+Pr_work
%end
%[PR_MEAN(:,1,1) PR_MEAN(:,2,1) PR_MEAN(:,3,1)] %Pr_Runempl+Pr_Rreg+Pr_work
fprintf('++++++++++++++++++++\r\n') 
fprintf('CHECKING THE FIT OF THE DATA BY COMPARING ESTIMATED CHOICE PROBABILITIES WITH OBSERVED PATTERN \r\n') 
fprintf('++++++++++++++++++++\r\n') 




fprintf('1---ESTIMATES: predicted choice probabilities of the 3 choices (work, UI, retirement: x-axis)\n')
fprintf('by age (y-axis) cond on still working ( - based on %4.1f observations per cell): \n', N) 
[PR_MEAN(:,1,3) PR_MEAN(:,2,3) PR_MEAN(:,3,3)] %Pr_Runempl+Pr_Rreg+Pr_work with adj prob of type
%fprintf('ESTIMATES: choice probabilities of the 3 choices (work, UI, retirement: x-axis) by age (y-axis) cond on still working --- seperated by types ( - based on %4.1f observations per column): \n', N) 
%[PR_MEAN(:,1,2) PR_MEAN(:,2,2) PR_MEAN(:,3,2) PR_MEAN(:,4,2) PR_MEAN(:,5,2) PR_MEAN(:,6,2)]

fprintf('2---OBSERVED: Observed shares of choices for 3 options (work, UI, retirement: x-axis)\n')
fprintf('by age (y-axis) cond on still working ( - based on %4.1f observations per cell): \n', N) 
for stp=1:pmax
hazardrates_observed(stp,:)=[mean(darr{1,stp}.ch_r.*darr{1,stp}.ch) mean((1-darr{1,stp}.ch_r).*darr{1,stp}.ch) mean(1-darr{1,stp}.ch) ];
end
hazardrates_observed

%fprintf('mean(nu+xb(startperiod)): %12.8f\n',NUXBETA_MEAN)
%fprintf('del: %12.8f\n',del)

