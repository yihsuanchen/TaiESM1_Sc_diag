#!/bin/csh -f

# Script to make a community-available SCAM run library for ARM standard IOP cases

# Lin Su and John Truesdale (please contact Lin Su (linsu@ucar.edu) for SCAM diagnostic package)).
# modified to test SCAM on Chia Machine by CJ Shiu due to the out of order of SCUD

set VERSION=12072012
echo "***** Version - $VERSION *****"

#########################################################################
### Set vars needed for this script code dir, case, data dir, mods, wrkdir
#########################################################################

set CAM_ROOT  = /chia_cluster/home/cjshiu/cesm1_2_2
set CSMDATA   = /chia_cluster/data/cesm1/inputdata
set USR_SRC = /chia_cluster/home/cjshiu/SCM_ZMJPtrig/Codes_TaiESM_tn9_SourceMods_usedinCESM_ZMMOD_fromScud # Test mods dir.

###set IOP_CASES_TO_RUN = 'arm95 arm97 gateIII mpace sparticus togaII twp06'
set IOP_CASES_TO_RUN = 'twp06' ## 'gateIII' ## 'twp06' ## 'togaII' ## 'arm97'

###set CAM_TIMESTEPS_TO_RUN = '60 300 600 900 1200'
set CAM_TIMESTEPS_TO_RUN = '1200'

### set CAM_LEVELS  # options are 26,27,30,60,90,120,150,180,210,240
                    # you must have initial condition files for number of levels
set CAM_LEVELS_TO_RUN = 30 

#set CASE = scam5_cam_togaII_1timestep15 ## scam5_gateIII_001 ## scam5_twp06_005 ## scam5_togaII_001 ## scam5_arm97_004
set CASE = TaiESM_tn9_only_tpdf_ZMMOD_fromScud_inCESM122_ctrl   ## scam5_gateIII_001 ## scam5_twp06_005 ## scam5_togaII_001 ## scam5_arm97_004

set WRKDIR = /chia_cluster/home/cjshiu/SCM_ZMJPtrig  && if (! -e  $WRKDIR) mkdir -p $WRKDIR

#########################################################################
### Select compiler+libraries env vars and set paths depending on machine.
#########################################################################
source $MODULESHOME/init/csh

module add intel/13_sp1.4/211/x86_64
module add lib/netcdf/4.1.3/intel_13_sp1/x86_64

set FC_DIR=/chia_cluster/opt/aracbox/intel/Compiler/composer_xe_2013_sp1.4.211
set USER_FC=ifort
set NCHOME=/chia_cluster/opt/aracbox/lib/netcdf/4.1.3/intel_13_sp1/x86_64/
set DBUG = "-debug"

#########################################################################
### Shouldn't have to modify below here
#########################################################################

setenv INC_NETCDF ${NCHOME}/include
setenv LIB_NETCDF ${NCHOME}/lib
setenv NCARG_ROOT /share/apps/ncl/6.1.2
setenv PATH ${NCHOME}/bin:${FC_DIR}/bin:${NCARG_ROOT}/bin:${PATH}
setenv LD_LIBRARY_PATH ${FC_DIR}/lib:${LIB_NETCDF}:${LD_LIBRARY_PATH}

alias MATH 'set \!:1 = `echo "\!:3-$" | bc -l`'  # do not modify this

set runtypes="test"

#########################################################################
# NOTE: Below, set iopname, levarr, tarray.  can be more than one values, if so will loop 
#########################################################################

foreach iopname ($IOP_CASES_TO_RUN) # change this, see above (depending on case you want to simulate)
foreach tarray ($CAM_TIMESTEPS_TO_RUN)   # change this, the host model timestep 
foreach levarr ($CAM_LEVELS_TO_RUN)      # change this, number of levels to run

set EXPNAME={$CASE}_{$iopname}_L{$levarr}_T{$tarray}

#########################################################################
### Set some case specific parameters here
### Here the boundary layer cases use prescribed aerosols while the deep convection
### and mixed phase cases use prognostic aerosols.  This is because the boundary layer
### cases are so short that the aerosols do not have time to spin up.

if ($iopname == 'arm95' ||$iopname == 'arm97' ||$iopname == 'mpace' ||$iopname == 'twp06' ||$iopname == 'sparticus' ||$iopname == 'togaII' ||$iopname == 'gateIII' ||$iopname == 'IOPCASE') then
set aero_mode = 'trop_mam3'
#  set aero_mode = 'none'
else
  set aero_mode = 'none'
endif

