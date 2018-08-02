capture log close
capture log using "$log/se2_format.log", replace

/////////////////////////////////////FORMATIERUNG-->spell ins long format/////////////
//außerdem: generierung von zeitunveränderlichen hilfsvariablen*/

set more off

/*nochmals auf variable daten zugreifen um gewisse charakteristika zu besetimmen,
die ab alter 59 als konstant angenommen werden (bildung, beruf, ostwest, kreis etc*/

use "$data/2_small_fix.dta", clear 
keep persnr SUEGPT_WEST-ZQMOKIPE_OST KIND ZTPTRTBE RTZTMO PSGR

merge 1:m persnr using "$data/2_small_var.dta" , keepus(persnr gebdat begepi ///
endepi level* quelle_gr spell EGPT EGPTAN schbild bild beruf ow_knz tentgelt ///
nation_gr frau zustand wo_kreis schweb stib/*SCHULAZ FASCHULAZ */)

keep if gebdat<-144 //geb vor 1947m3, dh. 60 jahre und älter plus toleranz

gen erwerbm=1 if zustand==24 & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen xerwerbm=sum(erwerbm)
replace erwerbm = 0
replace erwerbm = 1 if xerwerbm>0 & xerwerbm<. 
drop xerwerbm

drop if erwerbm == 1 /*erwerbsminderungsrentner raus - nicht relevant, da erst mit gebdat>=1948 im sample */

gen tz= stib==8 | stib==9 /*teikzeitbeschäftigung*/

gen kindererz = ZQMOKIPE_WEST+ZQMOKIPE_OST /*KINDERERZIEHUNGSZEITEN*/
label var kindererz "Kindererziehungszeiten"
gen egpt_bfrei = BYFHEGPT_WEST + BYFHEGPT_OST /*EGPT aus beitragsfreien Zeiten*/
gen egpt_zus = ZQEGPTKIPE_WEST+ZQEGPTKIPE_OST /*zus EGPT wegen Erz/Pflege*/
gen egpt_bgem = BYGMEGPTZQ_WEST+BYGMEGPTZQ_OST /*EGPT aus beitragsgem Zeiten*/


bysort persnr: egen xberuf=mode(beruf) if beruf>0 & beruf<99999, minmode //häufigster Beruf
bys persnr: egen ber=min(xberuf)
label var ber "haeufigster Beruf"
bys persnr: egen xost=mode(ow_knz) if ow_knz >=0 & ow_knz <100, minmode //ostdummy, hilfsv
bys persnr: egen ost=min(xost) //ostdummy
label var ost "Ost Dummy"
bys persnr: egen xkreis=mode(wo_kreis) if wo_kreis>=1000 & wo_kreis<20000, minmode  //kreis(wohnen)
bys persnr: egen kreis=min(xkreis) //kreis(wohnen)
label var kreis "haeufigst genannter Kreis"
replace schweb=1 if PSGR==62 //wer später Rente für Schwerbeh. erhält, wird immer schon als schwerbeh. kodiert.
bysort persnr: egen schwebd=min(schweb) //schwebehindertendummy
recode schwebd (2=1) (3=1) (4=0) (.=0) (.n=0) //4 und . bedeutet nicht schwerbehindert
label var schwebd "Dummy fuer Schwerbehindertenstatus (irgendwann im Leben)"
//tab schwebd

by persnr: egen xdeu=mode(nation_gr) if nation_gr>0 & nation_gr<999999, minmode //deutschdummy
by persnr: egen deu=max(xdeu)
label var deu "Deutschdummy"
replace deu=(deu==10|deu==.n|deu==.z)
drop xost xkreis xberuf schweb xdeu


**************nur leute behalten die zwischen 59M9 oder 60  min 1 mal arbeiten****************************************
gen arbeit60t=(zustand==2| zustand==3 | zustand==4 | zustand==5 | zustand==6 | zustand==19) /// übt beschäftigung aus
				& (mofd(begepi)-gebdat<=60*12) & mofd(endepi)-gebdat>=60*12-3 // im alter 60
bys persnr: egen arbeit60=max(arbeit60t)
keep if arbeit60==1		/*alle droppen die mit 60 nicht in beschäftigung sind*/		
********************************************************************************************

*********ostdeutsche dropen, sample verschlanken******
drop if ost==1
******************************************************

/*VON ANDREAS; BEGINN*/
gen begepi_m=mofd(begepi)
format begepi_m 
format %tm begepi_m 
format 


gen age=(begepi_m-gebdat)/12
label var age "Alter in Jahren"


*****************
  * Bildung
*****************

cap drop educ
label list bild_de // exakte Beschreibung der labels
clonevar educ = bild

