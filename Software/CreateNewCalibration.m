function calibrationID=CreateNewCalibration()
global g_calibrationID
hdf5File = SessionWrapper('GetSession');
% find how many calibrations are there...
hdf5FileInfo = h5info(hdf5File);
calibrationID = 1;
if isempty(hdf5FileInfo.Groups)
    % no calibrations done yet.
else
    calibrationGroup = find(ismember({hdf5FileInfo.Groups.Name},'/calibrations'));
    if isempty(calibrationGroup)
        % no calibrations done yet.
    else
        Tmp = hdf5FileInfo.Groups(calibrationGroup);
        calibrationID = length(Tmp.Groups)+1;
    end
end
try
    h5create(hdf5File,sprintf('/calibrations/calibration%d/dummy',calibrationID),[1 1])
catch
    fprintf('Failed to create a new calibration group\n');
    return;
end
g_calibrationID = calibrationID;
fprintf('Creating new calibration ID %d in %s\n',calibrationID,hdf5File);
    
return;
