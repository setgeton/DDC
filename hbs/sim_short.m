%% SIMULATION

%% CREATE ARTIFICIAL COHORT SUBJECT TO ALL DEDUCTIONS COUNTING FROM 65/67
global ESTIM;
global PR_MEAN;

clear darr;

load('H:\data\prepdata4.mat'); %use coh43-44 to simulate
paras_est=ESTIM';
savrate_incr=(darr{1, 1}.savrate(2)-0.001)*100;
beta2   = paras_est(1:b2)';
stigma=paras_est(2+b2:1+b2+b3)';
alpha   = paras_est(b2+b3+2);
h4=darr{1,1}.h4;
draws=1000; %how many draws to simulate future

%% PROJECTION FOR COHORT 43-44
%% retirement age still at 65

reform=0;
pmax=5;
n_base=length(darr{1,1}.incw);
obs=length(darr{1,1}.incw).*pmax;
partfric=1.0;
era=60;
WDmin=0;


fprintf('+++++++++++++++++++ \r\n');
fprintf('SIMULATIONS: Simulations below are either based on %3.0f different sets of basic characteristics that are \n', n_base)
fprintf('projected for 5 to 7 future periods, or on %4.0f*%4.0f*(5;7) draws from those simulated trajectories.  \r\n', draws,n_base);
fprintf('No real data reported if not indicated otherwise! \r\n');
fprintf('+++++++++++++++++++ \r\n');


fprintf('+++++++++++++++++++ \r\n');
fprintf('BASELINE SIMULATION (NORMAL RETIREMENT AGE = 65, EARLY RET AGE=%2.0f, frictions at %1.1f, cost of work reduction by %1.1f yrs  \r\n', era, partfric,WDmin);
fprintf('+++++++++++++++++++ \r\n');

darr_45=pmaxgen(pmax,darr,reform,partfric,h4); %simulate potential retirement benefits

[~,arr,t1_65,t2_65,optst_65]=dpll(paras_est,darr_45,pmax,T,model_para_vec,survcsv,era,WDmin); %grab probabilities of retirement
fprintf('mean savings rate of type 1: %3.3f and type 2: %3.3f \n', mean(optst_65(:,1).*(1-darr_45{1,1}.taxrate)).*savrate_incr, mean(optst_65(:,2).*(1-darr_45{1,1}.taxrate)).*savrate_incr);

%[PR_MEAN(:,1,1) PR_MEAN(:,2,1) PR_MEAN(:,3,1)] %Pr_Runempl+Pr_Rreg+Pr_work with const prob of type encounter
% fprintf('Predicted choice probabilities of the 3 choices (x-axis) by age (y-axis) conditional\n')
% fprintf('on still working (- based on %5.0f * %2.0f  simulated observations): \n', n_base, pmax) 
% [PR_MEAN(:,1,3) PR_MEAN(:,2,3) PR_MEAN(:,3,3)] %Pr_Runempl+Pr_Rreg+Pr_work with adj prob of type
%fprintf('choice probabilities (estimated hazard rates) of the 3 choices (x-axis) by age (y-axis) cond on still working --- seperated by types (- based on %5.0f * %2.0f  simulated observations): \n', n_base, pmax) 
%[PR_MEAN(:,1,2) PR_MEAN(:,2,2) PR_MEAN(:,3,2) PR_MEAN(:,4,2) PR_MEAN(:,5,2) PR_MEAN(:,6,2)]

survp=zeros(N,pmax,2);
for typ=0:1
temp=ones(N,pmax+1);
for i=2:pmax+1
temp(:,i)=temp(:,i-1).*arr{1,i-1}.prw(:,typ+1); %SURVIVALPROB TIMES THE PROB TO BE IN THE SAMPLE IN THE FIRST PLACE
end
survp(:,1:pmax,typ+1)=temp(:,2:pmax+1);
%survival prob for different periods
end
% fprintf('Pr_surv(x:age,regime65,y:type1&2) (= mean of %5.0f simulated choices per cell): \n',n_base)
% mean(survp)


retu=zeros(N,pmax,2);
for typ=0:1
retu(:,:,typ+1)=arr{1,1}.pru(:,typ+1)*ones(1,pmax);
for i=2:pmax
retu(:,i,typ+1)=(survp(:,i-1,typ+1)).*arr{1,i}.pru(:,typ+1);
end
% fprintf('Pr_retire_unemployment(y-axis:age;regime65) for type %2.0f -workers (= mean of %5.0f simulated choices per cell) \n',typ+1,n_base)
% fprintf('%12.8f\n',mean(retu(:,:,typ+1),1))
end

retreg=zeros(N,pmax,2);
for typ=0:1
retreg(:,:,typ+1)=arr{1,1}.prr(:,typ+1)*ones(1,pmax);
for i=2:pmax
retreg(:,i,typ+1)=(survp(:,i-1,typ+1)).*arr{1,i}.prr(:,typ+1);
end
% fprintf('Pr_ret_regular(age,regime65) for type %2.0f -workers (= mean of %5.0f simulated choices per cell) \n',typ+1,n_base)
% fprintf('%12.8f\n',mean(retreg(:,:,typ+1),1))
end

ret_age65=60.*ones(length(survp(:,1,1)),2)+[sum(survp(:,1:pmax,1),2) sum(survp(:,1:pmax,2),2)];
% fprintf('mean job exit age (nra=65; based on %5.0f * %2.0f  simulated observations): %8.3f\n',n_base,pmax, mean(typprob(1).*ret_age65(:,1)+(typprob(2)).*ret_age65(:,2)))

