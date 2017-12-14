function [Res, parsedResponse] = LEDdriverWrapper(strCommand, opt)
global g_LEDDriverWrapper


parsedResponse = [];

if strcmpi(strCommand,'Init')
    comPort = getCOMmapping('LEDdriver');
    [Res, parsedResponse] = fnInit(comPort);
    return;
elseif strcmpi(strCommand,'SetDurationOn')
    channel = opt(1);
    value = opt(2);
    strOpt = sprintf('%02d %d',channel,value);
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_SET_DURATION_ON, strOpt, 'OK!',0);
    return;       
elseif strcmpi(strCommand,'SetDurationOff')
    channel = opt(1);
    value = opt(2);
    strOpt = sprintf('%02d %d',channel,value);
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_SET_DURATION_OFF, strOpt, 'OK!',0);
    return;       
elseif strcmpi(strCommand,'SetNumPulses')
    channel = opt(1);
    value = opt(2);
    strOpt = sprintf('%02d %d',channel,value);
    
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_SET_NUM_PULSES,strOpt, 'OK!',0);
    return;       
elseif strcmpi(strCommand,'SetIntensity')
    channel = opt(1);
    value = opt(2);
    strOpt = sprintf('%02d %d',channel,value);
    
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_SET_INTENSITY, strOpt, 'OK!',0);
    return;  
elseif strcmpi(strCommand,'TurnOn')
    channel = opt(1);
    strOpt = sprintf('%02d',channel);
    
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_TURN_ON, strOpt, 'OK!',0);
    return;  
elseif strcmpi(strCommand,'SimulateTrigger')
    channel = opt(1);
    strOpt = sprintf('%02d',channel);
    
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_SIMULATE_TRIGGER, strOpt, 'OK!',0);
    return;      
    
elseif strcmpi(strCommand,'TurnOff')
    channel = opt(1);
    strOpt = sprintf('%02d',channel);
    
    Res = auxSendCommand(g_LEDDriverWrapper.codes.CMD_TURN_OFF, strOpt, 'OK!',0);
    return;      
elseif strcmpi(strCommand,'Release')
    fprintf('Releasing LED driver controller\n');
     try
     if ~isempty(g_LEDDriverWrapper)
        fclose(g_LEDDriverWrapper.com);
     end
     catch
     end
    g_LEDDriverWrapper.initialized = false;
    Res = true;   
 
else
    fprintf('Unknown command!\n');
end

return;


function [Res,parsedResponse]=fnInit(strPort)
global g_LEDDriverWrapper

g_LEDDriverWrapper.codes.CMD_SET_DURATION_ON = 1;
g_LEDDriverWrapper.codes.CMD_SET_DURATION_OFF = 2;
g_LEDDriverWrapper.codes.CMD_SET_NUM_PULSES = 3;
g_LEDDriverWrapper.codes.CMD_SET_INTENSITY = 4;
g_LEDDriverWrapper.codes.CMD_TURN_ON = 5;
g_LEDDriverWrapper.codes.CMD_TURN_OFF = 6;
g_LEDDriverWrapper.codes.CMD_SIMULATE_TRIGGER = 7;
fprintf('Initializing LED Driver ...\n');
parsedResponse = [];
allComObjects = instrfind('Port',strPort);
for k=1:length(allComObjects)
    if strcmp(allComObjects(k).Status,'open')
        fprintf('Found an already opened port...closing!\n');
        fclose(allComObjects(k));
    end
end
g_LEDDriverWrapper.com = serial(strPort,'BaudRate',115200);
try
    fopen(g_LEDDriverWrapper.com);
catch
    fprintf('Warning. Could not connect to LED Driver!\n');
    Res = false;
    return;
end
if ~strcmp(g_LEDDriverWrapper.com.Status,'open')
    printError();
    Res = false;
    return;
    
end
WaitSecs(3);
clearBuffer();

g_LEDDriverWrapper.initialized = true;
Res = true;
return;


function [Res, parsedRespose] = auxSendCommand(command, strParameters, strExpectedResponse, waitPeriod)
global g_LEDDriverWrapper
parsedRespose =[];
Res = false;
if isempty(g_LEDDriverWrapper) || strcmp(g_LEDDriverWrapper.com.Status,'closed')
    return;
end;
    clearBuffer();
if ~isempty(strParameters)
 fprintf(g_LEDDriverWrapper.com, [sprintf('%02d %s',command,strParameters),10]);    
else
    try
        fprintf(g_LEDDriverWrapper.com, [sprintf('%02d',command),10]);
    catch
    printError();
    Res = false;
        
    end
    
end
if ~exist('waitPeriod','var')
    waitPeriod = 0.9;
end
if waitPeriod > 0
    WaitSecs(waitPeriod);
else
    fprintf('Waiting for LED driver controller to respond...');
    while g_LEDDriverWrapper.com.BytesAvailable == 0
        WaitSecs(0.2);
    end
    fprintf('OK\n');
end

if g_LEDDriverWrapper.com.BytesAvailable > 0
    Dummy = fread(g_LEDDriverWrapper.com, g_LEDDriverWrapper.com.BytesAvailable);
else
    printError();
    Res = false;
    return;
    
end
if isempty(strExpectedResponse)
    Res = char(Dummy');
    return;
end
if ~strncmpi(char(Dummy'),strExpectedResponse,length(strExpectedResponse))
    fprintf('Error communicating with controller (weird response: %s)\n',char(Dummy'));
    Res = false;
    return;
else
    %fprintf('Communication with device OK!\n');
end
if length(Dummy) > 5
  parsedRespose = str2num(char(Dummy(5:end)'));
end
Res = true;
return;

function clearBuffer()
global g_LEDDriverWrapper
% clear buffer.

clear Dummy
if g_LEDDriverWrapper.com.BytesAvailable > 0
    Dummy = fread(g_LEDDriverWrapper.com, g_LEDDriverWrapper.com.BytesAvailable);
end

function printError()
fprintf('Error communicating with controller\n');