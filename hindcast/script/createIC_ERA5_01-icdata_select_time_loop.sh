#!/bin/bash 
#===================================
#  Bourne-Again shell script
#
#  Description:
#    select each time step in the files and write it into a new file
#
#  Usage:
#    Edit "user setting" and execute this script
#    > ./THIS_SCRIPT
#
#  History:
#    December 2023
#
#  Author:
#    Yi-Hsuan Chen
#    yihsuan@umich.edu
#===================================

###################
# user setting
###################

#--- time in the file
yyyy=2001
mm=06
hh="00Z"
dd_start=1
dd_end=30

#--- data path
datapath="/lfs/home/yihsuanc/data/data.TaiESM1_hindcast/data.July2001_ERA5.hindcast"  # on RCEC 300T

#--- input files contain one-month data. You can download the data from ERA5 website and rename them.  
filenames=("ERA5_PRS.t_q_u_v.${yyyy}${mm}_${hh}.r1440x721.nc" "ERA5_SFC.sp.${yyyy}${mm}_${hh}.r1440x721.nc")

#--- output files
#    the file name would be ${newfilehead}"${yyyy}_${mm}_${dd}_${hh}"${newfileend}
newfilehead=("ERA5_PRS.t_q_u_v.r1440x721." "ERA5_SFC.sp.r1440x721.")
newfileend=(".nc")


##################
# program start
##################

num_files=$((${#filenames[@]}))

for((j=0; j<$num_files; j=j+1))
do
  fname=${datapath}/${filenames[$j]}
  new_head=${newfilehead[$j]}

  for ((i=${dd_start}; i<=${dd_end}; i=i+1))
  do
    dd=$(printf "%02d" $i)
    ss="${yyyy}_${mm}_${dd}_${hh}"
    file1=${datapath}/${new_head}${ss}${newfileend}

    #echo $fname, $file1
    comd="ncks -F -d time,$i $fname $file1"
    $comd && echo "Done. create [$file1]" || exit 1
  done  # loop of dd

done    # loop of files

exit 0

