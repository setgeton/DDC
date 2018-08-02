clear;

%%set years to analyse: 3=all, 4= simulation on the ground of years 43,44
%%first observations(other periods will be simulated)

for yr = ['3','4']

%load(['..\matlab\ws' yr 'b.mat']);
load(['H:\data\ws' yr 'b.mat']);

c=2; %number of choices
T=20; %Time horizon after age65
delta_inc=0.01; %yearly change in wages
pmax=5;
pre_est_lifespan=5;
a=4; %periods added for sefety
h4=0.5; % level of social assistance (hartz4)
interest=0.02;
sav_typ=60;
savrate=(0.001:0.005:(sav_typ-1)*0.005+0.001);  %step size has to be factored into sim for average savingsrate computation
N =length(rente0_exp);
startalter=720.*ones(N,1);
obs=sum(altersg<65);
[~,~,xxc]=unique(persnr(altersg<65));
uniq_pers=max(xxc);

[~,~,icpers]=unique(persnr); %persnr from 1 to N

if yr=='3'
fprintf('Maximum Likelihood Estimation of Model Parameters uses %6.0f observations of %6.0f unique persons in up to %2.0f periods \r\n',N,uniq_pers,pmax)
end

if yr=='4'
fprintf('Subsequent simulation will use %6.0f observations of %6.0f unique persons as starting point to simulate\n',N)
fprintf('biographies of %2.0f periods; if indicated, procedure is repeated 1000 times. \r\n',uniq_pers,pmax)
end

simdataseed = RandStream('mt19937ar','seed',116);
RandStream.setGlobalStream(simdataseed);


p=pmax; %periods until definite retirement

p0=zeros(N,1);
for pj=1:pmax+1
p0=p0+pj.*(alter>=720+(pj-1).*12 & alter<732+(pj-1).*12 );
end



incm=lohn_exp.*30./1000;
%% Prob of involuntary job loss
%d.prob_fric=  0.5.*alopr*(ones(1,pmax)); % zeros(N,pmax)  ; %

alterp=[alter/12 alter/12+1 alter/12+2 alter/12+3 alter/12+4 alter/12+5 alter/12+6 alter/12+7 alter/12+8 alter/12+9 alter/12+10 alter/12+11 alter/12+12 alter/12+13 alter/12+14 alter/12+15 alter/12+16 alter/12+17 alter/12+18 alter/12+19];
%bsmon(bsmon==59)=240;
d.prob_fric =1.00.*1./(1+exp(-( 0.00499*(alterp(:,1:pmax+a)) +((   0.637*jahre_ue -0.0753.*(min([jahre_ue 7.*ones(N,1)],[],2)).^2 -0.169*jahre_e +0.00262*jahre_e2 - 0.512*tenure2p -0.315*log(incm(:,1).*1000) -0.0451*(9+jahre_schule) +0.076*(1-deu) +2.382)*ones(1,pmax+a) ) ) ));
fprintf('Friction probabilities average at %6.6f \n',mean(d.prob_fric(:,1)))

employed=ones(N,1);
prob_partner =1.00.*1./(1+exp(-( -0.0309*(alterp(:,1)) +((   0.0803*jahre_ue +0.1202*jahre_e -0.00145*jahre_e2 - 0.1406*tenure2p +0.0000587*(incm(:,1).*1000) +0.3881.*(1-employed) +0.009694*(9+jahre_schule) +0.179*(1-deu) +1.0025)*ones(1,1) ) ) ));
fprintf('Probability of having partner average at %6.6f (std: %3.6f) \n',mean(prob_partner),std(prob_partner))

prob_partner_inc_d =1.00.*1./(1+exp(-( -0.0222*(alterp(:,1:pmax+pmax+a+a)) +((   0.0138*jahre_ue +0.0020*jahre_e -0.0005*jahre_e2 - 0.0102*tenure2p +   0.0000139*(incm(:,1).*1000) -0.0352.*(1-employed) +0.0263*(9+jahre_schule) +0.076*(1-deu) +1.5705)*ones(1,pmax+pmax+a+a) ) ) ));
fprintf('Probability of partner earning income at %6.6f (std: %3.6f) \n',mean(prob_partner_inc_d(:,1)),std(prob_partner_inc_d(:,1)))

