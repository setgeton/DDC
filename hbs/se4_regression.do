capture log close
capture log using "${LOG_DIR}se4_regression.log", replace

set more off


///////////**REGRESSION**///////////////////

//0: OLS
//a: LOGIT
//b: LOGIT ML
//c: DOUBLE-HURDLE LOGIT
//d: BIVARIATE PROBIT

use "${TEMP_DIR}2_temp5_97_25_94-zf01.dta", clear


/*
drop zf*
drop raf*
drop arw*
export delimited "${MATLAB_DIR}2_temp_matlab", replace
*/

*keep if zugang>0 & zugang<.


/*-----------------WELCHE GRUPPE UNTERSUCHEN?------------------*/
keep if frau==0 & ost==0 
/*------------------------------------------?------------------*/

tab bula
*keep if bula<7 //|bula==3

capture drop akt_rente
gen akt_rente=rente0
/*-----------------ONLY PEOPLE AT RISK?------------------*/
keep if /*rrz_akt>=15  & */ akt_rente>0 /*d.h. wartezeit15 jahre + jahrgänge 1946/47 schaffen angehobene altersgrenze*/
/*------------------------------------------?------------------*/



sort persnr zeit
/*nicht zuordbar raus?? (eigentlich aber keine rentenrechtlichen regeln, die ausscheiden in jenem alter erlauben)*/
gen out=(zugang==0.0 & retire==1) 
bysort persnr: egen out2=sum(out)
*tab out
tab out2  //TRIFFT NIRGENDS MEHR ZU! 22.9.2015
*drop if out2==1
drop out*
*drop if zugang==0.5



local lambda =1.8 //Freizeitgewichtungsfaktor
local delta  =0.95 //Diskontfaktor
local rho =   0.95 //1-sterbewahrscheinlichkeit

/*survival analysis*/

gen survtime=(alter-59*12)/12 //survival time: zeit bis rente ab vollendetem 59 lebensjahr, sprich alter 59
stset survtime, id(persnr) failure(retire==1)

bysort persnr : egen ret1 = sum(retire)


preserve

cd H:\
levelsof _t  /*if ret1==1*/, local(intv)
qui sts list /*if ret1==1*/, /*at(0 `intv')*/ saving(\data\survivor2.dta, replace)
use data\survivor2.dta, clear
list, clean noobs

restore

*sts graph
capture drop ret1


/*finaler zuschnitt*/
keep if alter>=59*12
keep if alter>=60*12



/*tempvar*/
//gen lnalter= ln(alter)
gen altersg=0
forvalues j=0/6 {
replace altersg=59+`j' if alter>=(59+`j')*12
}
label var altersg "Alter in Jahren, abgeschnitten"

gen alter781=alter
replace alter781=782 if alter>781
label var altersg "Alter in Monaten, abgeschnitten bei 782 (65J 1M)"

gen minregelalter= (zugang>=1) //dummy mindestens regelaltersgrenze
gen regelalterm= (zugang==1) & persnr[_n-1]==persnr & zugang[_n-1]<1 /* | ( zugang>=1.06 & zugang<=1.07 & alter<63*12)*/ //genau regelalter-dummy
gen gebdummy= (alter==720 |alter==732 |alter==744 |alter==756 |alter==768 |alter==780 )
gen a65= (alter==780) //dummy für 65. geburtstag: arbeitsrechtliche relevanz: typisches befristungsdatum, ab nun nur noch unbefristete einstellungen+weiterbeschäftigungen
gen firstday = (persnr!=persnr[_n-1])
gen jahresende= (year==2002 |year==2003|year==2004|year==2005|year==2006|year==2007|year==2008)
gen a63b35=(rrz_akt>=35 & alter>=756)

gen lohn_p85log=log(lohn_p85)

tab altersg, gen(altersg_)
tab bula, gen(bula_)
/*adhoc recode von ausbil==3 (nur abitur) zu ausbil==4 (abi+berufsausbil) wegen geringer fallzahl*/
recode ausbil (3=4)
tab ausbil, gen(ausbil_)
 
gen work = 1
label var work "Nichtrentner"
replace work = 0 if retire==1
gen krank00=0
replace krank00=1 if jahre_krank50>0
gen krank05=0
replace krank05=1 if jahre_krank50>0.5
label var work "Nichtrentner"
drop jahre_krank50
*gen beitragsz25= (jahre_e50+jahre_alo50>=25)


*gen alopr = 1/(1+exp(-(0.022*(alter/12) - 0.05*(bsmon/12) -0.43*tenure2 - 0.57*tenure5 -0.15*ln(lohn_exp*30) +0.56*ost -0.11*jahre_schule -0.11*deu -1.1 )))
capture drop weiterpr
gen weiterpr=1-alopr
replace weiterpr=1 if alozs==1 | (alozs[_n-1]==1 & persnr==persnr[_n-1]) //weiter in arbeitslosigkeit, falls nun gerade in arbeitslosigkeit


/*tempvar ende*/ 