****************************************************************************************************
** Nun verwende ich das Imputationsverfahren, vorgeschlagen durch Fitzenberger et al 2005.
** Hierbei wird der Besetzungsgrad der Bildungsvariable verbessert. 
****************************************************************************************************

replace educ=. if zustand!=4 & zustand!=5 & zustand!=6 // nur Informationen aus Beschäftigungsspells

*** Start: Volks-/Haupt-/Realschule
bys persnr: egen minbil1=min(spell) if bild==1 & inrange(zustand,4,6)
bys persnr: egen maxminbil1=max(minbil1)
bys persnr: replace minbil1=maxminbil1 if minbil1==.
drop maxminbil1
bys persnr: replace educ=1 if (educ==.z | educ==.n | educ==.) & spell>minbil1 

* ...mit Berufsausbildung

bys persnr: egen minbil2=min(spell) if bild==2 & inrange(zustand,4,6)
bys persnr: egen maxminbil2=max(minbil2)
bys persnr: replace minbil2=maxminbil2 if minbil2==.
drop maxminbil2
bys persnr: replace educ=2 if (educ==.z | educ==.n | educ<2 | educ==.) & spell>minbil2 

* Abitur

bys persnr: egen minbil3=min(spell) if bild==3 & inrange(zustand,4,6)
bys persnr: egen maxminbil3=max(minbil3)
bys persnr: replace minbil3=maxminbil3 if minbil3==.
drop maxminbil3

bys persnr: replace educ=3 if (educ==.z | educ==.n | educ<3 | educ==.) & spell>minbil3

*** Unklar ob Abitur oder niedriger Abschluss mit Berufsausbildung höherwertig -> beide in Kat. 4

* erst abi dann ausbildung
bys persnr: replace educ=4 if (educ==.n | educ==.z | educ<4 | educ==.) & minbil3<minbil2 & (minbil3!=. & minbil2!=.) & spell>=minbil2  

* erst ausbildung dann abi
bys persnr: replace educ=4 if (educ==.n | educ==.z | educ<4 | educ==.) & minbil3>minbil2 & (minbil3!=. & minbil2!=.) & spell>=minbil3  

* Abi mit Ausbildung angegeben

bys persnr: egen minbil4=min(spell) if bild==4 & inrange(zustand,4,6)
bys persnr: egen maxminbil4=max(minbil4)
bys persnr: replace minbil4=maxminbil4 if minbil4==.
drop maxminbil4

bys persnr: replace educ=4 if (educ==.z | educ==.n | educ<4 | educ==.) & spell>minbil4

* FH Abschluss

bys persnr: egen minbil5=min(spell) if bild==5 & inrange(zustand,4,6)
bys persnr: egen maxminbil5=max(minbil5)
bys persnr: replace minbil5=maxminbil5 if minbil5==.
drop maxminbil5

bys persnr: replace educ=5 if (educ==.z | educ==.n | educ<5 | educ==.) & spell>minbil5

* Uni Abschluss

bys persnr: egen minbil6=min(spell) if bild==6 & inrange(zustand,4,6)
bys persnr: egen maxminbil6=max(minbil6)
bys persnr: replace minbil6=maxminbil6 if minbil6==.
drop maxminbil6

bys persnr: replace educ=6 if (educ==.z | educ==.n | educ<6 | educ==.) & spell>minbil6


*** Missing Spells vor der ersten gültigen Bildungsinformation

bys persnr: egen mineduc=min(spell) if (educ!=. & educ!=.n & educ!=.z) 
bys persnr: egen mineducmax=max(mineduc) 
bys persnr: replace mineduc=mineducmax if mineduc==.
label var mineducmax "Spell mit erster gült. bildungsinfo"
drop mineducmax

bys persnr: gen educ_min=educ if mineduc==spell
bys persnr: egen educ_minmax=max(educ_min)
bys persnr: replace educ_min=educ_minmax if educ_min==.
label var educ_min "erste gült. Bildungsinfo"
drop educ_minmax

replace educ=1 if mineduc>spell & educ_min==1  & (educ==. | educ==.n | educ==.z) 
replace educ=2 if mineduc>spell & educ_min==2  & (educ==. | educ==.n | educ==.z) & age>= 20
replace educ=3 if mineduc>spell & educ_min==3  & (educ==. | educ==.n | educ==.z) & age>= 21
replace educ=4 if mineduc>spell & educ_min==4  & (educ==. | educ==.n | educ==.z) & age>= 23
replace educ=5 if mineduc>spell & educ_min==5  & (educ==. | educ==.n | educ==.z) & age>=27
replace educ=6 if mineduc>spell & educ_min==6  & (educ==. | educ==.n | educ==.z) & age>=29

drop mineduc educ_min mineduc minbil*

*************************************************************************************
* Ende der Bildungsimputation
*************************************************************************************