prob_partner_inc_d_ue =1.00.*1./(1+exp(-( -0.0222*(alterp(:,1:pmax+pmax+a+a)) +((   0.0138*jahre_ue +0.0020*jahre_e -0.0005*jahre_e2 - 0.0102*tenure2p +0.*0.0000139*(incm(:,1).*1000) -0.0352.*(1)           +0.0263*(9+jahre_schule) +0.076*(1-deu) +1.5705)*ones(1,pmax+pmax+a+a) ) ) ));
%fprintf('Probability of partner earning income if individual is unemployed at %6.6f \n',mean(prob_partner_inc_d_ue(:,1)))

pred_partner_income =(1.00./1000).*(exp( -0.0211*(alterp(:,1:pmax+pmax+a+a)) +(   -0.0364*jahre_ue +0.0037*jahre_e -0.00022*jahre_e2 - 0.0767*tenure2p     +   0.000016*(incm(:,1).*1000) -0.0383.*(1-employed)   +0.0695*(9+jahre_schule) +0.0299*(1-deu) +7.6337)*ones(1,pmax+pmax+a+a)  ));
fprintf('Predicted partner income at %3.6f (std: %3.6f) \n',mean(pred_partner_income(:,1)),std(pred_partner_income(:,1)))

pred_partner_income_ue =(1.00./1000).*(exp( -0.0211*(alterp(:,1:pmax+pmax+a+a)) +(   -0.0364*jahre_ue +0.0037*jahre_e -0.00022*jahre_e2 - 0.0767*tenure2p  +0.*0.000016*(incm(:,1).*1000) -0.0383.*(1)             +0.0695*(9+jahre_schule) +0.0299*(1-deu) +7.6337)*ones(1,pmax+pmax+a+a)  ));
%fprintf('Predicted partner income if individual is unemployed at %6.6f \n',mean(pred_partner_income_ue(:,1)))


%% Income
d.incw=NaN(N,pmax+a);
%t_lowbr=0.7;
%t_highbr=0.6;
%t_thresh=1.8;
%d.incw(:,1)=max(incm-tax(incm,0),h4); %t_lowbr.*d.incw(:,1).*(d.incw(:,1)<t_thresh)+(t_thresh.*t_lowbr+((d.incw(:,1)-t_thresh).*t_highbr)).*(d.incw(:,1)>=t_thresh); %tax func T(inc)=tax free until 1100e, above 35%

for it=1:pmax+pmax+a+a
d.inc_partner(:,it)=prob_partner.*prob_partner_inc_d(:,it).*pred_partner_income(:,it);
d.inc_partner_ue(:,it)=prob_partner.*prob_partner_inc_d_ue(:,it).*pred_partner_income_ue(:,it);
end

inc_couple=NaN(N,p+a);
for it=1:p+a
inc_couple(:,it)=incm.*(1+delta_inc).^(it-1)+d.inc_partner(:,it);  
d.incw(:,it)=max((inc_couple(:,it)-1.0.*tax(inc_couple(:,it),0,prob_partner)),h4); %disposable income equals gross minus tax but at leeast h4 level
end
d.taxrate(:,1)=(inc_couple(:,1)-max((inc_couple(:,1)-1.0.*tax(inc_couple(:,1),0,prob_partner)),h4))./(inc_couple(:,1));
alosatz=max(alosatz./1000.*(60./100) + 0.0001,h4);

%fprintf('income tax scheme: %6.2f perc up to %6.2f , and %6.2f above  \n',1-t_lowbr,t_thresh*1000,1-t_highbr)
fprintf('h4 level is set to EUR %2.2f \n',h4*1000)

%REGULAR RETIREMENT

%prae-reform-renten
d.rente=NaN(N,pmax+a);
d.rente=[rente0_exp rente1_exp rente2_exp rente3_exp rente4_exp rente5_exp*ones(1,a)];
d.rente=( d.rente)./1000;
for pi=1:pmax+a
    couple_rente_inc_temp=d.rente(d.rente(:,pi)>0.01,pi)+d.inc_partner_ue(d.rente(:,pi)>0.01,pi);  %what does the couple earn together once indiivdual is retired.
