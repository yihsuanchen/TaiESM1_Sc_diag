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

;=======================
; Description
;   Interpolate JRA3Q surface pressure and T,Q,U,V on CAM hybrid vertical coordiante and lat/lon grids.
;   This creates CAM initial data that can be used for running hindcast simulations.
;
; Author:
;   Yi-Hsuan Chen
;   yihsuanc@gate.sinica.edu.tw
;
; Date:
;   May 2024
;=======================

;------------------
; general settings
;------------------

    ;--- whether to write out the interpolated fields into new files
    ;do_writeout = False
    do_writeout = True

    ;--- input arguments from command line
    ;date = "2001070100" ;YYYYMMDDHH
    ;filename_out = "zz1-"+date+".nc"   ; the file content is same as filename_cami

    ;--- data
    datapath = "~/data/data.TaiESM1_hindcast/data.July2001_JRA3Q.hindcast/"
    filename_prs_ref = datapath+"anl_p125_[spfh,tmp,ugrd,vgrd]."+date
    filename_sfc = datapath+"anl_surf125."+date
    filename_cami = datapath+"cami-snap_0000-01-01_0.9x1.25_L30_c100618.nc"

    print("Input JRA3Q PRS file: "+filename_prs_ref)
    print("Input JRA3Q SFC file: "+filename_sfc)
    print("Output ref file    : "+filename_cami)
    print("Output file        : "+filename_out)

;--------------------------------
; Open files and read variables
;--------------------------------

    ;--- open files
    ;file_prs  = addfile(filename_prs,"r")
    file_sfc  = addfile(filename_sfc,"r")
    file_cami = addfile(filename_cami,"r")

    ;--- time in prs and sfc files
    ;time_prs = cd_calendar(file_prs->time, 3)  ; option = -3 The values returned will be in the format YYYYMMDDHH 
    ;time_sfc = cd_calendar(file_sfc->time, 3)  ; option = -3 The values returned will be in the format YYYYMMDDHH 

    print("Time in JRA3Q PRS and SFC: "+date)

    ;--- read cami variables
    lon_cami = file_cami->lon
    lat_cami = file_cami->lat
    slon_cami = file_cami->slon
    slat_cami = file_cami->slat
    hyam = file_cami->hyam                             ; get a coefficiants
    hybm = file_cami->hybm                              ; get b coefficiants
    P0mb = 1000.

    ;--- Because the horizontal resolution of JRA3Q (1.25 lat x 1.25 lon) is lower than TaiESM1 (0.9 lat x 1.25 lon), 
    ;    the NCL funtion linint2 is used to interpolate. linint2 does not do extrepolation and TaiESM1 lat is 90.000001 and -90.0000001, which is outside ot JRA3Q range [-90, 90].
    ;    So, linint2 results in misssing values at -90 and 90. Change the max/min lat_cami to 90/-90 to avoid this problem.
    nlat = dimsizes(lat_cami)
      lat_cami(0) = -90.
      lat_cami(nlat-1) = 90.

;------------------------------------------------------------
; Read JMA3Q surface pressure and interpolate it on cami lat/lon grids
;------------------------------------------------------------

    print("  process [sp]...")

    ;--- read JMA3Q surface pressure
    varname_sp   = "PRES_P0_L1_GLL0"

    psfc = file_sfc->$varname_sp$         ; (lat,lon) or (time,lat,lon)
    psfc = psfc/100.
    psfc@units = "hPa"
    pslon = file_sfc->lon_0
    pslat = file_sfc->lat_0
    opt = True
    ;opt@critpc = 50

    ;--- interpolat JMA3Q surface pressure on cami lat/lon grids. Note that lat_prs is [90,-90] and lat_cami is [-90,90].
    ;       Because the horizontal resolution of JRA3Q (1.25 lat x 1.25 lon) is lower than TaiESM1 (0.9 lat x 1.25 lon), the NCL funtion linint2 is used to interpolate

    ;psfc_intrp  = area_hi2lores (pslon, pslat(::-1), psfc(::-1,:) , True, 1,  lon_cami, lat_cami, opt  )  ; (ntim,49,120)
    psfc_intrp = linint2 (pslon, pslat(::-1), psfc(::-1,:) , True, lon_cami, lat_cami, 0)

    psfc_intrp_pa = psfc_intrp * 100.
    psfc_intrp_pa@units = "Pa"

    ;printVarSummary(psfc)
    ;printVarSummary(psfc_intrp)
    ;printVarSummary(psfc_intrp_linint2)

;print(psfc)
;print(psfc_intrp)

