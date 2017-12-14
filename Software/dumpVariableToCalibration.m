function dumpVariableToCalibration(var, name)
if ~exist('name','var')
    name = inputname(1);
end
hdf5File = SessionWrapper('GetSession');
calibrationID=GetCurrentCalibration();
calibrationPath = sprintf('/calibrations/calibration%d/%s',calibrationID,name);
if islogical(var) || ischar(var)
    var = uint8(var);
end

try
 if prod(size(var))<4e9
        h5create(hdf5File, calibrationPath, size(var),'Deflate',0, 'DataType', class(var),'ChunkSize',size(var));
    else
        h5create(hdf5File, calibrationPath, size(var),'Deflate',0, 'DataType', class(var),'ChunkSize',size(var)/2);
 end
catch
    fprintf('Warning, %s already exists. Rewriting...\n',name);
end
    
% try
% if size(var,1) > 50 && size(var,2) > 80
%     if size(var,3) > 50
%         if size(var,4) > 1
%             h5create(hdf5File,calibrationPath,size(var),'Deflate',0,'ChunkSize',[50 80 50 3 3],'Datatype',class(var));
%         else
%             h5create(hdf5File,calibrationPath,size(var),'Deflate',0,'ChunkSize',[50 80 50],'Datatype',class(var));
%         end
%     elseif size(var,3) > 10
%         h5create(hdf5File,calibrationPath,size(var),'Deflate',0,'ChunkSize',[50 80 10],'Datatype',class(var));
%     else
%         h5create(hdf5File,calibrationPath,size(var),'Deflate',0,'ChunkSize',[50 80],'Datatype',class(var));
%     end
% else
%     h5create(hdf5File,calibrationPath,size(var),'Datatype',class(var));
% end
% catch
%     fprintf('Warning, %s already exists. Rewriting...\n',name);
% end
try
    h5write(hdf5File,calibrationPath, var);
catch
    fprintf('error Dumping variable %s\n. Drive too full ?!?!?',name);    
end
return;