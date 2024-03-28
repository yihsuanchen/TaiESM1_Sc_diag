#!/bin/bash 
#===================================
#  Bourne-Again shell script
#
#  Description:
#    Run TaiESM1 simulation on Taiwania 3
#
#  Usage:
#    Edit the "user setting" section, and then execute this script
#    > ./THIS_SCRIPT
#
#    The case folder will be at $CASE
#    The output will be at /work/$USER/taiesm_work/{CASENAME}
#
#  Author:
#    Yi-Hsuan Chen
#    yihsuanc@gate.sinica.edu.tw
#===================================

###################
# user setting
###################

#set -x  # echo all commands

# temp variable
temp=`date +%m%d_%H%M`
yyyymmdd=`date  +%Y_%m_%d`

#--- TaiESM source code folder
CCSMROOT="/work/yihsuan123/taiesm_ver170803/"

#--- simulation setup
compset="F_2000_TAI"
res="f09_f09"

STOP_OPTION="ndays"
STOP_N=1

#--- simulation case
WRKDIR="/work/yihsuan123/taiesm1_test_hindcast/"
#CASENAME="xx01-taiesm1.${compset}.${res}.${temp}"
#CASENAME="y1-hindcast_2001July-taiesm1.${compset}.${res}.${temp}"
CASENAME="hindcast02_2001July-taiesm1.${compset}.${res}"
CASE="$WRKDIR/$CASENAME"

#--- slurm setup
do_submit="F"        # "T": submit the job

account="MST112228"  # account name on Taiwania 3
queue="ct224"        # name of queue on Taiwania 3. Use "sinfo -s" to view the available queue
num_cpu=128          # number of cpu

#--- source code change
do_srcmod="T"
srcmod_dir="/home/yihsuan123/research/TaiESM1_Sc_diag/scam_taiesm1/script/scam_mods"

##################
# program start
##################

#--- get this script name
this_script="`pwd`/$0"
script_backup="$CASE/zz-run.${CASENAME}.sh"

#--- check whether $srcmod_dir exist
if [ $do_srcmod == "T" ]; then
  if [ ! -d $srcmod_dir ]; then
    echo "ERROR: srcmod_dir [$srcmod_dir] does not exist. STOP"
    exit 1
  fi
fi

#------------
# Build the model
#  ./create_newcase
#  ./cesm_setup
#  ./${casename}.build
#------------

cd $CCSMROOT/scripts  || exit 1

#--- create_newcase
./create_newcase -case ${CASE} -mach twnia3 -compset ${compset} -res ${res} || exit 1

cd $CASE || exit 1

#--- user settings

# Set computational geometry: number of processors to allocate to each model
./xmlchange -file env_mach_pes.xml -id NTASKS_ATM -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_LND -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_ICE -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_OCN -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_CPL -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_ROF -val $num_cpu || exit 300
./xmlchange -file env_mach_pes.xml -id NTASKS_GLC -val $num_cpu || exit 300

./xmlchange -file env_run.xml -id STOP_OPTION -val ${STOP_OPTION} || exit 300
./xmlchange -file env_run.xml -id STOP_N -val ${STOP_N}           || exit 300

cat > ./user_nl_cam << EOF
&cam_inparm
nhtfrq = 24 
mfilt  = 12
/
EOF

#--- source code change
if [ $do_srcmod == "T" ]; then
  cp $srcmod_dir/* ./SourceMods/src.cam && echo "Done. copy codes from [$srcmod_dir] to [./SourceMods/src.cam]" || exit 301
fi

#--- cesm_setup
./cesm_setup  || exit 1
 
#--- build the model
./$CASENAME.build || exit 1

#--- modify the slurm setup
sed -i "s/#SBATCH -p.*/#SBATCH -p ${queue}/g" $CASENAME.run && echo "Done. queue is [${queue}]" || exit 305

sed -i "s/#SBATCH --account.*/#SBATCH --account ${account}/g" $CASENAME.run && echo "Done. account is [${account}]" || exit 305

#--- submit the run
if [ $do_submit == "T" ]; then
  ./$CASENAME.submit || exit 1
else
  echo "Please submit the job manually at [$CASE]"
  echo "For hindcast simulations, please submit the runs using run_TaiESM1_02-hindcast.sh"
fi

#--- back up this script
cp $this_script $script_backup && echo "Done. backup of the script [${script_backup}]" || exit 1

exit 0

