cap log close
log using tab6_external.log, replace

use ${scratch}/czeffects, clear

su logwage cz_effects_m? [aw=wcount]

keep logwage cz_effects_m? wcount
outreg2 logwage cz_effects_m? using ${results}/tab6_external.txt [aw=wcount], sum(log) replace	