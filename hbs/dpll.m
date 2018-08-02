% likelihood evaluation
function [val, arr,t1,t2,optst]=dpll(paras,darr_raw,pmax,T,model_para_vec,surv,era,WDmin)


global PARAVEC;
PARAVEC=paras;

darr=darr_raw;

b2=model_para_vec(1);
b3=model_para_vec(2);
h4=model_para_vec(3);

gamm = abs(paras(1+b2));
%alpha2= paras(4+b2);
beta2 = paras(1:b2)';
alpha= paras(2+b2+b3);
a63= 0; %paras(3+b2+b3);
anz_typ=2;
sav_typ=darr{1,1}.sav_typ;
typprob=NaN(2,1);
typprob(1)= 1/(1+exp(-paras(4+b2+b3)));
%typprob(2)= (1-typprob(1)).*1/(1+exp(-paras(5+b2+b3))); %(1-typprob(1))./3;
typprob(2)= 1-typprob(1);
 %number of types
%typ1prob= 1/(1+exp(-paras(5+b2+b3)));
%typ2prob= 1-typ1prob-typ0prob;
stigma=paras(2+b2:1+b2+b3)';
alpha2= paras(3+b2+b3); %paras(3+b2+b3);
alpha3= 1; %1/(1+exp(-paras(5+b2+b3)));
%alpha4=paras(5+b2+b3); %1/(1+exp(-paras(5+b2+b3))); %paras(5+b2+b3); %paras(3+b2+b3);
%tau= paras(3+b2);
del = 0.96; % abs(paras(4+b2)); %

%for pj=1:pmax
%darr{1,pj}.annuA=alpha4.*darr{1,pj}.annuA;
%darr{1,pj}.annu=alpha4.*darr{1,pj}.annu;
%end

%if del>0.99
%del = 0.99;
%end

para_eV=[del gamm alpha stigma' beta2' a63 alpha2 alpha3];
    sim=0; %no simulation, only estimation
    e=0;

%LL_subsample=NaN(1,1);

% save prob to be of certain type in different periods
%typ0prob_l=NaN(pmax,1);

