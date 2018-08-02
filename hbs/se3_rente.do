capture log using "$log/se3_rente.log", replace


///////////////////////////////////BERECHNUNG DER RENTEN UND DER ZUGEHÖRIGEN NUTZEN////////////////

set more off

use  "$orig/zugangsfaktoren.dta", clear
  expand 12 if gebmon==0 , generate(dupli)
  sort gebjahr gebmon dupli
  forvalues j=1/12 {
  replace gebmon=`j' if gebmon==0 & dupli[_n-`j'+1]==0
  }
  drop dupli

save "$data/temp_zugangsfaktoren.dta", replace





foreach num of numlist 0.003 0.0033 {
local deduc=`num'
di `deduc'

 
use "$data/2_temp5.dta", clear

bys zeit: sum tentgelt tentgelt_pred

forvalues j=0/15 {
replace tentgelt=tentgelt*(1.01)^`j' if zeit<575-`j'*12 & zeit>=563-`j'*12
replace tentgelt_pred=tentgelt_pred*(1.01)^`j' if zeit<575-`j'*12 & zeit>=563-`j'*12
}
replace tentgelt=1500 if tentgelt>1500
bys persnr: egen tentgelt_pred_max=max(tentgelt_pred)
bys persnr: egen tentgelt_pred_mean=mean(tentgelt_pred) if tentgelt_pred!=0
replace tentgelt_pred=tentgelt_pred_mean if tentgelt_pred>400 //if high (>400) tentgelt_pred, then replace it by its mean over periods with positive earnings
replace tentgelt_pred=400 if tentgelt_pred>400 //if high (>400) tentgelt_pred, then replace it by its mean over periods with positive earnings

bys zeit: sum tentgelt*



//keep if kreis<2000
//drop if frau==1
replace alter=alter-1
/*alter um den einen Monat korrigieren der immer
draufgeschlagen wird: für bessere intuition: monat nach dem 60geb ist nun alter 60.0
und nicht 60.0833*/



drop if alter<59*12


/*vertrauensschutz?:*/
gen vschutz0=0
replace vschutz0=1 if year<=2004 & (zustand==25 | (zustand>=5 & zustand<20) )
bysort persnr: egen vschutz = max(vschutz)
drop vschutz0

/*arbeitslosigkeitsrisiko?*/
replace tentgelt=0 if tentgelt >9999999999999
sort persnr zeit
gen lohn_exp=tentgelt_pred[_n-1] if persnr==persnr[_n-1] //erwarteter Lohn entspricht altem lohn
replace lohn_exp=200/30 if lohn_exp<200/30 | lohn_exp>9999999999999 //aber min hartz4 niveau
gen alopr = 1/(1+exp(-(0.022*(alter/12) - 0.05*(bsmon/12) -0.43*tenure2 - 0.57*tenure5 -0.15*ln(lohn_exp*30) +0.56*ost -0.11*jahre_schule -0.11*deu -1.1 )))
recode alopr (.=0)
capture drop weiterpr
gen weiterpr=1-alopr
replace weiterpr=1 if alozs==1 | (alozs[_n-1]==1 & persnr==persnr[_n-1]) //weiter in alo, if gerade nun in alo!


/*monate arbeitslos zählen*/
sort persnr zeit

gen l12_alo=0
/*
forvalues j=1/12 {
replace l12_alo=l12_alo+1 if alozs[_n-`j']==1 &persnr==persnr[_n-`j']
}
replace l12_alo=0 if l12_alo<3 /*dummy: mehr als 3 mon alo in letzten 12 mon?*/
replace l12_alo=1 if l12_alo>=3 | alo_rente==1 | PSGR==17
replace l12_alo=1 if l12_alo[_n-1]==1 & persnr==persnr[_n-1] //vormat berechtigt? dann bleibt das auch so!
*/

/*monate altersteilzeit zählen*/
sort persnr zeit
gen l12_atz=0

/*
forvalues j=1/12 {
replace l12_atz=l12_atz+1 if zustand[_n-`j']==25 & persnr==persnr[_n-`j']
}
replace l12_atz=0 if l12_atz<1 /*temporär: jeder darf in altersteilzeitrente?*/
replace l12_atz=1 if l12_atz>=1 | atz_rente==1
*/

/*NEUE ZUGANGSFAKTOREN nach alter anmergen*/
merge m:1 gebjahr gebmon using "$data/temp_zugangsfaktoren.dta"
drop if _merge==2  //jahre die nicht in dbasid vertreten sind
drop _merge
/*ENDE GEN NEUE ZUGANGSFAKTOREN*/







/*----------------UEBERSCHREIBEN: ANN:ALLE MIT MÖGLICHKEIT ZUR ALORENTE-----------------------*/
replace l12_alo=1
/*----------------------------------------------------------------------------------------*/



*inflationsindex, geschätzt, basis jahr 2000
*gen infl = 1.02^(year-2000)


/*rentenberechnung nach der rentenformel: rente(mtl)=entgeltpkt * zugangsfaktor * rentenartfaktor * aktueller rentenwert     */

/*FÜR DIE NÄCHSTEN FÜNF JAHRE*/

/*
/*zf: ZUGANGSFAKTOR ERSTES JAHR MONATL*/
forvalues k=1/12 {
gen zf_`k'=0 //zugangsfaktor
gen alo_rente_`k'=0 //alorente möglich?

/*RENTE FÜR LANGJÄHRIG VERSICHERTE: ab 63 mit abschlägen*/

/*bis einschl 1945-46 geboren*/
replace zf_`k'=1-0.003*(65*12-(alter+`k')) if (alter+`k')<65*12 & (alter+`k')>=63*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente vor 65, monatlich 0.003 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12-(alter+`k')) if (alter+`k')>=65*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente nach 65, monatlich 0.005 zuschlag = jährlich 6.0%

/*ab 1947 bis 1958 geboren*/
forvalues j=1947/1958 {
local zusmon=`j'-1946
replace zf_`k'=1-0.003*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>65*12+`zusmon'  & (alter+`k')>=63*12 & gebjahr>=1947 & gebjahr<1959 //rente vor 65+x, monatlich 0.003 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>=65*12+`zusmon' & gebjahr>=1947 & gebjahr<1959 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab 1959 bis 1964 geboren*/
forvalues j=1959/1964 {
local zusmon=(`j'-1958)*2+12
replace zf_`k'=1-0.003*(65*12+`zusmon'-(alter+`k')) if (alter+`k')<65*12+`zusmon'  & (alter+`k')>=63*12 & gebjahr>=1959 & gebjahr<1965 //rente vor 65+x, monatlich 0.003 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>=65*12+`zusmon' & gebjahr>=1959 & gebjahr<1965 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab1965*/
replace zf_`k'=1-0.003*(67*12-(alter+`k')) if (alter+`k')<67*12  & (alter+`k')>=63*12 & gebjahr>=1965 //rente vor 67, monatlich 0.003 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(67*12-(alter+`k')) if (alter+`k')>=67*12 & gebjahr>=1965 //rente nach 67, monatlich 0.005 zuschlag = jährlich 6.0%

/*REGELALTERSRENTE*/

replace zf_`k'=0 if alter+`k'<65*12 & rrz_akt<35 //rente für langjährigversicherte nicht möglich, d.h. nur regelaltersrente oder andere rente, s.u.
//tab zf_`k', miss




/*bis einschl 1944 geboren???, RRG 1992/96*/
/*FRAUEN*/

forvalues j=1940/1944 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k' >= 60*12+12*(`jahrnacheinf')+`z' & gebjahr==`j' & gebmon==`z' & frau==1 & alter+`k'<=65*12 & beitragsz_f10==1 //frauenrentenaltersgrenze wird allmählich angehoben
replace zf_`k'=1-0.003*(60*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (60*12/*+`jahrnacheinf'*3+`z'/4*/) & (60*12+12*(`jahrnacheinf')+`z' >(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
//replace zf_`k'=1-0.000*(60*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man darüber schon hinaus ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (60*12+12*(`jahrnacheinf')+`z' <=(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1

}
}

/*Ab Jahrg 1945 ist Regelgrenze 65 für Frauen, minimum zunächst bei 60 --> FALLS CODE NOCHMALS BENUTZT WIRD AUF NEUERE DATEN: minimalaltersteigerung für zukünftige jahrgänge fehlt noch*/
replace zf_`k'=1-0.003*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k') /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k')>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12>=alter+`k') & gebjahr>=1945 & frau==1 & beitragsz_f10==1
//replace zf_`k'=1-0.000*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k') /* minus alter ==> monate die man über grenze ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if  (65*12<=alter+`k') & gebjahr>=1945 & frau==1 & beitragsz_f10==1



replace zf_`k'=0 if alter+`k'<60*12 /*& frau==1*/ //keine verrentung vor 60




/*bis einschl 1941 geboren???, RRG 1992/96*/
/*PARTTIMERS UND Arbeitslose*/

forvalues j=1937/1941 { //übergangsphase
forvalues z=1/12 {
local jahrnacheinf=(`j'-1937)
replace zf_`k'=1 if alter+`k' >= 59*12+12*(`jahrnacheinf')+`z' & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'<=65*12 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12) //alo-rentenaltersgrenze für abschlagsfreie rente wird allmählich angehoben
replace zf_`k'=1-0.003*(59*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z' >(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12)
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65?
 if (alter+`k') >= (59*12) & (alter+`k')<65*12 & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1)
//replace zf_`k'=1-0.000*(59*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z' <=(alter+`k')) & gebjahr==`j' & gebmon==`z' & alter+`k'<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12)
}
}

//altergrenze bereits hochgesetzt
replace zf_`k'=1-0.003*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (59*12) & (64*12>=(alter+`k'))& gebjahr>=1942 & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & (rrz_akt<35 | (alter+`k')<63*12)
replace zf_`k'=1-0.000*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// ab akt grenze werden (faktisch keine) zuschläge vorgenommen
if (alter+`k') >= (59*12) & (64*12<(alter+`k'))& gebjahr>=1942  & alter+`k'<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & (rrz_akt<35 | (alter+`k')<63*12)

