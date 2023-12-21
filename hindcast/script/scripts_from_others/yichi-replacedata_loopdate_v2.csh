#! /bin/csh -f

#cami-mam3_0000-01-01_0.9x1.25_L30.replace.eraitm.ps.nc_intrp.nc
#cami-mam3_0000-01-01_0.9x1.25_L30.replace.eraitm.q.nc_intrp.nc
#cami-mam3_0000-01-01_0.9x1.25_L30.replace.eraitm.t.nc_intrp.nc
#cami-mam3_0000-01-01_0.9x1.25_L30.replace.eraitm.usvs.nc_intrp.nc
#cami-mam3_0000-01-01_0.9x1.25_L30.replace.eraitm.uv.nc_intrp.nc

  set OUTDIR = replace

#ncks -A -v U in.nc out.nc
#set INDATE = 2017-12-19
#foreach iday (`seq 22 30`)
#  set INDATE = 2011-04-${iday}
#foreach iday (`seq 10 10`)
#  set INDATE = 2011-05-${iday}
foreach iyear (`seq 2017 2017`)
foreach imonth (`seq 9 9`)
foreach iday (`seq 1 30`)
  if ( ${iday} < 10 ) then
  set INDATE = ${iyear}-0${imonth}-0${iday}
  else
  set INDATE = ${iyear}-0${imonth}-${iday}
  endif
  echo $INDATE

set OUTNAME = ERA5_${INDATE}_initial

cp ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30_c100618.nc ${OUTNAME}.nc



set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.sp_${INDATE}.nc_intrp
ncks -A -C -v PS ${INNAME}.nc ${OUTNAME}.nc

# US, US
set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.usvs_direct${INDATE}.nc_intrp
ncks -A -C -v US,VS ${INNAME}.nc ${OUTNAME}.nc

# V
#set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.v_${INDATE}.nc_intrp
#ncks -A -C -v V ${INNAME}.nc ${OUTNAME}.nc

# U
#set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.u_${INDATE}.nc_intrp
#ncks -A -C -v U ${INNAME}.nc ${OUTNAME}.nc

# Q
set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.q_${INDATE}.nc_intrp
ncks -A -C -v Q ${INNAME}.nc ${OUTNAME}.nc

# T
set INNAME = ${OUTDIR}/cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5.t_${INDATE}.nc_intrp
ncks -A -C -v T ${INNAME}.nc ${OUTNAME}.nc

end
end
end
