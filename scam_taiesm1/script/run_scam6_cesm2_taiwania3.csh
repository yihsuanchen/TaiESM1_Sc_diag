#!/bin/csh -f

#===================================
#  Description:
#    Running single-column model (SCAM6) CESM2.3 on Taiwania 3
#
#  Author:
#    Yi-Hsuan Chen (yihsuanc@gate.sinica.edu.tw)
#
#  Usage:
#    1. Make sure SBATCH setting are correct.
#    2. Modify the variables in "setup for the SCAM run" section, such as the IOP case, model physics, etc.
#    3. Run the script 
#       > sbatch THIS_SCRIPT
#    4. Check the results
#
#  References
#    - Single Column Atmospheric Model (SCAM) Overview, https://www.cesm.ucar.edu/models/simple/scam
#    - Example: run SCAM, https://ncar.github.io/CAM/doc/build/html/users_guide/atmospheric-configurations.html#cam-single-column-fscam-compset
#
#  Date:
#    December 2023
#===================================

# echoing each command
set echo

# -------------------------------------------------------------------------
#  set environment variables on Taiwania 3
# -------------------------------------------------------------------------

set USER = yihsuan123

set CIME_SCRIPT  = /work/j07hsu00/cesm2_work/code/cesm23/cime/scripts  #  yhc note 2023-12-08: Hsin-Chien Liang made some changes in cesm23/cime_config.
                                                                       #  In SCAM, it forced using mpi-serial in cime_config/??, but create_case uses openmpi.
                                                                       #  As a result, ./case.build will fail with this error message:
                                                                       #  "Makefile:193: *** NETCDF not found: Define NETCDF_PATH or NETCDF_C_PATH and NETCDF_FORTRAN_PATH in config_machines.xml or config_compilers.xml.  Stop.

#--- parameters using in create_newcase. Modify it if needed
set newcase_params = "--machine nchc3 --compiler intel --mpilib openmpi --compset FSCAM --res T42_T42 --queue ctest --project MST112228"

# -------------------------------------------------------------------------
# setup for the SCAM run
# -------------------------------------------------------------------------

# temporary variable
set temp=`date +%m%d%H%M%S`

#--- set case
set exp_name = "ee01-scam6_test".${temp}

set CASE = /work/${USER}/${exp_name}

#--- supported iopname: /work/j07hsu00/cesm2_work/code/cesm23/components/cam/cime_config/usermods_dirs/
#       scam_arm95       scam_atex        scam_cgilsS11    scam_cgilsS6     scam_dycomsRF02  scam_mandatory   scam_rico        scam_sparticus   scam_twp06       
#       scam_arm97       scam_bomex       scam_cgilsS12    scam_dycomsRF01  scam_gateIII     scam_mpace       scam_SAS         scam_togaII 
set iopname = "scam_twp06"

set CASE_EXP = $CASE/test01_${iopname}

# ----------------------
# link inputdata to your home directory
# ----------------------

set inputdata_dir = /home/${USER}/runs/cesm
set inputdata_link = ${inputdata_dir}/inputdata

if (! -d $inputdata_dir) then
  mkdir -p $inputdata_dir || exit 1
endif

if (! -e $inputdata_link) then
  ln -s /home/j07hsu00/runs/cesm/inputdata $inputdata_link || exit 1
endif

# ----------------------
# Set up a SCAM
#   ./create_newcase
#   ./case.setup
#   ./case.build
# ----------------------

cd $CIME_SCRIPT || exit 1

./create_newcase $newcase_params --case $CASE --user-mods-dir ../../components/cam/cime_config/usermods_dirs/scam_mandatory || exit 1

cd $CASE || exit 1

./case.setup  || exit 1

./case.build  || exit 1

# ----------------------
# Run an IOP case
#   ./create_clone
#   ./case_submit
# ----------------------

#--- create iop case
cd $CIME_SCRIPT || exit 1
./create_clone --case $CASE_EXP --clone $CASE --user-mods-dir ../../components/cam/cime_config/usermods_dirs/${iopname} --keepexe || exit 1

#--- run SCAM
cd $CASE_EXP || exit 1
./xmlchange --force JOB_QUEUE=ctest
./case_submit  || exit 1

# ----------------------
# back up this script
# ----------------------

#--- back up this script in $BLDDIR
set this_script = "$0"
set script_name = "zz-run_scam6.csh"
cp $this_script $CASE_EXP || exit 1

exit 0


