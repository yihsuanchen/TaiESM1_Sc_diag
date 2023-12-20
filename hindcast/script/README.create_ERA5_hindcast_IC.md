# README - Create the initial data for TaiESM hindcast simulation from ERA5

**Pre-request**
Download the ERA5 data

- ERA5 hourly data on pressure levels from 1940 to present
  - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=overview
-  ERA5 hourly data on single levels from 1940 to present
  - https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=overview

**Step-by-step instruction**
1. Edit and run 01a-icdata_select_time_loop.sh.
   This script will select each time step in the ERA5 files and write the data into new files.

2. Edit the run 01b-intrp_ERA5_to_CAM_coords.sh.

   This script will create commands running a NCL program with given files from the previous step.
   The NCL program will Interpolate ERA5 surface pressure and T,Q,U,V on CAM hybrid vertical coordinate and lat/lon grids, and save these interpolated fileds into a new file. 
   The new files are used for running hindcast simulations.

3. Check the original ERA5 fields with the newly interpolated fields 

**Reference program:**
- /lfs/home/hsieh8835/05-IC/geticdata_loop_goamzn.csh
- /lfs/home/hsieh8835/05-IC/replacedata_loopdate_v2.csh
- /lfs/home/hsieh8835/05-IC/plevint_eraitm_intp_loopdate.ncl


**Author:** 
Yi-Hsuan Chen (yihsuan@umich.edu)

**Date:** 
December 2023