forvalues j=1946/1949 { //ab 1946 der frühstmögliche termin hochgesetzt
forvalues z=1/12 { //mindestalter (ohne vertrauensschutz) wird angewandt, dh. zf==0 für alter 60j0m usw.
local jahrnacheinf=(`j'-1946)
replace zf_`k'=0 if (59*12+12*(`jahrnacheinf')+`z' >(alter+`k')) & (gebjahr==`j') & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) /*& (rrz_akt<35 | (alter+`k')<63*12)*/ & /*vertrauensschutz?:*/vschutz==0
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65?
if (59*12+12*(`jahrnacheinf')+`z' <=(alter+`k')) & (alter+`k')<65*12 & gebmon==`z' & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & vschutz==0
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65? (vertrauensschutz)
if (59*12 <=(alter+`k')) & (alter+`k')<65*12 & gebmon==`z' & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & vschutz==1
}
}


/*PARTTIMERS UND Arbeitslose*/
/*
forvalues j=1937/1941 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k'>=60*12+12*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'<=65*12 //rentenaltersgrenze wird allmählich angehoben
replace zf_`k'=1-0.003*(60*12+12*(`jahrnacheinf')+`k'+`z'/*aktuelle altergrenze für volle bezüg*/ -(alter+`k')/*monate die man davon entfernt ist*/ )/// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k')>=60*12 & gebjahr==`j' & gebmon==`z' & frau==0
replace zf_`k'=1 if alter+`k'>=60*12+12*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0 //
}
}
*/



/*LANGJÄHRIG VERSICHERTE*/

//nicht relevant, da niemand in datensatz vor 1940 geboren
/*
forvalues j=1937/1938 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k'>=63*12+4*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0
}
}
replace zf_`k'=0 if alter+`k'<63*12 & frau==0 */

/*
replace zf`k'=0 if alter+`k'*12<63*12 
replace zf`k'=0 if alter+`k'*12<63*12 & frau==0
replace zf`k'=0 if alter+`k'*12<60*12 & frau==1*/

replace zf_`k'=1 if alter+`k'>=60*12 & schwebd==1 & zf_`k'<1 & rrz_akt>=35 /*abschlagsfreiue schwebrente? gibt es sowas?*/
/*replace zf`k'=1 if alter+`k'*12>=63*12 & (gebjahr + alter+`k') >=1992 & schwebd==1*/

replace zf_`k'=1 if alter+`k'<65*12 & zf_`k'>1


/*raf: RENTENARTFAKTOR*/
gen raf_`k'=0 /* oder 0.5?*/
replace raf_`k'=1 if alter+`k'>=60*12 //normale altersrente möglich

gen arw_`k'=28.07*1.01^(year-2010+`k'/12)   // +(2000-year+`k')*0.25

/*
Renten wegen Alters 	1,0
Renten wegen voller Erwerbsminderung 	1,0
Erziehungsrenten 	1,0
große Witwenrente 	0,55
Renten wegen teilweiser Erwerbsminderung 	0,5
kleine Witwenrente 	0,25
Vollwaisenrente 	0,2
Halbwaisenrente 	0,1
*/

/*ACHTUNG ERWEITERUNG MÖGLICH?!: statt simpel egpt der letzten monate zu nehmen, egpt für alo bezug berücksichtigen als minimalgrenze?!*/


//recode zf_`k' (0=0.5)
gen egpt_`k'= 0
forvalues q=1/`k' {
replace egpt_`k'=egpt_`k'+weiterpr^(`q'/12)*(1/12)*egpt_l12
}
gen rente_`k' = (egpt_dyn /*egpt_bfrei+egpt_bgem+egpt_zus*/+egpt_`k') /*idee von hannes: durschnitt der letzten 12mon oder 5 jahre?*/ * zf_`k' * raf_`k' * arw_`k' //rentenberechnung nach rentenformel
/*replace rente_`k' = (egpt_dyn+egpt_bfrei+(`k'/12)*0.3) if egpt_l12<0.2*/ /*HIER STATT 0,2 DEN WERT FÜR ALO EINSETZEN*/ 
}

*/

/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/

if `deduc'== 0.0033 {

forvalues p=0/10  {
local j=720+`p'*6
replace zfage`j'=1-(1-zfage`j')*1.1
}

}



