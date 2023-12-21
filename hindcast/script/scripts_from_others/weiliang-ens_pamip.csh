#!/bin/csh -f
setenv CCSMROOT /work1/j07hsu00/taiesm_work/bin/ver170803
setenv MYROOT /work1/j07hsu00/taiesm_work/PAMIP
setenv CASE1 $MYROOT/f09.F-PD.PAMIP.pd001

set U = MST108251
set Q = dc20200044
#set Q = dc20190047

set NS = 2
set NE = 2
while ($NS <= $NE)
  if ($NS < 10) then
    set NN = 00${NS}
  else if ($NS < 100) then
    set NN = 0${NS}
  else
    set NN = ${NS}
  endif
  setenv CASE $MYROOT/f09.F-PD.PAMIP.d${NN}

  cd $CCSMROOT/scripts
  ./create_clone -case ${CASE} -clone ${CASE1}

  cd $CASE
  cp ../config/user_nl_cam .
  cp ../config/user_nl_clm .
  echo pertlim = ${NS}.d-14 >> user_nl_cam
  ./cesm_setup
  cd run
  ln -s ../../archive/f09.B-hist.k32.2000-04.ini/rest/2000-03-01-00000/f09* .
  cp ../../archive/f09.B-hist.k32.2000-04.ini/rest/2000-03-01-00000/rp* .
# ln -s ../../archive/f09.B-hist.k32.2000-04.ini/rest/2000-04-01-00000/f09* .
# cp ../../archive/f09.B-hist.k32.2000-04.ini/rest/2000-04-01-00000/rp* .
  cd ..
  set R = *.run
  mv $R temp1.$$
  sed -e "s/ct400/$Q/g" temp1.$$ > temp2.$$
  sed -e "s/MST109184/$U/g" temp2.$$ > $R
  rm -f temp1.* temp2.*
  chmod +x $R

  @ NS ++
end
