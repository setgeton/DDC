capture log close
capture log using "$log/se1_sample.log", replace

/* BASID SE1_SAMPLE.DO
STEFAN ETGETON; DIW BERLIN
ZUSCHNITT DES SAMPLES, GENERIERUNG VON ZEIT- UND ALTERSVARIABLEN
PROJEKT 619*/



use "$data/2_small_fix.dta", clear
keep persnr KTSD PSGR


//variable Merkmale an den fixen Teil anmergen
merge 1:m persnr using "$data/2_small_var.dta", keepus (gebdat endepi  VSGR )
drop if _merge==2


keep if gebdat<-144 //geboren VOR jan1947
keep if VSGR==1 | VSGR==2 | VSGR==0 //nur Arbeiter und Angestelltenversicherung - nicht knappschaftliche/Handwerker
bysort persnr: egen versart =sum(VSGR) if  VSGR==1 | VSGR==2
bysort persnr: egen versart2= min(versart)
keep if versart2>0 & versart2<.

keep if PSGR==99 /*kein Rentenbezug*/ | PSGR==16 | PSGR==17 | PSGR==18 | PSGR==31 | PSGR==62 | PSGR==63

drop VSGR KTSD versart2 versart PSGR



bysort persnr: egen ende = max(endepi) //ende der aufzeichnungen bestimmen
bysort persnr: gen num = _n
keep if num==1 //nur eine beobachtung behalten, wird nachher expanded!

replace ende = mofd(ende) //in monate umrechnen
replace ende = 611 if ende>611 //auf dez 2010 beschränken //575==dec2007
sum ende gebdat
format ende %tm

gen laenge = ende-(gebdat+12*50) //gesamtlänge bestimmen ab alter 50 fürs expanden
sum laenge
drop if laenge<=0 //nur beobachtungen(personen) die über 50 hinausreichen
expand laenge, gen(duplicate)
bysort persnr: gen alter=50*12+_n //alter in monaten
bysort persnr: gen zeit=gebdat+alter //zeitangabe monatsgenau
format zeit %tm

label var zeit "zeitpunkt in monaten"

//Geburtsdatum umkodieren
/*
gen begyear=year(begepi)
gen begmon=month(begepi)
gen begday=day(begepi)
gen endyear=year(endepi)
gen endmon=month(endepi)
gen endday=day(endepi)*/
gen gdat=dofm(gebdat)
format gdat %d
gen gebjahr=year(gdat)
gen gebmon=month(gdat)

tab gebmon

*gen alterl = begyear*12 + begmon - gebjahr*12 - gebmon //alter bei spellbeginn in monaten


keep persnr endepi gebdat gebmon gebjahr alter zeit

save "$data/2_temp1.dta", replace

log close
