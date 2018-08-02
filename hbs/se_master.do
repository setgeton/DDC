*****************************************	
*	BASID MASTER DO						*
*	STEFAN ETGETON; DIW BERLIN			*
*	PROJEKT 619							*
*	setgeton@diw.de						*
*	Datum: 24,09,2015					*
*****************************************

clear
set more off, permanently
set linesize 120

/*"global IN_DIR "H:\orig\"
"global DO_DIR "H:\prog\"
"global OUT_DIR "H:\data\"
"global TEMP_DIR "H:\data\"
"global MATLAB_DIR "H:\matlab\"
"global LOG_DIR "H:\log\"
*/
*set max_memory .



*do "$prog/se0_small.do" 			//optional: stichprobenumfang reduzieren
*do "$prog/se1_sample.do"			//sample zuschneiden
*quietly{
*do "$prog/se2_format.do"			//format und hilfsvariablen
*do "$prog/se3_rente.do"			//rente und andere groessen berechnen
*}
*do "$prog/se5_export.do"			//export zu matlab vorbereiten und letzte umcodierungen und summary statistics

cd $prog
shell "C:\Program Files\MATLAB\R2013b\bin\win64\MATLAB.exe" -nosplash -r "master"

