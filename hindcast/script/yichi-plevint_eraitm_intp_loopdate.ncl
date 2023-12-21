; created : Yi-Chi
; this program is to intepolate

;--------------------------------
; revised: 
;--------------------------------
   casename = "f09.F2000.CAM5";
;   pathin   = "/data1/home/ychwang/DATA_process/GASS_ERA5IC/0/01-IOP2/00-variables/"
   ; 2015/6-7
   ;pathin = "../../GASS_ERA5IC/04-PECAN/00-variables/"
   ; 2015/08
   ;pathin = "../../GASS_ERA5IC/05-GOAMZN/01-IOP2/00-variables/"
   ; 2017/09
   pathin = "/lfs/home/hsieh8835/05-IC/variables/"
   ; 2015/08
   ;pathin = "../../GASS_ERA5IC/05-GOAMZN/01-IOP2/00-variables/"

   outdir   = "/lfs/home/hsieh8835/05-IC/replace/"


   listfileps = systemfunc("cd "+pathin+";ls " + ".nc")
   dims = dimsizes(listfileps)
   nfiles = dims(0)

   varmatrix = (/"t","q","u","v"/)

; --------------------------------
; start every day
;-----------------------------------
;     days = ispan(1,31,1)
     days = ispan(1,30,1)
     months=ispan(9,9,1)
do imonth = 0,0
do idate  = 0,29
     date = "2017-"+sprinti("%0.2i",months(imonth))+"-"+sprinti("%0.2i",days(idate))
     print(date)
do ivar  = 0, 3
     var = varmatrix(ivar)
     outfilename = "cami-mam3_0000-01-01_0.9x1.25_L30.replace.era5."+var+"_"+date+".nc"
     fileout     = "cami-mam3_0000-01-01_0.9x1.25_L30_c100618.nc"
     fout           = addfile(outdir+fileout, "r")
  lonnew  = fout->lon
  latnew  = fout->lat
     
;     var = varmatrix(ivar)
     print(var)
;    listfileu  = systemfunc("cd "+path+";ls "+var+".*.nc")
     filenamet = "E5_PRS_"+var+"_"+date+"_00Z.nc"
     filenameps= "E5_SFC_"+date+"_sp.nc"

     ft           = addfile(pathin+filenamet, "r")
     fps          = addfile(pathin+filenameps, "r")
     ;filedate    = f->date
     ;filedatesec = f->datesec
  lon = ft->longitude
  lat = ft->latitude
  time = ft->time
     cloud = short2flt(ft->$var$)

     psfc = short2flt(fps->sp)         ; (lat,lon) or (time,lat,lon)
     psfc = psfc/100.
     pslon = fps->longitude
     pslat = fps->latitude
    opt = True
  opt@critpc = 50
     psfc_intrp  = area_hi2lores (pslon,pslat(::-1), psfc(:,::-1,:) , True, 1,  lon, lat, opt  )  ; (ntim,49,120)
    
     hyam = fout->hyam                             ; get a coefficiants
     hybm = fout->hybm                              ; get b coefficiants
     P0mb = 1000.

     plev = ft->level
     ;plev = plev/100.
;     pnew = (/ 850 /)
;     pnew = (/  50, 70, 100,150,200,250 \
;                     , 300,350, 400,450,500,550,600,650,700,750,800,825, 850, 875,  900, 925, 950, 975, 1000 /)
;     t_plev = vinth2p (cloud(time|:,level|:,lat|:,lon|:),hyam,hybm,pnew,fps->sp,1,P0mb,1,False)
     t_plev   = pres2hybrid(plev,psfc_intrp,P0mb,cloud,hyam,hybm,4) 
     ;t_plev&lat   = lat
     ;t_plev&lon   = lon


     ; calculate saturated theta e
     ; printVarSummary(t_plev)
     ; printVarSummary(pnew)
     ; p2d = conform_dims(dimsizes(t_plev), pnew, 1)
     ; printVarSummary(p2d)

    ;============================================
    ; interpolate
    ;============================================
   ;opt = False
   ;opt@NLATo = NLATG
   ;print(latnew)
    ;t_intrp  = area_conserve_remap (lon,lat(::-1), t_plev(:,:,::-1,:) , lonnew, latnew, opt)
  ; opt = True
  ;opt@critpc = 50                ; require only 50% of the values to be present 
  ;t_intrp  = area_hi2lores (lon,lat(::-1), t_plev(:,:,::-1,:) , True, 1,  lonnew, latnew, opt  )  ; (ntim,49,120)
    t_intrp = area_conserve_remap (lon,lat(::-1),t_plev(:,:,::-1,:), lonnew,latnew, False)

    printVarSummary(t_intrp)
    ;=====================================================================
    ; output data file
    ;=============================================
       ncdfname = outdir+"/"+outfilename+"_intrp.nc"
       system("/bin/rm -f "+ncdfname)   ; remove any pre-existing file
       print(ncdfname)
       ncdf     = addfile(ncdfname ,"c")  ; open output netCDF file

    ; make time and UNLIMITED dimension      ; recommended  for most applications
       filedimdef(ncdf,"time",-1,True)

       t_intrp!3    = "lon"
       t_intrp!2    = "lat"
       t_intrp!1    = "lev"
       t_intrp!0    = "time"
       t_intrp&lat   = latnew
       t_intrp&lon   = lonnew
      ; t_plev&hyam   = hyam
       
       t_intrp&time  = time
       if (var .eq. "q") then
         t_intrp@long_name = "Specific humidity"           ; assign attributes
         t_intrp@units     = "kg/kg"
         ncdf->Q  = t_intrp
       end if
       if (var .eq. "t") then
         t_intrp@long_name = "Temperature"           ; assign attributes
         t_intrp@units     = "K"
         ncdf->T  = t_intrp
       end if
       if (var .eq. "v") then
         t_intrp@long_name = "Meridional wind, staggered"           ; assign attributes
         t_intrp@units     = "m/s"
         ncdf->V  = t_intrp
       end if
       if (var.eq."u") then
         t_intrp@long_name = "Zonal wind, staggered"           ; assign attributes
         t_intrp@units     = "m/s"
         ncdf->U  = t_intrp
       end if
       ;ncdf->$var$  = t_intrp

      ;ncdf->lev  = plev

      ;ncdf->date = filedate
      ;ncdf->datesec = filedatesec

      ;ncdf->PS   = psfc         ; (lat,lon) or (time,lat,lon)
      ncdf->hyam = hyam                             ; get a coefficiants
      ncdf->hybm = hybm                              ; get b coefficiants
      delete(cloud)
      ;delete(filedate)
      ;delete(filedatesec)
      delete(time)
      delete(psfc)
      delete(t_plev)
      ;delete(p2d)
      delete(var)
end do ; loop for
;  delete(var)
end do
end do
