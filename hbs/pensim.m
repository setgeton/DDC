function pen_sim_total=pensim(pmax,N,draws,arr,renteA,rente,mon,randnrdr,era)



for i = 1:pmax
    for typ=0:1
pretu(:,i,typ+1)=arr{1,i}.pru(:,typ+1);
pretreg(:,i,typ+1)=arr{1,i}.prr(:,typ+1);
    end
end


pen_sim_total=NaN(N,draws,2);

for dr=1:draws %simulate biographies some "draws" number of times
       
            pen_sim=NaN(N,2);
            
            
            randnr=randnrdr(:,:,dr);
                            
            for randtyp=1:2
                
                if pmax==5 %NRA65
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* (renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24));
                    for period=2:3
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24));
                    end
                    period=4;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24));
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period);
                    period=5;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*renteA(:,period+1);
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period);
                    period=6;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*rente(:,period);
                end
                
                if pmax==7 && era==60 %NRA67ERA60
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* (renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24));
                    for period=2:3
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24));
                    end
                    for period=4:6
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24)); %transit into unemployment pension
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period); %transit into normal pension
                    end
                    period=7;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*renteA(:,period+1);
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period);
                    period=8;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*rente(:,period);
                end
                
                if pmax==7 && era==63 %NRA67ERA63
                                       
                    period=1;
                    pen_sim(:,randtyp)=(pretu(:,period,randtyp)>randnr(:,period)).* ( (renteA(:,period+1) + 2.*renteA(:,period+1)./0.784.*0.036).*(mon==12) + (renteA(:,period+2) + renteA(:,period+2)./0.82.*0.036).*(mon>=24)  );
                    period=2;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*( (renteA(:,period+1) + renteA(:,period+1)./0.82.*0.036).*(mon==12) + (renteA(:,period+2)).*(mon>=24)   );
                    period=3;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*( (renteA(:,period+1) ).*(mon==12) + (renteA(:,period+2)).*(mon>=24)   );
                    for period=4:6
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*(renteA(:,period+1).*(mon==12) + renteA(:,period+2).*(mon>=24)); %transit into unemployment pension
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period); %transit into normal pension
                    end
                    period=7;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)>randnr(:,period)).*renteA(:,period+1);
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*(pretu(:,period,randtyp)+pretreg(:,period,randtyp)>randnr(:,period)).*rente(:,period);
                    period=8;
                    pen_sim(:,randtyp)=pen_sim(:,randtyp) + (pen_sim(:,randtyp)==0).*rente(:,period);
                end
            
           
            pen_sim_total(:,dr,randtyp)=pen_sim(:,randtyp);
            
            
            
            end
            
            %randomly chosing a typ
            %drawtyp=(rand(N,1)<typprob(1));
            %drawtyp=ones(N,1);
            %pen_sim_rt=(drawtyp==1).*pen_sim(:,1) + (drawtyp~=1).*pen_sim(:,2);
            
end
end