;------------------------------------------------------------
; Read JMA3Q variables on pressure levels and interpolate it on cami lat/lon grids
;------------------------------------------------------------

    filename_prs_var = (/"tmp","spfh","ugrd","vgrd"/)  ; variable appearing in the file names
    varname_prs      = (/"TMP_P0_L100_GLL0","SPFH_P0_L100_GLL0","UGRD_P0_L100_GLL0","VGRD_P0_L100_GLL0"/)  ; variable names in the data

    nvar = dimsizes(varname_prs)

    ;--- read JMA3Q pressure levels

    do vv=0, nvar-1
    ;do vv=0,0

      ;--- read file
      filename_var = filename_prs_var(vv)
      varname = varname_prs(vv)

      filename_prs = datapath+"anl_p125_"+filename_var+"."+date
      file_prs  = addfile(filename_prs,"r")

      ;--- read a variable
      print("  process ["+varname+"]...")
      var_prs = file_prs->$varname$

      plev_prs = file_prs->lv_ISBL0
        plev_prs = plev_prs/100.
        plev_prs@units = "hPa"
      lon_prs = file_prs->lon_0
      lat_prs = file_prs->lat_0

      ;print("aa1")
      ;ii=100
      ;var_tmp = file_prs->$varname$(0,:,:,ii)
      ;print("float: "+var_prs(0,:,:,ii)+" , short: "+var_tmp)
      ;print("aa2")

      ;printVarSummary(var_prs)
      ;printVarSummary(psfc_intrp)

      ;--- interpolate the variable on cam hybrid levels. All pressure in hPa.
      var_hylev = pres2hybrid(plev_prs, psfc, P0mb, var_prs, hyam, hybm,4)

      ;--- interpolate the variable on cam lat/lon grids. Note that lat_prs is [90,-90] and lat_cami is [-90,90].
      if (varname.eq."UGRD_P0_L100_GLL0") then   ; u_intrp(time, lev, slat, lon)
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,::-1,:), lon_cami, slat_cami, False)
        lat_out = slat_cami
        lon_out = lon_cami

      elseif (varname.eq."VGRD_P0_L100_GLL0") then   ; v_intrp(time, lev, lat, slon)
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,::-1,:), slon_cami, lat_cami, False)
        lat_out = lat_cami
        lon_out = slon_cami
      else
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,::-1,:), lon_cami, lat_cami, False)
        lat_out = lat_cami
        lon_out = lon_cami
      end if

      ;--- set var_intrp coordinate
      ;var_intrp!3    = "lon"
      ;var_intrp!2    = "lat"
      ;var_intrp!1    = "lev"
      ;var_intrp!0    = "time"
      ;var_intrp&lat   = lat_out
      ;var_intrp&lon   = lon_out    

      var_intrp!2    = "lon"
      var_intrp!1    = "lat"
      var_intrp!0    = "lev"
      var_intrp&lat   = lat_out
      var_intrp&lon   = lon_out    

      ;--- set var_intrp long_name and units
      if (varname.eq."TMP_P0_L100_GLL0") then
        t_intrp = var_intrp
        t_intrp@long_name = "Temperature"           ; assign attributes
        t_intrp@units     = "K"
      elseif (varname.eq."SPFH_P0_L100_GLL0") then
        q_intrp = var_intrp
        q_intrp@long_name = "Specific humidity"           ; assign attributes
        q_intrp@units     = "kg/kg"
      elseif (varname.eq."UGRD_P0_L100_GLL0") then
        u_intrp = var_intrp
        u_intrp@long_name = "Zonal wind, staggered"           ; assign attributes
        u_intrp@units     = "m/s"
      elseif (varname.eq."VGRD_P0_L100_GLL0") then
        v_intrp = var_intrp
        v_intrp@long_name = "Meridional wind, staggered"           ; assign attributes
        v_intrp@units     = "m/s"
      end if

      ;printVarSummary(var_prs)
      ;printVarSummary(var_intrp)
      delete(var_intrp)
      delete(lon_out)
      delete(lat_out)

      delete(file_prs)
      delete(var_prs)
    end do ; end loop of vv
    
;-------------
; write out
;-------------
    ;printVarSummary(psfc_intrp)
    ;printVarSummary(t_intrp)
    ;printVarSummary(q_intrp)
    ;printVarSummary(u_intrp)
    ;printVarSummary(v_intrp)

  if (do_writeout) then
    ; create file_out
    comd = "cp -i "+filename_cami+" "+filename_out+" && echo create_file_out || exit 1"
    ;print(comd)
    system(comd)

    ;msg = "  write out variables to ["+filename_out+"] ..."
    ;print(msg)
    print("  write out variables to ["+filename_out+"] ...")

    file_out = addfile(filename_out, "w")

    ;--- write variables
    file_out->T (0,:,:,:) = (/t_intrp/)
    file_out->Q (0,:,:,:) = (/q_intrp/)
    file_out->US(0,:,:,:) = (/u_intrp/)
    file_out->VS(0,:,:,:) = (/v_intrp/)
    file_out->PS(0,:,:)   = (/psfc_intrp_pa/)

    ;--- add file attributes
    current_time = systemfunc("date +%Y%m%d_%H:%M:%S")
    file_out@file_modification = "replace T,Q,US,VS,PS with JMA3Q data at "+current_time
    file_out@Input_JMA3Q_PRS_file = filename_prs_ref
    file_out@Input_JMA3Q_SFC_file = filename_sfc
    file_out@Output_ref_file = filename_cami
    file_out@Convert_grib2nc_sfc = "ncl_convert2nc "+filename_sfc+".grib"
    file_out@Convert_grib2nc_prs = "ncl_convert2nc "+filename_prs_ref+".grib"

  end if  ; end if of do_writeout

end
