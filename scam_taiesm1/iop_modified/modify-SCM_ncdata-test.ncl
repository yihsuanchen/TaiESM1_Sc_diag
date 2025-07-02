load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "/Users/yi-hsuanchen/Downloads/yihsuan//scripts/ncl//ignorantNCL.ncl"
;load "./ignorantNCL.ncl"
;load "/Users/yi-hsuanchen/Downloads/yihsuan//scripts/ncl//ignorantNCL-colormaps.ncl"
;load "zz-read_parameters.ncl"

begin

;------------------
; general settings
;------------------

  wks_name = "test111"
  wks_type = "png"  ; or x11,pdf,ncgm

;------------------
; open files & wks
;------------------

  filename_in = "./cami_0000-01-01_64x128_L30_c090102.nc"
  filename_set1 = "./cami_0000-01-01_64x128_L30_c090102.yhc0701_ncl_soa_a2_cnst.nc"

  commd = "cp "+filename_in+" " +filename_set1
  system(commd)

  file_set1 = addfile( filename_set1 , "w" )

  NUMICE_set1 = file_set1->NUMICE

  soa_a2 = NUMICE_set1
    soa_a2 = 1.e-13
    soa_a2@long_name = "soa_a2"

  ;printVarSummary(soa_a2)
  ;print(soa_a2(0,:,0,0))

  file_set1->soa_a2 = soa_a2

  text1 = "Done. create "+filename_set1
  print(text1)

end