label var educ "Bildung (nach Imputation)"

gen educ_abi=.
replace educ_abi=1 if inrange(educ,3,6)
replace educ_abi=0 if inrange(educ,1,2)
gen educ_mis=.
replace educ_mis=0 if inrange(educ,1,6)
replace educ_mis=1 if educ==.

/*VON ANDREAS; ENDE*/



bysort persnr: egen ausbil=max(educ) //höchster bildungsabschluss
label var ausbil "höchster Bildungsabschluss"


//abhängige variable definieren
gen retire_2007 = (ZTPTRTBE>000000 & ZTPTRTBE<.) //rentenbezug 31dec2007
gen retire_akt = (ZTPTRTBE<=mofd(endepi)) //aktueller rentenbezug 
gen retire_erst58 = (zustand==26 & (mofd(begepi)-gebdat)>=58*12) //vom jahr 58 ausgesehen die erste rentenzahlung
gen xZTPTRTBE58 = mofd(begepi) if zustand==26 & (mofd(begepi)-gebdat)>=58*12 //beginn der ersten rentenperiode nach 58
bysort persnr: egen ZTPTRTBE58 = min(xZTPTRTBE58) //beginn früheste rentenperiode nach 58
format ZTPTRTBE58 %tm
drop xZTPTRTBE58
gen alterr=(ZTPTRTBE-gebdat)/12 //alter des aktuellen renteneintritts (beim stichtag 2007)
tab alterr
drop alterr
bysort persnr: egen rentbeg=min(begepi) if zustand==26 //erster rentenbeginn
bysort persnr: replace rentbeg=mofd(rentbeg) if zustand==26
bysort persnr: egen rentbeg_m = max(rentbeg) //letzter rentenbeginn
drop rentbeg

sort persnr spell
replace retire_erst58=2 if persnr==persnr[_n-1] & (retire_erst58[_n-1]==1 | retire_erst58[_n-1]==2)/* Variable retire ist 2 wenn Individuum in Vorperiode bereits in Rente*/
replace retire_akt=2 if persnr==persnr[_n-1] & (retire_akt[_n-1]==1 | retire_akt[_n-1]==2)/* Variable retire ist 2 wenn Individuum in Vorperiode bereits in Rente*/


*drop if retire_erst58==2 //nur eine letzte Periode soll retire==1 behalten, vgl jenkins 1995 dazu (wichtig für discrete time duration models)
drop if retire_akt==2 //momentan für diese rentenbestimmung entschieden


/*ÄNDERUNG AUG2015 BEGINN*/
bys persnr: egen zti=min(ZTPTRTBE)
tab zti, miss //wie viele sind überhaupt 2007 sind in rente?
bys persnr: egen maxend=max((endepi))

gen alter=(mofd(endepi)-gebdat)/12
bys persnr: egen maxalter= max(alter)
gen in2007schon65=(575-gebdat>65*12)
tab zti in2007schon65, miss
 
/*ÄNDERUNG AUG2015 ENDE*/


keep if quelle_gr==6 | quelle_gr==7 //nur episoden aus der VSKT beibehalten
* drop if zustand ==24 /*erwerbsgem*/ | zustand ==20 /*mutterschaft*/ | zustand ==10 /*ALG*/ | zustand ==1 /*Schulische Ausb*/ //zustände ohne echtes entgelt

bysort persnr begepi: egen EGPTsum=sum(EGPT) //summe der entgeltpunkte pro episode
label var EGPTsum "summe der entgeltpunkte pro episode"
bysort persnr: egen EGPTtot=sum(EGPT) //summe der entgeltpunkte übers leben
label var EGPTtot "summe der entgeltpunkte übers leben"
bysort persnr: egen xEGPTtot59=sum(EGPT) if mofd(endepi)-gebdat<59*12 //bis alter 59
bysort persnr: egen EGPTtot59=min(xEGPTtot59)
label var EGPTtot59 "summe der entgeltpunkte bis 59"

/*LEICHT UNGENAUER BEHELF FÜR MONATE ZWISCHEN GEBURTSTAG UND SPELLENDE;*/
bysort persnr: egen letzter_nicht_mehr= max(endepi) if mofd(endepi)-gebdat<59*12 //ende der letzten periode vor dem geburtstag!
bysort persnr: egen letzter_nicht_mehr2=min(letzter_nicht_mehr) //steht jetzt in jedem feld
drop letzter_nicht_mehr

bysort persnr begepi: egen tentgeltsum=sum(tentgelt)
drop if persnr==persnr[_n-1] & begepi==begepi[_n-1] //parallele perioden werden gedropt, entgelt und EGPT ist in jeweils anderer schon erfasst



drop EGPT EGPTAN tentgelt

