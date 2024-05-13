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
#CASENAME="xx01-taiesm1.F_2000_TAI.f09_f09.1226_1050"
#CASENAME="hindcast02_2001July-taiesm1.F_2000_TAI.f09_f09"
CASENAME="hindcast03-taiesm1.F_2000_TAI.f09_f09"
#CASENAME="y1-hindcast_2001July-taiesm1.F_2000_TAI.f09_f09.0327_2045"
CASE="$WRKDIR/$CASENAME"

#--- initial condition data for each hindcase run
icdata_option="ERA5"
#icdata_optio_option="JMA3Q"

icdata_path="/work/yihsuan123/data/data.TaiESM1_hindcast/data.July2001_${icdata_option}.hindcast/"
icdata_filehead="cami-snap_0000-01-01_0.9x1.25_L30.${icdata_option}_ic."
icdata_fileend=".nc"
start_date=20010701
#end_date=20010711
end_date=$start_date
hh="00Z"

#--- stop options
STOP_OPTION="ndays"
#STOP_N=6
STOP_N=1

#--- pause for 1 second in case you want to stop the script (set do_pause=F to skip)
do_pause="T"
#do_pause="F"

#--- hold if there is any unfinished job.
do_hold="T"
#do_hold="F"

hold_seconds=$((60 * 1))   # seconds   
#hold_seconds=$((1 * 1))   # seconds   

counts_max=20  # maximum times of counts for hold_seconds

#--- whether back up this script
do_backup_script="T"  
#do_backup_script="F"  

#--- sleep for a few minutes before submitting another job
do_sleep="F"
sleep_seconds=$((60 * 2))   # # seconds   

###################
# program start
###################

#--- back up this script
if [ $do_backup_script == "T" ]; then
  date_now=`date +%Y%m%d_%H%M`
  this_script="`pwd`/$0"
  #script_backup="$CASE/zz-run_hindcast.${CASENAME}.sh.${date_now}"
  script_backup="$CASE/zz-run_TaiESM1_02-hindcast.${CASENAME}.sh.${date_now}"
  cp $this_script $script_backup && echo "Done. back up this script [$script_backup]" || exit 1
fi

#--- check start_date and end_date
if [ "$start_date" -gt "$end_date" ]; then
  echo "ERROR: start_date [$start_date] is greater than end_date [$end_date]. Please edit this script to fix it."
  exit 1
fi

#--- loop for dates
current_date="$start_date"

while [ "$current_date" -le "$end_date" ]; do

  cd $CASE || exit 1  ## move to the CASE directory

  echo "Hindcast simulation start date: [$current_date]"
  echo "                    ic data   : [$icdata]"

  #--- check whether previous job is still in queue
  job_in_queue=0
  counts="0"
  if [ $do_hold == "T" ]; then
    while [ $job_in_queue -ne 1 ] && [ $counts -le $counts_max ]; do
      job_in_queue=`squeue -u $USER | grep "PD" >> /dev/null ; echo $?`

      if [ $job_in_queue -eq 0 ]; then  #  previous job is still in queue
        echo "WARNING: previous job is still in queue. Hold [$hold_seconds] seconds..."
        sleep $hold_seconds
      fi

      counts=$((counts+1))
      echo "Counts: [$counts]"
    done
  fi

  if [ $counts -ge $counts_max ]; then
    echo "STOP: Previous jobs are in queue. Date [$current_date] has not been submitted."
    exit 0
  fi

  #--- set the initial condition file
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
#         Customize CAM output: https://ncar.github.io/CESM-Tutorial/notebooks/namelist/output/output_cam.html
#         CESM1 output fields: https://www2.cesm.ucar.edu/models/cesm1.0/cam/docs/ug5_0/hist_flds_fv_cam4.html, search "Master Field List"
#         CESM2 output fields: https://www2.cesm.ucar.edu/models/cesm2/atmosphere/docs/ug6/hist_flds_f2000.html
  cat > ./user_nl_cam << EOF
&cam_inparm
nhtfrq = -1, -3, -3, -3
mfilt  = 24, 8, 8, 8
ncdata = '${file1}'
hfilename_spec = "%c.${icdata_option}_icdate_${current_date}.cam.h%t_2d_1h.%y-%m-%d-%s.nc", "%c.${icdata_option}_icdate_${current_date}.cam.h%t_state_3h.%y-%m-%d-%s.nc","%c.${icdata_option}_icdate_${current_date}.cam.h%t_Ttend_3h.%y-%m-%d-%s.nc", "%c.${icdata_option}_icdate_${current_date}.cam.h%t_Qtend_3h.%y-%m-%d-%s.nc"
empty_htapes = .true. 

fincl1 = "CLDHGH:A","CLDLOW:A","CLDMED:A","CLDTOT:A","FLDS:A","FLNS:A","FLNSC:A","FLUT:A","FLUTC:A","FSDS:A","FSDSC:A","FSNS:A","FSNSC:A","FSNTOA:A","FSNTOAC:A","FSUTOA:A","LHFLX:A","LWCF:A","PBLH:A","PRECC:A","PRECL:A","PS:A","QREFHT:A","SHFLX:A","SOLIN:A","SWCF:A","TREFHT:A","TS:A","U10:A","Z3:A","TGCLDIWP:A","TGCLDLWP:A","CONCLD:A","TMQ:A","AST:A","SST:A"

fincl2 = "CLDICE:A", "CLDLIQ:A", "CLOUD:A", "OMEGA:A","PS:A", "Q:A", "T:A", "U:A", "V:A", "Z3:A", "RELHUM:A"

fincl3 = "TTEND_TOT:A","DTCORE:A","PTTEND:A","ZMDT:A","EVAPTZM:A","FZSNTZM:A","EVSNTZM:A","ZMMTT:A","CMFDT:A","DPDLFT:A","SHDLFT:A", "MACPDT:A","MPDT:A","QRL:A","QRS:A","DTV:A","TTGWORO:A"

fincl4 = "PTEQ:A","ZMDQ:A","EVAPQZM:A","CMFDQ:A","MACPDQ:A","MPDQ:A","VD01:A", "PTECLDLIQ:A","ZMDLIQ:A","CMFDLIQ:A","DPDLFLIQ:A","SHDLFLIQ:A","MACPDLIQ:A","MPDLIQ:A","VDCLDLIQ:A","PTECLDICE:A","ZMDICE:A","CMFDICE:A","DPDLFICE:A","SHDLFICE:A","MACPDICE:A","MPDICE:A","VDCLDICE:A","QVTEND_TOT:A","QLTEND_TOT:A","QITEND_TOT:A","DQVCORE:A","DQLCORE:A","DQICORE:A"
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
  if [ $do_sleep == "T" ]; then
    echo "sleep [$sleep_seconds] seconds in case the previos job uses the setup of the following job..."  
    sleep $sleep_seconds
  fi

done  # end loop of current_date


