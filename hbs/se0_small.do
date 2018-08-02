capture log using "$log/se0_small.log", replace

/* BASID SAMPLE.DO
STEFAN ETGETON; DIW BERLIN
PROJEKT 619*/

///////////////////FÜR TESTZWECKE KLEINERE STICHPROBE///////////////


use "$orig/basid_5109_v1_fix.dta", clear
drop if KTSD == 0000 | KTSD==9999 | KTSD==.n //nicht kontogeklärte Fälle raus
bysort persnr: gen subs = runiform()
//drop if subs>0.5 //only use subsample

save "$data/2_small_fix.dta", replace

keep persnr subs

//variable Merkmale an den fixen Teil anmergen
merge 1:m persnr using "$orig/basid_5109_v1_var.dta"
drop if _merge==2
drop _merge

drop if frau==1  //wer soll untersucht werden? drop frau==1 bedeutet weibl raus


save "$data/2_small_var.dta", replace

log close
