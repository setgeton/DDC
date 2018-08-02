%% 1 to pmax period generator
function [darr]=pmaxgen(pmax,darr,reform,partfric,h4)


interest=darr{1,1}.interest;

sav_typ=darr{1,1}.sav_typ;
savrate=darr{1,1}.savrate;
delta_inc=darr{1,1}.delta_inc;
N=length(darr{1,1}.rente(:,1));

darr{1,1}.abschlag=(darr{1,1}.rente(:,5)-darr{1,1}.rente(:,4)); %yearly pension increase (deduction+contribution)
%darr{1,1}.abschlag_nowage=darr{1,1}.renteA(:,1)./0.82.*0.036; %yearly pension increase when no work (only deduction)
%darr{1,1}.abschlagA=(darr{1,1}.renteA(:,5)-darr{1,1}.renteA(:,4)); %pension level when 65 is 1/0.82 of todays pension level
darr{1,1}.renteMAX=darr{1,1}.rente(:,6); %pension level when 65 is 1/0.82 of todays pension level + future contributions influence

if reform==67
     darr{1,1}.renteMAX=darr{1,1}.rente(:,6).*max([darr{1,1}.rente(:,5)./darr{1,1}.rente(:,4) - 0.036 ones(length(darr{1,1}.rente(:,1)),1)] ,[],2).^2; %pension level when 67 = 65 + adjusted for further egpt
     darr{1,1}.renteA(:,1)=darr{1,1}.renteA(:,1).*0.748./0.82;
     
end


for pj=1:pmax %run over different starting periods
darr{1,pj}=darr{1,1};
darr{1,pj}.mon=12.*ones(length(darr{1,pj}.mon),1)+12.*darr{1,1}.tenure5;
end



%% ACHTUNG: auch höhere rente durch mehr beitragspunkte
for pj=1:pmax
  darr{1,pj}.renteA(:,1)=darr{1,1}.renteA(:,1)+(pj-1).*darr{1,1}.abschlag;
  for it=2:pmax+3 %size(darr{1,pj}.renteA,2)+2
    darr{1,pj}.renteA(:,it)=min([darr{1,pj}.renteA(:,it-1)+darr{1,pj}.abschlag darr{1,pj}.renteMAX] ,[],2) ;
  end
end

for pj=1:pmax
 darr{1,pj}.prob_fric(:,1:7)=partfric.*[darr{1,pj}.prob_fric(:,pj:7) darr{1,pj}.prob_fric(:,end)*ones(1,pj-1)] ;  
    for it=1:pmax+3
 darr{1,pj}.renteA(:,it)=max([darr{1,pj}.renteA(:,it) h4.*ones(length(darr{1,pj}.renteA(:,it)),1)] ,[],2) ;
    end
end


%%%HERE: BUILD IN THAT ACCESS NOT BEFORE 63! UND 35 JAHRE BEITRAGSZ!
    for pj=1:pmax %copy renten values from alo rente which is equivalent with only difference being eligibility
    darr{1,pj}.rente=darr{1,pj}.renteA;
    end
 for pj=1:3
  for it=1:(3-pj+1)
     darr{1,pj}.rente(:,it)=zeros(length(darr{1,pj}.rente(:,it)),1);
  end
 end

 
 %% INCOME, Wealth, from DPREP
 
 %% wealth initialization
%d.fin_dyn=NaN(N,pmax+2,sav_typ);
%d.fin_i=NaN(N,pmax+2,sav_typ);
%d.house=1.*(((own_house.*w_house./1000)./30)./12);
%d.lt_earn=rente5_exp./28.07.*30000;
    %w_fin./1000 unused? or factor in by decreasing importance of endogeneous
    %savings?!
    
 for pj=1:pmax
     for st=1:sav_typ
  darr{1,pj}.fin_dyn(:,1,st)=darr{1,1}.fin_dyn(:,pj,st);
  %darr{1,pj}.fin_i(:,1,st)=darr{1,1}.fin_i(:,pj,st);
     end;
 end    
    
%% income
%darr{1,1}.incw(:,1)=darr{1,1}.incw(:,1) -darr{1,1}.house -darr{1,1}.inc_partner(:,1);


darr{1,1}.inc_partner_temp=darr{1,1}.inc_partner;
darr{1,1}.inc_partner_ue_temp=darr{1,1}.inc_partner_ue;
for pj=1:pmax
 darr{1,pj}.inc_partner=NaN(N,pmax+3);
 darr{1,pj}.inc_partner_ue=NaN(N,pmax+3);   