///////////////////////////////////0: OLS/////////////////////////////////
set matsize 2000
reg retire U_diff alter59 alter592 alter593 gebdummy a65 minregel


///////////////////////////////////a: logit/////////////////////////////////
////////i: mit arbeitsmarkt/////
logit retire krank05 minregel U_diff frau deu gebdummy a65 alter59 /*i.altersg*/ ant_ue50_jun2007 ant_ue55_jun2007 l12_alo i.bula jahre_e50 lohn_p85 alo_sex_62007 deu alo_kr i.ausbil
//margins, dydx(krank05 U_diff frau deu /*i.altersg*/ ant_ue50_jun2007 ant_ue55_jun2007 l12_alo /*i.bula*/ jahre_e50 lohn_p85 alo_sex_62007 deu alo_kr /*i.ausbil*/) atmeans cont


/*
/*sensitivity für verschiedene cut-offs */
forvalues j=1/20{
local j1=`j'/200 //cutoff value [0,1]
quietly: estat class, cutoff(`j1')
di "`r(P_corr)'___`r(P_p1)'___`r(P_n0)'__`j1'" //correct predictions____sensitivity___specificity___cutoff[0,1]
}
*/

//marginal effects at means (in %) händisch berechnen
/*
  local par_max=e(k)
matrix x=e(b)
 qui matrix list x
 matrix x1=x[1,1..`par_max'] //zahl der parameter + cons
 qui matrix list x1
 
 matrix accum A1= krank05 U_diff frau deu altersg_* ant_ue50_jun2007 ant_ue55_jun2007 l12_alo bula_* jahre_e50 lohn_p85 alo_sex_62007 deu alo_kr ausbil_* if e(sample)==1, mean(m1)
qui  matrix list m1
 matrix c1=x1*m1'
qui  matrix list c1
 di exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix b1=x1*100*exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix list b1
 */

////////ii: ohne arbeitsmarkt///// 
 logit retire krank05 U_diff a65 minregel deu // frau deu // i.altersg /*ost*/ i.ausbil
margins, dydx(krank05 U_diff /*frau*/ deu /*i.altersg ost i.ausbil*/) atmeans cont

//marg effects atmeans (in %) händisch berechnen
/*
  local par_max=e(k)
matrix x=e(b)
qui  matrix list x
 matrix x1=x[1,1..`par_max'] //zahl der parameter + cons
qui  matrix list x1
 *tab ausbil, gen(ausbil)
 matrix accum A1= krank05 U_diff frau deu altersg_* ausbil_* if e(sample)==1, mean(m1)
qui  matrix list m1
 matrix c1=x1*m1'
qui  matrix list c1
 di exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix b1=x1*100*exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix list b1
 */
 
 
 
 //////////////////////////////////////b: LOGIT ML, 2PFADE, PARAM ESTM./////////
 