by persnr: egen lohn_max=max(tentgeltsum) //maximallohn
by persnr: egen lohn_p85=pctile(tentgeltsum), p(85)
label var lohn_p85 "85. Lohnperzentil"
gen lohn_p85log=log(lohn_p85)
label var lohn_p85log "Log vom 85. Lohnperzentil"

gen PSEGPT=PSEGPT_WEST+PSEGPT_OST
gen BYVLEGPT=BYVLEGPT_WEST+BYVLEGPT_OST

gen diff=BYVLEGPT-EGPTtot
sum diff, detail //es gibt einige Ausreißer
drop diff

sum EGPT* BYVLEGPT PSEGPT


gen periodenlaenge = mofd(endepi)-mofd(begepi)+1
//replace periodenlaenge = 0.5 if periodenlaenge==0

/*letzer spell vor 59 geburtstag wird bis 59 geburtstag verlängert(max 12mon)*/
gen fehllohn_bis59=(gebdat+59*12-mofd(letzter_nicht_mehr2))*EGPTsum/periodenlaenge if gebdat+59*12-mofd(letzter_nicht_mehr2)<12 & letzter_nicht_mehr2==endepi & periodenlaenge>1
bys persnr: egen zusatz59=min(fehllohn_bis59)
recode EGPTtot59 (.=0)
replace EGPTtot59=EGPTtot59+zusatz59 if zusatz59!=.
drop zusatz59 fehllohn_bis59 letzter_nicht_mehr2



//ZAEHLER FÜR VOLLZEITJAHRE UND ARBEITSLOSENJAHRE ETC
gen xalter50=(mofd(begepi)-gebdat<=50*12) //alter<50 bei beginn
gen xalter55=(mofd(begepi)-gebdat<=55*12) //alter<55 bei beginn
gen xaltergr60=(mofd(begepi)-gebdat>60*12) //alter>60 bei beginn
gen xaltergr40=(mofd(begepi)-gebdat>40*12) //alter>40 bei beginn

gen periodenlaenge_z=(endepi-begepi+1)/365 //tagesgenau

gen e=periodenlaenge_z if (zustand==2| zustand==3 | zustand==4 | zustand==5 | zustand==6 |zustand==25) & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_e=sum(e)

drop e

gen e55=periodenlaenge_z if (zustand==2| zustand==3 | zustand==4 | zustand==5 | zustand==6 |zustand==25) & xalter55==1 & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_e55=sum(e55)

drop e55

gen e60=periodenlaenge_z if (zustand==2| zustand==3 | zustand==4 | zustand==5 | zustand==6 |zustand==25) & xaltergr60==0 & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_e60=sum(e60)

drop e60

gen bzeit40=periodenlaenge_z if (zustand==2| zustand==3 | zustand==4 | zustand==5 | zustand==6 | zustand== 7|  zustand==9 |  zustand==10 | zustand==19 |zustand==25) & xaltergr40==1 & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_bzeit40=sum(bzeit40)

drop bzeit40


