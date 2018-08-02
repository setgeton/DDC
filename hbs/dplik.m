% likelihood evaluation
function [Pr_work, Pr_Rreg, Pr_Runempl,uret,uwork]=dplik(d,mon,cr,cr_r,para_eV,p,pj,pmax,model_para_vec,T,N,sim,e,surv,typ,era,WDmin,st)


b2=model_para_vec(1);
b3=model_para_vec(2);
h4=model_para_vec(3);

del=para_eV(1);
gamm=para_eV(2);
alpha=para_eV(3);
stigma=para_eV(4:3+b3)';
beta2=para_eV(3+b3+1:3+b3+b2)';
a63=para_eV(4+b3+b2).*(typ==1);
alpha3=para_eV(6+b3+b2);

d1dim=d;
annuwidth=length(d.annu(1,1:end,1));
annuheigth=length(d.annu(1:end,1,1));
d1dim.annu=zeros(annuheigth,annuwidth,1);
d1dim.annuA=zeros(annuheigth,annuwidth,1);
d1dim.incw_sav=zeros(annuheigth,annuwidth-1,1);
for sti=1:d.sav_typ;
d1dim.annu=d1dim.annu+((st==sti)*ones(1,annuwidth)).*d.annu(:,:,sti);
d1dim.annuA=d1dim.annuA+((st==sti)*ones(1,annuwidth)).*d.annuA(:,:,sti);
d1dim.incw_sav=d1dim.incw_sav+((st==sti)*ones(1,annuwidth-1)).*d.incw_sav(:,:,sti);
end;
    %% rekursive Valuefunction calculation
    % eVFt(:,j, -(p-pmax))=expected Value from (all indiv, conditional on ret in period j (65=p&64=p-1&...pj=1), for the specific period 65=1&64=2&... runs backwards=recursive)

    [eVFt,~,~,nu,tau,V_ret65,V_ret65u12,eVret,eVretu12,eVretu24,eVretu32,eVretu12H4_24,eVretu12H4_36,eVretu24H4_36]=eVfunc(para_eV,d1dim,p,pmax,model_para_vec,T,N,sim,e,surv,typ,era,WDmin);

    %% LIKELIHOOD BERECHNUNG




    uret=NaN(N,2);
    uwork=NaN(N,1);
    Pr_work=NaN(N,1);
    Pr_Rreg=NaN(N,1);
    Pr_Runempl=NaN(N,1);
    
    dchoice=[cr(:,1)==1 cr(:,1)==0]; %how do individuals behave in their respective first period
    dchoice_r=[cr_r(:,1)==1 cr_r(:,1)==0]; %which pathway into retirement
    %utility of different choices

    if pj<pmax %more than one period until 66
        
        alo_u = @(alosatz,mon,gam,x3,stigm,eVretu12,eVretu24,eVretu32) (mon~=24 & mon~=32).*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj) + eVretu12(:,1)  ) ... 12month unemplbenefits
    +(mon==24).* ( ((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj)  + del.*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1)  + eVretu24(:,1)  ) )...
    +(mon==32).* ( ((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj)  + del.*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1) )  ...
            +(del^2).*((2/3).*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+2)) ...
                + (1/3).*(((d.annuA(:,1)+d.renteA(:,1+2)).^(1-gam)-1)/(1-gam))...
                +eVretu32(:,1)  ) ) ;

            if pj==1 && era==63 %that is, age 60!
                   
                      alo_u = @(alosatz,mon,gam,x3,stigm,eVretu12,eVretu24,eVretu32) (mon==12).* ( ((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj) ... 12month unempl benefits then hartz4
                          + del.*(((d.annu(:,1)+alpha3.*h4(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1) )  ...
                        +(del^2).*((3/3).*(((d.annuA(:,1)+alpha3.*h4(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+2)) ...
                            + (0/3).*(((d.annuA(:,1)+d.renteA(:,1+2)).^(1-gam)-1)/(1-gam))...
                            +eVretu24H4_36(:,1)  ) ) ...
                  +(mon==24).* ( ((d.annu(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj)  + del.*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1) )  ... 24 unempl then h4
                        +(del^2).*((3/3).*(((d.annuA(:,1)+alpha3.*h4(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+2)) ...
                            + (0/3).*(((d.annuA(:,1)+d.renteA(:,1+2)).^(1-gam)-1)/(1-gam))...
                            +eVretu12H4_36(:,1)  ) ) ;
            end
             if pj==2 && era==63 %that is, age 61!
                   
                      alo_u = @(alosatz,mon,gam,x3,stigm,eVretu12,eVretu24,eVretu32)  +(mon==12).* ( ((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj)...
                  + del.*(((d.annuA(:,1)+alpha3.*h4(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1)  + eVretu12H4_24(:,1)  ) )...
                  +(mon==24).* ( ((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj)...
                  + del.*(((d.annuA(:,1)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pj+1)  + eVretu24(:,1)  ) );
            end
        
    
    uret(:,1)=(((d.annu(:,1)+d.rente(:,1)).^(1-gamm)-1)./(1-gamm))+eVret(:,1)+a63.*(pj==4).*ones(N,1) ; %at age 63 there's a special access to retirement
    uret(:,2)=alo_u(d.alosatz,mon,gamm,d.x3,stigma,eVretu12,eVretu24,eVretu32); % retirement option unemployment
     
    
    %uc(:,1)=(((d.annu(:,1)+d.alosatz(:,1)).^(1-gamm)-1)/(1-gamm))-stigma+eVretu(:,1); % retirement option unemployment
    uwork=((d.incw_sav(:,1).^(1-gamm)-1)/(1-gamm))-nu(:,pj)+del.*(eVFt(:,2,p-1)); %working option %+d.x2*(-beta2)
    
    end

    if pj==pmax %only one period
    
    uret(:,1)=(((d.annu(:,1)+d.rente(:,1)).^(1-gamm)-1)/(1-gamm) + V_ret65(:,p) ); % retirement option 1
    uret(:,2)=(((d.annuA(:,1)+alpha3.*d.alosatz(:,1)).^(1-gamm)-1)/(1-gamm) -tau(:,pj) + V_ret65u12(:,p) ); % retirement option 2
    
    
        
    %(d.rente(:,1).^(1-gamm)-1)/(1-gamm)-(d.alosatz(:,1).^(1-gamm)-1)/(1-gamm)
    uwork=((d.incw_sav(:,1).^(1-gamm)-1)/(1-gamm) -nu(:,pj) + V_ret65(:,p+1)); %working option
    %uc(:,3)=((d.rente(:,1).^(1-gamm)-1)/(1-gamm) + V_ret65u(:,p) );    %retirement option 1
    
    end

    %uoptc =(uc.*dchoice*ones(2,1)); %utility realized choice
    %u_c=(uc.*(1-dchoice)*ones(2,1)) - uoptc;

    % sum (of exponential of) utilities from other than optim choice+1 (optimal
    % choice is as zero in u_c --> exp(0)=1)
    %sumexpuc =(exp(u_c)+1);
    %Pr of observing optim choice
    %Pr_fric=NaN(N,1);
    %Pr_optc=NaN(N,1);
    Pr_work=(d.rente(:,1)>0.01) .* max( [  ... %Pr to work for those eligible for Rreg
        (   (ones(N,1)-d.prob_fric(:,pj)) .* 1./(1+exp(log(exp(uret(:,1)) + exp(uret(:,2)))    -uwork)) )     ...
        ones(N,1).*10.^(-10) ],[],2   ) + ...
        (d.rente(:,1)<0.01).* max( [  ... %Pr to work for those NOT eligible for Rreg
        (   (ones(N,1)-d.prob_fric(:,pj)) .* 1./(1+exp(uret(:,2)    -uwork)) )     ...
        ones(N,1).*10.^(-10) ],[],2   ) ;
    %Pr_fric=(d.prob_fric(:,pj)).*(dchoice(:,1)==1);
    Pr_Rreg=(d.rente(:,1)>0.01) .* ... %Pr to retire via Rreg for those eligible for Rreg
        (d.prob_fric(:,pj)+(1-d.prob_fric(:,pj)).* 1./(1+exp(uwork -log(exp(uret(:,1)) + exp(uret(:,2)))   ))  ) ... Pr to end up retired
        .* 1./(1+exp(uret(:,2)-uret(:,1))) + ... %Pr to retire regularly |cond on retirement
         (d.rente(:,1)<0.01).*0.000000001; %Pr to retire via Rreg for those NOT eligible for Rreg
    Pr_Runempl=(d.rente(:,1)>0.01) .* ... %Pr to retire via Runempl for those eligible for Rreg
        (d.prob_fric(:,pj)+(1-d.prob_fric(:,pj)).* 1./(1+exp(uwork -log(exp(uret(:,1)) + exp(uret(:,2)))   ))  ) ... Pr to end up retired
        .* 1./(1+exp(uret(:,1)-uret(:,2))) ... %Pr to retire via unempl |cond on retirement
        + (d.rente(:,1)<0.01).*... %Pr to retire via Runempl for those NOT eligible for Rreg
    (d.prob_fric(:,pj)+(1-d.prob_fric(:,pj)).* 1./(1+exp(uwork -uret(:,2)   )) ); % Pr to end up retired with only Runempl as an option
%LL_subsample(pj)=sum(-log(Pr_optc(d.startalter>=720 & d.startalter<=780)+Pr_fric(d.startalter>=720 & d.startalter<=780))); %sum up likelihood within different subsamples of length pj periods! +Pr_fric


end



