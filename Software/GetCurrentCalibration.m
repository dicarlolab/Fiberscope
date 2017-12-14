
function calibrationID=GetCurrentCalibration()
global g_calibrationID
if isempty(g_calibrationID)
   g_calibrationID = 1;
   calibrationID=1;
else
    calibrationID = g_calibrationID ;
end
% % 
% % hdf5File = SessionWrapper('GetSession');
% % % find how many calibrations are there...
% % hdf5FileInfo = h5info(hdf5File);
% % calibrationID = [];
% % if isempty(hdf5FileInfo.Groups)
% %     % no calibrations done yet.
% % else
% %     calibrationGroup = find(ismember({hdf5FileInfo.Groups.Name},'/calibrations'));
% %     if isempty(calibrationGroup)
% %         % no calibrations done yet.
% %     else
% %         Tmp = hdf5FileInfo.Groups(calibrationGroup);
% %         calibrationID = length(Tmp.Groups);
% %     end
% % end
return;