forvalues k=0/5 {

gen zf`k'=0 //zugangsfaktor regulär
gen zfalo`k'=0 //zugangsfaktor regulär
gen alo_rente`k'=0 //alorente möglich?


/*neue zuweisung zf*/
//ALO_RENTEN ZF
forvalues p=0/10  {
local j=720+`p'*6
replace zfalo`k'=zfage`j' if alter+`k'*12>=`j' &  alter+`k'*12<=`j'+5 
}
replace zfalo`k'=1 if alter+`k'*12>=780
//REGULÄRE RENTEN ZF
replace zf`k'=1-`deduc'*(65*12-(alter+`k'*12)) if (alter+`k'*12)<65*12 & (alter+`k'*12)>=63*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente vor 65, monatlich 0.003 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12-(alter+`k'*12)) if (alter+`k'*12)>=65*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente nach 65, monatlich 0.005 zuschlag = jährlich 6.0%

/*neue zuweisung zf ende*/



/*
/*bis einschl 1946 geboren*/
replace zf`k'=1-`deduc'*(65*12-(alter+`k'*12)) if (alter+`k'*12)<65*12 & (alter+`k'*12)>=63*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente vor 65, monatlich 0.003 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12-(alter+`k'*12)) if (alter+`k'*12)>=65*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente nach 65, monatlich 0.005 zuschlag = jährlich 6.0%

/*ab 1947 bis 1958 geboren*/
forvalues j=1947/1958 {
local zusmon=`j'-1946
replace zf`k'=1-`deduc'*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)<65*12+`zusmon' & (alter+`k'*12)>=63*12 & gebjahr>=1947 & gebjahr<1959 //rente vor 65+x, monatlich 0.003 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)>=65*12+`zusmon' & gebjahr>=1947 & gebjahr<1959 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab 1959 bis 1964 geboren*/
forvalues j=1959/1964 {
local zusmon=(`j'-1958)*2+12
replace zf`k'=1-`deduc'*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)<65*12+`zusmon' & (alter+`k'*12)>=63*12 & gebjahr>=1959 & gebjahr<1965 //rente vor 65+x, monatlich 0.003 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)>=65*12+`zusmon' & gebjahr>=1959 & gebjahr<1965 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab1965*/
replace zf`k'=1-`deduc'*(67*12-(alter+`k'*12)) if (alter+`k'*12)<67*12 & (alter+`k'*12)>=63*12 & gebjahr>=1965 //rente vor 67, monatlich 0.003 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(67*12-(alter+`k'*12)) if (alter+`k'*12)>=67*12 & gebjahr>=1965 //rente nach 67, monatlich 0.005 zuschlag = jährlich 6.0%

replace zf`k'=0 if alter+`k'*12<65*12 & rrz_akt<35 //rente für langjährigversicherte nicht möglich, d.h. nur regelaltersrente oder andere rente, s.u.


*/


/*FRAUEN: bis einschl 1944 geboren???, RRG 1992/96*/


/*
forvalues j=1940/1944 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf`k'=1 if alter+`k'*12 >= 60*12+`z'+12*(`jahrnacheinf') & gebjahr==`j' & gebmon==`z' & frau==1 & alter+`k'*12<=65*12 & beitragsz_f10==1 //frauenrentenaltersgrenze wird allmählich angehoben
replace zf`k'=1-`deduc'*(60*12+`z'+12*(`jahrnacheinf') /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (60*12+`z'+12*(`jahrnacheinf')>(alter+`k'*12)) & gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
//replace zf`k'=1-0.000*(60*12+`z'+12*(`jahrnacheinf') /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man drüber ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (60*12+`z'+12*(`jahrnacheinf')<=(alter+`k'*12)) & gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
}
}

/*Ab Jahrg 1945 ist Regelgrenze 65 für Frauen, minimum zunächst bei 60 --> FALLS CODE NOCHMALS BENUTZT WIRD AUF NEUERE DATEN: minimalaltersteigerung für zukünftige jahrgänge fehlt noch*/
replace zf`k'=1-`deduc'*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12>=alter+`k'*12) & gebjahr>=1945 & frau==1 & beitragsz_f10==1
//replace zf`k'=1-0.000*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12<alter+`k'*12) & gebjahr>=1945 & frau==1 & beitragsz_f10==1


replace zf`k'=0 if alter+`k'*12<60*12 //keine verrentung vor 60!
*/


/*bis einschl 1941 geboren???, RRG 1992/96*/
/*PARTTIMERS UND Arbeitslose*/


/*
forvalues j=1937/1941 { //übergangsphase
forvalues z=1/12 {
local jahrnacheinf=(`j'-1937)
replace zf`k'=1 if alter+`k'*12 >= 59*12+`z'+12*(`jahrnacheinf') & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'*12<=65*12 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1| `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12) //altersgrenze wird allmählich angehoben
replace zf`k'=1-`deduc'*(59*12+`z'+12*(`jahrnacheinf') /*aktuelle altergrenze für volle bezüg (nach einem alojahr)*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ )  /// zwischen 59(60) und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z'>(alter+`k'*12))& gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
//replace zf`k'=1-0.000*(59*12+`z'+12*(`jahrnacheinf') /*aktuelle altergrenze für volle bezüg (nach einem alojahr)*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ )  /// zwischen 59(60) und akt grenze werden abschläge vorgenommen
//if (alter+12*`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z'<=(alter+`k'*12))& gebjahr==`j' & gebmon==`z'  & alter+`k'*12<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & (rrz_akt<35 | (alter+`k'*12)<63*12)
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65 beginnen
 if (alter+12*`k') >= (59*12) & (alter+12*`k')<65*12 & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0)

}
}

//altersgrenze bereits hochgesetzt
replace zf`k'=1-`deduc'*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (64*12>=(alter+`k'*12))& gebjahr>=1942 & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
replace zf`k'=1-0.000*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (64*12<(alter+`k'*12))& gebjahr>=1942  & alter+`k'*12<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
forvalues j=1946/1949 { //ab 1946 der frühstmögliche termin hochgesetzt
forvalues z=1/12 {
local jahrnacheinf=(`j'-1946)
replace zf`k'=0 if (59*12+12*(`jahrnacheinf')+`z' >(alter+`k'*12)) & (gebjahr==`j') & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1| `k'>0)  /*& (rrz_akt<35 | (alter+`k'*12)<63*12)*/ & /*vertrauensschutz?:*/vschutz==0
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65?
 if (alter+12*`k') >= (59*12+12*(`jahrnacheinf')+`z') & (alter+12*`k')<65*12 & gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & /*vertrauensschutz?:*/vschutz==0
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65?
 if (alter+12*`k') >= (59*12) & (alter+12*`k')<65*12 & gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & /*vertrauensschutz?:*/vschutz==1
}
}

*/

/*
replace zf`k'=0 if alter+`k'*12<63*12 
replace zf`k'=0 if alter+`k'*12<63*12 & frau==0
replace zf`k'=0 if alter+`k'*12<60*12 & frau==1*/

*replace zf`k'=1 if alter+`k'*12>=60*12  & schwebd==1 & zf`k'<1 & rrz_akt>=35
/*replace zf`k'=1 if alter+`k'*12>=63*12 & (gebjahr + alter+`k') >=1992 & schwebd==1*/

replace zf`k'=1 if alter+12*`k'<65*12 & zf`k'>1


/*raf: RENTENARTFAKTOR*/
gen raf`k'=0 /* oder 0.5?*/
replace raf`k'=1 if alter+`k'*12>=60*12 //normale altersrente möglich

gen arw`k'=28.07*1.01^(year-2010+`k')   // akt rentenwert und inflation

/*
Renten wegen Alters 	1,0
Renten wegen voller Erwerbsminderung 	1,0
Erziehungsrenten 	1,0
große Witwenrente 	0,55
Renten wegen teilweiser Erwerbsminderung 	0,5
kleine Witwenrente 	0,25
Vollwaisenrente 	0,2
Halbwaisenrente 	0,1
*/

/*ACHTUNG ERWEITERUNG MÖGLICH?!: statt simpel egpt der letzten monate zu nehmen, egpt für alo bezug berücksichtigen als minimalgrenze?!*/


//recode zf`k' (0=0.5)
gen egpt`k'= 0
forvalues q=0/`k' {
replace egpt`k'=egpt`k'+/*weiterpr^(`q')* */ egpt_l12 if `q'>0
}
gen rente`k' = (egpt_dyn +egpt`k') * zf`k' * raf`k' * arw`k' //rentenberechnung nach rentenformel
gen rente`k'A= (egpt_dyn +0.8*egpt`k') * zfalo`k' * raf`k' * arw`k' //rentenberechnung nach rentenformel; ad-hoc runtergewichtung da kaum EGPT-erwerb in alo

drop egpt`k'
/*replace rente`k' = (egpt_dyn+egpt_bfrei+egpt_bgem+egpt_zus+`k'*0.2) if egpt_l12<0.2*/ /*HIER STATT =:§ DEN WERT FÜR ALO EINSETZEN*/ 
}

// tab egpt_dyn in 1/1000, miss


forvalues k=0/5 {
//sum rente`k' if rente`k'>0
gen rente`k'_exp=rente`k'
replace rente`k'_exp=200 if rente`k'_exp<200 & zf`k'!=0 & raf`k'!=0
replace alo_rente`k'=1-(alter+12*`k'-64*12)/12 /*verbleibende monate/12 die mit alo aufgefüllt werden müssen*/  if alter+12*`k'>64*12 & alo_rente`k'==1 //alorente ab 64 nicht mehr möglich "anzufangen", d.h. alospells zu sammeln, da man vor 65 nicht mehr fertig wird.
replace alo_rente`k'=0 if alo_rente`k'<0
gen rente`k'_expA=rente`k'A
replace rente`k'_expA=200 if rente`k'_expA<200 & zfalo`k'!=0 & raf`k'!=0
}






/*
forvalues k=1/12 {
//sum rente_`k' if rente_`k'>0
gen rente_`k'_exp=rente_`k'
replace rente_`k'_exp=500 if rente_`k'_exp<500  & (zf_`k'!=0 & raf_`k'!=0) //grundsicherungsniveau
replace alo_rente_`k'=1-(alter+`k'-64*12)/12 if alter+`k'>64*12 & alo_rente_`k'==1 
replace alo_rente_`k'=0 if alo_rente_`k'<0
}
*/


//erwartete rente berücksichtigt noch grundsicherungsniveau


if `deduc'==0.003 {

/*Utility abhängig vom Renteneintritt T*/

replace tentgelt=0 if tentgelt >9999999999999
sort persnr zeit
//gen lohn_exp=lohn_p85 //erwarteter Lohn entspricht 85er percentilsder vergangenen Löhne
*gen lohn_exp=tentgelt[_n-1] if persnr==persnr[_n-1] //erwarteter Lohn entspricht altem lohn
*replace lohn_exp=500/30 if lohn_exp<500/30 | lohn_exp>9999999999999 //aber min hartz4 niveau
gen alosatz=0 //ARBEITSLOSENENTGELT FALLS ALORENTE IN ANSPRUCH GENOMMEN WIRD!
replace alosatz=30*tentgelt[_n-1]*(100/65)*0.8 if zustand[_n-1]==7 & persnr==persnr[_n-1] //ALG1 vergleichbar machen mit steuerpflichtigem bruttoeinkommen
replace alosatz=30*tentgelt[_n-1]*0.8 if zustand[_n-1]!=7  & persnr==persnr[_n-1] //ALG1 berechnen für aktuellen Lohn
replace alosatz=200 if alosatz<200 //ALG2
sum lohn*  rente* alosatz

save "$data/2_temp5a.dta", replace

use "$data/2_temp5a.dta", clear

/*
local lambda =2.8 //Freizeitgewichtungsfaktor
local delta  =0.97 //Diskontfaktor
local rho = 0.93 //überlebewahrscheinlichkeit
local gamma = 0.75 //Curvature der Nutzenfunktion


forvalues k=0/5 {
	gen double U`k'=0
	gen ueberleb=1
	forvalues j=0/30 { //Renteneintritt jetzt oder in k Jahren
		replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<=1 & `rho'^(alter/12-67+`j')>0
		replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
		replace U`k'=U`k'+`delta'^(`j')*ueberleb*(lohn_exp*30*1.01^`k')^(`gamma') if `j'<`k' & alter+`j'*12<=65*12 //nutzen aus arbeitseink
		replace U`k'=U`k'+`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+1)^(`gamma')) if `j'>=`k' //nutzen aus rente if nicht alorente
		replace U`k'=U`k'-			   `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+1)^(`gamma')) +				 `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'==1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
		replace U`k'=U`k'-alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+1)^(`gamma')) + alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'>0 & alo_rente`k'<1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
	}
	capture drop ueberleb
}

forvalues k=1/12 {
	gen double U_`k'=0
	gen ueberleb=1
	forvalues j=1/12 { //Renteneintritt jetzt oder in j Monaten
		replace ueberleb=`rho'^((alter/12-67)/*+`j'/12*/) if  `rho'^(alter/12-67/*+`j'/12*/)<1 & `rho'^(alter/12-67/*+`j'/12*/)>0 /*0.98655^((alter-60*12)+`j')<1 & 0.98655^((alter-60*12)+`j')>0*/
		replace U_`k'=U_`k'+(1/12)*`delta'^(`j'/12)*ueberleb*(lohn_exp*30*1.01^(`k'/12))^(`gamma') if `j'<`k' & alter+`j'<=65*12 //nutzen aus arbeitseink
		replace U_`k'=U_`k'+(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(rente_`k'_exp+1)^(`gamma')) if `j'>=`k' //nutzen aus rente if not alorente
		replace U_`k'=U_`k'-(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(rente_`k'_exp+1)^(`gamma')) + (1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'>=`k' & ( (`j'-`k')/12<alo_rente_`k' |alo_rente_`k'==1) //nutzen aus ersten 12-k mon rente if alorente
	}
	drop ueberleb
	gen ueberleb=1
	forvalues j=1/30 { //angefügt wird der nutzen der entsteht für alle weiteren rentenjahre; macht berechnung schneller
	replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<1 & `rho'^(alter/12-67+`j')>0
	replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
	replace U_`k'=U_`k'+         `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente_`k'_exp+1)^(`gamma')) //nutzen aus rente if not alo rente
	replace U_`k'=U_`k'-(alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente_`k'_exp+1)^(`gamma')) + (alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==1 & (alo_rente_`k'==1 |alo_rente_`k'-(12-`k')/12>0)  //nutzen aus k mon rente die auf die ersten (12-k) mon folgen if alorente
	}
	capture drop ueberleb
}

