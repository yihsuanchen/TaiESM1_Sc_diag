#!/bin/sh

iStrt=20150611
iLast=20150611
vnm=f05.F-hist.tn15.tAmip.k01


#for ((date=$iStrt; date<=$iLast; date=`date +"%Y%m%d" -d"$date 12:00 +1 day"`)) ; do
for date in 20150609 ; do

  yr=`echo $date | cut -c 1-4` 
  mo=`echo $date | cut -c 5-6` 
  dy=`echo $date | cut -c 7-8` 

  idate=${yr}-${mo}-${dy}

  ### replace the date ## 
  echo "Simulation date = ${idate}"
  ./xmlchange -file env_run.xml -id RUN_REFDATE -val $idate 
  ./xmlchange -file env_run.xml -id RUN_STARTDATE -val $idate 
  sed -i "s/ncdata =.*/ncdata = \"\/work\/j07hsu00\/hind_inputdata\/ERA5\/ERA5_${idate}_initial.nc\"/g" user_nl_cam

  ./${vnm}.submit 
# sleep 40m 
done
