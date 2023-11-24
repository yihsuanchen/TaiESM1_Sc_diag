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

  varname = "T"

  path1 = "/work/yihsuan123/qq03-scam_test/qq03-scam_test.twp06.taiphy.1124131233/run/"
  filename1 = path1+"camrun.cam.h0.2006-01-17-10800.nc"
  file1 = addfile(filename1, "r")
  var1 = file1->$varname$

  path2 = "/work/yihsuan123/qq03-scam_test/qq03-scam_test.twp06.1124120254/run/"
  filename2 = path2+"camrun.cam.h0.2006-01-17-10800.nc"
  file2 = addfile(filename2, "r")
  var2 = file2->$varname$

  print(var1+" , "+var2)



end