gen  double SSW= 0 // SOCIAL SECURITY WEALTH
gen ueberleb=1
	forvalues j=1/30 { //Renteneintritt jetzt, summation über j Jahre
		replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<1 & `rho'^(alter/12-67+`j')>0
		replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
		replace SSW=SSW+(`delta'^(`j'))*ueberleb*rente0 //nutzen aus arbeitseink
     }
capture drop ueberleb


sum U* //Übersicht über veschiedene Nutzen

gen U_future=max(U1,U2,U3,U4,U5,U_1,U_2,U_3,U_4,U_5,U_6,U_7,U_8,U_9,U_10,U_11,U_12)
gen U_diff=U0-U_future
label var U_diff "Nutzenunterschied Ruhestand nun oder später"


sum U_diff, detail

*/

*gen U_future2=max(U1,U2,U3,U4,U_3,U_4,U_5,U_6,U_7,U_8,U_9,U_10,U_11,U_12) //2monatslücke zwischen jetztverrentung und nächstem termin
*gen U_diff2=U0-U_future2
*sum U_diff2, detail
gen zugang=zf0

*drop zf* raf* arw* U1 U2 U3 U4 U5 U_1 U_2 U_3 U_4 U_5 U_6 U_7 U_8 U_9 U_10 U_11 U_12
save "$data/2_temp5b.dta", replace
count if rente0==0 & retire==1
//keep if rente0>0
//reg retire U_diff

/*ALOQUOTEN ZUSPIELEN AUF KREISBASIS*/

use "$orig/kreise.dta", clear
drop kreis
rename kreis_id kreis
replace kreis = kreis/1000
save "$data/2_kreis.dta", replace

use "$data/2_temp5b.dta", clear

recode kreis (15082=15151) (15089=15153) (15091=15171) (15002=15202) /// sachsen-anhalt reform 2007
	(15084=15256) (15087=15260) (15003=15303) (15083=15355) (15085=15357) ///
	(15086=15358) (15090=15363) (15081=15370) (15088=15265) ///
	(14730=14374) (14522=14375) (14729=14379) (14612=14262) (14626=14263) /// sachsen reform 2008
	(14625=14272) (14627=14280) (14628=14287) (14511=14161) (14524=14167)  ///
	(14523=14178) (14521=14181) (14713=14365) ///
	(5334=5313) // aachen 2010 	

gen bula=0 if kreis>999 & kreis<.	
forvalues j=1/16 {
recode bula (0=`j') if kreis>=`j'*1000 & kreis<`j'*1000+1000
}
	
/*es fehlen noch die zuordnungen für 14713 und 15088*/	
	
	
merge m:1 kreis using "$data/2_kreis.dta"
drop if _merge==2
/*wie kann man das kreiszuordnungsproblem lösen?*/
gen alo_kr=.
forvalues j = 455/611 {
 replace alo_kr=m`j' if zeit==`j'
 }
drop m455-m611

gen alo_sex_62007 =quote_m_jun2007 if frau==0
replace alo_sex_62007= quote_f_jun2007 if frau==1

gen aloq55= ant_ue55_jun2007*alo_kr


drop quote_m*
drop quote_f*

capture drop _merge
save "$data/2_temp5_97_25_94-zf01.dta", replace
capture log close

}

if `deduc'==0.0033 {

forvalues k=0/5 {
gen ded_rente`k'_exp = rente`k'_exp
gen ded_rente`k'_expA = rente`k'_expA
}

keep ded* persnr alter

capture drop _merge
merge 1:1 persnr alter using "$data/2_temp5_97_25_94-zf01.dta"

save "$data/2_temp5_97_25_94-zf01.dta", replace

capture drop _merge

}



/*

erase "${TEMP_DIR}2_kreis.dta"
erase "${TEMP_DIR}2_temp5a.dta"
erase "${TEMP_DIR}2_temp5b.dta"

capture log using "${LOG_DIR}5_reform.log", replace


set more off

///////////////////REFORM!!!!!!!!!!!!!!!!!//////////////////////
/*ABSCHLAG 6 Prozent*/

rename rente0 akt_rente
rename U_diff xU_diff
rename U_1 xU_1
rename U1 xU1
rename U0 xU0

drop zf* raf* arw* U* rente* lohn_exp alo_rente0-alo_rente5 alo_rente_*


/*replace alter=alter-1*/ /*alter um den einen Monat korrigieren der immer
draufgeschlagen wird: für bessere intuition: monat nach dem 60geb ist nun alter 60.0
und nicht 60.0833*/

drop if alter<59*12



*inflationsindex, geschätzt, basis jahr 2000
*gen infl = 1.02^(year-2000)


/*rentenberechnung nach der rentenformel: rente(mtl)=entgeltpkt * zugangsfaktor * rentenartfaktor * aktueller rentenwert     */

/*FÜR DIE NÄCHSTEN FÜNF JAHRE*/

/*zf: ZUGANGSFAKTOR ERSTES JAHR MONATL*/
forvalues k=1/12 {
gen zf_`k'=0 //zugangsfaktor
gen alo_rente_`k'=0 //alorente möglich?
di "zf (reform), monatlich, k=`k'"
/*RENTE FÜR LANGJÄHRIG VERSICHERTE: ab 63 mit abschlägen*/

/*bis einschl 1945-46 geboren*/
replace zf_`k'=1-0.005*(65*12-(alter+`k')) if (alter+`k')<65*12 & (alter+`k')>=63*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente vor 65, monatlich 0.005 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12-(alter+`k')) if (alter+`k')>=65*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente nach 65, monatlich 0.005 zuschlag = jährlich 6.0%

/*ab 1947 bis 1958 geboren*/
forvalues j=1947/1958 {
local zusmon=`j'-1946
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>65*12+`zusmon'  & (alter+`k')>=63*12 & gebjahr>=1947 & gebjahr<1959 //rente vor 65+x, monatlich 0.005 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>=65*12+`zusmon' & gebjahr>=1947 & gebjahr<1959 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab 1959 bis 1964 geboren*/
forvalues j=1959/1964 {
local zusmon=(`j'-1958)*2+12
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')<65*12+`zusmon'  & (alter+`k')>=63*12 & gebjahr>=1959 & gebjahr<1965 //rente vor 65+x, monatlich 0.005 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(65*12+`zusmon'-(alter+`k')) if (alter+`k')>=65*12+`zusmon' & gebjahr>=1959 & gebjahr<1965 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab1965*/
replace zf_`k'=1-0.005*(67*12-(alter+`k')) if (alter+`k')<67*12  & (alter+`k')>=63*12 & gebjahr>=1965 //rente vor 67, monatlich 0.005 abzug = jährlich 3.6%
replace zf_`k'=1-0.005*(67*12-(alter+`k')) if (alter+`k')>=67*12 & gebjahr>=1965 //rente nach 67, monatlich 0.005 zuschlag = jährlich 6.0%

/*REGELALTERSRENTE*/

replace zf_`k'=0 if alter+`k'<65*12 & rrz_akt<35 //rente für langjährigversicherte nicht möglich, d.h. nur regelaltersrente oder andere rente, s.u.
//tab zf_`k', miss



di "zf frauen (reform), monatlich"
/*bis einschl 1944 geboren???, RRG 1992/96*/
/*FRAUEN*/

forvalues j=1940/1944 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k' >= 60*12+12*(`jahrnacheinf')+`z' & gebjahr==`j' & gebmon==`z' & frau==1 & alter+`k'<=65*12 & beitragsz_f10==1 //frauenrentenaltersgrenze wird allmählich angehoben
replace zf_`k'=1-0.005*(60*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (60*12/*+`jahrnacheinf'*3+`z'/4*/) & (60*12+12*(`jahrnacheinf')+`z' >(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
//replace zf_`k'=1-0.000*(60*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k') >= (60*12/*+`jahrnacheinf'*3+`z'/4*/) & (60*12+12*(`jahrnacheinf')+`z' <=(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
}
}

/*Ab Jahrg 1945 ist Regelgrenze 65 für Frauen, minimum zunächst bei 60 --> FALLS CODE NOCHMALS BENUTZT WIRD AUF NEUERE DATEN: minimalaltersteigerung für zukünftige jahrgänge fehlt noch*/
replace zf_`k'=1-0.005*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k') /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k')>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12>=alter+`k') & gebjahr>=1945 & frau==1 & beitragsz_f10==1
//replace zf_`k'=1-0.000*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k') /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k')>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12<=alter+`k') & gebjahr>=1945 & frau==1 & beitragsz_f10==1



