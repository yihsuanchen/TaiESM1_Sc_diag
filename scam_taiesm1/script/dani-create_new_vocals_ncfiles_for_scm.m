% Open the original file for reading
clear;
ncpath = '/lfs/home/dani/TaiESM_scam/ncinputs/IOP/';
vocals_fn = 'VOCALS_REx-GFS_SCM_forc-all_times_stations.nc';
vocals_fullpath = ([ncpath,vocals_fn]);
vocals_allstations = netcdf.open([vocals_fullpath], 'NOWRITE');

vocals = ncinfo(vocals_fullpath);
% Get the dimension IDs
time_dimID = netcdf.inqDimID(vocals_allstations, 'time');
lev_mid_dimID = netcdf.inqDimID(vocals_allstations, 'lev_mid');
lev_int_dimID = netcdf.inqDimID(vocals_allstations, 'lev_int');


% Get the dimension sizes
[~, time_size] = netcdf.inqDim(vocals_allstations, time_dimID);
[~, lev_mid_size] = netcdf.inqDim(vocals_allstations, lev_mid_dimID);
[~, lev_int_size] = netcdf.inqDim(vocals_allstations, lev_int_dimID );
%[~, latitude_size] = netcdf.inqDim(vocals_allstations, latitude_dimID);
%[~, longitude_size] = netcdf.inqDim(vocals_allstations, longitude_dimID);

