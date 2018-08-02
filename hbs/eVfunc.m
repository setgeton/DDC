%% (expected) Value Function [recursive calc]
function [eVFt,ch,dret,nu,tau,V_ret65,V_ret65u12,eVret,eVretu12,eVretu24,eVretu32,eVretu12H4_24,eVretu12H4_36,eVretu24H4_36]=eVfunc(para_eV,d,p,pmax,model_para_vec,T,N,sim,e,surv,typ,era,WDmin)

prob_fric=d.prob_fric;

ch=NaN(N,p);%save every period's choice (also takes up values if person
            %is already retired=choice if person wasn't retired yet)

b2=model_para_vec(1);
b3=model_para_vec(2);
h4=model_para_vec(3);       
            
dret=NaN;
if sim==1
ev_c=e.ev_c;
%enu=e.nu;
end
del=para_eV(1);
gamm=para_eV(2);
alpha=para_eV(3);
stigma=para_eV(4:3+b3)';
beta2=para_eV(3+b3+1:3+b3+b2)';
a63=para_eV(4+b3+b2).*(typ==1);
alpha2=(typ==1).*para_eV(b2+b3+5);   %1/(1+exp(-para_eV(b2+b3+5))).*(typ==1); %.*(-beta2(end))
alpha3=para_eV(b2+b3+6);   %1/(1+exp(-para_eV(b2+b3+6))).*(typ<=2);


   %decision of eventual job loss made randomly every period using:
   rndp=rand(N,pmax); %only for simulation

   
   del_vec=NaN(N,T); %matrix used for summation of utility age 65+, discountfact
   for iT=1:T
          del_vec(:,iT)=del.^iT;
   end
   
   %% month cut off due to retirement pathway
   mon=d.mon;
   
   %% SURVIVAL PROBABILITY
   gebjahr=d.gebjahr;
      
   surv_vec=zeros(N,T);
   
   for iT=1:T
        for yr=1940:1946 %for a specific birthyear the survival probs are grabbed from "surv"
          surv_vec(:,iT)=surv_vec(:,iT)+(gebjahr==yr).*del_vec(:,iT).*surv{7+(yr-1940)*9,iT+3};
        end
   end
   
   
   %p away from 65: survcsv{line 7-p=age65-p, 4th column= prob to survive 1 more year

        V_ret65=NaN(N,p+1); %remaining retirement value after age 65 for regular retirement (N,retirement entry)
        V_ret65u12=NaN(N,p+1); %remaining retirement value after age 65 for unempl+retirement
        V_ret65u24=NaN(N,p+1); %remaining retirement value after age 65 for unempl+retirement
        V_ret65u32=NaN(N,p+1); %remaining retirement value after age 65 for unempl+retirement

        for ip=1:p+1
        V_ret65(:,ip)=((((d.annu(:,ip)+d.rente(:,ip)).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
        end
        
        for ip=1:p
        V_ret65u12(:,ip)=((((d.annuA(:,ip)+d.renteA(:,ip+1)).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
       
        V_ret65u24(:,ip)=((((d.annuA(:,ip)+d.renteA(:,ip+2)).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
        
        V_ret65u32(:,ip)=((((d.annuA(:,ip)+d.renteA(:,ip+3)).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
        end
        
        eVret=NaN(N,p-1); %remaining retirement value before age 65 for regular retirement starting in ip, looking from ip, ip excluded
        eVretu12=NaN(N,p-1); %remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+1 on, looking from ip, ip exlcuded
        eVretu24=NaN(N,p-1); %remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+2 on, looking from ip, ip exlcuded
        eVretu12H4_24=zeros(N,p-1);%remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+2 on, looking from ip, ip exlcuded, H4 for 12month
        eVretu32=NaN(N,p-1); %remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+3 on, looking from ip, ip exlcuded
        eVretu12H4_36=zeros(N,p-1);%remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+3 on, looking from ip, ip exlcuded, H4 for 12month
        eVretu24H4_36=zeros(N,p-1);%remaining retirement value before age 65 for unemploym+retirement starting in ip, actual ret from ip+3 on, looking from ip, ip exlcuded, H4 for 24month
        
        for ip=1:p-1
            if p>1   
        eVret(:,ip)= ((((d.annu(:,ip)+d.rente(:,ip)).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip)+0.5772).*(del_vec(:,1:(p-ip)))*ones(p-ip,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65(:,ip);
        eVretu12(:,ip)= ((((d.annuA(:,ip)+d.renteA(:,ip+1)).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip)+0.5772).*(del_vec(:,1:(p-ip)))*ones(p-ip,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u12(:,ip);
               
        eVretu24(:,ip)= ((((d.annuA(:,ip)+d.renteA(:,ip+2)).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip-1)+0.5772).*(del_vec(:,1:(p-ip-1)))*ones(p-ip-1,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u24(:,ip);
        
        eVretu32(:,ip)= ((((d.annuA(:,ip)+d.renteA(:,ip+3)).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip-2)+0.5772).*(del_vec(:,1:(p-ip-2)))*ones(p-ip-2,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u32(:,ip);
        
        
        %% IF REFORM SCENARIO IS ERA=63, however, this will only play a role for the simulation
        if era==63 %might Hartz4 play a role? that is, does eligible start not before 63
                    
        d.rente63_12H4_24=(d.renteA(:,ip+1)+d.renteA(:,ip+1)./0.82.*0.036);     %Pension if retirement in age=63 and last 12 month Hartz4, looking from 63yrs-24mnonth
                                                                                %until ip+1 i let pension increase normally, thereafter, only deductions are reduced!
        d.rente63_12H4_36=(d.renteA(:,ip+2)+d.renteA(:,ip+2)./0.82.*0.036);
        d.rente63_24H4_36=(d.renteA(:,ip+1)+2.*d.renteA(:,ip+1)./0.784.*0.036);
        
        V_ret65u24H4=((((d.annuA(:,ip)+d.rente63_12H4_24).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
        V_ret65u32H4_12=((((d.annuA(:,ip)+d.rente63_12H4_36).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
        V_ret65u32H4_24=((((d.annuA(:,ip)+d.rente63_24H4_36).^(1-gamm)-1)/(1-gamm))*ones(1,T)+0.5772).*(surv_vec)*ones(T,1);
              
        
        eVretu12H4_24(:,ip)= ((((d.annu(:,ip)+d.rente63_12H4_24).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip-1)+0.5772).*(del_vec(:,1:(p-ip-1)))*ones(p-ip-1,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u24H4;
        eVretu12H4_36(:,ip)= ((((d.annu(:,ip)+d.rente63_12H4_36).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip-2)+0.5772).*(del_vec(:,1:(p-ip-2)))*ones(p-ip-2,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u32H4_12;
        eVretu24H4_36(:,ip)= ((((d.annu(:,ip)+d.rente63_24H4_36).^(1-gamm)-1)/(1-gamm))*ones(1,p-ip-2)+0.5772).*(del_vec(:,1:(p-ip-2)))*ones(p-ip-2,1)...
            + del_vec(:,p-ip).*(1./del).*V_ret65u32H4_24;
                
        end
        
            end
        
        end
%% intial working disutility running from 1 to pmax (even if pj(starting period for subsample)>1)
nu=NaN(N,pmax);
nu(:,1)=d.x2*(beta2) + alpha2 - WDmin.*alpha.*ones(N,1);  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
if pmax>1
for ip=2:pmax
    nu(:,ip)=nu(:,1) + (alpha).*(ip-1).*ones(N,1); %+ alpha2.*((ip-1)^2).*ones(N,1) ;  % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
end
end

%verjüngung?
%nu=nu+(alpha).*(-0.5).*ones(N,pmax);

%% intial stigma running from 1 to pmax (even if pj(starting period for subsample)>1)
tau=NaN(N,pmax+2);
tau(:,1)=d.x3*stigma;  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
if pmax>1
for ip=2:pmax+2
    tau(:,ip)=tau(:,1) ; % + alpha2.*ones(N,1).*(ip>3) ; %+ alpha2.* ((ip-1)^2).*ones(N,1) ;  %+ alpha2.*((ip-1)^2).*ones(N,1)   % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
end
end

%if pmax>3
%nu(:,1:3)=nu(:,1:3)+tau.*ones(N,3);
%end
%% VALUE FUNCTIONS
eVFt=NaN(N,p,p); %expectation over value function
%final decision period=64//pmax
eret= exp( ((d.annuA(:,p)+alpha3.*d.alosatz(:,1)).^(1-gamm)-1)/(1-gamm)-tau(:,pmax) + V_ret65u12(:,p)) ...
            + exp( ((d.annu(:,p)+d.rente(:,p)).^(1-gamm)-1)/(1-gamm)  + V_ret65(:,p)) ;%expected value of retirement choice
        if sim==1
        mVFt_0=NaN(N,p); %actual Value Function in p_final conditional on retirement in specific p, cond on having choice
        VFt_0=NaN(N,p); %actual Value Function in p_final conditional on retirement in specific p, incl involuntary retirement
        [mVFt_0(:,p),ch(:,p)]=max([(((d.annu(:,ip)+d.rente(:,p)).^(1-gamm)-1)/(1-gamm))+ev_c(:,1,p) + V_ret65(:,p) ...
            ((d.incw_sav(:,p).^(1-gamm)-1)/(1-gamm))-nu(:,pmax)+ ev_c(:,2,p) + V_ret65(:,p+1)  ],[],2);
        VFt_0(:,p)=(rndp(:,pmax)>prob_fric(:,pmax)).*mVFt_0(:,p) ...
            + (rndp(:,pmax)<prob_fric(:,pmax)).*(((d.rente(:,p).^(1-gamm)-1)/(1-gamm))+ev_c(:,1,p) + V_ret65(:,p));
        ch(:,p)=((ch(:,p)==1)+(rndp(:,pmax)<prob_fric(:,pmax))>0);
        end
       
eVFt(:,p,1)=(1-prob_fric(:,pmax)).*(0.5772+log(eret +... %d.rente(:,p)
    exp((d.incw_sav(:,p).^(1-gamm)-1)/(1-gamm)-nu(:,pmax) + V_ret65(:,p+1) )))...
    + (prob_fric(:,pmax)).*(0.5772 + log(eret) ) ; %expectation of current value function, used in T-1
%eVFt(:,p,1)=(0.5772 + d.rente(:,p).^(1-gamm)/(1-gamm) + d.x2*(beta2)+ V_ret65(:,p) ) ;
%eVFt(:,p,1)=(1-prob_fric(:,pmax)).*(0.5772+log(exp((d.rente(:,p).^(1-gamm)/(1-gamm) + d.x2*(beta2)+ V_ret65(:,p) ))+...
%    exp((d.incw(:,p).^(1-gamm))/(1-gamm)-nu(:,pmax) + d.x2*(-beta2) )))...
%    + (prob_fric(:,pmax)).*(0.5772 + d.rente(:,p).^(1-gamm)/(1-gamm) + d.x2*(beta2)+ V_ret65(:,p) ) ;
%if p>1
%for ip=1:p-1
    %VFtmax(:,ip)=(d.rente(:,:,ip).^(1-gamm)/(1-gamm))+ev_c(:,1,p);
    %eVFt(:,ip,1)=0.5772+((d.rente(:,ip).^(1-gamm)-1)/(1-gamm) + V_ret65(:,ip)); %if already retired, regularly
%end
%end


if p>1
    w63=1.*(pmax==5)+3.*(pmax==7); % which j marks age 63?
    w61=3.*(pmax==5)+5.*(pmax==7); % which j marks age 61?
    for j=1:p-1 %recusrively running from pmax (or here pmax-1) period to first period
        
       
              alo_u = @(alosatz,mon,gam,eVretu12,eVretu24,eVretu32) (era~=63 | j~=w61).*(mon~=24 & mon~=32).*(((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j) + eVretu12(:,p-j)  ) ... 12month unemplbenefits
  + (era==63 && j==w61).*(mon~=24 & mon~=32).*(((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j) + del.*(((d.annuA(:,p-j)+alpha3.*h4.*ones(N,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j+1)  + eVretu12H4_24(:,p-j)  ) ) ... 12month unemplbenefits+1yr Hartz4
          +(mon==24).* ( ((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j)  + del.*(((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j+1)  + eVretu24(:,p-j)  ) )...
    +(mon==32).* ( ((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j)  + del.*(((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j+1) ) ...
            +(del^2).*((2/3).*(((d.annuA(:,p-j)+alpha3.*alosatz(:,1)).^(1-gam)-1)/(1-gam)-tau(:,pmax-j+2)) ...
                + (1/3).*(((d.annuA(:,p-j)+d.renteA(:,p-j+2)).^(1-gam)-1)/(1-gam))...
                +eVretu32(:,p-j)  ) ) ;  
      

 eret= exp( alo_u(d.alosatz,mon,gamm,eVretu12,eVretu24,eVretu32)    ) ...
      + (d.rente(:,p-j)>0.01).*exp( ((d.annu(:,p-j)+d.rente(:,p-j)).^(1-gamm)-1)/(1-gamm) + eVret(:,p-j) +a63.*(j==w63).*ones(N,1)   )  ;%expected value of retirement choice
      if sim==1
        mVFt=NaN(N,p-j,p-1);
        VFt=NaN(N,p-j,p-1); %actual value function, Dimensions:(Individual n, retired in t_ret, calculated for period now noted as -(p_now-pmax) )
        [mVFt(:,p-j,j),ch(:,p-j)]=max([(((d.annu(:,p-j)+alpha3.*d.alosatz(:,1)).^(1-gamm)-1)/(1-gamm))+ev_c(:,1,p-j)+del.*(eVFt(:,p-j,j)) ... %instead of d.alosatz(:,1) i used d.rente(:,p-j)
            ((d.incw_sav(:,p-j).^(1-gamm)-1)/(1-gamm))-nu(:,pmax-j)+ev_c(:,2,p-j)+del.*(eVFt(:,p-j+1,j))],[],2); %maximizing if voluntary decision
        VFt(:,p-j,j)=(rndp(:,pmax-j)>prob_fric(:,p-j)).*mVFt(:,p-j,j) ... %(1-pfric)*voluntary decision +
            + (rndp(:,p-j)<prob_fric(:,pmax-j)).*((((d.annu(:,p-j)+d.rente(:,p-j)).^(1-gamm)-1)/(1-gamm))+ev_c(:,1,p-j)+del.*(eVFt(:,p-j,j))) ; %(pfric)*involuntary ret
        ch(:,p-j)=((ch(:,p-j)==1)+(rndp(:,pmax-j)<prob_fric(:,p-j))>0);
        end
    eVFt(:,p-j,j+1)=(1-prob_fric(:,pmax-j)).*(0.5772+log(  eret ... %instead of d.alosatz(:,1) i used d.rente(:,p-j) ?!?!?!?! not true i think, code is right
      + exp(((d.incw_sav(:,p-j).^(1-gamm)-1)/(1-gamm))-nu(:,pmax-j)+del.*(eVFt(:,p-j+1,j))) ))...
      + prob_fric(:,pmax-j).*( 0.5772 + log(eret)  );
        %for ip=1:(p-j-1)
        %    %already retired=no options
        %    eVFt(:,ip,j+1)=0.5772+((d.rente(:,ip).^(1-gamm)-1)/(1-gamm) +del.*(eVFt(:,ip,j)));
        %end
    end
end


        if sim==1
        fprintf('%7.4f ',mean(ch,1))

        retp=ch(:,1)==1; %immidiate retirement
            if p>1
                for j=2:p
                retp=retp+(ch(:,j)==1|retp>0); %summing up periods after first retirement
                end
            end
        dret=p+1-retp; %retirement in period X, X=p+1 means no retirement at all.
        d.ch0=ch(:,1); %current period's choice

        end

end