set SCAM_MODS = $WRKDIR/$CASE/mods    && if (! -e  $SCAM_MODS) mkdir -p $SCAM_MODS 
rm -rf $SCAM_MODS/*
/bin/cp -f $USR_SRC/* $SCAM_MODS

set BLDDIR    = $WRKDIR/$CASE/{$CASE}_bld_L${levarr}_${aero_mode}  && if (! -e  $BLDDIR) mkdir -p $BLDDIR
cd $BLDDIR

set IOPDESC = `grep IOP\: $CAM_ROOT/models/atm/cam/bld/namelist_files/use_cases/scam_${iopname}.xml`
 
echo ""
echo "***** $IOPDESC *****"
echo ""

##------------------------------------------------
## Configure for building
##------------------------------------------------
   
#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -cppdefs -DDISABLE_TIMERS -scam -usr_src $SCAM_MODS -fc $USER_FC $DBUG -ldflags "-llapack -lblas -Mnobounds" #-comp_intf mct -ice none -ocn docn# -cice_nx 1 -cice_ny 1 -microphys mg1.5

##$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -cppdefs -DDISABLE_TIMERS -scam -usr_src $SCAM_MODS -fc $USER_FC $DBUG -ldflags "-llapack -lblas -Mnobounds" # -cice_nx 1 -cice_ny 1 -microphys mg1.5
##$CAM_ROOT/models/atm/cam/bld/configure -s -ccsm_seq -ice none -ocn docn -comp_intf mct -scam -nosmp -nospmd -dyn eul -res 64x128 -phys cam5 -dyn eul -scam

#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -fc $USER_FC -usr_src $SCAM_MODS

#$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -fc $USER_FC 

$CAM_ROOT/models/atm/cam/bld/configure -s -chem $aero_mode -nlev $levarr -dyn eul -res 64x128 -nospmd -nosmp -scam -ocn dom -comp_intf mct -phys cam5 -fc $USER_FC -usr_src $SCAM_MODS -debug
##--------------------------
## compile
##--------------------------

echo ""
echo " -- Compile"
echo ""
gmake -j >&! MAKE.out || echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1
#gmake -j > MAKE.out || echo "ERROR: Compile failed for' bld_${levarr}_${aero_mode} - exiting run_scam" && exit 1

#--------------------------
## Build the namelist with extra fields needed for scam diagnostics
##--------------------------

cat <<EOF >! tmp_namelistfile
&camexp 
    history_budget       = .true.,
    dtime                = $tarray,
    nhtfrq               = -3, 
    print_energy_errors=.true., 
    deep_scheme = 'ZMMOD'
    macrop_scheme='tpdf' 
/
&cam_inparm
    iopfile = '/chia_cluster/data/cesm1/inputdata/atm/cam/scam/iop/TWP06_4scam.nc'
    ncdata = '/chia_cluster/data/cesm1/inputdata/atm/cam/inic/gaus/cami_0000-01-01_64x128_L30_c090102.nc'   
/
&seq_timemgr_inparm
    stop_n               = 1872,
    stop_option          = 'nsteps'
    fincl1               = 'MACPDT','MACPDQ','MACPDLIQ','MACPDICE','MPDT','MPDQ','MPDLIQ','MPDICE','CMFDT','CMFDQ','CMFDLIQ','CMFDICE','tten_PBL','qvten_PBL','qlten_PBL','qiten_PBL'
/
EOF
#&cam_inparm
#    iopfile = '/nethome/gchen/SCAM/inputdata/scam/iop/TOGAII_4scam.nc'
#    ncdata  = '/nethome/gchen/SCAM/Ocn1Atm10.cam2.9.r.0126-01-01-00000.nc'
#/
#&cam_inparm
#    iopfile = '/nethome/gchen/SCAM/inputdata/scam/iop/TOGAII_4scam.nc'
#    ncdata = '/nethome/gchen/SCAM/inputdata/inic/gaus/cami_0000-01-01_64x128_L30_c090102.nc'   
#/
    #iopfile              = '/glade/scratch/ginochen/SCAM/rce_iop_twp06_mean_ctrl.nc'
### NOT FOUND 'CNVCLD','DQSED','HCME','HEVPA','HFREEZ','HREPART','HSED','PTTEND_RESID','REPARTICE','REPARTLIQ',
### cat <<EOF >! tmp_namelistfile
### &camexp 
###     history_budget       = .true.,
###     dtime                = $tarray,
###     ndens                = 1,
###     fincl1               = 'CLDST','ZMDLF','ZMDT','ZMDQ',
###                          'ICWMR','ICIMR','FREQL','FREQI','LANDFRAC','CDNUMC','FICE','WSUB','CCN3','ICLDIWP',
###                          'CDNUMC', 'AQSNOW',  'WSUB', 'CCN3', 'FREQI', 'FREQL', 'FREQR', 'FREQS', 'CLDLIQ', 'CLDICE',
###                          'FSDS', 'FLDS','AREL','AREI','NSNOW','QSNOW','DSNOW','AWNC','AWNI',
###                          'FLNT','FLNTC','FSNT','FSNTC','FSNS','FSNSC','FLNT','FLNTC','QRS','QRSC','QRL','QRLC',
###                          'LWCF','SWCF', 'NCAI', 'NCAL', 'NIHF','NIDEP','NIIMM','NIMEY', 'ICLDIWP','ICLDTWP', 'CONCLD',
###                          'QCSEVAP', 'QISEVAP', 'QVRES', 'CMELIQ', 'CMEIOUT', 'EVAPPREC', 'EVAPSNOW', 'TAQ',
###                          'ICLMRCU', 'ICIMRCU' ,'ICWMRSH' ,'ICWMRDP', 'ICLMRTOT' , 'ICIMRTOT' , 'SH_CLD' ,  'DP_CLD',
###                          'LIQCLDF','ICECLDF', 'ICWMRST', 'ICIMRST', 'EFFLIQ', 'EFFICE','ADRAIN','ADSNOW'
### /
### EOF
### &cam_inparm
###    scm_iop_srf_prop     = .true.,
### /
### &seq_timemgr_inparm
###    stop_n               = 2160,
###    stop_option          = 'nsteps'
### /

$CAM_ROOT/models/atm/cam/bld/build-namelist -s -infile tmp_namelistfile -use_case scam_${iopname} -csmdata $CSMDATA \
    || echo "build-namelist failed" && exit 1

set RUNDIR    = $WRKDIR/$CASE/$EXPNAME                  && if (! -e  $RUNDIR) mkdir -p $RUNDIR
cd $RUNDIR

 ### RUN

cp -f $BLDDIR/docn.stream.txt $RUNDIR
cp -f $BLDDIR/*_in            $RUNDIR
cp -f $BLDDIR/cam             $RUNDIR

echo ""
echo " -- Running SCAM in $RUNDIR"
echo ""
###./cam >&! scam_output.txt
./cam > scam_output.txt

end           #foreach iopname
end           #foreach tarray
end           #foreach levarr

exit 0

