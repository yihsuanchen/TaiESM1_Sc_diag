#!/bin/csh -f
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

# echo command echoing
set echo

# -------------------------------------------------------------------------
# Bluefire build specific settings
#   copy from TaiESM1, env_mach_specific file
# -------------------------------------------------------------------------
source /opt/ohpc/admin/lmod/8.1.18/init/csh
setenv MODULEPATH /home/yhtseng00/modules:/opt/ohpc/Taiwania3/modulefiles:/opt/ohpc/Taiwania3/pkg/lmod/comp/intel/2020:/opt/ohpc/pub/modulefiles
module purge
module load cmake/3.15.4 compiler/intel/2020u4 IntelMPI/2020 netcdf-4.8.0-NC4-intel2020-impi pnetcdf-1.8.1-intel2020-impi

# -------------------------------------------------------------------------
#  set environment variables in Taiwania 3
# -------------------------------------------------------------------------

set CAM_ROOT  = /home/j07hsu00/taiesm/ver170803
set CSMDATA = /home/j07hsu00/taiesm/inputdata

set NCHOME = /home/yhtseng00/netcdf-4.8.0-NC4-intel2020-impi/
setenv INC_NETCDF ${NCHOME}/include
setenv LIB_NETCDF ${NCHOME}/lib

set USER_FC = "ifort"

#########################################################################
### Set vars needed for this script code dir, case, data dir, mods, wrkdir
#########################################################################

# temporary variable
set temp=`date +%m%d%H%M%S`

set iopname = 'arm95'
set model = "qq01-scam_test01"

set CASE = ${model}.${iopname}.${temp}
set WRKDIR = /work/yihsuan123/${model}/
set BLDDIR = $WRKDIR/$CASE/bld
set RUNDIR = $WRKDIR/$CASE/run
mkdir -p $BLDDIR || exit 1
mkdir -p $RUNDIR || exit 1

#########################################################################
### Set some case specific parameters here
### Here the boundary layer cases use prescribed aerosols while the deep convection
### and mixed phase cases use prognostic aerosols.  This is because the boundary layer
### cases are so short that the aerosols do not have time to spin up.

if ($iopname == 'arm95' ||$iopname == 'arm97' ||$iopname == 'mpace' ||$iopname == 'twp06' ||$iopname == 'sparticus' ||$iopname == 'togaII' ||$iopname == 'gateIII' ||$iopname == 'IOPCASE') then
  set aero_mode = 'trop_mam3'
  #set aero_mode = 'none'
else
  set aero_mode = 'none'
endif
#
#
#
#

#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -fc $USER_FC -usr_src $SCAM_MODS -debug

##--------------------------
## configure
##--------------------------
cd $BLDDIR || exit 1
#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc $USER_FC -ldflags -static-intel
$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc $USER_FC

##--------------------------
## compile
##--------------------------

echo ""
echo " -- Compile"
echo ""
gmake -j LDFLAGS="" >&! MAKE.out || echo "ERROR: Compile failed. Check out MAKE.out [$BLDDIR/MAKE.out]" && exit 1
#gmake -j >&! MAKE.out #|| echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1
#gmake -j > MAKE.out || echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1

##--------------------------
## Build the namelist with extra fields needed for scam diagnostics
##--------------------------

cat <<EOF >! tmp_namelistfile
&camexp 
    history_budget       = .true.,
    nhtfrq               = -3, 
    print_energy_errors=.true., 
/
EOF

$CAM_ROOT/models/atm/cam/bld/build-namelist -s -infile tmp_namelistfile -use_case scam_${iopname} -csmdata $CSMDATA \
    || echo "build-namelist failed" && exit 1

##--------------------------
## Run SCAM
##--------------------------

cd $RUNDIR
cp -f $BLDDIR/*_in $RUNDIR || exit 1
ln -s $BLDDIR/cam  $RUNDIR || exit 1

echo ""
echo " -- Running SCAM in $RUNDIR"
echo ""
###./cam >&! scam_output.txt
./cam > scam_output.txt

exit 0