set more off
 *preserve
 *keep if bula<7 
 *replace weiterpr=1
 capture program drop logRE
 program logRE
	version 13
	args lnf xb beta gamma
	tempvar U_diff ueberleb U_future U0 U1 U2 U3 U4 U5 U_1 U_2 U_1 U_2 /// 
			U_3 U_4 U_5 U_6 U_7 U_8 U_9 U_10 U_11 U_12 
	quietly {
	local y "$ML_y1"
	
*local beta=0.8	
local lambda =2.0 //Freizeitgewichtungsfaktor
local delta  =0.96 //Diskontfaktor
local rho = 0.8 //überlebewahrscheinlichkeit
*local gamma = .75 //Curvature der Nutzenfunktion
local eta = 1 //monetarisierte freizeit
*if `gamma'>1 local gamma = 1
*if `gamma'<0.1 local gamma = 0.1
*if `beta'<=0 local beta = 0
*if `lambda'>=3 local lambda = 3

local z = 30 //maximaler zeithorizont
local d = 100 //todeszeitpunkt

gen double `ueberleb'=1

quietly{
forvalues k=0/5 {
	gen  double `U`k''=0
	replace `ueberleb'=1
	forvalues j=0/`z' { //Renteneintritt jetzt oder in k Jahren
		replace `ueberleb'=`rho'^(alter/12-75+`j') if  `rho'^(alter/12-75+`j')<=1 & `rho'^(alter/12-75+`j')>0
		replace `ueberleb'=0 if alter/12+`j'>`d'
		replace `U`k''=`U`k''+weiterpr^(`j')*`delta'^(`j')*`ueberleb'*(lohn_exp*30*1.01^`j')^(`gamma') ///
							 +(1-weiterpr^(`j'))*`delta'^(`j')*`ueberleb'*(alosatz)^(`gamma') if `j'<`k' & alter+`j'*12<65*12 //nutzen aus arbeitseink/alo
		replace `U`k''=`U`k''+`lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) if `j'>=`k' //nutzen aus rente if nicht alorente
		replace `U`k''=`U`k''-			   `lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) +				 `lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'==1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
		replace `U`k''=`U`k''-alo_rente`k'*`lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) + alo_rente`k'*`lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'>0 & alo_rente`k'<1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
	}
	
}
 /*
	local mon "1 2 6"
    foreach k of local mon {
	gen  double `U_`k''=0
	replace `ueberleb'=1
	forvalues j=1/12 { //Renteneintritt jetzt oder in j Monaten
		replace `ueberleb'=`rho'^((alter/12-75)+`j'/12) if  `rho'^(alter/12-75+`j'/12)<1 & `rho'^(alter/12-75+`j'/12)>0 /*0.98655^((alter-60*12)+`j')<1 & 0.98655^((alter-60*12)+`j')>0*/
		replace `U_`k''=`U_`k''+(1/12)*weiterpr^(`j'/12)*`delta'^(`j'/12)*`ueberleb'*(lohn_exp*30*1.01^(`j'/12))^`gamma' ///
							+(1/12)*(1-weiterpr^(`j'/12))*`delta'^(`j'/12)*`ueberleb'*(alosatz)^`gamma' if `j'<`k' & alter+`j'<65*12 //nutzen aus arbeitseink
		replace `U_`k''=`U_`k''+(1/12)*`lambda'*`delta'^(`j'/12)*`ueberleb'*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) if `j'>=`k' //nutzen aus rente if not alorente
		replace `U_`k''=`U_`k''-(1/12)*`lambda'*`delta'^(`j'/12)*`ueberleb'*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) + (1/12)*`lambda'*`delta'^(`j'/12)*`ueberleb'*(/*2+*/(alosatz)^(`gamma')) if `j'>=`k' & ( (`j'-`k')/12<alo_rente_`k' |alo_rente_`k'==1) //nutzen aus ersten 12-k mon rente if alorente
	}
	
	replace `ueberleb'=1
	forvalues j=1/`z' { //angefügt wird der nutzen der entsteht für alle weiteren rentenjahre; macht berechnung schneller
	replace `ueberleb'=`rho'^(alter/12-75+`j') if  `rho'^(alter/12-75+`j')<1 & `rho'^(alter/12-75+`j')>0
	replace `ueberleb'=0 if `ueberleb'<0 | alter/12+`j'>`d'
	replace `U_`k''=`U_`k''+         `lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) //nutzen aus rente if not alo rente
	replace `U_`k''=`U_`k''-(alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) + (alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*`ueberleb'*(/*2+*/(alosatz)^(`gamma')) if `j'==1 & (alo_rente_`k'==1 |alo_rente_`k'-(12-`k')/12>0)  //nutzen aus k mon rente die auf die ersten (12-k) mon folgen if alorente
	}
	
}
*/

gen double `U_future'=  max(`U1',`U2',`U3',`U4',`U5'/*,`U_1',`U_2',`U_3',`U_4',`U_5',`U_6', ///
				`U_7',`U_8',`U_9',`U_10',`U_11',`U_12'*/)
gen double `U_diff'=`U0'-`U_future'
}
	
	
	replace `lnf' = ln(  invlogit((`beta'*(`U_diff'/1000)) + `xb' )) if `y'==1
	replace `lnf' = ln(1-invlogit((`beta'*(`U_diff'/1000)) + `xb' )) if `y'==0
	}
	end
	
	ml model lf logRE 	(eq1: retire = ///
						krank05 gebdummy firstday alter59 ant_ue55_jun2007 l12_alo lohn_p85 deu alo_kr i.ausbil i.bula a65) /// l12_alo lohn_p85 deu alo_kr i.ausbil i.bula)
						(beta:) (gamm:), vce(cluster persnr) //constraints(2)
	*ml check
	*ml search
	ml init  /beta=0.8 /gamm=0.7  // /gamm=0.75 // /delta=0.75 //lohn_exp=-0.01 /beta=0.1
	ml maximize , iterate(200) difficult

	
	
	
capture log close	

 stopppi
 
 *alter59 gebdummy lohn_exp /*lohn_exp*/ /*jahresende*/ /*i.ber*/ ) ///
 
///////////////////////////////////b: Double Hurdle/////////////////////////////

//temporär:
//replace alter = 781 if alter>781

////U_DIFF/////

//drop if zugang==0

//keep if alter59>=49
//keep if regelalte==1

/*HIER WEITER*/
//drop if alter<=63*12
//gen U_diff_1=U_diff
//replace U_diff_1=U_diff[_n-1] if persnr==persnr[_n-1] & retire==1



preserve
drop if PSGR==62 //|minregel==1
//drop if rente0<600
set matsize 2000

		capture program drop lf_dhhazard
		program lf_dhhazard
  version 10.1
  args lnf xb zt
  local d "$ML_y1"
  quietly replace `lnf' = ln(invlogit(-`xb') * invlogit(-`zt'))  if `d'==0
  quietly replace `lnf' = ln(invlogit(`xb') + invlogit(-`xb') * invlogit(`zt')) if `d'==1  
  
		end
/* läuft, ergebnisse stimmig
ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ krank00 /*krank05*/ /*jahre_e50*/ /*kindererz*/ U_diff /*i.ber*/ /*ost*/ KIND frau deu /*i.nation_gr*/ /*married*/ i.altersg /*alter lnalter*/) /// option value
						(laborm_constr: retire = ant_ue50_jun2007 /*lohn_p85*/ jahre_alo50 /*jahre_e50*/ frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ alo_sex_62007 ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*jahre_schule*/ alter /*i.ber*/ /*i.kreis*/ /*FASCHULAZ SCHULAZ*/) ///
						, vce(cluster persnr)
