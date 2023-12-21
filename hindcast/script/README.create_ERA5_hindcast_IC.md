# README - Create the initial data for TaiESM hindcast simulation. The initial data is from ERA5.

**Pre-request**
Download the ERA5 data

- ERA5 hourly data on pressure levels from 1940 to present
  - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=overview
-  ERA5 hourly data on single levels from 1940 to present
  - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=overview

**Step-by-step instruction**
1. Edit and run createIC_01a-icdata_select_time_loop.sh.
   This script will select each time step in the ERA5 files and write the selected data into new files.

2. Edit createIC_01b-intrp_ERA5_to_CAM_coords.sh, and run it.

   This script will create commands running a NCL program with given files from the previous step.
   The NCL program will Interpolate ERA5 surface pressure and T,Q,U,V on CAM hybrid vertical coordinate and lat/lon grids, and save these interpolated fileds into a new file. 
   The new files are used for running hindcast simulations.

3. Use 'ncview' to check the original ERA5 fields with the newly interpolated fields.
   > ncview $ERA5_FILE   # note that although ERA5 variables are in short format, ncview somehow convert them into float format
   > ncview $NEW_FILE

   Select Var, and click 'Range' botton to set the contour intervals.
   Click 'level' to plot the variables on map. Note that the level is on vertical coordinate (pressure levels or hybrid levels).
   Although $NEW_FILE is on hybrid level, the values not indicate actually pressure but they are close when surface pressure ~1000hPa.

**Reference program:**
- /lfs/home/hsieh8835/05-IC/geticdata_loop_goamzn.csh
- /lfs/home/hsieh8835/05-IC/replacedata_loopdate_v2.csh
- /lfs/home/hsieh8835/05-IC/plevint_eraitm_intp_loopdate.ncl


**Author:** 
Yi-Hsuan Chen (yihsuan@umich.edu)

**Date:** 
December 2023