%how long afterwards is the actual retirement (i.e. what's the average length of alg1 receipt?)
duration_alg65=(typprob(1).* (sum(retu(:,1:end-1,1),2).*darr_45{1,1}.mon + retu(:,end,1).*12)+ typprob(2).* (sum(retu(:,1:end-1,2),2).*darr_45{1,1}.mon + retu(:,end,2).*12));


probrente=zeros(N,2) ; %probable pension for the two types
for typ=0:1
for pj=1:pmax
probrente(:,typ+1)=probrente(:,typ+1)+retu(:,pj,typ+1).*((darr_45{1,1}.renteA(:,pj+1).*(((darr_45{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45{1,1}.mon),1) )>=1))...
    + darr_45{1,1}.renteA(:,pj+2).*(darr_45{1,1}.mon>=24).*(pmax~=pj));
probrente(:,typ+1)=probrente(:,typ+1)+retreg(:,pj,typ+1).*darr_45{1,1}.rente(:,pj);
end
probrente(:,typ+1)=probrente(:,typ+1)+(survp(:,pmax,typ+1)).*darr_45{1,1}.rente(:,pmax+1);
end


probinc=zeros(N,pmax+1,2) ; %probable inc for the two types under 65-regime
for typ=0:1
for pj=1:pmax %period
probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+survp(:,pj,typ+1).*(darr_45{1,1}.incw(:,pj)-darr_45{1,1}.house(:,1));
probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+retu(:,pj,typ+1).*darr_45{1,1}.alosatz(:,1);
if pj>1 %2 yrs ago into ALG and ALG eligibility>12month
probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+retu(:,pj-1,typ+1).*(darr_45{1,1}.mon>=24).*(pmax~=pj).*darr_45{1,1}.alosatz(:,1);
end
    for pjt=1:pj
        if pjt>3
      probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+retreg(:,pjt,typ+1).*darr_45{1,1}.rente(:,pjt);
        end
        if pjt>2
      probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+retu(:,pjt-2,typ+1).*(darr_45{1,1}.mon>=24).*(pmax~=pj).*darr_45{1,1}.renteA(:,pjt);
        end
        if pjt>1
      probinc(:,pj,typ+1)=probinc(:,pj,typ+1)+retu(:,pjt-1,typ+1).*(((darr_45{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45{1,1}.mon),1) )>=1).*darr_45{1,1}.renteA(:,pjt);
        end
    end
end
probinc(:,pmax+1,typ+1)=probrente(:,typ+1);
end
probinc_age=typprob(1).*(probinc(:,:,1))+typprob(2).*(probinc(:,:,2));

probu=zeros(N,pmax+1,2) ; %probable flow utility for the two types under 65-regime
for typ=0:1
for pj=1:pmax %period
        
        nu=NaN(N,pmax);
        alpha2=(typ==1).*paras_est(b2+b3+3);
               nu(:,1)=darr_45{1,1}.x2*(beta2) + alpha2;  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
        if pmax>1
        for ip=2:pmax
            nu(:,ip)=nu(:,1) + (alpha).*(ip-1).*ones(N,1); %+ alpha2.*((ip-1)^2).*ones(N,1) ;  % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
        end
        end
        
        tau=NaN(N,pmax+2);
        tau(:,1)=darr_45{1,1}.x3*stigma;  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
        if pmax>1
        for ip=2:pmax+2
            tau(:,ip)=tau(:,1) ; % + alpha2.*ones(N,1).*(ip>3) ; %+ alpha2.* ((ip-1)^2).*ones(N,1) ;  %+ alpha2.*((ip-1)^2).*ones(N,1)   % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
        end
        end
    
probu(:,pj,typ+1)=probu(:,pj,typ+1)+survp(:,pj,typ+1).*(((darr_45{1,1}.incw(:,pj).^(1-gamm)-1)/(1-gamm))-nu(:,pj));
probu(:,pj,typ+1)=probu(:,pj,typ+1)+retu(:,pj,typ+1).*((darr_45{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj));
if pj>1 %2 yrs ago into ALG and ALG eligibility>12month
probu(:,pj,typ+1)=probu(:,pj,typ+1)+retu(:,pj-1,typ+1).*(darr_45{1,1}.mon>=24).*(pmax~=pj).*((darr_45{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj));
end
for pjt=1:pj
        if pjt>3
      probu(:,pj,typ+1)=probu(:,pj,typ+1)+retreg(:,pjt,typ+1).*((darr_45{1,1}.rente(:,pjt).^(1-gamm)-1)./(1-gamm));
        end
        if pjt>2
      probu(:,pj,typ+1)=probu(:,pj,typ+1)+retu(:,pjt-2,typ+1).*(darr_45{1,1}.mon>=24).*(pmax~=pj).*((darr_45{1,1}.renteA(:,pjt).^(1-gamm)-1)./(1-gamm));
        end
        if pjt>1
      probu(:,pj,typ+1)=probu(:,pj,typ+1)+retu(:,pjt-1,typ+1).*(((darr_45{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45{1,1}.mon),1) )>=1).*((darr_45{1,1}.renteA(:,pjt).^(1-gamm)-1)./(1-gamm));
        end
   end
end
probu(:,pmax+1,typ+1)=((probrente(:,typ+1).^(1-gamm)-1)./(1-gamm));
end
probu_age=typprob(1).*(probu(:,:,1))+typprob(2).*(probu(:,:,2));

probu_age=[probu_age probu_age(:,end) probu_age(:,end)];




probrente_pov=zeros(N,2) ; %probable pension for the two types under 65-regime
for typ=0:1
for pj=1:pmax
probrente_pov(:,typ+1)=probrente_pov(:,typ+1)+retu(:,pj,typ+1).*((darr_45{1,1}.renteA(:,pj+1)<0.850).*(((darr_45{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45{1,1}.mon),1) )>=1) ...
    + (darr_45{1,1}.renteA(:,pj+2)<0.850).*(darr_45{1,1}.mon>=24).*(pmax~=pj) );
probrente_pov(:,typ+1)=probrente_pov(:,typ+1)+retreg(:,pj,typ+1).*(darr_45{1,1}.rente(:,pj)<0.850);
end
probrente_pov(:,typ+1)=probrente_pov(:,typ+1)+(survp(:,pmax,typ+1)).*(darr_45{1,1}.rente(:,pmax+1)<0.850);
end



randnrdr=rand(N,7,draws);
pen_simtot65=pensim(pmax,N,draws,arr,darr_45{1,1}.renteA,darr_45{1,1}.rente,darr_45{1,1}.mon,randnrdr,era);
[pencons_simtot65,pencons_simtot65wohouse]=penconssim(pmax,N,draws,arr,darr_45{1,1}.renteA,darr_45{1,1}.rente,darr_45{1,1}.annuA,darr_45{1,1}.annu,optst_65,darr_45{1,1}.house,darr_45{1,1}.mon,randnrdr,era);



%for cohort=1:7 %cohort 1940:1945 and the overall means
%[PR_MEAN(:,1,cohort) PR_MEAN(:,2,cohort) PR_MEAN(:,3,cohort)]; %Pr_Runempl+Pr_Rreg+Pr_work
%end
%[PR_MEAN(:,1,7) PR_MEAN(:,2,7) PR_MEAN(:,3,7)] %Pr_Runempl+Pr_Rreg+Pr_work
%temp2=PR_MEAN(:,1,7);


fprintf('******************** \r\n');
fprintf('SIMULATING REFORM: Normal Retirement age shifted to age 67 \r\n');
fprintf('Different scenarios are simulated: All combinations of\n')
fprintf('>>cost of work reduction 0 & 2 yrs<<,\n')
fprintf('>>frictions at 50 & 100perc<<,\n')
fprintf('>>ERA at 60 and 63<<\n');
fprintf('--> 2*2*2=8 combinations are simulated. \r\n');
fprintf('******************** \r\n');

simNo=0;

%% Reform. retirement at age 67!
for WDmin=0:2:2;

    
for fric_reduce=0:1;
    partfric=(fric_reduce==0)*1 + (fric_reduce==1)*0.5;

for era_runs=1:2;
 simNo=simNo+1;  %Number of the specific reform simulation?   

reform=67; %normal retirement is shifted to 67, reform indicator
pmax=7; %thus, need to simulate 7 years after age 60
%partfric=1.0;  %fricitions at which level [0,1]?
%WDmin=0; %reduced disutility of work?


if era_runs==1
 era=60; %era still at 60?

fprintf('+++++++++++++++++++ \r\n');
fprintf('REFORM SIMULATION N° %2.0f [%1.4f] (NORMAL RETIREMENT AGE(NRA) = 67, cost of work reduction by %1.1f yrs, frictions at %1.1f,  EARLY RET AGE(ERA)=%2.0f \r\n',simNo,WDmin+0.1*partfric+ 0.0001*era,WDmin, partfric,era);
fprintf('+++++++++++++++++++ \r\n');

darr_45r=pmaxgen(pmax,darr,reform,partfric,model_para_vec(3)); %simulate pensiuon income for reform and next 7 years
[~,arr,t1_67,t2_67,optst_67]=dpll(paras_est,darr_45r,pmax,T-2,model_para_vec,survcsv,era,WDmin); %resulting choice probabilities

fprintf('mean savings rate of type 1: %3.3f and type 2: %3.3f \n', mean(optst_67(:,1).*(1-darr_45r{1,1}.taxrate)).*savrate_incr, mean(optst_67(:,2).*(1-darr_45r{1,1}.taxrate)).*savrate_incr)
end

if era_runs==2
era=63;

fprintf('+++++++++++++++++++ \r\n');
fprintf('REFORM SIMULATION N° %2.0f [%1.4f] (NORMAL RETIREMENT AGE = 67, cost of work reduction by %1.1f yrs, frictions at %1.1f,  EARLY RET AGE=%2.0f \r\n',simNo,WDmin+0.1*partfric+ 0.0001*era,WDmin, partfric,era);
fprintf('+++++++++++++++++++ \r\n');

darr_45r=pmaxgen(pmax,darr,reform,partfric,model_para_vec(3));
[~,arr,t1_6763,t2_6763,optst_67]=dpll(paras_est,darr_45r,pmax,T-2,model_para_vec,survcsv,era,WDmin);
fprintf('mean savings rate of type 1: %3.3f and type 2: %3.3f \n', mean(optst_67(:,1).*(1-darr_45r{1,1}.taxrate)).*savrate_incr, mean(optst_67(:,2).*(1-darr_45r{1,1}.taxrate)).*savrate_incr)

end



%[PR_MEAN(:,1,1) PR_MEAN(:,2,1) PR_MEAN(:,3,1)] %Pr_Runempl+Pr_Rreg+Pr_work
% fprintf('Predicted choice probabilities of the 3 choices (x-axis) by age (y-axis) conditional\n')
% fprintf('on still working (- based on %5.0f * %2.0f  simulated observations): \n', n_base, pmax) 
% [PR_MEAN(:,1,3) PR_MEAN(:,2,3) PR_MEAN(:,3,3)] %Pr_Runempl+Pr_Rreg+Pr_work with adj prob of type
%fprintf('choice probabilities (estimated hazard rates) of the 3 choices (x-axis) by age (y-axis) cond on still working, era= %3.0f --- seperated by types (- based on %5.0f * %2.0f  simulated observations): \n', era,n_base,pmax) 
%[PR_MEAN(:,1,2) PR_MEAN(:,2,2) PR_MEAN(:,3,2) PR_MEAN(:,4,2) PR_MEAN(:,5,2) PR_MEAN(:,6,2)]

%who is gaining from reforms?



for typ=0:1
temp=ones(N,pmax+1);
for i=2:pmax+1
temp(:,i)=temp(:,i-1).*arr{1,i-1}.prw(:,typ+1); %SURVIVALPROB TIMES THE PROB TO BE IN THE SAMPLE IN THE FIRST PLACE
end
survp_r(:,1:pmax,typ+1)=temp(:,2:pmax+1);
%survival prob for different periods
end
% fprintf('survival probability (x-axis:age(60-67),NRA=67,y-axis:type1&2) (- based on %5.0f simulated choices per cell): \n',n_base)
% mean(survp_r)

%survana=1;
%for j=1:pmax
%survana=survana.*mean(survp_r(:,j,2))
%end
%survana=1;
%for j=1:pmax-2
%survana=survana.*mean(survp(:,j,2))
%end

ret_age67=60.*ones(length(survp_r(:,1,1)),2)+[sum(survp_r(:,1:pmax,1),2) sum(survp_r(:,1:pmax,2),2)];
% fprintf('mean job exit age (NRA=67; based on %5.0f * %2.0f  simulated observations): %8.3f\r\n',n_base,pmax,mean(typprob(1).*ret_age67(:,1)+typprob(2).*ret_age67(:,2)))


for typ=0:1
retu_r(:,:,typ+1)=arr{1,1}.pru(:,typ+1)*ones(1,pmax);
for i=2:pmax
retu_r(:,i,typ+1)=(survp_r(:,i-1,typ+1)).*arr{1,i}.pru(:,typ+1);
end
% fprintf('Pr_Retire_unemployment(x:age,regime67) for type %2.0f -workers (- each cell based on %5.0f simulated observations) \n',typ+1,n_base)
% fprintf('%12.8f\n',mean(retu_r(:,:,typ+1),1))
end

for typ=0:1
retreg_r(:,:,typ+1)=arr{1,1}.prr(:,typ+1)*ones(1,pmax);
for i=2:pmax
retreg_r(:,i,typ+1)=(survp_r(:,i-1,typ+1)).*arr{1,i}.prr(:,typ+1);
end
% fprintf('Pr_ret_regular(x:age,regime67) for type %2.0f -workers (- each cell based on %5.0f simulated observations) \n',typ+1,n_base)
% fprintf('%12.8f\n',mean(retreg_r(:,:,typ+1),1))
end

if era==60
duration_alg67=(typprob(1).* (sum(retu_r(:,1:end-1,1),2).*darr_45{1,1}.mon + retu_r(:,end,1).*12)+ typprob(2).* (sum(retu_r(:,1:end-1,2),2).*darr_45{1,1}.mon + retu_r(:,end,2).*12));
end
if era==63
duration_alg67=(typprob(1).* (sum(retu_r(:,3:end-1,1),2).*darr_45{1,1}.mon + retu_r(:,1,1).*36 + retu_r(:,2,1).*24 + retu_r(:,end,1).*12)+ typprob(1).* (sum(retu_r(:,3:end-1,2),2).*darr_45{1,1}.mon + retu_r(:,1,2).*36 + retu_r(:,2,2).*24 + retu_r(:,end,2).*12));
end

%% PROJECTED PENSION INCOME - COMPARISON 65 & 67

mean(probrente);
sim_pens=typprob(1).*probrente(:,1)+typprob(2).*probrente(:,2);
mean(sim_pens);
perc=[0 10 20 30 40 50 60 70 80 90 100];
pthres_65=prctile(sim_pens,perc);

pd65=NaN(N,10);
sim_pens65perc=NaN(1,10);
sim_retage65perc=NaN(1,10);
probinc_age65perc=NaN(6,10);
temp1=typprob(1).*ret_age65(:,1)+typprob(2).*ret_age65(:,2);
temp1a=temp1+duration_alg65./12; %predicted official retirement age
for i=1:10
   pd65(:,i)= sim_pens>=pthres_65(i) & sim_pens<pthres_65(i+1);
   sim_pens65perc(1,i)=mean(sim_pens(pd65(:,i)==1));
   sim_retage65perc(1,i)=mean(temp1(pd65(:,i)==1));
   sim_official_retage65perc(1,i)=mean(temp1a(pd65(:,i)==1));
   for age=1:6
   probinc_age65perc(age,i)=mean(probinc_age(pd65(:,i)==1,age));
   end
end



%mean(retu_r(pd65(:,1)==1,:,typ+1))
%mean(retreg_r(pd65(:,1)==1,:,typ+1))
probrente_r=zeros(N,2) ; %probable pension for the two types under 67-regime
for typ=0:1
for pj=1:pmax
%probrente_r(:,typ+1)=probrente_r(:,typ+1)+retu_r(:,pj,typ+1).*(darr_45r{1,1}.renteA(:,pj+1).*(((darr_45r{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45r{1,1}.mon),1) )>=1) ...
%    + darr_45r{1,1}.renteA(:,pj+2).*(darr_45r{1,1}.mon>=24).*(pmax~=pj) );
probrente_r(:,typ+1)=probrente_r(:,typ+1)+retu_r(:,pj,typ+1).*(darr_45r{1,1}.renteA(:,pj+1).*(((darr_45r{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45r{1,1}.mon),1) )>=1).*(pj>2|era==60) ...
    + (darr_45r{1,1}.renteA(:,pj+1)+2.*darr_45r{1,1}.renteA(:,pj+1)./0.784.*0.036).*(darr_45r{1,1}.mon==12 ).*(pj==1&&era==63)...
    + (darr_45r{1,1}.renteA(:,pj+1)+darr_45r{1,1}.renteA(:,pj+1)./0.82.*0.036).*(darr_45r{1,1}.mon==12 ).*(pj==2&&era==63)...
    + darr_45r{1,1}.renteA(:,pj+2).*(darr_45r{1,1}.mon>=24).*(pmax~=pj).*(pj>1|era==60) + ((darr_45r{1,1}.renteA(:,pj+2)+darr_45r{1,1}.renteA(:,pj+2)./0.82.*0.036)).*(darr_45r{1,1}.mon>=24).*(pj==1&&era==63));
probrente_r(:,typ+1)=probrente_r(:,typ+1)+retreg_r(:,pj,typ+1).*darr_45r{1,1}.rente(:,pj);
end
probrente_r(:,typ+1)=probrente_r(:,typ+1)+(survp_r(:,pmax,typ+1)).*darr_45r{1,1}.rente(:,pmax+1);
end

probinc_r=zeros(N,pmax+1,2) ; %probable pension for the two types under 67-regime
for typ=0:1
for pj=1:pmax
probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+survp_r(:,pj,typ+1).*(darr_45r{1,1}.incw(:,pj)-darr_45r{1,1}.house(:,1));
probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pj,typ+1).*darr_45r{1,1}.alosatz(:,1);
if pj>1 %2 yrs ago into ALG and ALG eligibility>12month
probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pj-1,typ+1).*(darr_45r{1,1}.mon>=24).*(pmax~=pj).*darr_45r{1,1}.alosatz(:,1);
end
    for pjt=2:pj
        if pjt>3
        probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retreg_r(:,pjt,typ+1).*darr_45r{1,1}.rente(:,pjt);
        end
        if pjt>2
      probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pjt-2,typ+1).*((darr_45r{1,1}.mon>=24).*(era==60||pj~=3).*(pmax~=pj).*darr_45r{1,1}.renteA(:,pjt));
      probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pjt-2,typ+1).*((darr_45r{1,1}.mon>=24).*(era==63&&pj==3).*h4);  %2 periods ago into ALG==> now H4 if not 63 yet<=>in period 3
        end
        if pjt>1
      probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pjt-1,typ+1).*(((darr_45r{1,1}.mon==12).*(era==60||pj>3) + (pmax==pj).*ones(length(darr_45r{1,1}.mon),1) )>=1).*darr_45r{1,1}.renteA(:,pjt);
      probinc_r(:,pj,typ+1)=probinc_r(:,pj,typ+1)+retu_r(:,pjt-1,typ+1).*((darr_45r{1,1}.mon==12).*(era==63&&pj<=3).*h4);    %1 period ago into ALG==> now H4 if not 63 yet&&only eligible 12mon
         end
    end
