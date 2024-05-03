load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/Users/yi-hsuanchen/Downloads/yihsuan//scripts/ncl//ignorantNCL.ncl"
load "./ignorantNCL.ncl"
;load "/Users/yi-hsuanchen/Downloads/yihsuan//scripts/ncl//ignorantNCL-colormaps.ncl"
;load "zz-read_parameters.ncl"

begin

;------------------
; general settings
;------------------

  ;rf = "RF01"
  rf = "RF02"

  ;do_writeout = False
  do_writeout = True

  if (rf .eq. "RF01") then
    filename_rf0X = "./DYCOMSrf01_4day_4scam.nc"
    outfilename_rf0X = "./DYCOMSrf01_4day_4scam_Recompute_Tqvql_inML.nc.nc"
    k_ml_top = 71
    k_ml_bottom = 94

  elseif (rf .eq. "RF02") then
    filename_rf0X = "./DYCOMSrf02_48hr_4scam.nc"
    outfilename_rf0X = "./DYCOMSrf02_48hr_4scam_Recompute_Tqvql_inML.nc.nc"
    k_ml_top = 124
    k_ml_bottom = 203
  end if

  print("RF: "+rf)
  print("  input file : "+filename_rf0X)
  print("  output file: "+outfilename_rf0X)

  ;current_time = systemfunc("date +\"%a %b %d %T %Y\"")
  current_time = systemfunc("date")
  ;print(current_time)

;------------------
; program start
;------------------

  setfileoption("nc","MissingToFillValue",False)  ; to avoid this error message: 
                                                  ; warning:NetOpenFile: MissingToFillValue option set True, but missing_value attribute and data variable (lhflx) types differ: not adding virtual _FillValue attribute
                                                  ; https://www.ncl.ucar.edu/Support/talk_archives/2011/2628.html
  file_rf0X = addfile( filename_rf0X , "r" )

  q_rf0X = file_rf0X->q
  T_rf0X = file_rf0X->T
  lev_rf0X = file_rf0X->lev

  ;--- pressure levels, the dimension is the same as T, q
  p_rf0X = q_rf0X
  do t=0,1
    p_rf0X(t, :, 0, 0) = (/lev_rf0X/) 
  end do

  if (rf.eq."RF02") then
    Lv = 2.47e+6        ; J/kg
    cpd = 1015          ; J/kg/K
    CLDLIQ_rf0X = file_rf0X->CLDLIQ
   
    theta_rf0X =  pot_temp(p_rf0X, T_rf0X, 0, False)
    theta_l_rf0X = theta_rf0X - (theta_rf0X/T_rf0X) * (Lv/cpd) * CLDLIQ_rf0X
    
    qt_rf0X = q_rf0X + CLDLIQ_rf0X
    ;print(p_rf0X+", theta_l= "+theta_l_rf0X+", q="+q_rf0X+", ql="+CLDLIQ_rf0X+", qt="+qt_rf0X)
  end if

  ;p_rf0X = p_rf0X / 100.
  ;p_rf0X@units = "hPa"

  ;--- RH=100%  
  rh100_rf0X = q_rf0X
  rh100_rf0X = 100.

  ;--- compute saturation specific humidity
  qs_rf0X = mixhum_ptrh(p_rf0X, T_rf0X, rh100_rf0X, 2)
  ;print(p_rf0X+", "+q_rf0X+ ", "+T_rf0X)

  qstar = q_rf0X - qs_rf0X

  ;--- 
  kx = dimsizes(lev_rf0X)

  qv_rf0X = q_rf0X
    ;qv_rf0X = 0.
    ;qv_rf0X@long_name = "w.v. mixing ratio. NO supersaturation"

  cldliq_rf0X = q_rf0X
    cldliq_rf0X = 0.
    ;cldliq_rf0X@long_name = "Cloud liquid water mixing ratio. Excess of q"

  Tmod_rf0X = T_rf0X

  do t=0,1
  do k=k_ml_top, k_ml_bottom
    if (rf .eq. "RF01") then
      theta_l = 289.
      qt      = 9.e-3
      
      varvar = theta_l_qt_to_T_ql(theta_l, qt, p_rf0X(t,k,0,0))
      ;print(varvar)     
 
      Tmod_rf0X   (t,k,0,0) = varvar@return_T
      qv_rf0X     (t,k,0,0) = varvar@return_qv
      cldliq_rf0X (t,k,0,0) = varvar@return_ql

    elseif (rf .eq. "RF02") then
      theta_l = 288.3
      qt      = 9.45e-3
      
      varvar = theta_l_qt_to_T_ql(theta_l, qt, p_rf0X(t,k,0,0))
      ;print(varvar)     
 
      Tmod_rf0X   (t,k,0,0) = varvar@return_T
      qv_rf0X     (t,k,0,0) = varvar@return_qv
      cldliq_rf0X (t,k,0,0) = varvar@return_ql

    end if ; end if of RF01
  end do  ; end loop of k
  end do  ; end loop of t

;  do t=0,1
;  do k=0, kx-1
;    qt = q_rf0X(t,k,0,0)
;    qs = qs_rf0X(t,k,0,0)
; 
;    if (qt .gt. qs) then
;      qv = (/qs/)
;      cldliq = qt - qs
;    else
;      qv = qt
;      cldliq = 0.
;    end if
;
;    qv_rf0X     (t,k,0,0) = (/qv/)
;    cldliq_rf0X (t,k,0,0) = (/cldliq/)
;
;  end do  ; end loop of k
;  end do  ; end loop of t

  ;print(p_rf0X+", q="+q_rf0X+ ", qs="+qs_rf0X+", q-qs="+qstar)
  ;print(p_rf0X+", qt= "+q_rf0X+", qv="+qv_rf0X+ ", cldliq="+cldliq_rf0X)
  print(p_rf0X+", T= "+T_rf0X+", Tmod="+Tmod_rf0X+", qt= "+q_rf0X+", qv="+qv_rf0X+ ", cldliq="+cldliq_rf0X)

  ;--- write out to a new file
  if (do_writeout) then

    outfile_rf0X = addfile( outfilename_rf0X , "w" )
  
    qv_rf0X@long_name = "w.v. mixing ratio. Recomputed given theta_l and q_t in the ML"
    outfile_rf0X->q = qv_rf0X

    cldliq_rf0X@long_name = "Cloud liquid water mixing ratio. Recomputed given theta_l and q_t in the ML"
    outfile_rf0X->CLDLIQ = cldliq_rf0X

    Tmod_rf0X@long_name = "Absolute temperature. Recomputed given theta_l and q_t in the ML"
    outfile_rf0X->T = Tmod_rf0X

    outfile_rf0X@modification_author = "Yi-Hsuan Chen"
    outfile_rf0X@modification = current_time+": Recompute T, qv, and cldliq in the ML given theta_l and q_t"
  end if

end