%% grid search optimal savingsrate 
    
    pakt=1;
    p=pmax-pakt+1; % length of horizon until age 65
    d=darr{pakt};
    mon=d.mon;
    cr=d.ch(:,1);
    cr_r=d.ch_r(:,1);
    N=d.N;
    optst=NaN(N,anz_typ);
    pre_est_lifespan=d.pre_est_lifespan; %age60 minus pre_est_lifespan is view point from which individual decides about optimal savings rate
    del_vec=NaN(1,pre_est_lifespan); %matrix used for summation of utility age 20-60: discountfact
   for iT=1:pre_est_lifespan
          del_vec(:,iT)=del.^iT;
   end
    lifetime_ust=NaN(N,sav_typ); %save optimal utilities for different savings levels st
    lfte_mon=(d.lt_earn(:,1)./40)./1000./12;
    x2beta2=d.x2*(para_eV(3+b3+1:3+b3+b2)');    
    alpha=para_eV(3);  % age trend in work disutiltiy
    WDmin_change =   - WDmin.*alpha.*ones(N,1);
    for typ = 1:anz_typ
    alpha2=(typ==1).*para_eV(b2+b3+5); %  type 1 additional disutility
    work_disutility= x2beta2 + alpha2 + WDmin_change;
        for i=1:sav_typ
            st=i.*ones(N,1);
       [~, ~, ~,uret,uwork]=dplik(d,mon,cr,cr_r,para_eV,p,pakt,pmax,model_para_vec,T,N,sim,e,surv,typ,era,WDmin,st);
    
  lifetime_ust(:,i)=(((((1-d.savrate(i)).*(lfte_mon+d.inc_partner(:,1)  -1.*tax(lfte_mon+d.inc_partner(:,1),0,d.prob_partner))).^(1-gamm)-1)./(1-gamm))+work_disutility)*(del_vec*ones(pre_est_lifespan,1)) + (del.^pre_est_lifespan)*max([uret(:,1) uret(:,2) uwork(:,1)],[],2); %creates the maximum utility of each n for savingsrate st; returns 2285x1 vector   
        end
        [~,optst_temp]=max(lifetime_ust(:,1:sav_typ),[],2); %returns 2285x1vector containing the savingsrate that maximizes life time utility looking from age 60 (pj==1)
    optst(:,typ)=optst_temp;
    end;
    
    for pj=1:pmax
   darr{1,pj}.optst=(optst(darr{1,pj}.from1toP==1,:));
    end;
    

%% actual likelihood computation at all ages
    
for typ = 1:anz_typ
for pj=1:pmax %run over different starting periods
    
    
    
    
    p=pmax-pj+1; % length of horizon until age 65

    d=darr{pj};
    st=d.optst(:,typ);
    mon=d.mon;
    cr=d.ch(:,1);
    cr_r=d.ch_r(:,1);
    N=d.N;
    
    

    
       
    if pj==1 && typ==1
        N0=N;
        l_typlik_n=ones(N0,anz_typ); %individual specific liklihood contribution by type    
    end    
    
    
% typlik=NaN(N,2);  

  
   [Pr_work, Pr_Rreg, Pr_Runempl,uret,uwork]=dplik(d,mon,cr,cr_r,para_eV,p,pj,pmax,model_para_vec,T,N,sim,e,surv,typ,era,WDmin,st);
%typlik(:,typ+1)=((1-typ).*typ0prob + typ.*(1-typ0prob )).*((cr(:,1)==0).*Pr_work  + (cr(:,1)==1).*(cr_r(:,1)==0).*(Pr_Rreg) + (cr(:,1)==1).*(cr_r(:,1)==1).* Pr_Runempl);
    if typ==1
      t1{1,pj}.U= [Pr_work.*uwork  Pr_Rreg.*uret(:,1)  Pr_Runempl.*uret(:,2) ];
    end
    if typ==2
      t2{1,pj}.U= [Pr_work.*uwork  Pr_Rreg.*uret(:,1)  Pr_Runempl.*uret(:,2)  ];
    end
    
    


    %if sum(d.ic==n)==1
l_typlik_n(d.from1toP==1,typ)=l_typlik_n(d.from1toP==1,typ).* ... %individual-, period- and type-specific likelihood
    ((cr(:,1)==0).*Pr_work  + (cr(:,1)==1).*(cr_r(:,1)==0).*(Pr_Rreg) + (cr(:,1)==1).*(cr_r(:,1)==1).* Pr_Runempl);
    %end


arr{1,pj}.prw(:,typ)=Pr_work; %save prob to work times prob of being a type    % *((1-typ).*typ0prob + typ.*(1-typ0prob ))
arr{1,pj}.pru(:,typ)=Pr_Runempl; %save prob to retire via unempl times prob of being a type
arr{1,pj}.prr(:,typ)=Pr_Rreg; %save prob to retire regularly times prob of being a type

   
end


end
val=sum( max( [  ... %%% IS THE FOLLOWING LINE CORRECT?
        -log(l_typlik_n*typprob  )    ...  %-log( typ0prob.*l_typlik_n(:,1)+(1-typ0prob ).*l_typlik_n(:,2)  )
        ones(N0,1).*10.^(-10) ],[],2   )); %sum up likelihood within different subsamples of length pj periods! +Pr_fric
global PR_MEAN;

%end of typ=0:1

%for c=1:6
%    cohort=1939+c;
%PR_MEAN(pj,1:3,c) = [mean(Pr_Runempl(d.gebjahr==cohort)) mean(Pr_Rreg(d.gebjahr==cohort)) mean(Pr_work(d.gebjahr==cohort))];
%end
typcalc=typprob;
for pj=1:pmax
    if pj>1 %justierung kommt nicht zum einsatz
    typcalc(1)=typcalc(1).*( mean(arr{1,pj-1}.prw(:,1)) ) ./ ( typcalc(1).*mean(arr{1,pj-1}.prw(:,1))+typcalc(2).*mean(arr{1,pj-1}.prw(:,2))  );
    typcalc(2)=1-typcalc(1);
    end
    %typ0prob_l(pj,1)=typ0prob;
    
    
PR_MEAN(pj,1:3,1) = [mean(arr{1,pj}.pru(:,1:2)*typprob(1:2)) mean(arr{1,pj}.prr(:,1:2)*typprob(1:2)) mean(arr{1,pj}.prw(:,1:2)*typprob(1:2))];
PR_MEAN(pj,1:6,2) = [mean(arr{1,pj}.pru(:,1)) mean(arr{1,pj}.pru(:,2))  mean(arr{1,pj}.prr(:,1)) mean(arr{1,pj}.prr(:,2))  mean(arr{1,pj}.prw(:,1)) mean(arr{1,pj}.prw(:,2)) ]; % ./(1-typ0prob )
PR_MEAN(pj,1:3,3) = [mean(arr{1,pj}.pru(:,1:2)*typcalc(1:2)) mean(arr{1,pj}.prr(:,1:2)*typcalc(1:2)) mean(arr{1,pj}.prw(:,1:2)*typcalc(1:2))];
end
%mean(d.prob_fric(d.gebjahr==cohort,:,pj)) 



%PR_MEAN(1,1:pmax,3)=typ0prob_l';
%PR_MEAN(1,1:pmax,3)

%val=LL_subsample(pmax-1)+LL_subsample(pmax-2);
%val=sum(LL_subsample(1)); %sum up likelihood of different subsamples! (subsmin:subsmax)
%fprintf('prs: %12.8f\n',paras)

end