end
probinc_r(:,pmax+1,typ+1)=probrente_r(:,typ+1);
end
probinc_r_age=typprob(1).*(probinc_r(:,:,1))+typprob(2).*(probinc_r(:,:,2));


pen_simtot67=pensim(pmax,N,draws,arr,darr_45r{1,1}.renteA,darr_45r{1,1}.rente,darr_45r{1,1}.mon,randnrdr,era);
[pencons_simtot67,pencons_simtot67wohouse]=penconssim(pmax,N,draws,arr,darr_45r{1,1}.renteA,darr_45r{1,1}.rente,darr_45r{1,1}.annuA,darr_45r{1,1}.annu,optst_67,darr_45r{1,1}.house,darr_45r{1,1}.mon,randnrdr,era);


%pension consumption comparison
%randomly choosing a typ

pencons_simtot65mean=mean(pencons_simtot65(:,:,1),2).*typprob(1)+mean(pencons_simtot65(:,:,2),2).*typprob(2);
pencons_simtot67mean=mean(pencons_simtot67(:,:,1),2).*typprob(1)+mean(pencons_simtot67(:,:,2),2).*typprob(2);

pencons_simtot65wohousemean=mean(pencons_simtot65wohouse(:,:,1),2).*typprob(1)+mean(pencons_simtot65wohouse(:,:,2),2).*typprob(2);
pencons_simtot67wohousemean=mean(pencons_simtot67wohouse(:,:,1),2).*typprob(1)+mean(pencons_simtot67wohouse(:,:,2),2).*typprob(2);