replace zf_`k'=0 if alter+`k'<60*12 /*& frau==1*/ //keine verrentung vor 60




/*bis einschl 1941 geboren???, RRG 1992/96*/
/*PARTTIMERS UND Arbeitslose*/

forvalues j=1937/1941 { //übergangsphase
forvalues z=1/12 {
local jahrnacheinf=(`j'-1937)
replace zf_`k'=1 if alter+`k' >= 59*12+12*(`jahrnacheinf')+`z' & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'<=65*12 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12) //alo-rentenaltersgrenze für abschlagsfreie rente wird allmählich angehoben
replace zf_`k'=1-0.005*(59*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z' >(alter+`k'))& gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12)
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65?
 if (alter+`k') >= (59*12) & (alter+`k')<65*12 & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1)
//replace zf_`k'=1-0.000*(59*12+12*(`jahrnacheinf')+`z' /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z' <=(alter+`k')) & gebjahr==`j' & gebmon==`z' & alter+`k'<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) // & (rrz_akt<35 | (alter+`k')<63*12)
}
}

//altergrenze bereits hochgesetzt
replace zf_`k'=1-0.005*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k') >= (59*12) & (64*12>=(alter+`k'))& gebjahr>=1942 & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & (rrz_akt<35 | (alter+`k')<63*12)
replace zf_`k'=1-0.000*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k') /*monate die man davon entfernt ist*/ ) /// ab akt grenze werden (faktisch keine) zuschläge vorgenommen
if (alter+`k') >= (59*12) & (64*12<(alter+`k'))& gebjahr>=1942  & alter+`k'<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & (rrz_akt<35 | (alter+`k')<63*12)

forvalues j=1946/1949 { //ab 1946 der frühstmögliche termin hochgesetzt
forvalues z=1/12 { //mindestalter (ohne vertrauensschutz) wird angewandt, dh. zf==0 für alter 60j0m usw.
local jahrnacheinf=(`j'-1946)
replace zf_`k'=0 if (59*12+12*(`jahrnacheinf')+`z' >(alter+`k')) & (gebjahr==`j') & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) /*& (rrz_akt<35 | (alter+`k')<63*12)*/ & /*vertrauensschutz?:*/vschutz==0
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65?
if (59*12+12*(`jahrnacheinf')+`z' <=(alter+`k')) & (alter+`k')<65*12 & gebmon==`z' & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & vschutz==0
replace alo_rente_`k'=1 /// marker: ist alorentenzugang in gewissem monat möglich, spätestens bis 65? (vertrauensschutz)
if (59*12 <=(alter+`k')) & (alter+`k')<65*12 & gebmon==`z' & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1) & vschutz==1
}
}


/*PARTTIMERS UND Arbeitslose*/
/*
forvalues j=1937/1941 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k'>=60*12+12*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'<=65*12 //rentenaltersgrenze wird allmählich angehoben
replace zf_`k'=1-0.005*(60*12+12*(`jahrnacheinf')+`k'+`z'/*aktuelle altergrenze für volle bezüg*/ -(alter+`k')/*monate die man davon entfernt ist*/ )/// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k')>=60*12 & gebjahr==`j' & gebmon==`z' & frau==0
replace zf_`k'=1 if alter+`k'>=60*12+12*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0 //
}
}
*/



/*LANGJÄHRIG VERSICHERTE*/

//nicht relevant, da niemand in datensatz vor 1940 geboren
/*
forvalues j=1937/1938 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf_`k'=1 if alter+`k'>=63*12+4*(`jahrnacheinf')+`k'+`z' & gebjahr==`j' & gebmon==`z' & frau==0
}
}
replace zf_`k'=0 if alter+`k'<63*12 & frau==0 */

/*
replace zf`k'=0 if alter+`k'*12<63*12 
replace zf`k'=0 if alter+`k'*12<63*12 & frau==0
replace zf`k'=0 if alter+`k'*12<60*12 & frau==1*/

replace zf_`k'=1 if alter+`k'>=60*12 & schwebd==1 & zf_`k'<1 & rrz_akt>=35 /*abschlagsfreiue schwebrente? gibt es sowas?*/
/*replace zf`k'=1 if alter+`k'*12>=63*12 & (gebjahr + alter+`k') >=1992 & schwebd==1*/

replace zf_`k'=1 if alter+`k'<65*12 & zf_`k'>1


/*raf: RENTENARTFAKTOR*/
gen raf_`k'=0 /* oder 0.5?*/
replace raf_`k'=1 if alter+`k'>=60*12 //normale altersrente möglich

gen arw_`k'=28.07*1.01^(year-2010+`k'/12)   // +(2000-year+`k')*0.25

/*
Renten wegen Alters 	1,0
Renten wegen voller Erwerbsminderung 	1,0
Erziehungsrenten 	1,0
große Witwenrente 	0,55
Renten wegen teilweiser Erwerbsminderung 	0,5
kleine Witwenrente 	0,25
Vollwaisenrente 	0,2
Halbwaisenrente 	0,1
*/

/*ACHTUNG ERWEITERUNG MÖGLICH?!: statt simpel egpt der letzten monate zu nehmen, egpt für alo bezug berücksichtigen als minimalgrenze?!*/


//recode zf_`k' (0=0.5)
gen rente_`k' = (egpt_dyn /*egpt_bfrei+egpt_bgem+egpt_zus*/+(`k'/12)*egpt_l12) /*idee von hannes: durschnitt der letzten 12mon oder 5 jahre?*/ * zf_`k' * raf_`k' * arw_`k' //rentenberechnung nach rentenformel
/*replace rente_`k' = (egpt_dyn+egpt_bfrei+(`k'/12)*0.3) if egpt_l12<0.2*/ /*HIER STATT 0,2 DEN WERT FÜR ALO EINSETZEN*/ 
}



/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/
/*zf: ZUGANGSFAKTOR JÄHRLICH*/
di "zugangsfaktoren jährlich nach fiktiver reform"
forvalues k=0/5 {

gen zf`k'=0 //zugangsfaktor
gen alo_rente`k'=0 //alorente möglich?
di "zf für langjährig versicherte"
di "jahr `k'"

/*bis einschl 1946 geboren*/
replace zf`k'=1-0.005*(65*12-(alter+`k'*12)) if (alter+`k'*12)<65*12 & (alter+`k'*12)>=63*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente vor 65, monatlich 0.005 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12-(alter+`k'*12)) if (alter+`k'*12)>=65*12 /*& gebjahr>=1945 */ & gebjahr<=1946  //rente nach 65, monatlich 0.005 zuschlag = jährlich 6.0%