d.rente(d.rente(:,pi)>0.01,pi)=d.rente(d.rente(:,pi)>0.01,pi)-(d.rente(d.rente(:,pi)>0.01,pi)./couple_rente_inc_temp).*tax(couple_rente_inc_temp,1,prob_partner(d.rente(:,pi)>0.01)); % 50% of retirement benefits are taxed
end


for pi=1:pmax+a
d.rente(d.rente(:,pi)>0.01,pi)=max(d.rente(d.rente(:,pi)>0.01,pi),h4); %minimum is h4, but only for those who are eleigible in the first place for reg retirement
end

%post-reform-renten
%d.renter=NaN(N,pmax+a);
%d.renter=[ded_rente0_exp ded_rente1_exp ded_rente2_exp ded_rente3_exp ded_rente4_exp ded_rente5_exp*ones(1,a)];
%d.renter=(ones(N,pmax+a) + d.renter)./1000;

%RETIREMENT AFTER UNEMPLOYMENT (ALO)
%prae-reform-renten
d.renteA=NaN(N,pmax+a);
d.renteA=[rente0_expA rente1_expA rente2_expA rente3_expA rente4_expA rente5_expA*ones(1,a)];
d.renteA=(d.renteA)./1000; % 0.001.*ones(N,pmax+a) + 
for pi=1:pmax+a
couple_renteA_inc_temp=d.renteA(:,pi)+d.inc_partner_ue(:,pi);  %what does the couple earn together once indiivdual is retired.
d.renteA(:,pi)=d.renteA(:,pi)-(d.renteA(:,pi)./couple_renteA_inc_temp).*tax(couple_renteA_inc_temp,1,prob_partner); %   deduct taxes that stem from retirement income of individual, other taxes deucted in annuA
end

for pi=1:pmax+a
d.renteA(:,pi)=max(d.renteA(:,pi),h4); %minimum is h4
end

%post-reform-renten
%d.renterA=NaN(N,pmax+a);
%d.renterA=[ded_rente0_expA ded_rente1_expA ded_rente2_expA ded_rente3_expA ded_rente4_expA ded_rente5_expA*ones(1,a)];
%d.renterA=(ones(N,pmax+a) + d.renterA)./1000;

%% wealth initialization
d.fin_dyn=NaN(N,pmax+2,sav_typ);
%d.fin_i=NaN(N,pmax+2,sav_typ);
d.house=((40-pre_est_lifespan)./40).*(((own_house.*w_house./1000)./30)./12);
d.lt_earn=rente5_exp./28.07.*30000;
    %w_fin./1000 unused? or factor in by decreasing importance of endogeneous
    %savings?!
lfte_mon=(d.lt_earn(:,1)./40)./1000./12;

pre_est_endog_savings=zeros(N,sav_typ);
for pj=1:pre_est_lifespan
    for i=1:sav_typ
  pre_est_endog_savings(:,i)=pre_est_endog_savings(:,i).*(1+interest)+(savrate(i).*12.*(lfte_mon+d.inc_partner(:,1)  -1.*tax(lfte_mon+d.inc_partner(:,1),0,prob_partner))); %endogenous savings from those 5 pre-estimation years  
    end
end
    
