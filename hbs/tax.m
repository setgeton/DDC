function inctaxm=tax(incm,rentner,couple_prob)

%%Abbildung der deutschen Lohnsteuerfunktion, ohne reichensteuer (250k+)

inc=(incm./(1+couple_prob)).*12.*1000;
if rentner==1
    inc=inc.*0.7;
end 
N=length(inc);
inctax=(inc<=8472).*0;
y=(inc-8472)./10000;
inctax=inctax+(inc>8472).*(inc<=13469).*(997.6.*y+1400.*ones(N,1)).*y;
z=(inc-13469)./10000;
inctax=inctax+(inc>13469).*(inc<=52881).*((228.74*z+2397.*ones(N,1)).*z+948.68);
inctax=inctax+(inc>52881).*(0.42.*(inc-52881)+13949);

%% Social Security Contributions (simplification=payed from 5000euro onwards)
incsocsec=incm.*12.*1000;
socsec=(min((incsocsec-5000).*(incsocsec>=5000),50000.*ones(N,1))).*((0.10+0.03).*(rentner==0)+0.09); %UI and pension contribution only for workers





inctaxm=(inctax+socsec)./(12.*1000);