/*ab 1947 bis 1958 geboren*/
forvalues j=1947/1958 {
local zusmon=`j'-1946
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)<65*12+`zusmon' & (alter+`k'*12)>=63*12 & gebjahr>=1947 & gebjahr<1959 //rente vor 65+x, monatlich 0.005 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)>=65*12+`zusmon' & gebjahr>=1947 & gebjahr<1959 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab 1959 bis 1964 geboren*/
forvalues j=1959/1964 {
local zusmon=(`j'-1958)*2+12
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)<65*12+`zusmon' & (alter+`k'*12)>=63*12 & gebjahr>=1959 & gebjahr<1965 //rente vor 65+x, monatlich 0.005 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(65*12+`zusmon'-(alter+`k'*12)) if (alter+`k'*12)>=65*12+`zusmon' & gebjahr>=1959 & gebjahr<1965 //rente nach 65+x, monatlich 0.005 zuschlag = jährlich 6.0%
}
/*ab1965*/
replace zf`k'=1-0.005*(67*12-(alter+`k'*12)) if (alter+`k'*12)<67*12 & (alter+`k'*12)>=63*12 & gebjahr>=1965 //rente vor 67, monatlich 0.005 abzug = jährlich 3.6%
replace zf`k'=1-0.005*(67*12-(alter+`k'*12)) if (alter+`k'*12)>=67*12 & gebjahr>=1965 //rente nach 67, monatlich 0.005 zuschlag = jährlich 6.0%

replace zf`k'=0 if alter+`k'*12<65*12 &  rrz_akt<35 //rente für langjährigversicherte nicht möglich, d.h. nur regelaltersrente oder andere rente, s.u.




di "frauen"
/*FRAUEN: bis einschl 1944 geboren???, RRG 1992/96*/

forvalues j=1940/1944 {
forvalues z=1/12 {
local jahrnacheinf=(`j'-1940)
replace zf`k'=1 if alter+`k'*12 >= 60*12+`z'+12*(`jahrnacheinf') & gebjahr==`j' & gebmon==`z' & frau==1 & alter+`k'*12<=65*12 & beitragsz_f10==1 //frauenrentenaltersgrenze wird allmählich angehoben
replace zf`k'=1-0.005*(60*12+`z'+12*(`jahrnacheinf') /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (60*12+`z'+12*(`jahrnacheinf')>(alter+`k'*12)) & gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
//replace zf`k'=1-0.000*(60*12+`z'+12*(`jahrnacheinf') /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man über grenze ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (60*12+`z'+12*(`jahrnacheinf')<=(alter+`k'*12)) & gebjahr==`j' & gebmon==`z' & frau==1 & beitragsz_f10==1
}
}

/*Ab Jahrg 1945 ist Regelgrenze 65 für Frauen, minimum zunächst bei 60 --> FALLS CODE NOCHMALS BENUTZT WIRD AUF NEUERE DATEN: minimalaltersteigerung für zukünftige jahrgänge fehlt noch*/
replace zf`k'=1-0.005*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12>=alter+`k'*12) & gebjahr>=1945 & frau==1 & beitragsz_f10==1
//replace zf`k'=1-0.000*(65*12 /*aktuelle altersgrenze für volle bezüge*/ -(alter+`k'*12) /* minus alter ==> monate die man von grenze entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
//if (alter+`k'*12)>=(60*12 /*`jahrnacheinf'*3+`z'/4*/ ) & (65*12<=alter+`k'*12) & gebjahr>=1945 & frau==1 & beitragsz_f10==1


replace zf`k'=0 if alter+`k'*12<60*12 //keine verrentung vor 60!


di "zugangsfaktoren atz und alorente"
/*bis einschl 1941 geboren???, RRG 1992/96*/
/*PARTTIMERS UND Arbeitslose*/

forvalues j=1937/1941 { //übergangsphase
forvalues z=1/12 {
local jahrnacheinf=(`j'-1937)
replace zf`k'=1 if alter+`k'*12 >= 59*12+`z'+12*(`jahrnacheinf') & gebjahr==`j' & gebmon==`z' & frau==0 & alter+`k'*12<=65*12 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1| `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12) //altersgrenze wird allmählich angehoben
replace zf`k'=1-0.005*(59*12+`z'+12*(`jahrnacheinf') /*aktuelle altergrenze für volle bezüg (nach einem alojahr)*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ )  /// zwischen 59(60) und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z'>(alter+`k'*12))& gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
//replace zf`k'=1-0.000*(59*12+`z'+12*(`jahrnacheinf') /*aktuelle altergrenze für volle bezüg (nach einem alojahr)*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ )  /// zwischen 59(60) und akt grenze werden abschläge vorgenommen
//if (alter+12*`k') >= (59*12) & (59*12+12*(`jahrnacheinf')+`z'<=(alter+`k'*12))& gebjahr==`j' & gebmon==`z'  & alter+`k'*12<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & (rrz_akt<35 | (alter+`k'*12)<63*12)
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65?
 if (alter+12*`k') >= (59*12) & (alter+12*`k')<65*12 & gebjahr==`j' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0)
}
}

di "zugangsfaktoren atz und alorente:altersgrenze bereits hochgesetzt"

//altersgrenze bereits hochgesetzt
replace zf`k'=1-0.005*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (64*12>=(alter+`k'*12))& gebjahr>=1942 & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
replace zf`k'=1-0.000*(64*12 /*aktuelle altergrenze für volle bezüg*/ -(alter+`k'*12) /*monate die man davon entfernt ist*/ ) /// zwischen 60 und akt grenze werden abschläge vorgenommen
if (alter+12*`k') >= (59*12) & (64*12<(alter+`k'*12))& gebjahr>=1942  & alter+`k'*12<65*12 /*annahme=rente für alo nur bis 65*/ & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) // & (rrz_akt<35 | (alter+`k'*12)<63*12)
forvalues j=1946/1949 { //ab 1946 der frühstmögliche termin hochgesetzt
forvalues z=1/12 {
local jahrnacheinf=(`j'-1946)
replace zf`k'=0 if (59*12+12*(`jahrnacheinf')+`z' >(alter+`k'*12)) & (gebjahr==`j') & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1| `k'>0)  /*& (rrz_akt<35 | (alter+`k'*12)<63*12)*/ & /*vertrauensschutz?:*/vschutz==0
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65?
 if (alter+12*`k') >= (59*12+12*(`jahrnacheinf')+`z') & (alter+12*`k')<65*12 & gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & /*vertrauensschutz?:*/vschutz==0
replace alo_rente`k'=1 /// marker: ist alorentenzugang in gewissem jahr möglich, spätestens bis 65?
 if (alter+12*`k') >= (59*12) & (alter+12*`k')<65*12 & gebjahr==`j' & gebmon==`z' & frau==0 & rrz_akt>=15 & (l12_alo==1 | l12_atz==1 | `k'>0) & /*vertrauensschutz?:*/vschutz==1
}
}



/*
replace zf`k'=0 if alter+`k'*12<63*12 
replace zf`k'=0 if alter+`k'*12<63*12 & frau==0
replace zf`k'=0 if alter+`k'*12<60*12 & frau==1*/

replace zf`k'=1 if alter+`k'*12>=60*12  & schwebd==1 & zf`k'<1 & rrz_akt>=35
/*replace zf`k'=1 if alter+`k'*12>=63*12 & (gebjahr + alter+`k') >=1992 & schwebd==1*/

replace zf`k'=1 if alter+12*`k'<65*12 & zf`k'>1


di "rentenartfaktoren"

/*raf: RENTENARTFAKTOR*/
gen raf`k'=0 /* oder 0.5?*/
replace raf`k'=1 if alter+`k'*12>=60*12 //normale altersrente möglich

gen arw`k'=28.07*1.01^(year-2010+`k')   // akt rentenwert und inflation

/*
Renten wegen Alters 	1,0
Renten wegen voller Erwerbsminderung 	1,0
Erziehungsrenten 	1,0
große Witwenrente 	0,55
Renten wegen teilweiser Erwerbsminderung 	0,5
kleine Witwenrente 	0,25
Vollwaisenrente 	0,2
Halbwaisenrente 	0,1
*/

/*ACHTUNG ERWEITERUNG MÖGLICH?!: statt simpel egpt der letzten monate zu nehmen, egpt für alo bezug berücksichtigen als minimalgrenze?!*/

di "renten generieren"

//recode zf`k' (0=0.5)
gen rente`k' = (egpt_dyn /*+egpt_bfrei+egpt_bgem+egpt_zus*/ +`k'*egpt_l12) /*idee von hannes: durschnitt der letzten 12mon oder 5 jahre?*/ * zf`k' * raf`k' * arw`k' //rentenberechnung nach rentenformel
/*replace rente`k' = (egpt_dyn+egpt_bfrei+egpt_bgem+egpt_zus+`k'*0.2) if egpt_l12<0.2*/ /*HIER STATT =:§ DEN WERT FÜR ALO EINSETZEN*/ 
}

// tab egpt_dyn in 1/1000, miss


forvalues k=0/5 {
//sum rente`k' if rente`k'>0
gen rente`k'_exp=rente`k'
replace rente`k'_exp=500 if rente`k'_exp<500 & zf`k'!=0 & raf`k'!=0
replace alo_rente`k'=1-(alter+12*`k'-64*12)/12 /*verbleibende monate/12 die mit alo aufgefüllt werden müssen*/  if alter+12*`k'>64*12 & alo_rente`k'==1 //alorente ab 64 nicht mehr möglich "anzufangen", d.h. alospells zu sammeln, da man vor 65 nicht mehr fertig wird.
replace alo_rente`k'=0 if alo_rente`k'<0
}