gen alo=periodenlaenge_z if (zustand== 7|  zustand==9 |  zustand==10) & (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_alo=sum(alo)

drop alo

gen alo55=periodenlaenge_z if (zustand== 7|  zustand==9 |  zustand==10) & xalter55==1
bysort persnr: egen jahre_alo55=sum(alo55)

drop alo55

gen alo5560=periodenlaenge_z if (zustand== 7|  zustand==9 |  zustand==10) & xalter55==0 & xaltergr60==0
bysort persnr: egen jahre_alo5560=sum(alo5560)

drop alo5560


gen schule=periodenlaenge_z if (zustand==1 | zustand==2  )& (quelle_gr==6 |quelle_gr==7 )
bysort persnr: egen jahre_schule=sum(schule)

drop schule

gen krank=periodenlaenge_z if zustand==19 & (quelle_gr==6 |quelle_gr==7 )
by persnr: egen jahre_krank=sum(krank)

drop krank

gen krank50=periodenlaenge_z if zustand==19 & xalter50==1 & (quelle_gr==6 |quelle_gr==7 )
by persnr: egen jahre_krank50=sum(krank50)

drop krank50

gen krank5060=periodenlaenge_z if zustand==19 & xalter50==0 & xaltergr60==0 & (quelle_gr==6 |quelle_gr==7 )
by persnr: egen jahre_krank5060=sum(krank5060)

drop krank5060

gen beitragsz_f15 =(RTZTMO/12>=15) // Jahre BEitragszeiten>15?
gen beitragsz_f35 =(RTZTMO/12>=35) // Jahre BEitragszeiten>35?
gen beitragsz_f10 =(jahre_bzeit40>=10) // Jahre Beitragszeiten>10 nach alter 40?


label var jahre_e "Jahre in Erwerbstaetigkeit"
label var jahre_e55 "Jahre in Erwerbstaetigkeit bis 55"
label var jahre_e60 "Jahre in Erwerbstaetigkeit bis 60"
label var jahre_alo "Jahre in Arbeitslosigk"
label var jahre_alo55 "Jahre in Arbeitslosigk bis 55"
label var jahre_alo5560 "Jahre in Arbeitslk zw 55 u 60"
label var jahre_schule "Jahre in Schule"
label var jahre_krank "Jahre mit Krankheit"
label var jahre_krank50 "Jahre mit Krankheit bis 50"
label var jahre_krank5060 "Jahre mit Krankheit zw 50 und 60"
label var beitragsz_f10 "Beitragsz von 10 Jahren nach Alter40"
label var beitragsz_f15 "Wartezeit von 15 Jahren erfuellt"
label var beitragsz_f35 "Wartezeit von 35 Jahren erfuellt"

drop jahre_krank jahre_alo



keep if mofd(endepi)-gebdat>55*12 // perioden die nach alter 55 enden werden behalten




bysort persnr: gen spells=_n
quietly: sum spells
local mx1 = r(max)
di `mx1'
drop spells


sort persnr spell
by persnr: gen abfolge=_n
keep persnr PSGR RTZTMO abfolge tz stib egpt_* jahre_* erwerbm begepi periodenlaenge beitragsz_f* KIND kreis frau educ kindererz schwebd ber endepi zustand /*rentbeg_m*/ tentgelt EGPT* PSEGPT BYVLEGPT retire_akt lohn_p85 ost ausbil deu
reshape wide begepi tz stib endepi periodenlaenge tentgeltsum educ retire_akt EGPTsum zustand, i(persnr) j(abfolge)



save "$data/2_temp2.dta", replace

/*nun wird der longdatensatz aus "se1_sample.do" zusammengefügt mit dem wideformat um die long-zeilen in schleifen zu füllen*/
use "$data/2_temp1.dta", clear
capture drop _merge
merge m:1 persnr using "$data/2_temp2.dta", keepus(retire_akt* begepi* endepi*)
drop if _merge==2 |_merge==1
drop _merge
gen retire=0


forvalues j = 1/`mx1' {
		replace retire=retire_akt`j' if (zeit>=mofd(begepi`j')) & (zeit<=mofd(endepi`j'))
		
		}
		drop retire_akt* begepi* endepi*
sort persnr zeit		
replace retire=2 if persnr==persnr[_n-1] & (retire[_n-1]==1 | retire[_n-1]==2)/* Variable retire ist 2 wenn Individuum in Vorperiode bereits in Rente*/
drop if retire==2		
		
/*etwa 3% sind im using nicht enthalten, warum?????*/
*drop if zeit>ZTPTRTBE //longpanel ist nun individuell zugeschnitten auf alter 59 bis renteneintritt
*drop if zeit>ZTPTRTBE58 & ZTPTRTBE==.n
*drop ZTPTRTBE*

gen cohort=0 //cohortsepezifizierung
replace cohort=1 if gebjahr>1942
replace cohort=2 if gebjahr>1944
replace cohort=3 if gebjahr>1946


label var cohort "Kohorten"
label define coh 0 "[0]<=42" 1 "[1]<=44" 2 "[2]<=46" 3 "[3]<46"

save "$data/2_temp1a.dta", replace

use "$data/2_temp1a.dta", clear
merge m:1 persnr using "$data/2_temp2.dta"
drop if _merge==2 |_merge==1
drop _merge

save "$data/2_temp3.dta", replace

drop retire_akt*

gen egpt_rel=0
gen tentgelt=0
gen zustand=0
gen besch=0 //beschäftigungszustand
gen alozs=0 //zustand von arbeitslosigkeit
gen educ=0
gen tz=0 //teilzeit
gen stib=0 // stellung im beruf

/*LEGENDE:
egpt_rel= nach zeit gewichtete entgeltpunkte für aktuellen spell
egpt_l12= egpt der letzten 12mon
egpt_dyn= kumulativer egpt bis zur aktuellen periode
*/
bysort persnr: gen perioden=_n
quietly: sum perioden
local mx2 = r(max)

