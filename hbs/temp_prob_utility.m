%% calculate the probable flow utility by type and age! for regime (era60 or era63) + nra67

probu_r=zeros(N,pmax+1,2) ; %probable pension for the two types under 67-regime
for typ=0:1
for pj=1:pmax
    
        nu=NaN(N,pmax);
        alpha2=(typ==1).*paras_est(b2+b3+3);
               nu(:,1)=darr_45r{1,1}.x2*(beta2) + alpha2;  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
        if pmax>1
        for ip=2:pmax
            nu(:,ip)=nu(:,1) + (alpha).*(ip-1).*ones(N,1); %+ alpha2.*((ip-1)^2).*ones(N,1) ;  % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
        end
        end
        
        tau=NaN(N,pmax+2);
        tau(:,1)=darr_45r{1,1}.x3*stigma;  % [-evrnd(-nu_location,nu_scale,N,1) NaN(N,p-1)]; %initial working disutility
        if pmax>1
        for ip=2:pmax+2
            tau(:,ip)=tau(:,1) ; % + alpha2.*ones(N,1).*(ip>3) ; %+ alpha2.* ((ip-1)^2).*ones(N,1) ;  %+ alpha2.*((ip-1)^2).*ones(N,1)   % (nu_loc).*ones(N,1)+d.x2*(beta2)  +  alpha.*(ip-1).* (d.x2*(beta2));
        end
        end
    
    
    
    
probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+survp_r(:,pj,typ+1).*(((darr_45r{1,1}.incw(:,pj).^(1-gamm)-1)/(1-gamm))-nu(:,pj));
probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pj,typ+1).*((darr_45r{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj));
if pj>1 %2 yrs ago into ALG and ALG eligibility>12month
probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pj-1,typ+1).*(darr_45r{1,1}.mon>=24).*(pmax~=pj).*((darr_45r{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj));
end
    for pjt=2:pj
        if pjt>3
        probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retreg_r(:,pjt,typ+1).*((darr_45r{1,1}.rente(:,pjt).^(1-gamm)-1)./(1-gamm));
        end
        if pjt>2
      probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pjt-2,typ+1).*((darr_45r{1,1}.mon>=24).*(era==60||pj~=3).*(pmax~=pj).*((darr_45r{1,1}.renteA(:,pjt).^(1-gamm)-1)./(1-gamm)));
      probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pjt-2,typ+1).*((era==63&&pj==3).*((darr_45r{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj)));  %2 periods ago into ALG==> now H4 if not 63 yet<=>in period 3
        end
        if pjt>1
      probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pjt-1,typ+1).*(((darr_45r{1,1}.mon==12) + (pmax==pj).*ones(length(darr_45r{1,1}.mon),1) )>=1).*((darr_45r{1,1}.renteA(:,pjt).^(1-gamm)-1)./(1-gamm));
      probu_r(:,pj,typ+1)=probu_r(:,pj,typ+1)+retu_r(:,pjt-1,typ+1).*((darr_45r{1,1}.mon==12).*(era==63&&pj<=3).*((darr_45r{1,1}.alosatz(:,1).^(1-gamm)-1)/(1-gamm)-tau(:,pj)));    %1 period ago into ALG==> now H4 if not 63 yet&&only eligible 12mon
         end
    end
end
probu_r(:,pmax+1,typ+1)=((probrente_r(:,typ+1).^(1-gamm)-1)./(1-gamm));
end
probu_r_age=typprob(1).*(probu_r(:,:,1))+typprob(2).*(probu_r(:,:,2));
