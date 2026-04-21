*read 5 year acs hh file (5 files);
*create simplified extract;
        
options ls=200 nocenter nofmterr;
libname here '../../tmp';

data h1;
set here.psam_husa
    here.psam_husb
    here.psam_husc
    here.psam_husd;

keep serialno puma st adjinc wgtp np type access bath bdsp rmsp rwat kit sink stov ten bld plm fs
            elefp fulfp gasfp watfp mrgt mrgp mrgi mrgp smp mrgx taxamt
            rntm rntp grntp valp ybl fes fincp hhl hht hincp grpip
            multg mv npf partner psf wif ;

*rwat=hot+cold running water;


if type='1';  /*drop group quarters*/


data h2;
set h1;
         
y=substr(serialno,1,4);
year=0;
year=y;
drop y;

        
     
length state numunits 3;
state=0;
state=st;
drop st;
         
numunits=0;
numunits=bld;
drop bld;



rename rntp=rent
       grntp=grossrent 
      valp =propertyvalue
      fincp=finc
      hincp=hinc
      bdsp=num_bedrooms
      rmsp=num_rooms

      mrgx=has_mortgage
      mrgp=mortgage 
      smp=smortgage
      taxamt=taxes

  ;

kitchen=(kit='1');
plumbing=(plm='1');

tax_inmortgage=(mrgt='1');
ins_inmortgage=(mrgi='1');

electric_inrent=(elefp='1');
gas_inrent=(gasfp='1');
water_inrent=(watfp='1');
fuel_inrent=(fulfp='1');
meals_inrent=(rntm='1');


drop kit plm mrgt mrgi elefp gasfp watfp fulfp rntm;


data here.household;
set h2;



posrent=(rent>0);
posmortgage=(mortgage>0);
possecond=(smortgage>0);
postaxes=(taxes>0);
posvalue=(propertyvalue>0);


proc means;

proc univariate;
where (posvalue=1);
var propertyvalue;

proc univariate;
where (posrent=1);
var rent;


proc corr;
where (posvalue=1);
var propertyvalue taxes;