% Loop through all station indexes
num_stations = 25+1;
for station_index = 1%:num_stations - 1


    % Create a file name with a two-digit station number
    fname = sprintf('VOCALS_ST%02d_4scam_sigma.nc', station_index);
    file_name = fullfile(ncpath,fname);
    disp(fname);
    % Check if the file exists and delete if it does
    if exist(file_name, 'file') == 2
        delete(file_name);
    end

    % Open a new NetCDF file for writing
    new_file = netcdf.create([file_name], 'NETCDF4');

    % Add global attributes to the new file
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'Title', 'NCAP GFS Single Column Model Forcing Data for VOCALS-Rex, binary to netCDF');
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'Data_source', 'NCAR/UCAR EOL - VOCALS: NCEP GFS Single Column Model Forcing Data, https://data.eol.ucar.edu/dataset/89.105');
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'Data_reference', 'https://data.eol.ucar.edu/file/download/41B38ABB023/NCEP_GFS_Single_Column_Model_Forcing_Data_for_VOCALS_Rex.pdf');
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'Data_notes', 'From the original VOCALS_REx-GFS_SCM_forc-all_times_stations.nc by yhc, only 3d data needed by TaiESM1-SCM simulation. Divided the original to per station');
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'History', 'Created on 2024-06-06');
    netcdf.putAtt(new_file, netcdf.getConstant('NC_GLOBAL'), 'Contact', 'Yi-Hsuan Chen (yihsuanc@gate.sinica.edu.tw), Danielle Manalaysay (danimanalaysay@gate.sinica.edu.tw)');

    % Define dimensions
    time_dimID_new = netcdf.defDim(new_file, 'time', time_size);
    lev_mid_dimID_new = netcdf.defDim(new_file, 'lev', lev_mid_size);
    latitude_dimID_new = netcdf.defDim(new_file, 'lat', 1);
    longitude_dimID_new = netcdf.defDim(new_file, 'lon', 1);
    %station_dimID_new =  netcdf.defDim(new_file, 'station', 1);

    % Define coordinate variables
    time_varID = netcdf.defVar(new_file, 'tsec', 'int', time_dimID_new);
    bdate_varID = netcdf.defVar(new_file, 'bdate', 'int',[]);
    station_varID = netcdf.defVar(new_file, 'station', 'int', []);


    %% Get the original time data
    time_varID_orig = netcdf.inqVarID(vocals_allstations, 'time');
    time_data = netcdf.getVar(vocals_allstations, time_varID_orig, 0, time_size);
    % Calculate tsec
    bdate_temp = num2str(time_data(1));
    bdate = int32(str2double(bdate_temp(1:8)));
    tdate_str= time_data;

    % Convert the base date string to a serial date number
    bdate_num = datenum(num2str(time_data(1)), 'yyyymmddHH');

    % Convert the target date string to a serial date number
    tdate_num = datenum(num2str(tdate_str), 'yyyymmddHH');

    % Calculate the difference in days
    days_difference = tdate_num - bdate_num;

    % Convert the difference in days to seconds
    tsec= days_difference * 24 * 3600;

    %% varID #1: tsec

    netcdf.putVar(new_file, time_varID, tsec);
    netcdf.putAtt(new_file, time_varID, 'long_name', 'Time in seconds after 0Z on base date');
    netcdf.putAtt(new_file, time_varID, 'units', 's');

    %% varID #2: bdate

    netcdf.putVar(new_file, bdate_varID, bdate);
    netcdf.putAtt(new_file, bdate_varID, 'long_name', 'Base date as 6 digit integer');
    netcdf.putAtt(new_file, bdate_varID, 'units', 'yymmdd');

    %% varID #3: station
    station_varID_orig = netcdf.inqVarID(vocals_allstations, 'station');
    station_data = netcdf.getVar(vocals_allstations, station_varID_orig, station_index-1, 1);
    netcdf.putVar(new_file, station_varID, station_data);


    %% varID #4 #5: lat/lon
    lat_varID = netcdf.defVar(new_file, 'lat', 'NC_FLOAT', latitude_dimID_new);
    lon_varID = netcdf.defVar(new_file, 'lon', 'NC_FLOAT', longitude_dimID_new);
    latitude_varID_orig = netcdf.inqVarID(vocals_allstations, 'latitude');
    longitude_varID_orig = netcdf.inqVarID(vocals_allstations, 'longitude');

    latitude_data = netcdf.getVar(vocals_allstations, latitude_varID_orig, station_index-1, 1);
    longitude_data = netcdf.getVar(vocals_allstations, longitude_varID_orig, station_index-1, 1);

    netcdf.putVar(new_file, lat_varID, latitude_data);
    netcdf.putVar(new_file, lon_varID, longitude_data);

    %% varID #6: lev
    lev_varID = netcdf.defVar(new_file, 'lev', 'NC_FLOAT', [lev_mid_dimID_new]);
    lev_varID_orig = netcdf.inqVarID(vocals_allstations, 'p');
    lev_data = netcdf.getVar(vocals_allstations, netcdf.inqVarID(vocals_allstations, 'p'), [0,station_index-1, 0], [lev_mid_size,1,1]);

    netcdf.putVar(new_file, lev_varID, flip(lev_data));
    note_on_lev = 'Model pressure of the first time step only';

    varNEW = {'station','latitude','longitude','p'};
    varNEW_index = {station_varID,lat_varID,lon_varID,lev_varID };
    for i = 1:4
        varname = varNEW{i};
        varID_orig = netcdf.inqVarID(vocals_allstations, varname );

        try
            lname = netcdf.getAtt(vocals_allstations, varID_orig , 'long_name');
            netcdf.putAtt(new_file, varNEW_index{i}, 'long_name', lname);
        catch
            % Attribute does not exist
        end
        try
            units = netcdf.getAtt(vocals_allstations,  varID_orig , 'units');
            netcdf.putAtt(new_file, varNEW_index{i}, 'units', units);
        catch
            % Attribute does not exist
        end
        if i ==4
            netcdf.putAtt(new_file, varNEW_index{i}, 'remarks',note_on_lev);
        end
    end

    varnames_2d = {'zsfc', 'psfc', 'dpsdt', 'tsfc', 'u10', 'v10', 't2', 'q2', 'hpbl'};
    for i = 1:numel(varnames_2d)
        varname = varnames_2d{i};
        var_data = netcdf.getVar(vocals_allstations, netcdf.inqVarID(vocals_allstations, varname), [station_index-1, 0], [1,time_size]);

        if i ==2 % if surface pressure, rename for SCAM
            varID = netcdf.defVar(new_file, 'Ps', 'NC_FLOAT', [longitude_dimID_new,latitude_dimID_new, time_dimID_new ]);
        elseif i ==3 % if surface pressure, rename for SCAM
            varID = netcdf.defVar(new_file, 'Ptend', 'NC_FLOAT', [longitude_dimID_new,latitude_dimID_new, time_dimID_new ]);
        elseif i == 4 % if surface temperature, rename for SCAM
            varID = netcdf.defVar(new_file, 'Tg', 'NC_FLOAT', [longitude_dimID_new,latitude_dimID_new, time_dimID_new ]);
        else
            varID = netcdf.defVar(new_file, varname, 'NC_FLOAT', [longitude_dimID_new,latitude_dimID_new, time_dimID_new ]);
        end

        netcdf.putVar(new_file, varID, var_data);

        % Preserve variable attributes
        varID_orig = netcdf.inqVarID(vocals_allstations, varname);

        try
            units = netcdf.getAtt(vocals_allstations, varID_orig, 'units');
            netcdf.putAtt(new_file, varID, 'units', units);
        catch
            % Attribute does not exist
        end
        try
            long_name = netcdf.getAtt(vocals_allstations, varID_orig, 'long_name');
            netcdf.putAtt(new_file, varID, 'long_name', long_name);
        catch
            % Attribute does not exist
        end
        try
            fillValue = netcdf.getAtt(vocals_allstations, varID_orig, '_FillValue');
            if isnan(fillValue)
                netcdf.putAtt(new_file, varID, 'missing_value', NaN);
            else
                netcdf.putAtt(new_file, varID, 'missing_value', 'NaNf');
            end
        catch
        end

    end

    %% Ptend


    varnames_3d = {'u', 'v', 't', 'q', 'omega', 'dtdt', 'dqdt'};
    % Loop through 3D variables and add them to the new file
    for i = 1:numel(varnames_3d)
        varname = varnames_3d{i};
        var_data = netcdf.getVar(vocals_allstations, netcdf.inqVarID(vocals_allstations, varname), [0, station_index-1, 0], [lev_mid_size, 1, time_size]);

        if i == 3
            varID = netcdf.defVar(new_file, 'T', 'NC_FLOAT', [longitude_dimID_new, latitude_dimID_new, lev_mid_dimID_new ,time_dimID_new]);
        elseif i == 6
            varID = netcdf.defVar(new_file, 'divT', 'NC_FLOAT', [longitude_dimID_new, latitude_dimID_new, lev_mid_dimID_new ,time_dimID_new]);
        elseif i == 7
           varID = netcdf.defVar(new_file, 'divq', 'NC_FLOAT', [longitude_dimID_new, latitude_dimID_new, lev_mid_dimID_new ,time_dimID_new]);
         else
            varID = netcdf.defVar(new_file, varname, 'NC_FLOAT', [longitude_dimID_new, latitude_dimID_new, lev_mid_dimID_new ,time_dimID_new]);
        end


        netcdf.putVar(new_file, varID, flip(var_data));
        % Preserve variable attributes
        varID_orig = netcdf.inqVarID(vocals_allstations, varname);

        % Attribute does not exist

        try
            units = netcdf.getAtt(vocals_allstations, varID_orig, 'units');
            netcdf.putAtt(new_file, varID, 'units', units);
        catch
            % Attribute does not exist
        end
        try
            long_name = netcdf.getAtt(vocals_allstations, varID_orig, 'long_name');
          %  if i == 8
          %      long_name = 'dummy vertical q advection term ';
          %  elseif i == 9
          %      long_name = 'dummy vertical q advection term ';
          %  end
            netcdf.putAtt(new_file, varID, 'long_name', long_name);
        catch
            % Attribute does not exist
        end
        try
            fillValue = netcdf.getAtt(vocals_allstations, varID_orig, '_FillValue');
            if isnan(fillValue)
                netcdf.putAtt(new_file, varID, 'missing_value', NaN);
            else
                netcdf.putAtt(new_file, varID, 'missing_value', 'NaNf');
            end
        catch
            % Attribute does not exist
        end
    end
    %}
    % Close the new file
    netcdf.close(new_file);
end

% Close the original file
netcdf.close(vocals_allstations);

vocals_orig= ncinfo(vocals_fullpath);
vocals_new = ncinfo(["new_file_station_01.nc"]);