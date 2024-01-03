#!/bin/bash 
#===================================
#  Bourne-Again shell script
#
#  Description:
#    Run TaiESM1 hindcast simulation on Taiwania 3
#
#  Usage:
#    First, make sure a TaiESM case is already built.
#
#    Edit the "user setting" section & user_nl_cam, and then execute this script
#    > ./THIS_SCRIPT
#
#    The case folder will be at $CASE
#    The output & log files will be at /work/$USER/taiesm_work/{CASENAME}
#
#  Author:
#    Yi-Hsuan Chen
#    yihsuanc@gate.sinica.edu.tw
#===================================

###################
# user setting
###################

#--- existing TaiESM1 case
WRKDIR="/work/yihsuan123/taiesm1_test_hindcast/"
CASENAME="xx01-taiesm1.F_2000_TAI.f09_f09.1226_1050"
CASE="$WRKDIR/$CASENAME"

#--- initial condition data for each hindcase run
icdata_path="/work/yihsuan123/data/data.TaiESM1_hindcast/data.July2001_ERA5.hindcast/"
icdata_filehead="cami-snap_0000-01-01_0.9x1.25_L30.ERA5_ic."
icdata_fileend=".nc"
start_date=20010701
end_date=20010703
hh="00Z"

#--- stop options
STOP_OPTION="ndays"
STOP_N=2

#--- pause for 1 second in case you want to stop the script (set do_pause=F to skip)
do_pause="T"
#do_pause="F"

###################
# program start
###################

#set -x

cd $CASE || exit 1

#--- check start_date and end_date
if [ "$start_date" -gt "$end_date" ]; then
  echo "ERROR: start_date [$start_date] is greater than end_date [$end_date]. Please edit this script to fix it."
  exit 1
fi

#--- loop for dates
current_date="$start_date"

while [ "$current_date" -le "$end_date" ]; do

  yr=`echo $current_date | cut -c 1-4` 
  mo=`echo $current_date | cut -c 5-6` 
  dy=`echo $current_date | cut -c 7-8` 

  idate=${yr}-${mo}-${dy}
  file_date=${yr}_${mo}_${dy}_${hh}
  file1=${icdata_path}/${icdata_filehead}${file_date}${icdata_fileend}
  if [ ! -f $file1 ]; then
    echo "ERROR: file [$file1] does not exist"
    exit 1
  fi

  ### replace the date ## 
  echo "Simulation date = ${idate}"
  ./xmlchange -file env_run.xml -id RUN_REFDATE   -val $idate         || exit 300
  ./xmlchange -file env_run.xml -id RUN_STARTDATE -val $idate         || exit 300
  ./xmlchange -file env_run.xml -id STOP_OPTION   -val ${STOP_OPTION} || exit 300
  ./xmlchange -file env_run.xml -id STOP_N        -val ${STOP_N}      || exit 300

  #sed -i "s|ncdata =.*|ncdata = $file1|g" user_nl_cam  || exit 1

#--- cam namelist
#    ref: CAM namelist variables: https://www2.cesm.ucar.edu/models/cesm1.2/cesm/doc/modelnl/nl_cam.html
#         CESM Tutorial: https://ncar.github.io/CESM-Tutorial/README.html#
  cat > ./user_nl_cam << EOF
&cam_inparm
nhtfrq = -1
mfilt  = 24
ncdata = '${file1}'
empty_htapes = .true. 
fincl1 = "CLDHGH:A","CLDICE:A","CLDLIQ:A","CLDLOW:A","CLDMED:A","CLDTOT:A","CLOUD:A","FLDS:A","FLNS:A","FLNSC:A","PBLH:A"
hfilename_spec = "%c.icdate_${current_date}.cam.h%t.%y-%m-%d-%s.nc"
/
EOF

  #--- do_pause
  if [ $do_pause == "T" ]; then
    echo "pause for 1 second in case you want to stop the script (set do_pause=F to skip)" 
    sleep 1   # pause for 
  fi
  
  #--- submit the job
  ./${CASENAME}.submit || exit 1
  current_date=$(date -d "$current_date + 1 day" +%Y%m%d)
  echo ""

  #--- yhc note: It seems like if one job is still in queue but another job is submitted. The previous job will use the setup of the following job.
  #              To avoid this situation, make this script sleep for 2 mins.
  echo "sleep 2 mins in case the previos job uses the setup of the following job..."  
  sleep 120

done  # end loop of current_date


