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
;   Interpolate ERA5 surface pressure and T,Q,U,V on CAM hybrid vertical coordiante and lat/lon grids.
;   This creates CAM initial data that can be used for running hindcast simulations.
;
; Author:
;   Yi-Hsuan Chen
;   yihsuanc@gate.sinica.edu.tw
;
; Date:
;   December, 2023
;=======================

;------------------
; general settings
;------------------

    ;--- input arguments
    ;datapath = "~/data/data.ERA5/"
    ;filename_prs = datapath+"ERA5_PRS.t_q_u_v.r1440x721.2001_07_01_00Z.nc"
    ;filename_sfc = datapath+"ERA5_SFC.sp.r1440x721.2001_07_01_00Z.nc"
    ;filename_cami = "cami-mam3_0000-01-01_0.9x1.25_L30_c100618.nc"
    ;filename_out = "zz1.nc"   ; the file content is same as filename_cami

    print("Input ERA5 PRS file: "+filename_prs)
    print("Input ERA5 SFC file: "+filename_sfc)
    print("Output file        : "+filename_out)


;--------------------------------
; Open files and read variables
;--------------------------------

    ;--- open files
    file_prs  = addfile(filename_prs,"r")
    file_sfc  = addfile(filename_sfc,"r")
    file_cami = addfile(outfile_ref,"r")

    ;--- read cami variables
    lon_cami = file_cami->lon
    lat_cami = file_cami->lat
    slon_cami = file_cami->slon
    slat_cami = file_cami->slat
    hyam = file_cami->hyam                             ; get a coefficiants
    hybm = file_cami->hybm                              ; get b coefficiants
    P0mb = 1000.

;------------------------------------------------------------
; Read ERA5 surface pressure and interpolate it on cami lat/lon grids
;------------------------------------------------------------

    print("  process [sp]...")

    ;--- read ERA5 surface pressure
    varname_sp   = "sp"

    psfc = short2flt(file_sfc->$varname_sp$)         ; (lat,lon) or (time,lat,lon)
    psfc = psfc/100.
    psfc@units = "hPa"
    pslon = file_sfc->longitude
    pslat = file_sfc->latitude
    opt = True
    opt@critpc = 50

    ;--- interpolat ERA5 surface pressure on cami lat/lon grids
    psfc_intrp  = area_hi2lores (pslon,pslat(::-1), psfc(:,::-1,:) , True, 1,  lon_cami, lat_cami, opt  )  ; (ntim,49,120)

    ;printVarSummary(psfc)
    ;printVarSummary(psfc_intrp)

;------------------------------------------------------------
; Read ERA5 variables on pressure levels and interpolate it on cami lat/lon grids
;------------------------------------------------------------

    varname_prs = (/"t","q","u","v"/)
    nvar = dimsizes(varname_prs)

    ;--- read ERA5 pressure levels
    plev_prs = file_prs->level
    lon_prs = file_prs->longitude
    lat_prs = file_prs->latitude

    do vv=0, nvar-1
    ;do vv=0,0

      ;--- read a variable
      varname = varname_prs(vv)
      print("  process ["+varname+"]...")
      var_prs = short2flt(file_prs->$varname$)

      ;printVarSummary(var_prs)
      ;printVarSummary(psfc_intrp)

      ;--- interpolate the variable on cam hybrid levels
      var_hylev = pres2hybrid(plev_prs, psfc, P0mb, var_prs, hyam, hybm,4)

      ;--- interpolate the variable on cam lat/lon grids
      if (varname.eq."u") then   ; u_intrp(time, lev, slat, lon)
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,:,::-1,:), lon_cami, slat_cami, False)
        lat_out = slat_cami
        lon_out = lon_cami

      elseif (varname.eq."v") then   ; v_intrp(time, lev, lat, slon)
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,:,::-1,:), slon_cami, lat_cami, False)
        lat_out = lat_cami
        lon_out = slon_cami
      else
        var_intrp = area_conserve_remap (lon_prs, lat_prs(::-1), var_hylev(:,:,::-1,:), lon_cami, lat_cami, False)
        lat_out = lat_cami
        lon_out = lon_cami
      end if

      ;--- set var_intrp coordinate
      var_intrp!3    = "lon"
      var_intrp!2    = "lat"
      var_intrp!1    = "lev"
      var_intrp!0    = "time"
      var_intrp&lat   = lat_out
      var_intrp&lon   = lon_out    

      ;--- set var_intrp long_name and units
      if (varname.eq."t") then
        t_intrp = var_intrp
        t_intrp@long_name = "Temperature"           ; assign attributes
        t_intrp@units     = "K"
      elseif (varname.eq."q") then
        q_intrp = var_intrp
        q_intrp@long_name = "Specific humidity"           ; assign attributes
        q_intrp@units     = "kg/kg"
      elseif (varname.eq."u") then
        u_intrp = var_intrp
        u_intrp@long_name = "Zonal wind, staggered"           ; assign attributes
        u_intrp@units     = "m/s"
      elseif (varname.eq."v") then
        v_intrp = var_intrp
        v_intrp@long_name = "Meridional wind, staggered"           ; assign attributes
        v_intrp@units     = "m/s"
      end if

      ;printVarSummary(var_prs)
      ;printVarSummary(var_intrp)
      delete(var_intrp)
      delete(lon_out)
      delete(lat_out)
    end do ; end loop of vv
    
;-------------
; write out
;-------------
    ;printVarSummary(psfc_intrp)
    ;printVarSummary(t_intrp)
    ;printVarSummary(q_intrp)
    ;printVarSummary(u_intrp)
    ;printVarSummary(v_intrp)

    ; create file_out
    comd = "cp -i "+outfile_ref+" "+filename_out+" && echo create_file_out || exit 1"
    ;print(comd)
    system(comd)

    print("  write out variables...")

    file_out = addfile(filename_out, "w")
    file_out->T  = (/t_intrp/)
    file_out->Q  = (/q_intrp/)
    file_out->US = (/u_intrp/)
    file_out->VS = (/v_intrp/)
    file_out->PS = (/psfc_intrp/)

end
