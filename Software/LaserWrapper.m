function [Res] = LaserWrapper(strCommand, opt)
global g_laserWrapper
Res = [];
if strcmpi(strCommand,'Init')
    comPort = getCOMmapping('laser');
    Res = fnInit(comPort);
elseif strcmpi(strCommand,'IsInitialized')
    if isempty(g_laserWrapper) || ~isfield(g_laserWrapper,'initialized')
        Res = false;
    else
        Res = g_laserWrapper.initialized;
    end
elseif strcmpi(strCommand,'Release')
     try
        fprintf(g_laserWrapper.com, ['OFF',13,10]);    
      
     if ~isempty(g_laserWrapper)
        fclose(g_laserWrapper.com);
     end
     catch
     end
     
    
elseif strcmpi(strCommand,'LaserON')
     fprintf(g_laserWrapper.com, ['ON',13,10]);    
    Res=1;
elseif strcmpi(strCommand,'LaserOFF')
    fprintf(g_laserWrapper.com, ['OFF',13,10]);    
    Res=1;
elseif strcmpi(strCommand,'SetPower')
    intensity= min(500,max(0,opt));
    strOut = [sprintf('POWER=%d',intensity),13,10];
    fprintf(g_laserWrapper.com,strOut );    
    Res = 1;
elseif strcmpi(strCommand,'SetPowerAndWaitForStabilization')
    targetIntensity=opt;
    LaserWrapper('SetPower', targetIntensity);
    maxReadings = 50;
    fprintf('Read: ');
    stable = false;
    numStable = 0;
    for k=0:maxReadings
        v=LaserWrapper('GetPower');
        fprintf('%.1f, ',v);
        if (abs(targetIntensity-v) < 2)
            numStable=numStable+1;
        end
        if (numStable > 3)
            stable=true;
            break;
        end
        WaitSecs(0.2);
    end
    if (stable)
        fprintf('Now Stable.\n');
        Res=1;
    else
        fprintf('Failed!.\n');
        Res=0;
    end
    
elseif strcmpi(strCommand,'GetPower')
    clearBuffer();
    fprintf(g_laserWrapper.com, ['POWER?',13,10]);
    WaitSecs(0.2);
    if g_laserWrapper.com.BytesAvailable > 0
        Dummy = char(fread(g_laserWrapper.com, g_laserWrapper.com.BytesAvailable)');
        i1=strfind(Dummy,'mW');
        if ~isempty(i1)
         substr = Dummy(1:i1(1)-1);
         Res = str2num(substr);
         return;
        end
        Res = NaN;
        return;
    else
        Res = NaN;
    end
end
    
   
function clearBuffer()
global g_laserWrapper
if g_laserWrapper.com.BytesAvailable > 0
    Dummy = fread(g_laserWrapper.com, g_laserWrapper.com.BytesAvailable);
end
     

function [Res]=fnInit(strLaserPort)
global g_laserWrapper
fprintf('Initializing Laser Module...\n');
allComObjects = instrfind('Port',strLaserPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_laserWrapper.com = serial(strLaserPort,'BaudRate',9600);
try
    fopen(g_laserWrapper.com);
catch
    fprintf('Warning. Could not connect to filter wheel!\n');
    Res = false;
    return;
end
    
if ~strcmp(g_laserWrapper.com.Status,'open')
    fprintf('Error communicating with controller\n');
    Res = false;
    return;
end
%Clear buffer
if g_laserWrapper.com.BytesAvailable > 0
    Dummy = fread(g_laserWrapper.com, g_laserWrapper.com.BytesAvailable);
end

strOut = ['OFF',13,10];
fprintf(g_laserWrapper.com,strOut );    
WaitSecs(0.2);
clearBuffer();

% Turn off
strOut = ['STATUS?',13,10];
fprintf(g_laserWrapper.com,strOut );    
WaitSecs(0.2);
if (g_laserWrapper.com.BytesAvailable  > 0)
    Dummy = char(fread(g_laserWrapper.com, g_laserWrapper.com.BytesAvailable))';
    if (findstr(Dummy,'DISABLED'))
        fprintf('Laser Module Initialized Successfuly\n');
        g_laserWrapper.initialized = true;
        Res = true;
        return;
    end
end

try
        fclose(g_laserWrapper.com);
catch
end
        g_laserWrapper.initialized = false;
        Res = false;

return;
