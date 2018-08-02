capture log close
capture log using "${LOG_DIR}4a_deskriptiv.log", replace

set more off

use "${TEMP_DIR}2_temp5_97_25_94-zf01.dta", clear
///////////**DESKRIPTIVE STATISTIK**///////////////////

/*frauen*/

descr
sum if frau==1
sum if ost==0 & frau ==1


/*männer*/
use "${TEMP_DIR}2_temp5_97_25_94-zf01.dta", clear

descr
sum if frau==0
sum if ost==0 & frau==0

capture log close
