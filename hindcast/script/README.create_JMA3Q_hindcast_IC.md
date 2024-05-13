# README - Create the initial data for TaiESM hindcast simulation. The initial data is from JMA3Q.

**Pre-request**
Download the JMA3Q data
https://jra.kishou.go.jp/JRA-3Q/index_en.html

An overview of JRA-3Q data, 1.25-degree latitude/longitude grid data (https://jra.kishou.go.jp/JRA-3Q/document/JRA-3Q_LL125_format_en.pdf)

Require variables: u, v, t, q, Ps
Time: 00Z on each day

JMA3Q data is on BIG: /lfs/archive/Reanalysis/JRA3Q

- JMA3Q 6-hourly data on pressure level
    - /lfs/archive/Reanalysis/JRA3Q/6hr/anl_p125
- JMA3Q surface data
    - /lfs/archive/Reanalysis/JRA3Q/6hr/anl_surf125

Example of JMA3Q file names (in Grib format)
    anl_p125_rh.2001073006

**Step-by-step instruction (not updated yet)**
1. Edit createIC_JMA3Q_01-intrp_JMA3Q_to_CAM_coords.sh, and then run it.

   This script will create commands running a NCL program with given input parameters.
   The NCL program will interpolate JMA3Q surface pressure and T,Q,U,V on CAM hybrid vertical coordinate and lat/lon grids, and save these interpolated fileds into a new file. 
   The new files are used for running hindcast simulations.

   The NCL program is 02a-intrp_JRA3Q_to_CAM_coords.ncl.

3. Use 'ncview' to check the original JMA3Q fields with the newly interpolated fields.
  
   > ncl_convert2nc $JMA3Q_FILE    # convert grib to nc. Check the global attributes in NEW_FILE

   > ncview $JMA3Q_FILE_NC         # netCDF version of JMA3Q files
   > ncview $NEW_FILE

   Select Var, and click 'Range' botton to set the contour intervals.
   Click 'level' to plot the variables on map. Note that the level is on vertical coordinate (pressure levels or hybrid levels).
   Although $NEW_FILE is on hybrid level, the values not indicate actually pressure but they are close when surface pressure ~1000hPa.

**Reference program:**

**Author:** 
Yi-Hsuan Chen (yihsuan@umich.edu)

**Date:** 
May 2024