sav_typ=max(max(optst_65));
inc_net65=zeros(N,1);
inc_net67=zeros(N,1);
for sti=1:sav_typ;
inc_net65=inc_net65+(optst_65(:,1)==sti).*typprob(1).*(darr_45{1,1}.incw_sav(:,1,sti)-darr_45{1,1}.house)+(optst_65(:,2)==sti).*typprob(2).*(darr_45{1,1}.incw_sav(:,1,sti)-darr_45{1,1}.house);
inc_net67=inc_net67+(optst_67(:,1)==sti).*typprob(1).*(darr_45r{1,1}.incw_sav(:,1,sti)-darr_45r{1,1}.house)+(optst_67(:,2)==sti).*typprob(2).*(darr_45r{1,1}.incw_sav(:,1,sti)-darr_45r{1,1}.house);
end;

%             pencons_diff_draw=zeros(N,2);
%             pencons_diff_draw50=zeros(N,2);
%             pencons_diff_draw_abs=zeros(N,2);
% 
% for drawtyp=1:2
%             for dr=1:draws
%             pencons_diff_draw(:,drawtyp)=pen_diff_draw(:,drawtyp) + ( (drawtyp==1).*(pencons_simtot67(:,dr,1)-pencons_simtot65(:,dr,1)) + ...
%                 (drawtyp~=1).*(pencons_simtot67(:,dr,2)-pencons_simtot65(:,dr,2)) >0 ) ;
%             pencons_diff_draw_abs(:,drawtyp)=pen_diff_draw_abs(:,drawtyp) + ( (drawtyp==1).*(pencons_simtot67(:,dr,1)-pencons_simtot65(:,dr,1)) + ...
%                 (drawtyp~=1).*(pencons_simtot67(:,dr,2)-pencons_simtot65(:,dr,2))) ;
%             end
%             end
%             pencons_diff_draw_abs_w=pencons_diff_draw_abs(:,1).*typprob(1)+pencons_diff_draw_abs(:,2).*typprob(2);
%             pencons_diff_draw_w=pencons_diff_draw(:,1).*typprob(1)+pencons_diff_draw(:,2).*typprob(2);