for st=1:sav_typ
    %20% chance of having inherited 70% of the house, that is, need to pay down
    %a smaller mortgage for basic renovation only (that's the missing 30%)
d.fin_dyn(altersg==60,1,st)=((40-pre_est_lifespan)./40).*( w_fin(altersg==60) )./1000 + pre_est_endog_savings(altersg==60,st)  ; %how much starting value of liquid assets
%d.fin_i(altersg==60,1,st)=d.fin_dyn(altersg==60,1,st).*interest./12;
end


%% income from labor plus house minus savings.

sav_from_inc=NaN(N,pmax+1,sav_typ);
%d.house=0.*(((w_house./1000)>100).*0.3+((w_house./1000)>112).*0.1+((w_house./1000)>120).*0.1); %0.3k to 0.5k additional income for House owner--> if imputed residence wealth>100k (i.e. house is worth>200k if couple)
%  -0.66.*mean(((w_house./1000)./30)./12) +; %0.3k to 0.5k additional income for House owner--> if imputed residence wealth>100k (i.e. house is worth>200k if couple)
d.annuA=NaN(N,pmax+a,sav_typ);

for st=1:sav_typ
for it=1:p+a-1
sav_from_inc(:,it,st)=(d.incw(:,it)).*(savrate(st)); % savings from rent free income
d.incw_sav(:,it,st)=(d.incw(:,it)).*(1-savrate(st))+d.house; %disposable income after savings == net inc plus rent-free leving * (1-savingsrate)
end
end

for it=1:p+a-1
d.incw(:,it)=d.incw(:,it)+d.house; %disposable income before savings == net inc plus rent-free leving
end

for alt=61:65
for pid=1:uniq_pers
    for st=1:sav_typ
d.fin_dyn(altersg==alt&icpers==pid,1,st)=d.fin_dyn(altersg==alt-1&icpers==pid,1,st)*(1+interest) + (sav_from_inc(altersg==alt-1&icpers==pid,1,st)).*12.*(1+interest); %how much starting value of liquid assets from lower ages of same person plus new savings
%d.fin_i(altersg==alt&icpers==pid,1,st)=d.fin_dyn(altersg==alt&icpers==pid,1,st).*interest./12;
    end;
end;
end;



%%wealth dynamics and annuity computation
for st=1:sav_typ
for pi=2:pmax+a 
d.fin_dyn(:,pi,st)=( (d.fin_dyn(:,pi-1,st)*(1+interest)) + sav_from_inc(:,pi-1,st).*12.*(1+interest) );  %last periods stock plus interest and last periods new savings plus interest makes new stock
%d.fin_i(:,pi,st)=d.fin_dyn(:,pi,st).*interest./12; %indefinite interest payment from current stock
end
end

for st=1:sav_typ
for pi=1:pmax+a 
%d.annuA_interestonly(:,pi,st)=d.house+d.fin_i(:,pi,st); %
d.annuA(:,pi,st)=max(0.7.*d.inc_partner_ue(:,pi)+d.house+d.fin_dyn(:,pi,st).*(1./12)./((1-(1+interest).^(-(90-(alter./12)+(pi-1))) )./interest),0.0001.*ones(N,1)); %generate montly annuity from wealth (in 1k euros) avalaible always (if work iust stopped)
                            %additional income from not paying rent but owning house 
d.annu(d.rente(:,pi)>0.01,pi,st)=d.annuA(d.rente(:,pi)>0.01,pi,st); %annuity only avalaible if regular pension eligibility --> the need is rather technical (not trick people into pension if no eligibility)
d.annu(d.rente(:,pi)<=0.01,pi,st)=0.001.*ones(sum(d.rente(:,pi)<=0.01),1)+0.00.*d.annuA(d.rente(:,pi)<=0.01,pi,st); % annuity to zero if no pension elegibility

end
end




ausbil(isnan(ausbil))=1;
%ausbil(ausbil==2)=1;
ausbil(ausbil==3)=2;
ausbil(ausbil>=4)=3;

stib(stib==4)=3; % 1=Ungelernte+TZ+Heimarbeit, 2=Arbeiter, 3=Meister+Angestellte
stib(stib>4)=1;
stib_dum=dummyvar(stib);

alo_kr(isnan(alo_kr))=mean(alo_kr(isnan(alo_kr)==0));
bula(isnan(bula))=1;
bula_dum=dummyvar(bula); %create dummy variables for federal states//bundesländer
ausbil_dum=dummyvar(ausbil);
%ant_ue55_jun2007(isnan(ant_ue55_jun2007))=mean(ant_ue55_jun2007(isnan(ant_ue55_jun2007)==0));
d.x2=[stib_dum(:,1:end-1) jahre_schule ones(N,1) ]; %stib_dum(:,1:end-1) ones(N,1) (ausbil<3) (ausbil<3) krank05  ones(N,1) alo_kr ; %(ausbil<3) krank05 jahre_schule<--erklärt nichts;  % deu log(d.incw(:,1)./1000+1)  (startalter-720) firstday  ((startalter-720).^2)./1000
d.x3=[tenure5 ones(N,1) ]; %tenure5 deu alo_kr deu ant_ue55_jun2007 (jahre_alo5060>0) (zfalo0+0.003.*mon_delete)>=1 alo_kr ausbil<3 ones(N,1)
if yr=='3'
    fprintf('covariates in x2: stib_dum(:,1:end-1) jahre_schule ones(N,1) \n');
    fprintf('covariates in x3: tenure5 ones(N,1)  \r\n');
    fprintf('further covariates used in descriptive analysis of simulations include: ausbil_dum(sampch==1,:) alo_kr(sampch==1) krank05(sampch==1) deu(sampch==1) \r\n')
end
b2=size(d.x2,2);
b3=size(d.x3,2);


%mon_delete=(12).*(alo_rente>0 | atz_rente>0);
%mon_delete(mon_delete==12 & bula<5)= 32;

%fprintf('\n average time/periods until retirement: %12.2f\n',mean(.ret))
%alobezug=(lohn_exp>16 & lohn_exp<17);
mon=mon_delete.*(mon_delete>0)+ 12.*(mon_delete==0).*(bsmon<50)+24.*(mon_delete==0).*(bsmon>=50);


d.N=N;
d2=d; %save data in different memory for recursive and selective re-use
darr=cell(1,pmax);
for pj=1:pmax
    clear d;
sampch=(altersg==59+pj); % & (altersg~=65 & firstday==1);
d.incm = incm(sampch==1);
d.incw = d2.incw(sampch==1,1:end-pj+1);
d.incw_sav=d2.incw_sav(sampch==1,1:end-pj+1,:);
d.inc_partner=d2.inc_partner(sampch==1,:);
d.inc_partner_ue=d2.inc_partner_ue(sampch==1,:);
d.prob_partner=prob_partner(sampch==1);
d.rente = d2.rente(sampch==1,1:end-pj+1);
d.fin_dyn = d2.fin_dyn(sampch==1,1:end-pj+1,:);
%d.fin_i = d2.fin_i(sampch==1,1:end-pj+1,:);
d.annu = d2.annu(sampch==1,1:end-pj+1,:);
d.annuA = d2.annuA(sampch==1,1:end-pj+1,:);
%d.renter = d2.renter(sampch==1,1:end-pj+1);
d.renteA = d2.renteA(sampch==1,1:end-pj+1);
d.lt_earn = d2.lt_earn(sampch==1);
%d.renterA = d2.renterA(sampch==1,1:end-pj+1);
d.x2 = d2.x2(sampch==1,:);
d.x3 = d2.x3(sampch==1,:);
d.prob_fric = d2.prob_fric(sampch==1,:);
d.ch = retire(sampch==1);
d.contr=[ausbil_dum(sampch==1,:) alo_kr(sampch==1) krank05(sampch==1) deu(sampch==1) stib_dum(sampch==1,1:end-1) jahre_schule(sampch==1) tenure5(sampch==1)];
mean(d.ch);
d.ch_r = (mon_delete(sampch==1) > 0) | altersg(sampch==1)<63 ;
d.mon=mon(sampch==1); %how many month of UI elgibility
mean(d.mon);
d.N=length(d.incw);
d.gebjahr=gebjahr(sampch==1);
d.w_fin=w_fin(sampch==1);
d.w_house=w_house(sampch==1);
d.own_house=own_house(sampch==1);
d.altersg=altersg(sampch==1);
d.taxrate=d2.taxrate(sampch==1,1);
d.savrate=savrate;
d.sav_typ=sav_typ;
d.savrate=savrate;
d.delta_inc=delta_inc;
d.pre_est_lifespan=pre_est_lifespan;
d.house=d2.house(sampch==1);
d.startalter=startalter(sampch==1);
d.alosatz=alosatz(sampch==1);
d.jahre_schule=jahre_schule(sampch==1);
d.gebjahr=gebjahr(sampch==1);
d.tenure5=tenure5(sampch==1);
d.alter_helpv=krank05(sampch==1);
d.ic=icpers(sampch==1); %person numbers with max(xxc)=N for first period, further periods have numbers missing inbetween.
d.interest=interest;
d.h4=h4;
darr{pj}=d;
end
clear d;
clear d2;

for pj=1:pmax
  [a,b,c]=unique(darr{1,pj}.ic);
  for n=1:darr{1,1}.N
      darr{1,pj}.from1toP(n,1)=sum(a==n)~=0;
      sum(a==n);
  end    
end

save(['H:\data\prepdata' yr '.mat'],'darr','c','T','b2','b3','pmax','N','h4');

end

