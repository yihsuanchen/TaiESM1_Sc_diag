#!/bin/csh -f
#SBATCH -A MST112228        # Account name/project number
#SBATCH -J scam_taiesm1     # Job name
#SBATCH -p ctest            # Partition name
#SBATCH -n 1                # Number of MPI tasks (i.e. processes)
#SBATCH -c 1                # Number of cores per MPI task
#SBATCH -N 1                # Maximum number of nodes to be allocated
#SBATCH -o %j.out           # Path to the standard output file
#SBATCH -e %j.err           # Path to the standard error ouput file
#SBATCH --mail-user=yihsuanc@gate.sinica.edu.tw  # send an email if SCM fails to run
#SBATCH --mail-type=FAIL

#===================================
#  Description:
#    Running single-column model (SCM) version of TaiESM1 on Taiwania 3
#
#  Author:
#    Yi-Hsuan Chen        (yihsuanc@gate.sinica.edu.tw)
#    Danielle Manalaysay  (danimanalaysa@gate.sinica.edu.tw)
#
#  Usage:
#    1. Make sure SBATCH setting are correct.
#    2. Modify the variables in "setup for the SCAM run" section, such as the IOP case, model physics, etc.
#    3. Run the script 
#       > sbatch THIS_SCRIPT
#
#       if SCM fails to compile, you will get an notification email. The "*.err" and "*.out" log files will be in the folder where you run the script.
#
#    4. The SCM output will be at /work/$USER/$exp_name/$CASE/run  
#
#  Date:
#    December 2023
#===================================
#

# echoing each command
set echo

# -------------------------------------------------------------------------
# set up modules on Taiwania 3 to run the SCM.
# Note that these modules are not the same as running TaiESM1, as the SCM would run into some errors using MPI.
#
# yhc 2023-11-21: SCM was compiled successfully with these below modules, but fail to execute "nf90_open". The error message was "Attempting to use an MPI routine before initializing MPICH".
# module purge
# module load cmake/3.15.4 compiler/intel/2020u4 IntelMPI/2020 netcdf-4.8.0-NC4-intel2020-impi pnetcdf-1.8.1-intel2020-impi
# $CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -debug -fc ifort -v
#-------------------------------------------------------------------------
source /opt/ohpc/admin/lmod/8.1.18/init/csh
setenv MODULEPATH /home/yhtseng00/modules:/opt/ohpc/Taiwania3/modulefiles:/opt/ohpc/Taiwania3/pkg/lmod/comp/intel/2020:/opt/ohpc/pub/modulefiles

module purge
module load compiler/intel/2020u4 netcdf-4.8.0-intel2020

# -------------------------------------------------------------------------
#  set environment variables on Taiwania 3
# -------------------------------------------------------------------------

#set CAM_ROOT  = /home/j07hsu00/taiesm/ver170803   # original TaiESM1 codes
set CAM_ROOT  = /work/yihsuan123/taiesm_ver170803  # yhc's TaiESM1 codes
set CSMDATA = /home/j07hsu00/taiesm/inputdata
setenv INC_NETCDF ${NETCDF}/include
setenv LIB_NETCDF ${NETCDF}/lib

# -------------------------------------------------------------------------
# setup for the SCAM run
# -------------------------------------------------------------------------

# temporary variable
set temp=`date +%m%d%H%M%S`
set date_now=`date +%Y%m%d_%H%M`

#--- set case
#set exp_name = "qq04-scam_test"
set exp_name = "scm_taiesm1"

#--- available iopname: arm95 arm97 gateIII mpace sparticus togaII twp06, according to $CAM_ROOT/models/atm/cam/bld/build-namelist.
#                       the build-namelist -use_case scam_${iopname} will fail if not these cases.
#                       If the user wants to run other cases, it seems to need specify required parameters in the namelist file. 
#                       These paramters should be able to found in CESM2 SCAM.
#set iopname = 'arm95'
#set iopname = 'twp06'
#set iopname = 'dycomsrf01'
set iopname = 'dycomsrf02'

#set phys = "cam5"
set phys = "taiphy"

set surf_flux = "psflx"  # prescribed surface sensible and latent heat fluxes
#set surf_flux = "isflx"  # interactive surface sensible and latent heat fluxes

#set CASE = ${exp_name}.${iopname}.${phys}.${temp}
set CASE = ${exp_name}.${iopname}.${surf_flux}.${temp}

#--- set the folder that contains modifed codes
#set SCAM_MODS = /home/yihsuan123/research/TaiESM1_Sc_diag/scam_taiesm1/script/scam_mods         # put the modifed files in this folder
set SCAM_MODS = /home/yihsuan123/research/TaiESM1_Sc_diag/scam_taiesm1/script/scam_mods.dycoms   # scam_mods.dycoms
                                                                                                 #   - no solar radiation (do_no_solar in radiation.F90)
                                                                                                 #   - radiation scheme is called at every time step 
                                                                                                 #     (iradlw=1=iradsw in runtime_opts.F90) 

#--- check whether scm_iop_srf_prop is supported
if ($surf_flux == "psflx") then
  set text_srf = 'scm_iop_srf_prop= .true.'

else if ($surf_flux == "isflx") then
  set text_srf = 'scm_iop_srf_prop= .false.'

else
  echo "ERROR: surface flux option [$surf_flux] is not supported."
  exit 1

endif

#--- set folders
set WRKDIR = /work/yihsuan123/taiesm_scm/${exp_name}/
set BLDDIR = $WRKDIR/$CASE/bld
set RUNDIR = $WRKDIR/$CASE/run
mkdir -p $BLDDIR || exit 1
mkdir -p $RUNDIR || exit 1

