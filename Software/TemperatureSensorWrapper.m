function [Res] = TemperatureSensorWrapper(strCommand, opt)
global g_tempWrapper
Res = [];
if strcmpi(strCommand,'Init')
    comPort = getCOMmapping('temperature');
    Res = fnInit(comPort);
elseif strcmpi(strCommand,'ClearBuffer')    
    Dummy = fread(g_tempWrapper.com, g_tempWrapper.com.BytesAvailable);
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_tempWrapper) || ~isfield(g_tempWrapper,'initialized')
        Res = false;
    else
        Res = g_tempWrapper.initialized;
    end
elseif strcmpi(strCommand,'GetTemperature')
    
    if g_tempWrapper.com.BytesAvailable > 0
        Dummy = fread(g_tempWrapper.com, g_tempWrapper.com.BytesAvailable);
         i1=find(Dummy==10,1,'first');
        i2=find(Dummy==10,1,'last');
        Res = str2num(char(Dummy(i1:i2)'));
        return;
    else
        Res = NaN;
    end
elseif strcmpi(strCommand,'Release')    
     if ~isempty(g_tempWrapper)
        fclose(g_tempWrapper.com);
     end
    g_tempWrapper.initialized = false;
    Res = true;   
end
    
        

function [Res]=fnInit(strMotorPort)
global g_tempWrapper
fprintf('Initializing Temperature Module...\n');
allComObjects = instrfind('Port',strMotorPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_tempWrapper.com = serial(strMotorPort,'BaudRate',115200);
try
    fopen(g_tempWrapper.com);
catch
    fprintf('Warning. Could not connect to temperature sensor!\n');
    Res = false;
    return;
end
    
if ~strcmp(g_tempWrapper.com.Status,'open')
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
    
end

g_tempWrapper.initialized = true;
Res = true;
return;
