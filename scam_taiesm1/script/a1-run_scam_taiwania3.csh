#!/bin/csh -f
set echo

# -------------------------------------------------------------------------
# Bluefire build specific settings
#   copy from TaiESM1, env_mach_specific file
# -------------------------------------------------------------------------
source /opt/ohpc/admin/lmod/8.1.18/init/csh
setenv MODULEPATH /home/yhtseng00/modules:/opt/ohpc/Taiwania3/modulefiles:/opt/ohpc/Taiwania3/pkg/lmod/comp/intel/2020:/opt/ohpc/pub/modulefiles
module purge
module load cmake/3.15.4 compiler/intel/2020u4 IntelMPI/2020 netcdf-4.8.0-NC4-intel2020-impi pnetcdf-1.8.1-intel2020-impi

exit 0

#########################################################################
### Set vars needed for this script code dir, case, data dir, mods, wrkdir
#########################################################################

# temp variable
#set temp=`date +%Y%m%d%H%M%S`
set temp=`date +%m%d%H%M%S`
#

set CAM_ROOT  = /home/j07hsu00/taiesm/ver170803
set CSMDATA = /home/j07hsu00/taiesm/inputdata

set USER_FC = "ifort"

set iopname = 'arm95'

set CASE = scam_test01.${iopname}.${temp}
set WRKDIR = /work/yihsuan123/scam_test1/
set BLDDIR = $WRKDIR/$CASE/bld
mkdir -p $BLDDIR
cd $BLDDIR

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
$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc $USER_FC

##--------------------------
## compile
##--------------------------

echo ""
echo " -- Compile"
echo ""
gmake -j >&! MAKE.out || echo "ERROR: Compile failed. Check out MAKE.out {$BLDDIR/MAKE.out}" && exit 1
#gmake -j >&! MAKE.out #|| echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1
#gmake -j > MAKE.out || echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1


