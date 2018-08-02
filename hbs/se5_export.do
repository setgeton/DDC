/* vorbereitung des datensatz für export nach matlab*/

capture log close
capture log using "$log/se5_export.log", replace

set more off


use "$data/2_temp5_97_25_94-zf01.dta", clear



/*-----------------WELCHE GRUPPE UNTERSUCHEN?------------------*/
keep if frau==0 & ost==0
*tab gebjahr schweb
keep if schwebd==0
/*------------------------------------------?------------------*/


quietly{

* LETZTE PERIODE VOR ALTER 60 GEARBEITET?
gen besch719=1 if besch==1 & alter==719
by persnr: egen fromwork=max(besch719)
recode fromwork (.=0)
keep if fromwork==1
drop fromwork besch719



/*-----------------ONLY PEOPLE AT RISK OF RETIREMENT?------------------*/
keep if rrz_akt>=30 & (rente0>0 | rente0A>0) /*d.h. wartezeit30 jahre(ALO-Rente möglich und rente für langjährig versicherte (fast)) + jahrgänge 1946/47 10 fälle raus wegen **keine ahnung**   */
/*------------------------------------------?------------------*/


/*finaler zuschnitt*/
keep if alter>=59*12
keep if alter>=60*12

recode del_alo (.=0)
recode del_atz (.=0)
gen mon_delete=del_alo + del_atz //anzahl der rausgelöschten monate nach beschäftigungsende
recode mon_delete (36=32)


/*tempvar*/
gen altersg=0 //altersgruppen
forvalues j=0/6 {
replace altersg=59+`j' if alter>=(59+`j')*12
}
label var altersg "Alter in Jahren, abgeschnitten"


keep if (gebjahr<1943) ///
	|	(gebjahr==1943&altersg<=61)	|	(gebjahr==1944&altersg<=60)		   //retire or claim ALGII before yr 2006M1

*keep if /*(gebjahr==1946 & altersg==60) |*/ (gebjahr<=1945 & altersg<=60) | (gebjahr==1944 & altersg<=61) | ///
*	(gebjahr==1943 & altersg<=62) | (gebjahr==1942 & altersg<=65) /*nicht <=63??*/ | (gebjahr==1941 & altersg<=65) |(gebjahr<=1940 & altersg<=66) // GENÜGEND INFOS UM 1oder2 JAHR FRÜHER IN ALORENTE ZU VERRENTEN


bys persnr altersg: egen retireyr=max(retire) //in welchem jahr rente?


sort persnr alter


gen alter781=alter
replace alter781=781 if alter>781
label var alter781 "Alter in Monaten, abgeschnitten bei 782 (65J 1M)"

gen minregelalter= (zugang>=1) //dummy mindestens regelaltersgrenze
gen regelalterm= (zugang==1) & persnr[_n-1]==persnr & zugang[_n-1]<1 /* | ( zugang>=1.06 & zugang<=1.07 & alter<63*12)*/ //genau regelalter-dummy
gen gebdummy= (alter==720 |alter==732 |alter==744 |alter==756 |alter==768 |alter==780 )
gen a65= (alter==780) //dummy für 65. geburtstag: arbeitsrechtliche relevanz: typisches befristungsdatum, ab nun nur noch unbefristete einstellungen+weiterbeschäftigungen
gen firstday = (persnr!=persnr[_n-1])
gen jahresende= (year==2002 |year==2003|year==2004|year==2005|year==2006|year==2007|year==2008)
gen a63b35=(rrz_akt>=35 & alter>=756) //mindestens alter 63 und rrz von min 35 jahren

gen lohn_p85log=log(lohn_p85) //85. lohnpercentil logarithmiert

tab altersg, gen(altersg_)
*tab bula, gen(bula_)
/*adhoc recode von ausbil==3 (nur abitur) zu ausbil==4 (abi+berufsausbil) wegen geringer fallzahl*/
recode ausbil (3=4)
tab ausbil, gen(ausbil_)

bys persnr: egen stibmax=max(stib) //generate "stelllung im beruf" - maximum to replace missing ("0") values, however, not all can be replaced
*tab stibmax stib
replace stib=stibmax if stib==0
recode stib (0=1) //recode missing to "Un- und Angelernte"
 
gen work = 1
label var work "Nichtrentner"
replace work = 0 if retire==1
//KRANKENGELDBEZUG MEHR ALS XX MONATE?
gen krank00=0
replace krank00=1 if jahre_krank50>0
gen krank05=0
replace krank05=1 if jahre_krank5060>0.5 | jahre_krank50>0.5
drop jahre_krank50 jahre_krank5060
*gen beitragsz25= (jahre_e50+jahre_alo50>=25)


sort persnr alter
capture drop weiterpr
gen weiterpr=1-alopr  
replace weiterpr=1 if alozs==1 | (alozs[_n-1]==1 & persnr==persnr[_n-1]) //weiter in arbeitslosigkeit, falls nun gerade in arbeitslosigkeit
/*tempvar ende*/ 


**nur jede 12 beobachtung (vor retirement oder ab beobachtungsbeginn (bei non-retirements))*****************
sort persnr alter
drop finret
bys persnr: egen finret=max(retire)  //person wird letztlich verrentet
gen keepr=0
replace keepr = 1 if (retire==1 | (persnr!=persnr[_n-1]&finret==0))
forvalues j=0/6 {
replace keepr=1 if (persnr==persnr[_n+12*`j'] & keepr[_n+12*`j'] ==1) | (persnr==persnr[_n-12*`j'] & keepr[_n-12*`j'] ==1)
}
keep if keepr==1
sort persnr zeit
recode retire (0=1) if altersg==65 & persnr[_n+1]!=persnr // retire a person if at maximum of sample horizon and above 65 but not yet retired (--> probably retiring next few months anyway)
***********************************************************
gen survtime=(altersg-59) //survival time: zeit bis rente ab vollendetem 59 lebensjahr, sprich alter 59
stset survtime, id(persnr) failure(retire==1)
bysort persnr : egen ret1 = sum(retire)



*preserve //SURVIVAL_ANALYSE ZUR ERSTELLUNG EINER KAPLAN-MEIER-KURVE
levelsof _t  /*if ret1==1*/, local(intv)

/*qui*/ sts list /*if ret1==1*/ /* , /*at(0 `intv')*/ saving("$data/survivor2.dta", replace)
 use "$data/survivor2.dta", clear
list, clean noobs
restore
sts graph //graphische analyse der survival function// KAPLAN MEIER KURVE
capture drop ret1
*/
bys altersg gebjahr: sum retire

bys altersg gebjahr: egen hazratej=mean(retire)
*twoway scatter hazratej altersg, by(gebjahr)

//lediglich zur illustration der fallzahlen der hazardrates, die im code 3 zeilen tiefer folgen
tab hazratej altersg

forval i=1940/1946 {
forval j=60/65 {
sum hazratej if altersg==`j' & gebjahr==`i', meanonly //anteil der observationen die nach gebjahr und altersg verrentet werden, fallzahlen siehe unten
dis "`i'--" "`j'--" r(mean)
}
}

sum alter altersg if frau==0 & ost==0  & finret==1   //Alter der individuen die innerhalb des datensatzes verrenten



/*probabilitiey of frictions*/

gen tenure1 = bsmon>=12
gen tenure2p = bsmon>24
gen tenure3 = bsmon>=36
gen tenure4 = bsmon>=48


*gen jahre_e55_2=jahre_e55^2
gen jahre_e2=jahre_e^2
gen jahre_ue=jahre_alo55 + jahre_alo5560
gen jahre_ue2=jahre_ue^2

gen  prob_fric =1*1/(1+exp(-( ((  0.00499*altersg  + 0.637*jahre_ue -0.0753*jahre_ue2 -0.169*jahre_e +0.00262*jahre_e2 - 0.512*tenure2p -0.315*log(lohn_exp*30) -0.0451*(9+jahre_schule) +0.076*(1-deu) +2.382)) ) ))
bys altersg: sum prob_fric
drop prob_fric

// impute wealth from SOEP:  wealth was regressed on following covariates that I also have in BASID --> gives rough idea of what wealth is typical for people
//first step: financial worth > 6k
gen wealth_financial_1st = 1/(1+exp(-(-6.882 - 0.1192 /*fuer 2007*/ + (55)*0.05272 +  0.00847* jahre_e55   -0.1208* jahre_alo55 + 0.502*log(lohn_exp*30) + (jahre_schule+9) * 0.05848 + (-0.4493) * (1-deu) )   )   ) 
//2nd step: ols on log wealth if wealth > 6k
gen wealth_financial_2nd = exp( 5.4054  -0.02547 /*fuer 2007*/ + (55)*0.02521 -  0.00259* jahre_e55   -0.0704* jahre_alo55 + 0.46874*log(lohn_exp*30) + (jahre_schule+9) * 0.025123 + (-0.1218) * (1-deu)   )
gen wealth_financial_twostep = wealth_financial_1st * wealth_financial_2nd + (1-wealth_financial_1st)* /*chance not above 6k times the average wealth if below 6k  */ 0
replace wealth_financial_twostep = 0 if wealth_financial_twostep<0

gen wealth_house_1st = 1/(1+exp(-(-6.442 + 0.0278 /*fuer 2007*/ - (55)*0.0043 +  0.03735* jahre_e55   -0.24183* jahre_alo55 + 0.6796*log(lohn_exp*30) + (jahre_schule+9) * 0.0916 + (-0.4499) * (1-deu) )   )   ) 
gen wealth_house_2nd = exp( 10.567  -0.0113 /*fuer 2007*/ - (55)*0.006316 +  0.00164* jahre_e55   -0.03113* jahre_alo55 + 0.14209*log(lohn_exp*30) + (jahre_schule+9) * 0.0270266 + (-0.06953) * (1-deu)   ) 
gen wealth_house_twostep = wealth_house_1st * wealth_house_2nd
gen own_house_rand=wealth_house_1st>runiform()

replace wealth_financial_twostep = 0 if alter>=732
replace wealth_house_twostep = 0 if alter>=732
replace wealth_house_1st =  0 if alter>=732
replace wealth_house_2nd =  0 if alter>=732
replace own_house_rand =  0 if alter>=732
bys persnr: egen w_fin = max(wealth_financial_twostep)
bys persnr: egen w_house = max(wealth_house_2nd)
bys persnr: egen prob_house = max(wealth_house_1st)
bys persnr: egen prob_w_house = max(wealth_house_twostep)
bys persnr: egen own_house = max(own_house_rand)

*hist w_fin if alter>=720 & alter <732
*hist w_house if alter>=720 & alter <732



/*drop unnecessary variables*/
drop pareto*
drop _*
}

sort persnr zeit
*descr
*sum jahre_alo* egpt_l12 egpt_dyn if  altersg==60
sum if  altersg==60


keep rente* w_* prob_house own_house bsmon stib tz tz_ever tenure* ded* gebjahr persnr year* zeit alter /*weiterpr alopr*/ alozs besch /*minregelalter a65*/ ///
	/*gebdummy*/  lohn* ausbil bula altersg krank* zf* atztentgelt tentgelt tentgelt_pred ///
	/*ant_ue55_jun2007*/ /*l12_alo*/ deu alo_kr /*aloq55 frau ost*/ jahre_* /*jahre_alo* egpt* */ alos* zustand retire rrz* del_* mon_del



*sum  if  altersg==60

sum alter altersg

 export delimited using "$data\2_temp_matlab3.csv", replace
 
 sort persnr alter
 keep if (gebjahr==1943|gebjahr==1944) & persnr[_n-1]!=persnr
 
 sum if altersg==60

 
 export delimited using "$data\2_temp_matlab4.csv", replace //NUR JAHRGAENGE 1944-45
 
 
 log close
