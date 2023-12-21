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

#--- input files. You can download the data from ERA5 website and rename them.  
filenames=("ERA5_PRS.t_q_u_v.200107_00Z.r1440x721.nc" "ERA5_SFC.sp.200107_00Z.r1440x721.nc")

#--- output files
#    the file name would be ${newfilehead}"${yyyy}_${mm}_${dd}_${hh}"${newfileend}
newfilehead=("ERA5_PRS.t_q_u_v.r1440x721." "ERA5_SFC.sp.r1440x721.")
newfileend=(".nc")

#--- time in the file
yyyy=2001
mm=07
hh="00Z"
dd_start=1
dd_end=31

##################
# program start
##################

num_files=$((${#filenames[@]}))

for((j=0; j<$num_files; j=j+1))
do
  fname=${filenames[$j]}
  new_head=${newfilehead[$j]}

  for ((i=${dd_start}; i<=${dd_end}; i=i+1))
  do
    dd=$(printf "%02d" $i)
    ss="${yyyy}_${mm}_${dd}_${hh}"
    file1=${new_head}${ss}${newfileend}

    #echo $fname, $file1
    comd="ncks -F -d time,$i $fname $file1"
    $comd && echo "Done. create [$file1]" || exit 1
  done  # loop of dd

done    # loop of files

exit 0