for it=1:pmax+3
darr{1,pj}.inc_partner(:,it)=darr{1,1}.inc_partner_temp(:,1+ pj-1 + it-1) ;  
darr{1,pj}.inc_partner_ue(:,it)=darr{1,1}.inc_partner_ue_temp(:,1+ pj-1 + it-1) ;  
end
end



for pj=1:pmax
for it=1:pmax+3
darr{1,pj}.inc_couple(:,it)=darr{1,1}.incm(:,1).*(1+delta_inc).^(pj-1 + it-1)+ darr{1,pj}.inc_partner(:,it) ;  
end
end

for pj=1:pmax
for it=1:pmax+3
darr{1,pj}.incw(:,it)=max((darr{1,pj}.inc_couple(:,it)-1.0.*tax(darr{1,pj}.inc_couple(:,it),0,darr{1,1}.prob_partner)),h4); %disposable income equals gross minus tax but at leeast h4 level
end
end


%d.house=0.*(((w_house./1000)>100).*0.3+((w_house./1000)>112).*0.1+((w_house./1000)>120).*0.1); %0.3k to 0.5k additional income for House owner--> if imputed residence wealth>100k (i.e. house is worth>200k if couple)
%  -0.66.*mean(((w_house./1000)./30)./12) +; %0.3k to 0.5k additional income for House owner--> if imputed residence wealth>100k (i.e. house is worth>200k if couple)

 for pj=1:pmax
    darr{1,pj}.sav_from_inc=NaN(N,pmax+1,sav_typ); 
for st=1:sav_typ
for it=1:pmax+2
darr{1,pj}.sav_from_inc(:,it,st)=(darr{1,pj}.incw(:,it)).*(savrate(st)); % savings from rent free income
darr{1,pj}.incw_sav(:,it,st)=(darr{1,pj}.incw(:,it)).*(1-savrate(st))+darr{1,1}.house; %disposable income after savings == net inc plus rent-free leving * (1-savingsrate)
end
end
 end
 
 for pj=1:pmax
 for it=1:pmax+3
  darr{1,pj}.incw(:,it)=darr{1,pj}.incw(:,it)+darr{1,pj}.house;
  end
 end 
 

for pj=1:pmax %starting period/period now
for addp=2:pmax+3 %future periods, 1 being now/starting period
    for st=1:sav_typ
darr{1,pj}.fin_dyn(:,addp,st)=darr{1,pj}.fin_dyn(:,addp-1,st)*(1+interest) + (darr{1,pj}.sav_from_inc(:,addp-1,st)).*12.*(1+interest); %how much starting value of liquid assets from lower ages of same person plus new savings
%darr{1,pj}.fin_i(:,addp,st)=darr{1,pj}.fin_dyn(:,addp,st).*interest./12;
    end;
end;
end;

for pj=1:pmax
    for st=1:sav_typ
        for pi=1:pmax+3
        %darr{1,pj}.annuA_interestonly(:,pi,st)=darr{1,pj}.house+darr{1,pj}.fin_i(:,pi,st); %
        darr{1,pj}.annuA(:,pi,st)=max(0.7.*darr{1,pj}.inc_partner_ue(:,pi)+darr{1,pj}.house+darr{1,pj}.fin_dyn(:,pi,st).*(1./12)./((1-(1+interest).^(-(90-(60+pj-1)+(pi-1))) )./interest),0.001.*ones(N,1)); %generate montly annuity from wealth (in 1k euros) avalaible always (if work iust stopped)
                                    %additional income from not paying rent but owning house 
        darr{1,pj}.annu(darr{1,pj}.rente(:,pi)>0.01,pi,st)=darr{1,pj}.annuA(darr{1,pj}.rente(:,pi)>0.01,pi,st); %annuity only avalaible if regular pension eligibility --> the need is rather technical (not trick people into pension if no eligibility)
        darr{1,pj}.annu(darr{1,pj}.rente(:,pi)<=0.01,pi,st)=0.001.*ones(sum(darr{1,pj}.rente(:,pi)<=0.01),1)+0.00.*darr{1,pj}.annuA(darr{1,pj}.rente(:,pi)<=0.01,pi,st); % annuity to zero if no pension elegibility

        end
    end
end
 






end




