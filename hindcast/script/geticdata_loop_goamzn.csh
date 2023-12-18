#! /bin/csh -f

#set INDATE = 2017-12-19
#set INDATE = 2011-05-01
#set INDATE = 2017-12-29
#set INDATE = 2018-01-03
#set INDATE = 2018-01-08
#set INDATE = 2018-01-13
#set INDATE = 2018-01-18
#set INDATE = 2018-01-23
#set INDATE = 2018-01-28
#set pathin = /lfs/archive/Reanalysis/ERA5/forYC/MC3E/
set pathin_sp = /lfs/home/hsieh8835/05-IC/variables
set pathin    = /lfs/home/hsieh8835/05-IC/variables

foreach iyear (`seq 2017 2017`)
foreach imonth (`seq 9 9`)
foreach iday (`seq 1 30`)
  if ($imonth < 10) then
    if ($iday < 10) then
      set INDATE  = ${iyear}-0${imonth}-0${iday}
    else
      set INDATE  = ${iyear}-0${imonth}-${iday}
    endif
  set INDATE2  = ${iyear}0${imonth}
  else
    if ($iday < 10) then
      set INDATE  = ${iyear}-${imonth}-0${iday}
    else
      set INDATE  = ${iyear}-${imonth}-${iday}
    endif
  set INDATE2  = ${iyear}${imonth}
  endif

  set INNAME = ${pathin_sp}/ERA5_SP_2017_09-10.nc
  set OUTNAME = variables/E5_SFC_${INDATE}_sp.nc
  cdo seldate,${INDATE}T00:00:00,${INDATE}T00:00:00 $INNAME $OUTNAME
 
  set INNAMET = ERA5_PRS_t_${iyear}0${imonth}_r360x181_00z.nc
  set OUTNAMET = variables/E5_PRS_t_${INDATE}_00Z.nc
  echo ${pathin}t/${INDATE}
  cdo seldate,${INDATE}T00:00:00,${INDATE}T00:00:00 ${pathin}/t/$INNAMET $OUTNAMET

  set INNAMEU  = ERA5_PRS_u_${iyear}0${imonth}_r360x181_6hr.nc
  set OUTNAMEU = variables/E5_PRS_u_${INDATE}_00Z.nc
  cdo seldate,${INDATE}T00:00:00,${INDATE}T00:00:00 ${pathin}/u/$INNAMEU $OUTNAMEU

  set INNAMEV  = ERA5_PRS_v_${iyear}0${imonth}_r360x181_6hr.nc
  set OUTNAMEV = variables/E5_PRS_v_${INDATE}_00Z.nc
  cdo seldate,${INDATE}T00:00:00,${INDATE}T00:00:00 ${pathin}/v/$INNAMEV $OUTNAMEV

  set INNAMEQ  = ERA5_PRS_q_${iyear}0${imonth}_r360x181_00z.nc
  set OUTNAMEQ = variables/E5_PRS_q_${INDATE}_00Z.nc
  cdo seldate,${INDATE}T00:00:00,${INDATE}T00:00:00 ${pathin}/q/$INNAMEQ $OUTNAMEQ
end
end
end