forvalues j = 1/`mx1'{
		replace egpt_rel=(EGPTsum`j'/periodenlaenge`j') if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j'))
		replace tentgelt=tentgeltsum`j' if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j'))
		replace zustand=zustand`j' if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j')) & zustand!=25 //25 soll fjden observiert werden
		replace besch=1 if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j')) & (zustand`j'==2| zustand`j'==3 | zustand`j'==4 | zustand`j'==5 | zustand`j'==6 | zustand`j'==19)
		replace alozs=1 if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j')) & (zustand`j'==7| zustand`j'==9 | (zustand`j'>=10 & zustand`j'<=18))
		replace educ=educ`j' if (alter+gebdat>=mofd(begepi`j'))
		replace tz=tz`j' if (alter+gebdat>=mofd(begepi`j')) & tz!=1
		replace stib = stib`j' if (alter+gebdat>=mofd(begepi`j')) & (alter+gebdat<=mofd(endepi`j')) & stib`j'>=1 & stib`j'<=9 //replace stib if new spell info is senseful, i.e. not missing
		drop periodenlaenge`j' tz`j' stib`j' EGPTsum`j' begepi`j' endepi`j' tentgeltsum`j' zustand`j' educ`j'
		}
		



label var egpt_rel "nach zeit gewichtete entgeltpunkte für aktuellen spell"
sum egpt_rel if egpt_rel>0, detail


/*betriebszugehörigkeit min 2jahre? 5jahre*/