%pension benefit comparison
%randomly choosing a typ

            %drawtyp=(rand(N,1)<typprob(1));
            pen_diff_draw=zeros(N,2);
            pen_diff_draw50=zeros(N,2);
            pen_diff_draw_abs=zeros(N,2);
            for drawtyp=1:2
            for dr=1:draws
            pen_diff_draw(:,drawtyp)=pen_diff_draw(:,drawtyp) + ( (drawtyp==1).*(pen_simtot67(:,dr,1)-pen_simtot65(:,dr,1)) + ...
                (drawtyp~=1).*(pen_simtot67(:,dr,2)-pen_simtot65(:,dr,2)) >0 ) ;
            pen_diff_draw50(:,drawtyp)=pen_diff_draw50(:,drawtyp) + ( (drawtyp==1).*(pen_simtot67(:,dr,1)-pen_simtot65(:,dr,1)) + ...
                (drawtyp~=1).*(pen_simtot67(:,dr,2)-pen_simtot65(:,dr,2)) >(50/1000) ) ;
            pen_diff_draw_abs(:,drawtyp)=pen_diff_draw_abs(:,drawtyp) + ( (drawtyp==1).*(pen_simtot67(:,dr,1)-pen_simtot65(:,dr,1)) + ...
                (drawtyp~=1).*(pen_simtot67(:,dr,2)-pen_simtot65(:,dr,2))) ;
            end
            end
            pen_diff_draw_abs_w=pen_diff_draw_abs(:,1).*typprob(1)+pen_diff_draw_abs(:,2).*typprob(2);
            pen_diff_draw_w=pen_diff_draw(:,1).*typprob(1)+pen_diff_draw(:,2).*typprob(2);

            %SHOUDL BE asymptotically EQUAL:
            [probrente(:,1).*typprob(1)+probrente(:,2).*typprob(2) mean(pen_simtot65(:,:,1),2).*typprob(1)+mean(pen_simtot65(:,:,2),2).*typprob(2)];
            [probrente_r(:,1).*typprob(1)+probrente_r(:,2).*typprob(2) mean(pen_simtot67(:,:,1),2).*typprob(1)+mean(pen_simtot67(:,:,2),2).*typprob(2)];

            

         

    temp_prob_utility % calculate the probable flow utility by type and age! for regime (era60 or era63) + nra67

    %probu_r_age60=probu_r_age; 
    %probu_r_age60=probu_r_age; 


   
        
%y6063=probu_r_age60 - probu_r_age63;

%ysum6063=sum(y6063,2)
   
 
 for pi=1:pmax+1
 ybin(:,pi)=(probu_r_age(:,pi) - probu_age(:,pi))>0; %utility: y-axis:individuals, x-axis:periods/age
 end
 for pi=1:pmax+1
 y(:,pi)=(probu_r_age(:,pi) - probu_age(:,pi)); %utility difference, nra67-65: y-axis:individuals, x-axis:periods/age
 end


ysum=sum((probu_r_age(:,1:end-1) - probu_age(:,1:end-1)),2)+(probu_r_age(:,end)-probu_age(:,end))*1; %utility difference summed up until age 67
 
 %for pi=1:pmax+1
 %yp=ybin(:,pi);
 %regress(sum(y,2)+y(:,8).*15 >0-0.2*pi,[darr_45{1,1}.x2 darr_45{1,1}.x3(:,1:end-1) darr_45{1,1}.prob_fric(:,1)])
 %end
 mean(sum(y,2)+y(:,8).*15);
 mean(sum(y,2)+y(:,8).*15 >-0);


  

mean(probrente_r); %mean pension by type
sim_r_pens=(typprob(1).*probrente_r(:,1)+typprob(2).*probrente_r(:,2));
mean(sim_r_pens); %mean pension, types joined, factoring behavioral response
mean(sim_r_pens./sim_pens); %ratio reform pension / initial pension
var(100.*sim_r_pens./sim_pens); %variation in ratio
mean(sim_r_pens)./mean(sim_pens);
prctile(sim_r_pens./sim_pens,perc); %percentiles of these ratios

% for yesno=0:1 % tenure?
% [mean(sim_pens(darr_45r{1,1}.x3(:,1)==yesno)) mean(sim_r_pens(darr_45r{1,1}.x3(:,1)==yesno))]
% end
% for yesno=0:1 % ausbil
% [mean(sim_pens(darr_45r{1,1}.x2(:,1)==yesno)) mean(sim_r_pens(darr_45r{1,1}.x2(:,1)==yesno))]
% end

sim_r_pens65perc=NaN(1,10);
var_pens65percvar=NaN(1,10);
share_pens_up5eur=NaN(2,10);
share_pens_up5eur=NaN(2,10);
pens_up_abs=NaN(2,10);
sim_r_retage65perc=NaN(1,10);
pencons65_dec=NaN(1,10);
pencons67_dec=NaN(1,10);
pencons65wohouse_dec=NaN(1,10);
pencons67wohouse_dec=NaN(1,10);
probinc_r_age65perc=NaN(8,10);
fric65perc=NaN(1,10);
temp2=typprob(1).*ret_age67(:,1)+typprob(2).*ret_age67(:,2); %predicted end of career age
temp2a=temp2+duration_alg67./12; %predicted official retirement age
pencons65_dec_median=NaN(1,10);
pencons67_dec_median=NaN(1,10);
pencons65_overall_raw=NaN(1,N.*(draws));
pencons67_overall_raw=NaN(1,N.*(draws));
for deci=1:10;
lengthdec=sum(pd65(:,deci)==1);
pencons65_dec_raw=NaN(1,lengthdec.*draws);
pencons67_dec_raw=NaN(1,lengthdec.*draws);
    for drawi=1:draws
    pencons65_dec_raw(1,(drawi-1).*lengthdec+1:(drawi).*lengthdec)=(pencons_simtot65(pd65(:,deci)==1,drawi));
    pencons67_dec_raw(1,(drawi-1).*lengthdec+1:(drawi).*lengthdec)=(pencons_simtot67(pd65(:,deci)==1,drawi));
            if deci==1
            pencons65_overall_raw(1,(drawi-1).*N+1:(drawi).*N)=(pencons_simtot65(:,drawi));
            pencons67_overall_raw(1,(drawi-1).*N+1:(drawi).*N)=(pencons_simtot67(:,drawi));
            end
    end;
pencons65_dec_median(deci)=median(pencons65_dec_raw);
pencons67_dec_median(deci)=median(pencons67_dec_raw);
end
pencons65_median=median(pencons65_overall_raw);
pencons67_median=median(pencons67_overall_raw);
    

