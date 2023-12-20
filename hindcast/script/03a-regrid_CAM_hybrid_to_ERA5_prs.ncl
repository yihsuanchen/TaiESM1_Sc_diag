load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/lfs/home/yihsuanc/scripts/ncl//ignorantNCL.ncl"
;load "./ignorantNCL.ncl"
load "/lfs/home/yihsuanc/scripts/ncl//ignorantNCL-colormaps.ncl"
;load "zz-read_parameters.ncl"

begin

;-------------------------------------------------
; Description:
;   interpolate CAM hybrid pressure levels to actual pressure levels of ERA5
;
; Yi-Hsuan Chen
; December, 2023
;-------------------------------------------------

;--------------
; user settings 
;--------------
  
  ;--- input file
  ;datapath_in = "/lfs/home/yihsuanc/data/data.TaiESM1_hindcast/data.July2001_ERA5/"
  datapath_in = "./"
  filename_cami = "cami-mam3_0000-01-01_0.9x1.25_L30.ERA5_ic.2001_07_31_00Z.nc"

  ;--- output file
  datapath_out = "./"
  filename_out = "regrid2era5-"+filename_cami

  ;do_write = False
  do_write = True

;--------------
; program start
;--------------

  file_cami = addfile(datapath_in+filename_cami , "r" )

  hyai_cami = file_cami->hyai      ; hybrid A coefficient at layer interface
  hybi_cami = file_cami->hybi      ; hybrid B coefficient at layer interface
  hyam_cami = file_cami->hyam      ; hybrid A coefficient at layer midpoints
  hybm_cami = file_cami->hybm      ; hybrid B coefficient at layer midpoints
  ps_cami   = file_cami->PS        ; surface pressures  in Pa
  p0_cami   = file_cami->P0        ; reference pressure in Pa
  t_cami = file_cami->T 
  q_cami = file_cami->Q 
  u_cami = file_cami->US 
  v_cami = file_cami->VS 

  nlat = dimsizes(ps_cami&lat)
  ;print(u_cami&slat+" , "+v_cami&lat(:190))

;-------------------------------------------------------------
; interpolate model data to given pressure level & write out 
;-------------------------------------------------------------

; function vinth2p( data, hyam, hybm, plev, ps, intyp, p0, ii, kxtrp )
;   data[:,:,lev,lat,lon] -- rightmost dimension must (be lev,lat,lon)
;   hyam[*] : hybrid A coefficients (unitless)
;   hybm[*] : hybrid B coefficients (unitless)
;   plev[*} : output pressure levels (hPa)
;   ps      : surface pressure, same dimension as data (Pa)
;   intyp   : interpolation type, 1 = LINEAR, 2 = LOG, 3 = LOG LOG
;   p0      : scalar, reference pressure (hPa)
;   ii      : Not used at this time. Set to 1.
;   kxtrp   : Logical.
;             False => no extrapolation when the pressure level is outside of the range of psfc.
;
;  var1_plev = vinth2p(var1, hyai, hybi, plev, ps, 1, p0/100., 1, False)
;  var1_plev = vinth2p(var1, hyam, hybm, plev, ps, 1, p0/100., 1, False)

  plev = (/1., 2., 3., 5., 7., 10., 20., 30., 50., 70., 100., 125., 150., 175., 200., 225., \
    250., 300., 350., 400., 450., 500., 550., 600., 650., 700., 750., 775., 800., 825., \
    850., 875., 900., 925., 950., 975., 1000./)
  plev@long_name = "pressure"
  plev@units     = "hPa"

  t_plev_cami = vinth2p(t_cami, hyam_cami, hybm_cami, plev, ps_cami, 1, p0_cami/100., 1, False)
  copy_VarAtts(t_cami, t_plev_cami)

  q_plev_cami = vinth2p(q_cami, hyam_cami, hybm_cami, plev, ps_cami, 1, p0_cami/100., 1, False)
  copy_VarAtts(q_cami, q_plev_cami)

  ; because #slat = #lat-1
  u_plev_cami = vinth2p(u_cami, hyam_cami, hybm_cami, plev, ps_cami(:,:nlat-2,:), 1, p0_cami/100., 1, False)
  copy_VarAtts(u_cami, u_plev_cami)

  v_plev_cami = vinth2p(v_cami, hyam_cami, hybm_cami, plev, ps_cami, 1, p0_cami/100., 1, False)
  copy_VarAtts(v_cami, v_plev_cami)

;----------------------
; write out to a file
;----------------------

if (do_write) then
  outfile = addfile( filename_out , "c" )
  outfile@input_file = datapath_in+filename_cami
  outfile@interpolate_levels = tostring(plev)
  outfile@interpolate_function = "vinth2p in NCL"

  outfile->t = t_plev_cami
  outfile->q = q_plev_cami
  outfile->u = u_plev_cami
  outfile->v = v_plev_cami

  print("Done. create ["+filename_out+"]")
end if

end