forvalues k=1/12 {
//sum rente_`k' if rente_`k'>0
gen rente_`k'_exp=rente_`k'
replace rente_`k'_exp=500 if rente_`k'_exp<500  & (zf_`k'!=0 & raf_`k'!=0) //grundsicherungsniveau
replace alo_rente_`k'=1-(alter+`k'-64*12)/12 if alter+`k'>64*12 & alo_rente_`k'==1
replace alo_rente_`k'=0 if alo_rente_`k'<0

}


//erwartete rente berücksichtigt noch grundsicherungsniveau

save "${TEMP_DIR}2_temp5a.dta", replace
use "${TEMP_DIR}2_temp5a.dta", clear

/*Utility abhängig vom Renteneintritt T*/

replace tentgelt=0 if tentgelt >9999999999999
sort persnr zeit
//gen lohn_exp=lohn_p85 //erwarteter Lohn entspricht 85er percentilsder vergangenen Löhne
gen lohn_exp=tentgelt[_n-1] if persnr==persnr[_n-1] //erwarteter Lohn entspricht altem lohn
replace lohn_exp=500/30 if lohn_exp<500/30 | lohn_exp>9999999999999 //aber min hartz4 niveau
*sum lohn*  rente*

/*
local lambda =1.8 //Freizeitgewichtungsfaktor
local delta  =0.95 //Diskontfaktor
local rho =   0.95 //überlebewahrscheinlichkeit
*/

forvalues k=0/5 {
	
	gen long U`k'=0
	gen ueberleb=1
	forvalues j=0/50 { //Renteneintritt jetzt oder in k Jahren
		replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<=1 & `rho'^(alter/12-67+`j')>0
		replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
		replace U`k'=U`k'+`delta'^(`j')*ueberleb*ln(lohn_exp*30*1.01^`k') if `j'<`k' //nutzen aus arbeitseink
		replace U`k'=U`k'+`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(rente`k'_exp+1)) if `j'>=`k' //nutzen aus rente if nicht alorente
		replace U`k'=U`k'-`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(rente`k'_exp+1)) + `lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(alosatz)) if `j'==`k' & alo_rente`k'==1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
		replace U`k'=U`k'-alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(rente`k'_exp+1)) + alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(alosatz)) if `j'==`k' & alo_rente`k'>0 & alo_rente`k'<1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
	}
	capture drop ueberleb
}

forvalues k=1/12 {
	gen long U_`k'=0
	gen ueberleb=1
	forvalues j=1/12 { //Renteneintritt jetzt oder in k Monaten, Nutzensummierung für die ersten j Monate
		replace ueberleb=`rho'^((alter/12-67)/*+`j'/12*/) if  `rho'^(alter/12-67/*+`j'/12*/)<1 & `rho'^(alter/12-67/*+`j'/12*/)>0 /*0.98655^((alter-60*12)+`j')<1 & 0.98655^((alter-60*12)+`j')>0*/
		replace U_`k'=U_`k'+(1/12)*`delta'^(`j'/12)*ueberleb*ln(lohn_exp*30*1.01^(`k'/12)) if `j'<`k' //nutzen aus arbeitseink
		replace U_`k'=U_`k'+(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/ln(rente_`k'_exp+1)) if `j'>=`k' //nutzen aus rente if not alorente
		replace U_`k'=U_`k'-(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/ln(rente_`k'_exp+1)) + (1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/ln(alosatz)) if `j'>=`k' & ( (`j'-`k')/12<alo_rente_`k' |alo_rente_`k'==1) //nutzen aus ersten 12-k mon rente if alorente
	}
	drop ueberleb
	gen ueberleb=1
	forvalues j=1/50 { //angefügt wird der nutzen der entsteht für alle weiteren rentenjahre; macht berechnung schneller
	replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<1 & `rho'^(alter/12-67+`j')>0
	replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
	replace U_`k'=U_`k'+         `lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(rente_`k'_exp+1)) //nutzen aus rente if not alo rente
	replace U_`k'=U_`k'-(alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(rente_`k'_exp+1)) + (alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/ln(alosatz)) if `j'==1 & (alo_rente_`k'==1 |alo_rente_`k'-(12-`k')/12>0)  //nutzen aus k mon rente die auf die ersten (12-k) mon folgen if alorente
	}
	capture drop ueberleb
}

/*
local lambda =1.2 //Freizeitgewichtungsfaktor
local delta  =0.97 //Diskontfaktor
local rho =   0.94 //sterbewahrscheinlichkeit
*/

gen SSW2= 0 // SOCIAL SECURITY WEALTH
gen ueberleb=1
	forvalues j=1/25 { //Renteneintritt jetzt oder in j Jahren
		replace ueberleb=`rho'^(alter/12-67+`j') if  `rho'^(alter/12-67+`j')<1 & `rho'^(alter/12-67+`j')>0
		replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
		replace SSW2=SSW2+(`delta'^(`j'))*ueberleb*rente0 //audsummiertes renteneinkommen
     }
capture drop ueberleb




*sum U* //Übersicht über veschiedene Nutzen

gen U_future=max(U1,U2,U3,U4,U_1,U_2,U_3,U_4,U_5,U_6,U_7,U_8,U_9,U_10,U_11,U_12)
gen U_diff2=U0-U_future
label var U_diff2 "Nutzenunterschied Ruhestand nun oder später"


sum U_diff2, detail

*gen U_future2=max(U1,U2,U3,U4,U_3,U_4,U_5,U_6,U_7,U_8,U_9,U_10,U_11,U_12) //2monatslücke zwischen jetztverrentung und nächstem termin
*gen U_diff2=U0-U_future2
*sum U_diff2, detail
gen zugang2=zf0

rename rente0 akt_rente2

drop zf* raf* arw* U1 U2 U3 U4 U5 U_1 U_2 U_3 U_4 U_5 U_6 U_7 U_8 U_9 U_10 U_11 U_12

rename xU_diff U_diff

save "${TEMP_DIR}2_temp5_97_25_94-zf01.dta", replace

erase "${TEMP_DIR}2_temp5a.dta"
*/

}
capture log close