for i=1:10
   sim_r_pens65perc(1,i)=mean(sim_r_pens(pd65(:,i)==1));
   var_pens65percvar(i)=var(100.*(sim_r_pens(pd65(:,i)==1)./sim_pens(pd65(:,i)==1)-1));
   mean_dec_savrates(1,i)=mean(optst_67(pd65(:,i)==1,1).*(1-darr_45r{1,1}.taxrate(pd65(:,i)==1,1)))./2; 
   mean_dec_savrates(2,i)=mean(optst_67(pd65(:,i)==1,2).*(1-darr_45r{1,1}.taxrate(pd65(:,i)==1,1)))./2;
   mean_dec_savrates65(1,i)=mean(optst_65(pd65(:,i)==1,1).*(1-darr_45{1,1}.taxrate(pd65(:,i)==1,1)))./2;
   mean_dec_savrates65(2,i)=mean(optst_65(pd65(:,i)==1,2).*(1-darr_45{1,1}.taxrate(pd65(:,i)==1,1)))./2;
   share_pens_up(1,i)=mean(pen_diff_draw(pd65(:,i)==1,1))./draws;
   share_pens_up(2,i)=mean(pen_diff_draw(pd65(:,i)==1,2))./draws;
   share_pens_up5eur(1,i)=mean(pen_diff_draw50(pd65(:,i)==1,1))./draws;
   share_pens_up5eur(2,i)=mean(pen_diff_draw50(pd65(:,i)==1,2))./draws;
   pens_up_abs(1,i)=mean(pen_diff_draw_abs(pd65(:,i)==1,1))./draws;
   pens_up_abs(2,i)=mean(pen_diff_draw_abs(pd65(:,i)==1,2))./draws;
   pencons65_dec(i)=mean(pencons_simtot65mean(pd65(:,i)==1));
   pencons67_dec(i)=mean(pencons_simtot67mean(pd65(:,i)==1));
   house_dec(i)=mean(darr_45{1,1}.house(pd65(:,i)==1));
   inc_dec65(i)=mean(inc_net65(pd65(:,i)==1,1));
   inc_dec67(i)=mean(inc_net67(pd65(:,i)==1,1));
   %share_pens_down_more_than_average(i)=mean((sim_r_pens(pd65(:,i)==1)./sim_pens(pd65(:,i)==1)-1)>mean(sim_r_pens(pd65(:,i)==1)./sim_pens(pd65(:,i)==1)-1));
   sim_r_retage65perc(1,i)=mean(temp2(pd65(:,i)==1));
   sim_r_official_retage65perc(1,i)=mean(temp2a(pd65(:,i)==1));
   fric65perc(1,i)=mean(darr_45r{1,1}.prob_fric(pd65(:,i)==1,1));
   meanX(1,i)=mean(darr_45r{1,1}.x2(pd65(:,i)==1,1)); %blue collar
   meanX(2,i)=mean(darr_45r{1,1}.x2(pd65(:,i)==1,2)); %white collar
   meanX(3,i)=mean(darr_45r{1,1}.x2(pd65(:,i)==1,3)); %education along deciles
   meanX(4,i)=mean(darr_45r{1,1}.x3(pd65(:,i)==1,1)); %tenure along deciles
   meanX(5,i)=mean(darr_45r{1,1}.incw(pd65(:,i)==1,1)./darr_45r{1,1}.renteA(pd65(:,i)==1,1)); %income per current pension
   meanX(6,i)=mean(darr_45r{1,1}.w_fin(pd65(:,i)==1,1)./1000); %liquid wealth along deciles
   meanX(7,i)=mean(40.*12.*darr_45r{1,1}.house(pd65(:,i)==1,1)); %residence value along deciles
   for age=1:8
   probinc_r_age65perc(age,i)=mean(probinc_r_age(pd65(:,i)==1,age));
   probu_del_age65perc(age,i)=mean((probu_r_age(pd65(:,i)==1,age)-probu_age(pd65(:,i)==1,age))>0.00); %prob to benefit from reform qua utility by age
   end
   probu_del_sum(1,i)=mean(sum(y(pd65(:,i)==1,:),2)+y(pd65(:,i)==1,8).*15 >-1);  % who benefits if u is summed up every period plus 15 retirement periods
end
%probu_del_sum
for i=1:10

end
% 
% if WDmin==0 && partfric==1 && era==60; %thus, displayed only once
% fprintf('mean savings rates of pre-reformbaseline simulation (NRA 65, for comparison)\n')
% fprintf('along income deciles(1-10) (- based on %4.0f draws from %5.0f simulated biographies \n',draws,N);
% fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
% a=  [mean_dec_savrates65(1,:).*typprob(1)+mean_dec_savrates65(2,:).*typprob(2)]'
% end
% 
% fprintf('mean savings rates along income deciles(1-10) (- based on %4.0f draws from %5.0f simulated observations \n',draws,N);
% fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
% a=  [mean_dec_savrates(1,:).*typprob(1)+mean_dec_savrates(2,:).*typprob(2)]'

%    %if era==60;
% fprintf('share of individuals with increased pensions along income deciles(1-10) (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n',draws,N,pmax);
% fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
% a=  [share_pens_up(1,:).*typprob(1)+share_pens_up(2,:).*typprob(2)]'

% [share_pens_up(1,:)' share_pens_up(2,:)']
% [share_pens_up5eur(1,:).*typprob(1)+share_pens_up5eur(2,:).*typprob(2)]'
% [share_pens_up5eur(1,:)' share_pens_up5eur(2,:)']
% [pens_up_abs(1,:)' pens_up_abs(2,:)'].*1000

if 1==2;
fprintf('absolute pension increase along deciles(1-10) in 1000 euro (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n',draws,N,pmax);
fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
a= [pens_up_abs(1,:).*typprob(1)+pens_up_abs(2,:).*typprob(2)]'

end;

% (pens_up_abs(1,:)+pens_up_abs(2,:))./sim_pens65perc(1,:)./2


% fprintf('share with increased pensions (wrt baseline) along controls; above vs below the mean (- each cell based on %4.0f draws from %5.0f * %2.0f /2 simulated observations) \n',draws,N,pmax);
% for control=1:6
%   
% %d.contr=[ausbil_dum(sampch==1,:) alo_kr(sampch==1) krank05(sampch==1) deu(sampch==1)];
% %mean(pen_diff_draw_abs_w(darr_45r{1,1}.contr(:,control)>mean(darr_45r{1,1}.contr(:,control))==yesno))./100.*1000
% zwisch1=mean(pen_diff_draw_w(darr_45r{1,1}.contr(:,control)>mean(darr_45r{1,1}.contr(:,control))))./draws;
% zwisch2=mean(pen_diff_draw_w(darr_45r{1,1}.contr(:,control)<=mean(darr_45r{1,1}.contr(:,control))))./draws;
% 
% 
% fprintf('contr var %1.0f : %1.3f vs %1.3f \n' , control,zwisch1,zwisch2);
% 
% end

%end;


if WDmin==0 && partfric==1 && era==60;
    
    
%fprintf('income  (in 1000Eur) pre-reform in dimension (Y:age60-65 - X:deciles) (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n',draws, N,pmax)
%fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
%probinc_age65perc(:,1:10)
end;

%if simNo>=1 && simNo<=4
%fprintf('income (in 1000Eur) post-reform in dimension (Y:age60-67 - X:deciles) (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n',draws, N,pmax)
%fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
%probinc_r_age65perc(:,1:10)


