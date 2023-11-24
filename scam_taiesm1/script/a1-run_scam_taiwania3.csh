#!/bin/csh -f
#SBATCH -A MST112228        # Account name/project number
#SBATCH -J scam_taiesm1     # Job name
#SBATCH -p ctest             # Partition name
#SBATCH -n 1               # Number of MPI tasks (i.e. processes)
#SBATCH -c 1                # Number of cores per MPI task
#SBATCH -N 1                # Maximum number of nodes to be allocated
#SBATCH -o %j.out           # Path to the standard output file
#SBATCH -e %j.err           # Path to the standard error ouput file
#SBATCH --mail-user=yihsuanc@gate.sinica.edu.tw
#SBATCH --mail-type=FAIL

#===================================
#  Description:
#    Running single-column version of TaiESM1 on Taiwania 3
#
#  Author:
#    Yi-Hsuan Chen (yihsuanc@gate.sinica.edu.tw)
#
#  Date:
#    November 2023
#===================================
#

# command echoing
set echo

# -------------------------------------------------------------------------
# modules 
#   copy from TaiESM1, env_mach_specific file
# -------------------------------------------------------------------------
source /opt/ohpc/admin/lmod/8.1.18/init/csh
setenv MODULEPATH /home/yhtseng00/modules:/opt/ohpc/Taiwania3/modulefiles:/opt/ohpc/Taiwania3/pkg/lmod/comp/intel/2020:/opt/ohpc/pub/modulefiles

module purge
module load compiler/intel/2020u4 netcdf-4.8.0-intel2020

## ===================================
## yhc 2023-11-21: SCM was compiled successfully with these modules, but fail to execute "nf90_open". The error message was "Attempting to use an MPI routine before initializing MPICH".
## module purge
## module load cmake/3.15.4 compiler/intel/2020u4 IntelMPI/2020 netcdf-4.8.0-NC4-intel2020-impi pnetcdf-1.8.1-intel2020-impi
## $CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc ifort -v
## ===================================

# -------------------------------------------------------------------------
#  set environment variables on Taiwania 3
# -------------------------------------------------------------------------

#set CAM_ROOT  = /home/j07hsu00/taiesm/ver170803
set CAM_ROOT  = /work/yihsuan123/taiesm_ver170803  # test TaiESM1 codes
set CSMDATA = /home/j07hsu00/taiesm/inputdata
setenv INC_NETCDF ${NETCDF}/include
setenv LIB_NETCDF ${NETCDF}/lib

# -------------------------------------------------------------------------
# set vars for the SCAM run
# -------------------------------------------------------------------------

# temporary variable
set temp=`date +%m%d%H%M%S`

#set iopname = 'arm95'
set iopname = 'twp06'
set model = "qq03-scam_test"

set CASE = ${model}.${iopname}.${temp}
set SCAM_MODS = /home/yihsuan123/research/TaiESM1_Sc_diag/scam_taiesm1/script/scam_mods
set WRKDIR = /work/yihsuan123/${model}/
set BLDDIR = $WRKDIR/$CASE/bld
set RUNDIR = $WRKDIR/$CASE/run
mkdir -p $BLDDIR || exit 1
mkdir -p $RUNDIR || exit 1

#--- back up this script in $BLDDIR
set this_script = "$0"
set script_name = "zz-run_scam.csh"
cp $this_script $BLDDIR/$script_name || exit 1

#--- not use sbatch
#set this_script = "`pwd`/$0"
#cp $this_script $BLDDIR || exit 1

# -------------------------------------------------------------------------
# Set some case specific parameters here
#   Here the boundary layer cases use prescribed aerosols while the deep convection
#   and mixed phase cases use prognostic aerosols.  This is because the boundary layer
#   cases are so short that the aerosols do not have time to spin up.
# -------------------------------------------------------------------------

if ($iopname == 'arm95' ||$iopname == 'arm97' ||$iopname == 'mpace' ||$iopname == 'twp06' ||$iopname == 'sparticus' ||$iopname == 'togaII' ||$iopname == 'gateIII' ||$iopname == 'IOPCASE') then
  set aero_mode = 'trop_mam3'
  #set aero_mode = 'none'
else
  set aero_mode = 'none'
endif

# --------------------------
# configure
# --------------------------
cd $BLDDIR || exit 1

#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc ifort -cc icc -fc_type intel \
#  || echo "ERROR: Configure failed." && exit 1

$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc ifort -cc icc -fc_type intel -usr_src $SCAM_MODS \
  || echo "ERROR: Configure failed." && exit 1

# --------------------------
# compile
# --------------------------

echo ""
echo " -- Compile"
echo ""
gmake -j >&! MAKE.out || echo "ERROR: Compile failed. Check out MAKE.out [$BLDDIR/MAKE.out]" && exit 1

# --------------------------
# Build the namelist with extra fields needed for scam diagnostics
# --------------------------

if ($iopname == 'twp06') then

cat <<EOF >! tmp_namelistfile
&camexp 
    history_budget       = .true.,
    nhtfrq               = -3, 
    print_energy_errors=.true., 
/
&cam_inparm
    iopfile = '/work/opt/ohpc/pkg/rcec/model/taiesm/inputdata/atm/cam/scam/iop/TWP06_4scam.nc'
    ncdata = "/home/j07hsu00/taiesm/inputdata/atm/cam/inic/gaus/cami_0000-01-01_64x128_L30_c090102.nc"  
/
&seq_timemgr_inparm
    stop_n               = 1872,
    stop_option          = 'nsteps'
/
EOF

else
  echo "ERROR: iopname [$iopname] namelist is not supported in this script" && exit 1

endif

$CAM_ROOT/models/atm/cam/bld/build-namelist -s -infile tmp_namelistfile -use_case scam_${iopname} -csmdata $CSMDATA \
    || echo "build-namelist failed" && exit 1

# --------------------------
# Run SCAM
 #--------------------------

cd $RUNDIR
cp -f $BLDDIR/*_in $RUNDIR || exit 1
ln -s $BLDDIR/cam  $RUNDIR || exit 1

echo ""
echo " -- Running SCAM in $RUNDIR"
echo ""

./cam > scam_output.txt || echo "ERROR: Running SCAM failed... check out log file [$RUNDIR/scam_output.txt]" && exit 99   ### try srun

exit 0