#--- back up this script in $BLDDIR
set this_script = "$0"
set script_name = "zz-run_scam.csh.$date_now"
cp $this_script $BLDDIR/$script_name || exit 1

#--- not use sbatch
#set this_script = "`pwd`/$0"
#cp $this_script $BLDDIR || exit 1


# -------------------------------------------------------------------------
# *** copy from the SCAM original script. May need to modify it if using TaiESM physics ***
# Set some case specific parameters here
#   Here the boundary layer cases use prescribed aerosols while the deep convection
#   and mixed phase cases use prognostic aerosols.  This is because the boundary layer
#   cases are so short that the aerosols do not have time to spin up.
# -------------------------------------------------------------------------

if ($iopname == 'arm95' ||$iopname == 'arm97' ||$iopname == 'mpace' ||$iopname == 'twp06' ||$iopname == 'sparticus' ||$iopname == 'togaII' ||$iopname == 'gateIII' ||$iopname == 'IOPCASE') then
  set aero_mode = 'trop_mam3'

else
  set aero_mode = 'none'
endif

# --------------------------
# configure
# --------------------------
cd $BLDDIR || exit 1

if ($phys == 'taiphy') then
  $CAM_ROOT/models/atm/cam/bld/configure -s -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -taiphy -debug -fc ifort -cc icc -fc_type intel -usr_src $SCAM_MODS \
    || echo "ERROR: Configure failed." && exit 1   # when using taiphy, don't need to specify -chem $aero_mode
else
  $CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys $phys -debug -fc ifort -cc icc -fc_type intel -usr_src $SCAM_MODS \
    || echo "ERROR: Configure failed." && exit 1
endif

# --------------------------
# compile
# --------------------------

echo ""
echo " -- Compile"
echo ""
gmake -j >&! MAKE.out || echo "ERROR: Compile failed. Check out MAKE.out [$BLDDIR/MAKE.out]" && exit 1

# --------------------------
# Build the namelist with extra fields needed for scam diagnostics
#   
#   Reference of scam_iop xml file (in CESM2)
#   /home/j07hsu00/cesm23/code/components/cam/cime_config/usermods_dirs/scam_dycomsRF01
# --------------------------

#--- scam_iop xml file 
set scam_iop_xml = "$CAM_ROOT/models/atm/cam/bld/namelist_files/use_cases/scam_${iopname}.xml"
set scam_iop_file = "/home/yihsuan123/research/TaiESM1_Sc_diag/scam_taiesm1/script/scam_${iopname}.xml"
if (! -f $scam_iop_xml) then
  cp $scam_iop_file $scam_iop_xml || exit 1
endif

#--- create namelist for respective iop

#--- dycomsrf01 and dycomsrf02 namelist
if ($iopname == 'dycomsrf01') then
  set iopfile = "/work/opt/ohpc/pkg/rcec/model/taiesm/inputdata/atm/cam/scam/iop/DYCOMSrf01_4day_4scam.nc"
else if ($iopname == 'dycomsrf02') then
  set iopfile = "/work/opt/ohpc/pkg/rcec/model/taiesm/inputdata/atm/cam/scam/iop/DYCOMSrf02_48hr_4scam.nc"
endif

if ($iopname == 'dycomsrf01' || $iopname == 'dycomsrf02') then

cat <<EOF >! tmp_namelistfile
&camexp 
    history_budget       = .true.,
    nhtfrq               = 1, 
    print_energy_errors=.true., 
    fincl1 = "TTEND_TOT:A","DTCORE:A","PTTEND:A","ZMDT:A","EVAPTZM:A","FZSNTZM:A","EVSNTZM:A","ZMMTT:A","CMFDT:A","DPDLFT:A","SHDLFT:A", "MACPDT:A","MPDT:A","QRL:A","QRS:A","DTV:A","TTGWORO:A", "PTEQ:A","ZMDQ:A","EVAPQZM:A","CMFDQ:A","MACPDQ:A","MPDQ:A","VD01:A", "PTECLDLIQ:A","ZMDLIQ:A","CMFDLIQ:A","MACPDLIQ:A","MPDLIQ:A","VDCLDLIQ:A", "PTECLDICE:A","ZMDICE:A","CMFDICE:A","MACPDICE:A","MPDICE:A","VDCLDICE:A", "DPDLFLIQ:A","DPDLFICE:A","SHDLFLIQ:A","SHDLFICE:A","DPDLFT:A","SHDLFT:A","QVTEND_TOT:A","QLTEND_TOT:A","QITEND_TOT:A","DQVCORE:A","DQLCORE:A","DQICORE:A",'TGCLDLWP_ql:A', 'TGCLDIWP_qi:A'
/

&cam_inparm
    iopfile = '${iopfile}',
    ${text_srf}
    ncdata = '/home/j07hsu00/taiesm/inputdata/atm/cam/inic/gaus/cami_0000-01-01_64x128_L30_c090102.nc',
    iradsw = 1,
    iradlw = 1
/
EOF

#--- twp06 namelist
else if ($iopname == 'twp06') then

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

#--- default namelist
else

cat <<EOF >! tmp_namelistfile
&camexp 
    history_budget       = .true.,
    nhtfrq               = 1, 
    print_energy_errors=.true., 
/

EOF
  #echo "ERROR: iopname [$iopname] namelist is not supported in this script" && exit 1

endif

#--- use build-namelist to create namelists
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