if 1==2;
% fprintf('income change [in PERCENT] due to reform in dimension (Y:deciles - X:age60-67), (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n', draws, N,pmax)
% fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
% a= [0:10 ; (60:67)' 100.*(probinc_r_age65perc(:,1:10)./[probinc_age65perc(:,1:10);probinc_age65perc(end,1:10);probinc_age65perc(end,1:10)]-ones(8,10))];
% fprintf('dec %3.0f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f %4.1f \r\n',a)
% 
% fprintf('utility change (+) post reform in dimension (Y:age60-67 - X:deciles) (- based on %4.0f draws from %5.0f * %2.0f simulated observations \n',draws,N,pmax)
% fprintf(' --> each cell: %4.0f * %5.0f /10 observations):\n', draws,N)
% probu_del_age65perc(:,1:10)
end;

global PROBU60D;
global PROBU63D;
global PROBU60;
global PROBU63;
global PROBINC60;
global PROBINC63;
if era==60
PROBU60D=probu_del_age65perc(:,1:10);
PROBU60=probu_r_age;
PROBINC60=probinc_r_age;
end
if era==63
PROBU63D=probu_del_age65perc(:,1:10);
PROBU63=probu_r_age;
PROBINC63=probinc_r_age;
end

if era==63
for i=1:10
   for age=1:8
      probinc_del6063_age65perc(age,i)=mean((PROBINC63(pd65(:,i)==1,age)-PROBINC60(pd65(:,i)==1,age))>0.01);
      probu_del6063_age65perc(age,i)=mean((PROBU63(pd65(:,i)==1,age)-PROBU60(pd65(:,i)==1,age))>+0.03);
   end
   %u_change_decsum=mean((sum(PROBU63(pd65(:,i)==1,:),2)-sum(PROBU60(pd65(:,i)==1,:),2))>+0.03);
   
end
    %fprintf('utility change (+) post reform (era=60-->era=63) in dimension (age60-67 X deciles) (- based on %4.0f biography simulations each of %5.0f age-60-observations):\n',draws,N)
    %probu_del6063_age65perc

%fprintf('?????????:\n')
%probu_del6063_age65perc
%probinc_del6063_age65perc

PROBU60;
PROBU63;
end;

%fprintf('blue collar, white collar, education, tenure, incw/pension, liquid wealth & residence value (y-axis) of different deciles (x-axis))(- based on %5.0f simulated observations):\n',N)
% meanX


if WDmin==0 && partfric==1 && era==60;
fprintf('+++++++++++++++\r\n')
fprintf('REPORT PRE-REFORM SIMULATIONS OF FRICTIONS; PENSION BENEFITS; RETIREMENT AGE; JOB EXIT AGE\n')
fprintf('is only reported together with 1st reform, because pre-reform values do not change cond on reform!\r\n')
fprintf('+++++++++++++++\r\n')
    
    
% fprintf('average friction probability by pre-reform pension decile (- based on %4.0f draws from %5.0f * %2.0f simulated observations): \n',draws,N,pmax)
% fprintf('%6.4f\n',fric65perc)
% fprintf('predicted pension benefits (EUR) in pre-reform-income-deciles pre reform (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_pens65perc*1000)
% fprintf('overall %6.2f\n\n',mean(sim_pens65perc*1000))
fprintf('predicted retirement consumption (EUR) in pre-reform-income-deciles pre reform (mean - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',pencons65_dec*1000);
fprintf('overall %6.2f\n\n',mean(pencons65_dec*1000));

fprintf('predicted retirement consumption (EUR) in pre-reform-income-deciles pre reform (median - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',pencons65_dec_median*1000);
fprintf('overall %6.2f\n\n',pencons65_median*1000);

fprintf('predicted value of rent free living (EUR) ( - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',house_dec*1000);
fprintf('overall %6.2f\n\n',mean(house_dec*1000));

fprintf('predicted net inc after savings (EUR) in pre-reform-income-deciles pre reform ( - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',inc_dec65*1000);
fprintf('overall %6.2f\n\n',mean(inc_dec65)*1000);

% fprintf('predicted ret age (yrs) in inc deciles (pre-reform) (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_official_retage65perc)
% fprintf('overall %6.2f\n\n',mean(sim_official_retage65perc))
% fprintf('predicted career end age (yrs) in inc deciles (pre-reform) (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_retage65perc)
% fprintf('overall %6.2f\n\n',mean(sim_retage65perc))

end;

fprintf('------\r\n')
fprintf('REPORT MAIN SIMULATIONS OF FRICTIONS; PENSION BENEFITS; RETIREMENT AGE; JOB EXIT AGE (for REFORM N° %1.0f) \r\n',simNo)
fprintf('------\r\n')


% fprintf('predicted pension benefits (EUR) in pre-reform-income-deciles post 67-reform (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_r_pens65perc*1000)
% fprintf('overall %6.2f\n\n',mean(sim_r_pens65perc*1000))
fprintf('predicted retirement consumption (EUR) in pre-reform-income-deciles post 67-reform (mean - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',pencons67_dec*1000);
fprintf('overall %6.2f\n\n',mean(pencons67_dec*1000));
fprintf('predicted retirement consumption (EUR) in pre-reform-income-deciles post 67-reform  (median - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',pencons67_dec_median*1000);
fprintf('overall %6.2f\n\n',pencons67_median*1000);
fprintf('predicted inc after savings (EUR) in pre-reform-income-deciles post 67-reform ( - based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
fprintf('%6.2f\n',inc_dec67*1000);
fprintf('overall %6.2f\n\n',mean(inc_dec65)*1000);
% fprintf('predicted ret age (yrs) in pre-reform-income-deciles post 67-reform (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_r_official_retage65perc)
% fprintf('overall %6.2f\n\n',mean(sim_r_official_retage65perc))
% fprintf('predicted career end age (yrs) in pre-reform-income-deciles post 67-reform (- based on %4.0f draws from %5.0f * %2.0f simulated observations):\n',draws,N,pmax)
% fprintf('%6.2f\n',sim_r_retage65perc)
% fprintf('overall %6.2f\n\n',mean(sim_r_retage65perc))


if simNo==1;
    for i=1:100
pens6560_draws(:,i)=pen_simtot65(:,i,1).*typprob(1)+pen_simtot65(:,i,2).*typprob(2);
pens67_R(:,i,simNo)=pen_simtot67(:,i,1).*typprob(1)+pen_simtot67(:,i,2).*typprob(2);
    end;
    end;

if simNo>1;
     for i=1:100;
pens67_R(:,i,simNo)=pen_simtot67(:,i,1).*typprob(1)+pen_simtot67(:,i,2).*typprob(2);
     end;
end;



end; %ERA
end; %frictions
end; %WDmin

perc=[0 10 20 30 40 50 60 70 80 90 100];
   for i=1:100
pthres_65_era60(i,:)=prctile(pens6560_draws(:,i),perc);
       for r=1:simNo;
pthres_67_R(i,:,r)=prctile(pens67_R(:,i,r),perc);
       end;
   end;
   
fprintf('+++++++++++++++++++ \r\n');
fprintf('FINAL RESULTS: \r\n');
fprintf('+++++++++++++++++++ \r\n');

fprintf('------------------- \n');
fprintf('overview of reforms:\r\n')
refnum=0;
for WD=0:2:2;
for fric_counter=1:1:2;
    fric=1./fric_counter;
for era_runs=1:2; 
    refnum=refnum+1;
    era_report=(era_runs==1)*60+(era_runs==2)*63;
fprintf('Reform N° %1.0f: WorkDisutility=-%1.0f, fric_level=%1.1f, ERA=%2.0f \n',refnum,WD,fric,era_report);

end; %ERA
end; %frictions
end; %WDmin
fprintf('------------------- \r\n');

fprintf('MEASURES OF PENSION INEQUALITY for the baseline and %1.0f reform simulations: \n',simNo)
fprintf('(Based on %4.0f draws from %5.0f * %2.0f simulated observations)\r\n',draws,N,pmax)


thres=[pthres_65_era60'];
for s=1:simNo
thres=[thres pthres_67_R(:,:,s)'];
end;


for m=1:3  %report 2 different measures of inequality
    
    if m==1
dec1=10; 
dec2=6;
    end;

    if m==2
dec1=10; 
dec2=2;
    end;
    
    if m==3
dec1=9; 
dec2=3;
    end;
    
for s=1:simNo+1;
ratio(s)=mean(thres(dec1,1+(s-1)*100:s*100)./thres(dec2,1+(s-1)*100:s*100));
end;
fprintf('MEASURE %1.0f: ratio %2.0f percentile to %2.0f percentile for Baseline and the %1.0f simulations: \r\n',m,(dec1-1)*10,(dec2-1)*10,simNo) 
fprintf('Baseline |')
for s=1:simNo-1;
fprintf(' Reform N° %1.0f |', s)
end;
fprintf(' Reform N° %1.0f | \n', simNo)

fprintf('  %1.4f |',ratio(1))
for s=1:simNo-1;
fprintf('   %7.4f   |',ratio(s+1))
end;
fprintf('   %7.4f   |\r\n', ratio(simNo+1))


end;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% 
% 
% sim_r_pens65perc %post reform pension (in 1000 EUR) by pre-reform decile-groups
% sim_r_pens65perc./sim_pens65perc %new pension is equal to X perc/100 of old pension for the decile groups
% sqrt(var_pens65percvar) %sqrt of variance of [ ratio ( (post reform pension / pre reform pension) -1) normalized to %]
% 
% sim_r_pens65percT=NaN(2,10);
% sim_pens65percT=NaN(2,10);
% for yesno=0:1
% for i=1:10
%    sim_r_pens65percT(yesno+1,i)=mean(sim_r_pens(pd65(:,i)==1 & darr_45r{1,1}.x3(:,1)==yesno ));
%    sim_pens65percT(yesno+1,i)=mean(sim_pens(pd65(:,i)==1 & darr_45r{1,1}.x3(:,1)==yesno ));
% end
% end
% sim_r_pens65percT(1,:)./sim_pens65percT(1,:)
% sim_r_pens65percT(2,:)./sim_pens65percT(2,:)
% 
% %% POVERTY RATE COMPARISON
% 
% mean(probrente_pov)
% sim_povrate=typprob(1).*probrente_pov(:,1)+typprob(2).*probrente_pov(:,2);
% mean(sim_povrate)  %SIMULATED POVERTY RATE if STATUTORY PENSION AGE=65
% 
% probrente_r_pov=zeros(N,2) ; %probable pension for the two types under 67-regime
% for typ=0:1
% for pj=1:pmax
% probrente_r_pov(:,typ+1)=probrente_r_pov(:,typ+1)+retu_r(:,pj,typ+1).*((darr_45r{1,1}.renteA(:,pj+1)<0.850).*(((darr_45r{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45r{1,1}.mon),1) )>=1)...
%    +(darr_45r{1,1}.renteA(:,pj+2)<0.850).*(darr_45r{1,1}.mon>=24).*(pmax~=pj));
% probrente_r_pov(:,typ+1)=probrente_r_pov(:,typ+1)+retreg_r(:,pj,typ+1).*(darr_45r{1,1}.rente(:,pj)<0.850);
% end
% probrente_r_pov(:,typ+1)=probrente_r_pov(:,typ+1)+(survp_r(:,pmax,typ+1)).*(darr_45r{1,1}.rente(:,pmax+1)<0.850);
% end
% 
% mean(probrente_r_pov)
% sim_r_povrate=typprob(1).*probrente_r_pov(:,1)+typprob(2).*probrente_r_pov(:,2);
% mean(sim_r_povrate)  %SIMULATED POVERTY RATE if STATUTORY PENSION AGE=67
% 
% for yesno=0:1 %education>highschool(abitur)?
% [mean(sim_povrate(darr_45r{1,1}.x3(:,1)==yesno)) mean(sim_r_povrate(darr_45r{1,1}.x3(:,1)==yesno))]
% end
% 
% %for cohort=1:7 %cohort 1940:1945 and the overall means
% %[PR_MEAN(:,1,cohort) PR_MEAN(:,2,cohort) PR_MEAN(:,3,cohort)]; %Pr_Runempl+Pr_Rreg+Pr_work
% %end
% %[PR_MEAN(:,1,7) PR_MEAN(:,2,7) PR_MEAN(:,3,7)] %Pr_Runempl+Pr_Rreg+Pr_work
% %[temp2./PR_MEAN(:,1,7) temp2-PR_MEAN(:,1,7)]
% 
% 
% %% NRA=67, ERA=63
% reform=67;
% era=63;
% pmax=7;
% %partfric=1.0;
% %darr_45r=pmaxgen(pmax,darr,reform,partfric); %simulate potential retirement benefits
% 
% [~,arr]=dpll(paras_est,darr_45r,pmax,T-2,b,survcsv,era); %grab probabilities of retirement
% 
% 
% [PR_MEAN(:,1,1) PR_MEAN(:,2,1) PR_MEAN(:,3,1)] %Pr_Runempl+Pr_Rreg+Pr_work with const prob of type encounter
% [PR_MEAN(:,1,3) PR_MEAN(:,2,3) PR_MEAN(:,3,3)] %Pr_Runempl+Pr_Rreg+Pr_work with adj prob of type
% [PR_MEAN(:,1,2) PR_MEAN(:,2,2) PR_MEAN(:,3,2) PR_MEAN(:,4,2) PR_MEAN(:,5,2) PR_MEAN(:,6,2)]
% 
% break;
% 
% %% USING THE NUMERIC HESSIAN FOR STD
% 
% hessian
% sdH=sqrt(diag(inv(hessian)))
% 
% 
% %% USING BOOTSTRAP FOR STD
% R=5;
% likmaxbs = @(y0,x1,x2)fminunc(@(paras_x) synthll(paras_x,y0,x1,x2,b2),x0,options);
% bootstat = bootstrp(R,likmaxbs,y0,x1,x2);
% mean(bootstat)
% sdBS = std(bootstat)
% histogram(bootstat(1:R,1),10); %histo of BS results for beta1
% coeffci=quantile(bootstat,[.025,0.975]) %use quantiles as confidence intervals (only makes sense if R is big)
% 
% 
% %%temp
% global TEMP;
% TEMP(1,:)=sim_pens65perc
% TEMP(2,:)=sim_r_pens65perc %post reform pension by pre-reform decile-groups
% 
