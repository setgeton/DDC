function [pen_sim_total,pen_sim_totalwohouse]=penconssim(pmax,N,draws,arr,renteA,rente,annuA_raw,annu_raw,optst,house,mon,randnrdr,era)



for i = 1:pmax
    for typ=0:1
pretu(:,i,typ+1)=arr{1,i}.pru(:,typ+1);
pretreg(:,i,typ+1)=arr{1,i}.prr(:,typ+1);
    end
end

annuwidth=length(annu_raw(1,1:end,1));
annuheigth=length(annu_raw(1:end,1,1));
annu_typ1=zeros(annuheigth,annuwidth,1);
annuA_typ1=zeros(annuheigth,annuwidth,1);
annu_typ2=zeros(annuheigth,annuwidth,1);
annuA_typ2=zeros(annuheigth,annuwidth,1);

sav_typ=max(max(optst));

for sti=1:sav_typ;
annu_typ1=annu_typ1+((optst(:,1)==sti)*ones(1,annuwidth)).*annu_raw(:,:,sti);
annuA_typ1=annuA_typ1+((optst(:,1)==sti)*ones(1,annuwidth)).*annuA_raw(:,:,sti);
end;
for sti=1:sav_typ;
annu_typ2=annu_typ2+((optst(:,2)==sti)*ones(1,annuwidth)).*annu_raw(:,:,sti);
annuA_typ2=annuA_typ2+((optst(:,2)==sti)*ones(1,annuwidth)).*annuA_raw(:,:,sti);
end;


pen_sim_total=NaN(N,draws,2);

for dr=1:draws %simulate biographies some "draws" number of times
       
            pen_sim=NaN(N,2);
            
            
            randnr=randnrdr(:,:,dr);
                            
            for randtyp=1:2
                
                        if randtyp==1
                        annu=annu_typ1;
                        annuA=annuA_typ1;
                        end    
                        if randtyp==2
                        annu=annu_typ2;
                        annuA=annuA_typ2;
                        end
                
                
                if pmax==5 %NRA65
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* (renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period));
                    for period=2:3
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period));
                    end
                    period=4;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period));
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period) + annu(:,period));
                    period=5;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1) + annuA(:,period));
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period) + annu(:,period));
                    period=6;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(rente(:,period) + annu(:,period));
                end
                
                if pmax==7 && era==60 %NRA67ERA60
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* (renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period));
                    for period=2:3
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period));
                    end
                    for period=4:6
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24) + annuA(:,period)); %transit into unemployment pension
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period) + annu(:,period)); %transit into normal pension
                    end
                    period=7;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1)+ annuA(:,period));
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period)+ annu(:,period));
                    period=8;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(rente(:,period)+ annu(:,period));
                end
                
                if pmax==7 && era==63 %NRA67ERA63
                                       
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* ( (renteA(:,period+1) + 2.*renteA(:,period+1)./0.784.*0.036).*(mon==12) + (renteA(:,period+2) + renteA(:,period+2)./0.82.*0.036).*(mon>=24)   + annuA(:,period));
                    period=2;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*( (renteA(:,period+1) + renteA(:,period+1)./0.82.*0.036).*(mon==12) + (renteA(:,period+2)).*(mon>=24)    + annuA(:,period));
                    period=3;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*( (renteA(:,period+1) ).*(mon==12) + (renteA(:,period+2)).*(mon>=24)   + annuA(:,period) );
                    for period=4:6
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24)  + annuA(:,period)  ); %transit into unemployment pension
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period) + annu(:,period)); %transit into normal pension
                    end
                    period=7;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1) + annuA(:,period));
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*(rente(:,period) + annu(:,period));
                    period=8;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(rente(:,period) + annu(:,period));
                end
            
           
            pen_sim_total(:,dr,randtyp)=pen_sim(:,randtyp);
            pen_sim_totalwohouse(:,dr,randtyp)=pen_sim(:,randtyp)-house;
            
            
            
            end
            
            %randomly chosing a typ
            %drawtyp=(rand(N,1)<typprob(1));
            %drawtyp=ones(N,1);
            %pen_sim_rt=(drawtyp==1).*pen_sim(:,1) + (drawtyp~=1).*pen_sim(:,2);
            
end
end