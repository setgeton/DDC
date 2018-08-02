capture log close
capture log using "${LOG_DIR}se3u_utility.log", replace



capture drop y
capture drop U*
capture drop ueberleb


quietly{
	gen y=retire
	
*local beta=0.8	
local lambda =2 //Freizeitgewichtungsfaktor
local delta  =0.97 //Diskontfaktor (0.8 statt 0.97 aus Gesundheitsgründen?!)
local rho = 0.9 //überlebewahrscheinlichkeit
local gamma = 0.6 //Curvature der Nutzenfunktion
local eta = 1 //monetarisierte freizeit
*if `gamma'>1 local gamma = 1
*if `gamma'<0.1 local gamma = 0.1
*if `beta'<=0 local beta = 0
*if `lambda'>=3 local lambda = 3

local z = 30 //zeithorizont


forvalues k=0/5 {
	gen  double U`k'=0
	gen ueberleb=1
	forvalues j=0/`z' { //Renteneintritt jetzt oder in k Jahren
		replace ueberleb=`rho'^(alter/12-75+`j') if  `rho'^(alter/12-75+`j')<=1 & `rho'^(alter/12-75+`j')>0
		replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
		replace U`k'=U`k'+weiterpr^(`j')*`delta'^(`j')*ueberleb*(lohn_exp*30*1.01^`j')^(`gamma') ///
							 +(1-weiterpr^(`j'))*`delta'^(`j')*ueberleb*(alosatz)^(`gamma') if `j'<`k' & alter+`j'*12<65*12 //nutzen aus arbeitseink/alo
		replace U`k'=U`k'+`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) if `j'>=`k' //nutzen aus rente if nicht alorente
		replace U`k'=U`k'-			   `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) +				 `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'==1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
		replace U`k'=U`k'-alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente`k'_exp+`eta')^(`gamma')) + alo_rente`k'*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==`k' & alo_rente`k'>0 & alo_rente`k'<1 //nutzen aus rente if alorente //eventuell nicht falls alter+k=720?
	}
	capture drop ueberleb
}

*replace ueberleb=1

	local mon "1 2 3 4 5 6 7 8 9 10 11 12"
    foreach k of local mon {
	gen  double U_`k'=0
	gen ueberleb=1
	forvalues j=1/12 { //Renteneintritt jetzt oder in j Monaten
		replace ueberleb=`rho'^((alter/12-75)+`j'/12) if  `rho'^(alter/12-75+`j'/12)<=1 & `rho'^(alter/12-75+`j'/12)>0 /*0.98655^((alter-60*12)+`j')<1 & 0.98655^((alter-60*12)+`j')>0*/
		replace U_`k'=U_`k'+(1/12)*weiterpr^(`j'/12)*`delta'^(`j'/12)*ueberleb*(lohn_exp*30*1.01^(`j'/12))^`gamma' ///
							+(1/12)*(1-weiterpr^(`j'/12))*`delta'^(`j'/12)*ueberleb*(alosatz)^`gamma' if `j'<`k' & alter+`j'<65*12 //nutzen aus arbeitseink
		replace U_`k'=U_`k'+(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) if `j'>=`k' //nutzen aus rente if not alorente
		replace U_`k'=U_`k'-(1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) + (1/12)*`lambda'*`delta'^(`j'/12)*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'>=`k' & ( (`j'-`k')/12<alo_rente_`k' |alo_rente_`k'==1) //nutzen aus ersten 12-k mon rente if alorente
	}
	capture drop ueberleb
	gen ueberleb=1
	forvalues j=1/`z' { //angefügt wird der nutzen der entsteht für alle weiteren rentenjahre; macht berechnung schneller
	replace ueberleb=`rho'^(alter/12-75+`j') if  `rho'^(alter/12-75+`j')<1 & `rho'^(alter/12-75+`j')>0
	replace ueberleb=0 if ueberleb<0 | alter/12+`j'>100
	replace U_`k'=U_`k'+         `lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) //nutzen aus rente if not alo rente
	replace U_`k'=U_`k'-(alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(rente_`k'_exp+`eta')^(`gamma')) + (alo_rente_`k'-(12-`k')/12)*`lambda'*`delta'^(`j')*ueberleb*(/*2+*/(alosatz)^(`gamma')) if `j'==1 & (alo_rente_`k'==1 |alo_rente_`k'-(12-`k')/12>0)  //nutzen aus k mon rente die auf die ersten (12-k) mon folgen if alorente
	}
	capture drop ueberleb
}


gen double U_future=max(U1,U2,U3,U4,U5/*,U_1,U_2,U_3,U_4,U_5,U_6,U_7,U_8,U_9,U_10,U_11,U_12*/)
gen double U_diff=(U0-U_future)/1000
}
*gen U_diffdiff=U_diff-U_diff2
*sum U_diffd, de
*bys alter781: sum U_diff	
logit retire U_diff krank05 gebdummy firstday alter59 ant_ue55_jun2007 l12_alo lohn_p85 deu alo_kr i.ausbil i.bula a65
logit retire U_diff krank05 gebdummy firstday alter59 ant_ue55_jun2007 l12_alo lohn_p85 deu alo_kr i.ausbil /*i.bula*/ a65

*logit retire U_diff krank05 gebdummy firstday
*logit retire U_diff SSW krank05 gebdummy firstday alter59 ant_ue55_jun2007 tenure2 l12_alo lohn_p85 deu alo_kr i.ausbil i.bula a65


capture log close
