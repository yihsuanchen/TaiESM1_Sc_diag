#!/usr/bin/env python
# coding: utf-8

# # Program - Read and Return different datasets
# 
# **Purpose**
# 
# 
# **Content**
# - read different dataset (model, reanalysis, etc.) and return Xarray Dataset
# 
# **Author:** Yi-Hsuan Chen (yihsuan@umich.edu)
# 
# **Date:** 
# 
# **Reference program:**
# 
# **Convert ipynb to py:**
# 
# jupyter nbconvert read_data.ipynb --to python
# 
# **import:**
# 
# import read_data as read_data
# 

# In[3]:


import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
import numpy as np
import xarray as xr
import io, os, sys, types

import yhc_module as yhc

xr.set_options(keep_attrs=True)  # keep attributes after xarray operation


# ## Template

# In[4]:


def read__data(choice): 
    func_name = "read__data"

    #--- set datapath and files
    if (choice == ""):
        datapath = ""
        fnames = [
            "",
            "",
                 ]


    else:
        error_msg = f"ERROR: function [{func_name}] does not support [{choice}]."
        raise ValueError(error_msg)

    #--- read files using xarray
    fnames = [datapath+"/"+file1 for file1 in fnames]
    ds_out = xr.open_mfdataset(fnames)

    #--- return dataset
    return ds_out
        
#-----------
# do_test
#-----------

#do_test=True
do_test=False

if (do_test):
    choice = ""
    ds_out = read__data(choice)
    print(ds_out)


# ## Read TaiESM data

# In[5]:


def read_TaiESM_data(choice): 
    func_name = "read_TaiESM_data"

    if (choice == "rsut_Amon_TaiESM1_amip-hist_r1i1p1f1_1979_2014"):
        datapath = "/Users/yi-hsuanchen/Downloads/yihsuan/research/data/TaiESM1/data/CMIP6/TaiESM1/amip-hist/atmos/mon/r1i1p1f1/"
        fnames = [
    "rsut_Amon_TaiESM1_amip-hist_r1i1p1f1_gn_197901-201012.nc",
    "rsut_Amon_TaiESM1_amip-hist_r1i1p1f1_gn_201101-201412.nc",
                 ]
        
    elif (choice == "rlut_Amon_TaiESM1_amip-hist_r1i1p1f1_1979_2014"):
        datapath = "/Users/yi-hsuanchen/Downloads/yihsuan/research/data/TaiESM1/data/CMIP6/TaiESM1/amip-hist/atmos/mon/r1i1p1f1/"
        fnames = [
    "rlut_Amon_TaiESM1_amip-hist_r1i1p1f1_gn_197901-201012.nc",
    "rlut_Amon_TaiESM1_amip-hist_r1i1p1f1_gn_201101-201412.nc",
                 ]
        
    else:
        error_msg = f"ERROR: function [{func_name}] does not support [{choice}]."
        raise ValueError(error_msg)
        
    fnames = [datapath+file1 for file1 in fnames]
    ds_out = xr.open_mfdataset(fnames)

    return ds_out
        
#-----------
# do_test
#-----------

do_test=True
#do_test=False

if (do_test):
    choice = "rlut_Amon_TaiESM1_amip-hist_r1i1p1f1_1979_2014"
    ds_TaiESM1 = read_TaiESM_data(choice)
    print(ds_TaiESM1)


# ## Read CERES data

# In[24]:


def read_CERES_data(choice): 
    func_name = "read_CERES_data"

    if (choice == "CERES_EBAF-TOA_Ed4.2_Subset_200101-201412"):
        datapath = "/Users/yi-hsuanchen/Downloads/yihsuan/research/data/CERES"
        fnames = [
            "CERES_EBAF-TOA_Ed4.2_Subset_200101-201412.nc"
                 ]

        fnames = [datapath+"/"+file1 for file1 in fnames]
        #fnames = [datapath+file1 for file1 in fnames]
        ds_out = xr.open_mfdataset(fnames)

        return ds_out

    else:
        error_msg = f"ERROR: function [{func_name}] does not support [{choice}]."
        raise ValueError(error_msg)
        
#-----------
# do_test
#-----------

#do_test=True
do_test=False

if (do_test):
    choice = "CERES_EBAF-TOA_Ed4.2_Subset_200101-201412"
    ds_out = read_CERES_data(choice)
    print(ds_out)


# In[ ]:




