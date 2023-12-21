#!/bin/csh -f
# CESM code directory ###
setenv CCSMROOT /home/j07hsu00/taiesm/TaiESM_1

# Cases directory ###
setenv MYRUNS $PWD

# Case name ###
setenv CASE $MYRUNS/f09.B2000.taiesm1-test1

# create newcase ###
cd $CCSMROOT/scripts

 ./create_newcase -case ${CASE} -mach twnia3 -compset B_2000 -res f09_g16
#./create_newcase -case ${CASE} -mach twnia3 -compset F_1850-2000 -res f09_f09 