*/						


/* läuft, ergebnisse stimmig
ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ /*kindererz*/ /*U_diff*/ /*a63b35*/  minregel#c.U_diff minregel alter59 /*regelalter*/ /*firstday*/ /*jahresende*/ gebdummy /*U_diff*/ /*i.ber*/ ost frau deu /*i.nation_gr*/ /*married*/ /*gebdummy*/ /*i.altersg*/ /*i.alter781*/  /*i.persnr*/ ) /// option value
						(laborm_constr: retire = /*ant_ue50_jun2007*/ /*l12_alo*/ aloq55 /*krank05*/ a65 jahresende alter59 /*ant_ue55_jun2007*/  /* bula_* */ /*jahre_alo50*/ frau /*deu#c.alo_ausl_jun2007*/ /*tentgelt*/ /*lohn_p85log*/ /*alo_sex_62007*/ ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*jahre_schule*/ /*alter59*/ /*alter59*/ /*minregelalter*/ /*alter592 alter593*/ /*alter594*/ /* alter595*/ /*i.ber*/ /*i.kreis*/ ) ///
						, vce(cluster persnr)
*/

ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ /*kindererz*/ /*U_diff*/ /*a63b35*/ c.U_diff#minregel minregel /*alter59*/ firstday /*regelalter*/ /*firstday*/ /*jahresende*/ gebdummy /*i.ber*/ ost frau deu /*i.nation_gr*/ /*married*/ /*gebdummy*/ /*i.altersg*/ /*i.alter781*/  /*i.persnr*/ ) /// option value
						(laborm_constr: retire = /*ant_ue50_jun2007*/ /*l12_alo*/ aloq55 alo_kr  a65 jahresende  /*ant_ue55_jun2007*/ alter59  bula_* /*jahre_alo50*/ frau /*deu#c.alo_ausl_jun2007*/ /*tentgelt*/ /*lohn_p85log*/ /*alo_sex_62007*/ ost deu /*steckt schon in alo_ausl: deu*/ i.ausbil /*jahre_schule*/ /*minregelalter*/ /*alter592 alter593*/ /*alter594*/ /* alter595*/ /*i.ber*/ /*i.kreis*/ ) ///
						, vce(cluster persnr)
			 			
 ml check
 ml search
 ml maximize, difficult

 restore
 
 capture drop sample
 gen sample=e(sample)
 di "pseudo r2: " e(r2_p) 
 
 /////MARGINALE EFFEKTE////
 local par1=8 //anzahl parameter in erster gleichung
 
 
 local par2=`par1'+1
 local par_max=e(k)
 
 //marg. effekte Gleichung 1
 matrix x=e(b)
qui  matrix list x
 matrix x1=x[1,1..`par1'] //zahl der parameter + cons
 matrix accum A1=  krank05 /*kindererz*/ U_diff /*i.ber*/ ost frau deu /*i.nation_gr*/ /*married*/ alter59 alter592 if e(sample)==1, mean(m1)
qui  matrix list m1
 matrix c1=x1*m1'