sort persnr zeit
gen bsmon2=0
forvalues j=1/24 {
replace bsmon2=bsmon2+1 if besch[_n-`j']==1 & persnr==persnr[_n-`j']
}
gen tenure2=(bsmon2==24)
drop bsmon2

gen bsmon5=0
forvalues j=1/59 {
replace bsmon5=bsmon5+1 if besch[_n-`j']==1 & persnr==persnr[_n-`j']
}
gen tenure5=(bsmon5==59)
drop bsmon5

gen bsmon=0 //beschäftigungsmonate in den letzten 5 jahren, konsekutiv, von 60 retrospektiv betrachtet.
gen bruch=0
forvalues j=1/59 {
replace bsmon=bsmon+1 if besch[_n-`j']==1 & bruch!=1 & persnr==persnr[_n-`j']
replace bruch=1 if besch[_n-`j']==0
}


/*ABSCHNEIDEN BEI ALTER 59*/
drop if alter<59*12


gen tz60 = tz==1 & alter<=731
bys persnr: egen xtz=sum(tz60)
bys persnr: egen xtz2=sum(tz)
replace tz=0
replace tz=1 if xtz>0
gen tz_ever = xtz2>0
drop xtz xtz2 tz60
 

/*
*gen work= (retire==0)
sort persnr spell
replace retire=2 if persnr==persnr[_n-1] & (retire[_n-1]==1 | retire[_n-1]==2)/* Variable retire ist 2 wenn Individuum in Vorperiode bereits in Rente*/
drop if retire==2 //nur eine letzte Periode soll retire==1 behalten, vgl jenkins 1995 dazu (wichtig für discrete time duration models)

bysort persnr: gen time=_n
*/



/*entgpunkte berechnung noch überarbeiten; dynamik nun gut?*/
gen egpt_dyn=EGPTtot59
label var egpt_dyn "kumulierte egpt bis zur aktuellen periode"
gen egpt_l12=0
forvalues j= 1/`mx2'   {
by persnr: egen xegpt = sum(egpt_rel) if perioden<=`j' //summe der egpt bis periode j
by persnr: egen xegpt12 = sum(egpt_rel) if perioden<=`j' & perioden>=`j'-12 //summe der egpt der letzten 12 perioden (1jahr), damit OHNE AKTUELLEN MONAT s.u.
replace egpt_dyn=EGPTtot59 + xegpt if perioden==`j' & xegpt!=. //kumulativer egpt-zeiger in jener periode
replace egpt_l12=xegpt12-egpt_rel if perioden==`j' & xegpt12!=. //letzte 12mon egpt-zeiger in jener periode AKTUELLER MONAT ABGEZOGEN
/*sum xegpt, meanonly
di r(mean)*/
drop xegpt* // temp summenzeiger gelöscht
}
/*bearbeitungsbereich ende*/


gen alter59=alter-59*12 //alter ab 59 in monaten
gen alter592=alter59^2 //alter ab 59 zum quadrat
gen alter593=alter59^3 //alter ab 59 zum ^3
gen alter594=alter59^4 //alter ab 59 zum ^4
gen alter595=alter59^5 //alter ab 59 zum ^5
gen lnalter59=log(alter59) //alter ab 59 in mon geloggt.

drop perioden

/* //ZU UNGENAU/ ADHOC/ ETC
bys persnr: egen zeitr=max(zeit) if retire==1
bys persnr: egen zeitret=max(zeitr) //alter bei retirement
gen rrz_akt=(RTZTMO-(zeitret-zeit))/12 if zeitret!=. 
replace rrz_akt=(RTZTMO-(575-zeit))/12 if zeitret==. 
replace rrz_akt=rrz_akt+5 if frau==1 //5 jahre bonus ad hoc bei frauen
replace rrz_akt=rrz_akt+3 if frau==0 //5 jahre bonus ad hoc bei männern
drop zeitr zeitret
*/
gen rrz_akt=RTZTMO/12
label var rrz_akt "Jahre rentenrechtl. Zeit dynamisch"




bys persnr: egen maxalter=max(alter)
bys persnr: egen finret=max(retire)
//tab maxalter finret, miss
drop if maxalter>781 & finret==0 //es gibt nämlich überhaupt kaum retirements nach 65!
drop finret

sort persnr zeit

capture drop workgap_bef_ret alo_bef_ret alo_bef_ce atz_bef_ret workf last_mon_a*

*2_help save

gen workgap_bef_ret=0 if retire==1 
gen alo_bef_ret=0 if retire==1
gen alo_bef_cens=0 if (persnr!=persnr[_n+1]) & retire==0
gen atz_bef_ret=0 if retire==1
gen workf=0 if retire==1 //recursively found working spell
forvalues j=1/60 {
replace workgap_bef_ret=workgap_bef_ret+1 if besch[_n-`j']!=1 & workf!=1 & persnr==persnr[_n-`j'] &workgap_bef_ret!=.
replace alo_bef_ret=alo_bef_ret+1 if alozs[_n-`j']==1 & workf!=1 & persnr==persnr[_n-`j'] &alo_bef_ret!=.
replace atz_bef_ret=atz_bef_ret+1 if zustand[_n-`j']==25 & workf!=1 & persnr==persnr[_n-`j'] &atz_bef_ret!=.
replace alo_bef_cens=alo_bef_cens+1 if (alozs[_n-`j']==1 | zustand[_n-`j']==25 | zustand[_n-`j']==0 ) & workf!=1 & persnr==persnr[_n-`j'] &alo_bef_cens!=.
replace workf=1 if besch[_n-`j']==1
}

gen last_mon_alo = 0 if workgap!=.
gen last_mon_atz = 0 if workgap!=.





replace last_mon_alo = 12 if ( alo_bef_ret>0 & alo_bef_ret<=12 )
replace last_mon_alo = 24 if ( alo_bef_ret>12 & alo_bef_ret<=24 )
replace last_mon_alo = 32 if ( alo_bef_ret>24 & alo_bef_ret<=60 )
replace last_mon_atz = 24 if ( atz_bef>0 & atz_bef<=24 )
replace last_mon_atz = 36 if ( atz_bef>24 & atz_bef<=60 )

recode last_mon_alo (0=12) if last_mon_atz==0 & workgap>4 //recode those who were neither unempl nor in atz (~200 cases)
replace last_mon_alo=0 if last_mon_atz==24 & (last_mon_alo>0 & last_mon_alo<=60) //recode those who were both (3 cases)

bys persnr: egen del_alo = max(last_mon_alo)
bys persnr: egen del_atz = max(last_mon_atz)


//altersteilzeit (atz) vor rentenbeginn und nach alter 60?
gen atzlohn=0
forvalues j=1/36 {
replace atzlohn=tentgelt[_n-`j'] if zustand[_n-`j']==25 & persnr==persnr[_n-`j'] &retire==1 & alter>60*12
}
bys persnr: egen atztentgelt=max(atzlohn)


gen retirea = 0 //retirement via alo/atz at that specific period
//um atz/alozeit früher verrenten
replace retirea=1 if persnr==persnr[_n+24] & retire[_n+24]==1 & del_atz==24  //atz vor rente
replace retirea=1 if persnr==persnr[_n+36] & retire[_n+36]==1 & del_atz==36  //
replace retirea=1 if persnr==persnr[_n+12] & retire[_n+12]==1 & del_alo==12  //alo vor rente
replace retirea=1 if persnr==persnr[_n+24] & retire[_n+24]==1 & del_alo==24  //
replace retirea=1 if persnr==persnr[_n+32] & retire[_n+32]==1 & del_alo==32  //


bys persnr: egen del_alo_cens = max(alo_bef_cens)
replace del_alo_cens = 12 if del_alo_cens>0 & del_alo_cens<23 // censored unemployed people are thought to retire after 12months
replace del_alo_cens = 24 if del_alo_cens>=23 & del_alo_cens<60 //censored
replace del_alo=del_alo_cens if (del_alo_cens==12|del_alo_cens==24) //use variable of uncensored cases to also denote here how
															//many month of unemployment benefits will be received, 12 is an assumption

bys persnr: egen del_aloh=	max(del_alo)
replace del_alo=del_aloh
drop del_aloh

//censored individuals

gen ret_cens=0
forvalues j=1/60 {
replace ret_cens = 1 if alo_bef_cens[_n+`j']==`j' & persnr==persnr[_n+`j']
}

gen delete1=0
replace delete1=1 if (retirea[_n-1]==1 | delete1[_n-1]==1) & persnr==persnr[_n-1]
replace delete1=1 if (ret_cens[_n-1]==1 | delete1[_n-1]==1) & persnr==persnr[_n-1]
drop if delete1==1
replace retire=1 if retirea==1
replace retire=1 if ret_cens==1
drop retirea ret_cens

replace del_alo=12 if  retire==0 & alter<781-12 & besch==0 & persnr!=persnr[_n+1]
bys persnr: egen del_aloh=	max(del_alo)
replace del_alo=del_aloh
drop del_aloh
replace retire=1 if  retire==0 & alter<781-12 & besch==0 & persnr!=persnr[_n+1] //40 fälle an grenze 2007m12 die nur einen nicht work monat haben

bys persnr: egen finret=max(retire)


save "$data/2_temp4.dta", replace

/*TOBIT IMPUTATION OF WAGES*/
/*
use "$data/2_temp4.dta", clear




drop if ost==.

gen year_month=(zeit/12) +1960
egen year=cut(year_month) , at(1999(1)2016)

bys year ost: egen tentgelt_mode_year_wo0=mode(tentgelt) if tentgelt!=0
bys year ost: egen tentgelt_mode_year=min(tentgelt_mode_year_wo0)
drop  tentgelt_mode_year_wo0

tab tentgelt_mode_year

gen tentgelt_pred = tentgelt if tentgelt<tentgelt_mode_year
forval y = 1999/2007 {
forval regio = 0/1 {
sum tentgelt_mode_year if year==`y' & ost==`regio', meanonly
local t_mode=r(mean)
tobit tentgelt alter59 alter592 deu jahre_e50 jahre_krank50 EGPTtot59 jahre_schule jahre_alo5060 jahre_alo50 beitragsz_f10 beitragsz_f15 beitragsz_f35 tenure2 tenure5 i.educ if tentgelt>0 & year==`y' & ost==`regio', ul(`t_mode')
predict t_pred, xb
replace tentgelt_pred = t_pred if tentgelt_pred==. & year==`y' & ost==`regio'
drop t_pred
}
}
*/



/*PARETO IMPUTATION OF WAGES*/
use "$data/2_temp4.dta", clear

drop if ost==.
drop if ost==1

gen year_month=(zeit/12) +1960
egen year=cut(year_month) , at(1999(1)2016)

bys year: egen tentgelt_mode_year_wo0=mode(tentgelt) if tentgelt!=0
bys year: egen tentgelt_mode_year=min(tentgelt_mode_year_wo0)
drop  tentgelt_mode_year_wo0


gsort year -tentgelt
gen rank_cont=_n

gen end=0

forval y = 1999/2007 {

egen start=max(rank_cont) if tentgelt==tentgelt_mode_year & year==`y'
egen start2=min(start)

count if year== `y'
gen start3=start2+round(0.01*r(N))
replace end=start3+round(0.15*r(N))

gen estim_sample=1 if rank_cont>=start3 & rank_cont<=end 

sum tentgelt if estim_sample==1
gen tmin=r(min)


count if year == `y' & tentgelt>=tentgelt_mode_year
gen rank = rank_cont - start2 + r(N)
sum rank if estim_sample==1
di r(max)

gen lnrn= log(rank/r(max))
gen lnttmin= log(tentgelt/tmin)

reg lnrn lnttmin if estim_sample==1, robust noconst

gen pareto_k_`y'=-_b[lnttmin]
gen pareto_se_`y'=-_se[lnttmin]
gen pareto_tmin_`y'=tmin

drop rank start start2 start3 estim_sample tmin lnrn lnttmin

}

capture drop tentgelt_pred
gen tentgelt_pred = tentgelt if tentgelt+4<tentgelt_mode_year
gen impu_flag=(tentgelt_pred==.)

forval y = 1999/2007 {
forval w = 1/10 {  //multiple rounds of imputation; only accept values above annual social security contribution threshold (tentgelt_mode_year)
di `w'
*count if tentgelt_pred==.
gen pareto_rand=((runiform()^(1/pareto_k_`y'))/(pareto_tmin_`y'))^(-1)
replace tentgelt_pred = pareto_rand if tentgelt_pred==. & year==`y' & (pareto_rand+4>=tentgelt_mode_year | `w'==10)
drop pareto_rand
}
}

hist tentgelt_pred if tentgelt_pred<500 & year==2003
graph export "$log\tentgelt2003pred.png", as(png) replace
hist tentgelt if tentgelt<500 & year==2003
graph export "$log\tentgelt2003orig.png", as(png) replace


*hist tentgelt_pred if tentgelt_pred<300



save "$data/2_temp5.dta", replace
log close