qui  matrix list c1
 di exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix b1=x1*100*exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix list b1
 
  //marg. effekte Gleichung 2
 matrix x=e(b)
 matrix x2=x[1,`par2'..`par_max'] //zahl der parameter + cons
 *tab ausbil, gen(ausbil)
 matrix accum A2=ant_ue50_jun2007 ant_ue55_jun2007 /*l12_alo*/ bula_* /*krank05*/ jahre_e50 frau /*deu#c.alo_ausl_jun2007*/ lohn_p85 alo_sex_62007 ost deu alo_kr i.ausbil if e(sample)==1, mean(m2)
qui  matrix list m2
 matrix c2=x2*m2'
qui  matrix list c2
 di exp(trace(c2))/(1+exp(trace(c2)))^2
 matrix b2=x2*100*exp(trace(c2))/(1+exp(trace(c2)))^2 //in prozent
 matrix list b2
 
 
 capture drop nodesire_xb
 predict nodesire_xb, equation(#1) xb
  capture drop p_nodesire
 gen p_nodesire=exp(nodesire_xb)/(1+exp(nodesire_xb))  if e(sample)==1
 
 
 capture drop laborm_xb
 predict laborm_xb, equation(#2) xb
  capture drop p_laborm
 gen p_laborm=exp(laborm_xb)/(1+exp(laborm_xb)) if e(sample)==1
 
/*SIMULATION*/

		//explanatory variable wir ausgetauscht
preserve
rename U_diff U_diff3
rename U_diff2 U_diff


//abschläge 5% ab 60, gleiche regeln wie bisher
capture drop nodesire_xb2
predict nodesire_xb2, equation(#1) xb
capture drop p_nodesire2
gen p_nodesire2=exp(nodesire_xb2)/(1+exp(nodesire_xb2))

/*SIMULATION ENDE*/

  capture drop p_sum
 gen p_sum=p_laborm+p_nodesire
 
  bysort altersg: sum p_* retire if p_laborm!=.
 
  bysort alter781: sum p_* retire if p_laborm!=.
 restore
/////SENSITITVITÄTSANALYSE/////

/*
//sensitivität desire predictor
 count if retire==1 & sample==1
 local N = r(N)
forvalues j=20/70{
local j1=`j'/1000
 quietly: count if p_nodesire>`j1' & retire==1 & sample==1
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N' //sensitivität
 count if p_nodesire>`j1' & sample==1 //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 /*-->0,04*/
 
//sensitivität labor market predictor 
 count if retire==1 & sample==1
 local N = r(N)
forvalues j=1/50{
local j1=`j'/1000
 quietly: count if p_laborm>`j1' & retire==1 & sample==1
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N'
 count if p_laborm>`j1' & sample==1 //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 
 count if retire==1 & p_laborm!=.
 local N = r(N)
 
forvalues j=20/60{
local j1=`j'/1000
 quietly: count if (p_laborm>(0.009/0.027)*`j1' | p_nodesire>`j1') & retire==1 & p_laborm!=.
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N'
 count if (p_laborm>(0.009/0.027)*`j1' | p_nodesire>`j1') & p_laborm!=. //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 */
 


 

 ////////////RENTENEINTRITT PREDICTEN: wie viele werden als rentner predictet?//////////
 
 //abschläge auf 5% aber gleiche regelungen ansonsten
 
 capture drop ll 
gen ll=p_laborm>0.010 if p_laborm!=. //rentner weil labor market ungünstig?
 
capture drop nn2
gen nn2=p_nodesire2>0.022 if p_laborm!=. //simulations-prediction (verändertes desire bei höheren abschlägen?)
 
  capture drop xerstr erstr
 bysort persnr (zeit): egen xerstr=min(zeit) if ll==1 | nn2==1
 bysort persnr: egen erstr=min(xerstr)
 recode nn2 (1=0) if zeit>xerstr
 recode ll (1=0) if zeit>xerstr
 *recode ll (1=0) if nn==1
  sort persnr alter 
  sum alter if (ll==1 | nn2==1 | (persnr!=persnr[_n+1] & erstr==.)) & p_laborm!=.
 sum alter if (ll==1 | nn2==1)
 capture drop unz
 gen unz=(erstr!=.)
 
 *bysort altersg: tab ll nn2 if p_laborm!=. //renteneintritt aus gründen ll=arbeitsmarkt oder nn=wunsch zu verrenten
 
 //rentenalter?
 sum alter if retire==1
 sum alter if (ll==1 | nn2==1 | (persnr!=persnr[_n+1] & erstr==.))  
 
 capture drop _merge
 merge 1:1 persnr zeit using "${TEMP_DIR}2_temp7_97_12_94-zf01.dta", keepus(akt_rente_* U_diff_*)
 
 drop if _merge==2
 drop _merge
 
 capture drop ll
capture drop nn
gen ll=p_laborm>0.010 if p_laborm!=. //rentner weil labor market ungünstig?
gen nn=p_nodesire>0.022 if p_laborm!=. //rentner weil wunsch zu verrenten?
 
 capture drop xerstr erstr
 bysort persnr (zeit): egen xerstr=min(zeit) if ll==1 | nn==1
 bysort persnr: egen erstr=min(xerstr)
 recode nn (1=0) if zeit>xerstr
 recode ll (1=0) if zeit>xerstr
 *recode ll (1=0) if nn==1
  sort persnr alter
 *bysort altersg: tab ll nn if p_laborm!=. //renteneintritt aus gründen ll=arbeitsmarkt oder nn=wunsch zu verrenten
  sum alter if (ll==1 | nn==1) & unz==1
 
  
 bysort altersg: count if retire==1
 sort persnr
 count if (p_nodesire!=.) & erstr==. & persnr!=persnr[_n-1]

 count if retire==1 & p_laborm!=.
 local N = r(N)
 
 quietly: count if (nn==1 | ll==1) & retire==1 & p_laborm!=.
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N'
 count if (nn==1 | ll==1) & p_laborm!=. //"false+true positives"
 
 /*SIMULATION*/
 
		//explanatory variable wir ausgetauscht 
rename U_diff U_diff2
rename U_diff_p2 U_diff


//abschläge 3.6% ab 60, regel ist immer 65
capture drop nodesire_xb_p2
predict nodesire_xb_p2, equation(#1) xb
capture drop p_nodesire_p2
gen p_nodesire_p2=exp(nodesire_xb_p2)/(1+exp(nodesire_xb_p2))

		//explanatory variable wir ausgetauscht
rename U_diff U_diff_p2
rename U_diff_p3 U_diff


//abschläge 5% ab 60, regel ist immer 65
capture drop nodesire_xb_p3
predict nodesire_xb_p3, equation(#1) xb
capture drop p_nodesire_p3
gen p_nodesire_p3=exp(nodesire_xb_p3)/(1+exp(nodesire_xb_p3))



/*ausgabe wahrscheinlichkeiten*/ bysort altersg: sum p_* retire if p_laborm!=.

  
//BERECHNUNG FÜR SIMULATION (EINFACHE REGEL 5% vs 3.6% abschläge

 //5.0%
 capture drop ll 
gen ll=p_laborm>0.010 if p_laborm!=. //rentner weil labor market ungünstig?
 
capture drop nn2
gen nn2=p_nodesire_p3>0.022 if p_laborm!=. //simulations-prediction (verändertes desire bei höheren abschlägen?)

  capture drop xerstr erstr
 bysort persnr (zeit): egen xerstr=min(zeit) if ll==1 | nn2==1
 bysort persnr: egen erstr=min(xerstr)
 recode nn2 (1=0) if zeit>xerstr
 recode ll (1=0) if zeit>xerstr
 *recode ll (1=0) if nn==1
  sort persnr alter 
  sum alter if (ll==1 | nn2==1 )
 *bysort altersg: tab ll nn2 if p_laborm!=. //renteneintritt aus gründen ll=arbeitsmarkt oder nn=wunsch zu verrenten
  sort persnr
 count if (p_nodesire_p3!=.) & erstr==. & persnr!=persnr[_n-1]
 capture drop unz
 gen unz=(erstr!=.)
 
 //3.6%  
capture drop ll
capture drop nn
gen ll=p_laborm>0.010 if p_laborm!=. //rentner weil labor market ungünstig?
gen nn=p_nodesire_p2>0.022 if p_laborm!=. //rentner weil wunsch zu verrenten?

 capture drop xerstr erstr
 bysort persnr (zeit): egen xerstr=min(zeit) if ll==1 | nn==1
 bysort persnr: egen erstr=min(xerstr)
 recode nn (1=0) if zeit>xerstr
 recode ll (1=0) if zeit>xerstr
 *recode ll (1=0) if nn==1
 sum alter if (ll==1 | nn==1 ) &unz==1 
 *bysort altersg: tab ll nn if p_laborm!=. //renteneintritt aus gründen ll=arbeitsmarkt oder nn=wunsch zu verrenten
 
sort persnr
 count if (p_nodesire_p2!=.) & erstr==. & persnr!=persnr[_n-1]
 
 bysort altersg: count if retire==1

 
 
 rename U_diff U_diff_p3
 rename U_diff3 U_diff
 ///////////////MARIGINALE EFFEKTE PER HAND BERECHNEN; WEIL KEIN STANDARDBEFEHL ZUR VERFÜGUNG//////// 
 
  //anzahl paramter in gleichung 1?
 
 
 
 
////rente0/////

set matsize 1200

		capture program drop lf_dhhazard
		program lf_dhhazard
  version 10.1
  args lnf xb zt
  local d "$ML_y1"
  quietly replace `lnf' = ln(invlogit(-`xb') * invlogit(-`zt'))  if `d'==0
  quietly replace `lnf' = ln(invlogit(`xb') + invlogit(-`xb') * invlogit(`zt')) if `d'==1  
  
		end
				

ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ krank05 /*kindererz*/  akt_rente /*i.ber*/ /*ost*/ frau deu /*i.nation_gr*/ /*married*/ i.altersg /*alter lnalter*/) /// option value
						(laborm_constr: retire = ant_ue50_jun2007 ant_ue55_jun2007 l12_alo /*i.bula*/ /*krank05*/ jahre_e50 frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ lohn_p85 alo_sex_62007 ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*lnalter*/ /*jahre_schule*/ /*alter*/ /*i.ber*/ /*i.kreis*/ /*FASCHULAZ SCHULAZ*/) ///
						, vce(cluster persnr)

						
 ml check
 ml search
 ml maximize, difficult
 
 capture drop sample
 gen sample=e(sample)
 
  di "pseudo r2: " e(r2_p) 
 
 
 capture drop nodesire_xb
 predict nodesire_xb, equation(#1) xb
  capture drop p_nodesire
 gen p_nodesire=exp(nodesire_xb)/(1+exp(nodesire_xb))  if e(sample)==1
 
 
 capture drop laborm_xb
 predict laborm_xb, equation(#2) xb
  capture drop p_laborm
 gen p_laborm=exp(laborm_xb)/(1+exp(laborm_xb)) if e(sample)==1
 
/*SIMULATION*/
rename akt_rente akt_rente3
rename akt_rente2 akt_rente


capture drop nodesire_xb2
predict nodesire_xb2, equation(#1) xb
capture drop p_nodesire2
gen p_nodesire2=exp(nodesire_xb2)/(1+exp(nodesire_xb2))

rename akt_rente akt_rente2
rename akt_rente3 akt_rente
/*SIMULATION ENDE*/

 
  bysort altersg: sum p_* if p_laborm!=.
 
/////SENSITITVITÄTSANALYSE/////

/*
//sensitivität desire predictor
 count if retire==1 & sample==1
 local N = r(N)
forvalues j=20/70{
local j1=`j'/1000
 quietly: count if p_nodesire>`j1' & retire==1 & sample==1
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N' //sensitivität
 count if p_nodesire>`j1' & sample==1 //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 /*-->0,04*/
 
//sensitivität labor market predictor 
 count if retire==1 & sample==1
 local N = r(N)
forvalues j=1/50{
local j1=`j'/1000
 quietly: count if p_laborm>`j1' & retire==1 & sample==1
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N'
 count if p_laborm>`j1' & sample==1 //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 
 count if retire==1 & p_laborm!=.
 local N = r(N)
 
forvalues j=20/60{
local j1=`j'/1000
 quietly: count if (p_laborm>(0.038/0.053)*`j1' | p_nodesire>`j1') & retire==1 & p_laborm!=.
 local N_nod = r(N)
 di "sensitivität: " `N_nod'/`N'
 count if (p_laborm>(0.038/0.053)*`j1' | p_nodesire>`j1') & p_laborm!=. //"false+true positives" 
 di `j1' " (cut-off grenze)"
 }
 */

 ////////////RENTENEINTRITT PREDICTEN: wie viele werden als rentner predictet?//////////
 
capture drop ll nn 
gen ll=p_laborm>0.02 if p_laborm!=. //rentner weil labor market ungünstig?
gen nn=p_nodesire>0.04 if p_laborm!=. //rentner weil wunsch zu verrenten?
 
capture drop nn2
gen nn2=p_nodesire2>0.055 if p_laborm!=. //simulations-prediction (verändertes desire bei höheren abschlägen?)

 tab ll nn if p_laborm!=.
 tab ll nn2 if p_laborm!=. 
 count if retire==1 & p_laborm!=.
 
 *bysort altersg: tab ll nn if p_laborm!=.
 
 *bysort altersg: tab ll nn2 if p_laborm!=.
 
 *bysort altersg: count if retire==1

 *drop p_*

 
 //anzahl paramter in gleichung 1?
 
 local par1=11
 
 
 local par2=`par1'+1
 local par_max=e(k)
 
 //marg. effekte eq1
 matrix x=e(b)
 matrix list x
 matrix x1=x[1,1..`par1'] //zahl der parameter + cons
 matrix accum A1=  krank05 /*kindererz*/ akt_rente /*i.ber*/ /*ost*/ frau deu /*i.nation_gr*/ /*married*/ altersg_* if e(sample)==1, mean(m1)
 qui matrix list m1
 matrix c1=x1*m1'
 qui matrix list c1
 di exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix b1=x1*100*exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix list b1
 
  //marg. effekte eq2
 matrix x=e(b)
 matrix x2=x[1,`par2'..`par_max'] //zahl der parameter + cons
 *tab ausbil, gen(ausbil)
 matrix accum A2=ant_ue50_jun2007 ant_ue55_jun2007 l12_alo /*i.bula*/ /*krank05*/ jahre_e50 frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ lohn_p85 alo_sex_62007 ost deu alo_kr i.ausbil if e(sample)==1, mean(m2)
 qui matrix list m2
 matrix c2=x2*m2'
 qui matrix list c2
 di exp(trace(c2))/(1+exp(trace(c2)))^2
 matrix b2=x2*100*exp(trace(c2))/(1+exp(trace(c2)))^2 //in prozent
 matrix list b2
 
////rente0///// 
/*
 set matsize 1200

		capture program drop lf_dhhazard
		program lf_dhhazard
  version 10.1
  args lnf xb zt
  local d "$ML_y1"
  quietly replace `lnf' = ln(invlogit(-`xb') * invlogit(-`zt'))  if `d'==0
  quietly replace `lnf' = ln(invlogit(`xb') + invlogit(-`xb') * invlogit(`zt')) if `d'==1  
  
		end
/* läuft, ergebnisse stimmig
ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ krank00 /*krank05*/ /*jahre_e50*/ /*kindererz*/ U_diff /*i.ber*/ /*ost*/ KIND frau deu /*i.nation_gr*/ /*married*/ i.altersg /*alter lnalter*/) /// option value
						(laborm_constr: retire = ant_ue50_jun2007 /*lohn_p85*/ jahre_alo50 /*jahre_e50*/ frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ alo_sex_62007 ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*jahre_schule*/ alter /*i.ber*/ /*i.kreis*/ /*FASCHULAZ SCHULAZ*/) ///
						, vce(cluster persnr)
*/						

ml model lf lf_dhhazard	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ krank00 /*jahre_e50*/ /*kindererz*/ rente0 /*i.ber*/ /*ost*/ KIND frau deu /*i.nation_gr*/ /*married*/ i.altersg /*alter lnalter*/) /// option value
						(laborm_constr: retire = ant_ue50_jun2007 ant_ue55_jun2007 /*krank05*/ /*lohn_p85*/ jahre_e50 jahre_alo50 frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ alo_sex_62007 ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*jahre_schule*/ alter /*i.ber*/ /*i.kreis*/ /*FASCHULAZ SCHULAZ*/) ///
						, vce(cluster persnr)

						
 ml check
 ml search
 ml maximize, difficult
 
 
  local par1=11
 
 
 local par2=`par1'+1
 local par_max=e(k)
 
 //marg. effekte eq1
 matrix x=e(b)
 matrix list x
 matrix x1=x[1,1..`par1'] //zahl der parameter + cons
 matrix accum A1= krank00 SSW KIND frau deu i.altersg if e(sample)==1, mean(m1)
 matrix list m1
 matrix c1=x1*m1'
 matrix list c1
 di exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix b1=x1*100*exp(trace(c1))/(1+exp(trace(c1)))^2
 matrix list b1
 
  //marg. effekte eq2
 matrix x=e(b)
 matrix x2=x[1,`par2'..`par_max'] //zahl der parameter + cons
// tab ausbil, gen(ausbil)
 matrix accum A2=ant_ue50_jun2007 ant_ue55_jun2007 jahre_e50 jahre_alo50 frau alo_sex_62007 ost deu alo_kr i.ausbil alter if e(sample)==1, mean(m2)
 matrix list m2
 matrix c2=x2*m2'
 matrix list c2
 di exp(trace(c2))/(1+exp(trace(c2)))^2
 matrix b2=x2*100*exp(trace(c2))/(1+exp(trace(c2)))^2 //in prozent
 matrix list b2
 
 
 
 
 
 
 
 
 


 
///////////////////////////////c: Bivariate Probit///////////////////


biprobit 	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ krank05 /*kindererz*/ U_diff /*i.ber*/ /*ost*/ frau deu /*i.nation_gr*/ /*married*/ i.altersg /*alter lnalter*/) ///
			(laborm_constr: retire = ant_ue50_jun2007 ant_ue55_jun2007 l12_alo i.bula /*krank05*/ jahre_e50 /*jahre_alo50*/ frau /* deu*/ /*deu#c.alo_ausl_jun2007*/ lohn_p85 alo_sex_62007 ost deu alo_kr /*steckt schon in alo_ausl: deu*/ i.ausbil /*lnalter*/ /*jahre_schule*/ /*alter*/ /*i.ber*/ /*i.kreis*/ /*FASCHULAZ SCHULAZ*/) ///
			, vce(cluster persnr) difficult

			
biprobit	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ /*kindererz*/ /*U_diff*/ /*a63b35*/ U_diff minregel alter59 /*regelalter*/ /*firstday*/ /*jahresende*/ gebdummy /*U_diff*/ /*i.ber*/ /*ost frau deu*/ /*i.nation_gr*/ /*married*/ /*gebdummy*/ /*i.altersg*/ /*i.alter781*/  /*i.persnr*/ ) /// option value
			(laborm_constr: retire = /*ant_ue50_jun2007*/ /*l12_alo*/ /*aloq55*/ /*krank05*/ a65 jahresende /*ant_ue55_jun2007*/  /* bula_* */ /*jahre_alo50*/ frau /*deu#c.alo_ausl_jun2007*/ /*tentgelt*/ /*lohn_p85log*/ /*alo_sex_62007*/ /*ost deu*/ /*alo_kr*/ /*steckt schon in alo_ausl: deu*/ /* i.ausbil */ /*jahre_schule*/ /*alter59*/ /*alter59*/ /*minregelalter*/ /*alter592 alter593*/ /*alter594*/ /* alter595*/ /*i.ber*/ /*i.kreis*/ ) ///
			, vce(cluster persnr) difficult					

					
biprobit	(nodesire2work: retire =/*i.cohort*/ /*zugang*/ /*kindererz*/ /*U_diff*/ /*a63b35*/ U_diff /*regelalter*/ /*firstday*/ /*jahresende*//*U_diff*/ /*i.ber*/ /*ost frau deu*/ /*i.nation_gr*/ /*married*/ /*gebdummy*/ /*i.altersg*/ /*i.alter781*/  /*i.persnr*/ ) /// option value
			(laborm_constr: retire = /*ant_ue50_jun2007*/ /*l12_alo*/ /*aloq55*/ /*krank05*/ alo_kr bula_* /*ant_ue55_jun2007*/  /* bula_* */ /*jahre_alo50*/ /*deu#c.alo_ausl_jun2007*/ /*tentgelt*/ /*lohn_p85log*/ /*alo_sex_62007*/ /*ost deu*/ /*alo_kr*/ /*steckt schon in alo_ausl: deu*/ /* i.ausbil */ /*jahre_schule*/ /*alter59*/ /*alter59*/ /*minregelalter*/ /*alter592 alter593*/ /*alter594*/ /* alter595*/ /*i.ber*/ /*i.kreis*/ ) ///
			, vce(cluster persnr) difficult					


save "${TEMP_DIR}2_temp6.dta", replace
	
capture log close

clear, exit stata

